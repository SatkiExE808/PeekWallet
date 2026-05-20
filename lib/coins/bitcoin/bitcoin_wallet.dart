import 'dart:async';

import 'package:flutter/foundation.dart' show compute;

import '../../prefs/rpc_overrides.dart';
import '../../util/peek_logger.dart';
import 'bitcoin_explorer.dart';
import 'bitcoin_keys.dart';
import 'bitcoin_tx_builder.dart';
import 'blockchair_explorer.dart';
import 'chain_params.dart';
import 'mempool_client.dart';

/// Runtime handle for a Bitcoin wallet — the equivalent of
/// MoneroWallet but coordinated through mempool.space instead of a
/// native sync engine. Lifecycle:
///
///   1. Construct via [BitcoinWallet.open] passing the seed material
///      (mnemonic + passphrase) and the gap-limit address horizon to
///      scan.
///   2. The constructor derives a window of addresses up to the gap
///      limit (default 20). UI polls [balance] / [transactions];
///      each call refreshes the mempool.space data.
///   3. [close] tears down the HTTP client.
///
/// Send (BIP143 P2WPKH) is implemented via [sendBitcoin]. Builds the
/// transaction with a hand-rolled BIP143 signer (no native deps; the
/// implementation is spec-vector tested against the canonical
/// `c37af31116d1...` sigHash from the BIP itself).
class BitcoinWallet {
  BitcoinWallet._({
    required this.mnemonic,
    required this.passphrase,
    required this.gapLimit,
    required this.addresses,
    required this.params,
  }) : _client = _buildClient(params);

  /// Build the chain's explorer. Always starts with the mempool.space-
  /// compatible client (primary + any user override + same-API
  /// fallbacks). For chains where the Esplora API has few public
  /// mirrors — Litecoin most notably — we also stack a Blockchair
  /// adapter underneath so a litecoinspace outage falls through to a
  /// different provider on a different infrastructure.
  static BitcoinExplorer _buildClient(BitcoinChainParams params) {
    final override = RpcOverrides.I.get(params.id, 'mempool');
    final urls = <String>[
      if (override != null && override.isNotEmpty) override,
      ...params.allMempoolBaseUrls,
    ];
    final mempool = MempoolClient(baseUrls: urls);
    final fallbacks = <BitcoinExplorer>[
      if (params.id == 'LTC') BlockchairExplorer.forLitecoin(),
      if (params.id == 'BTC') BlockchairExplorer.forBitcoin(),
    ];
    if (fallbacks.isEmpty) return mempool;
    return CompositeExplorer(primary: mempool, fallbacks: fallbacks);
  }

  /// Open a Bitcoin (or Litecoin / any BIP143-compatible chain) wallet
  /// for the given seed. Derives [gapLimit] addresses on the external
  /// (receive) chain so balance / history can be summed across all
  /// of them.
  ///
  /// [params] selects the chain. Default = Bitcoin mainnet, so the
  /// existing BTC call sites keep working with no change.
  factory BitcoinWallet.open({
    required String mnemonic,
    String passphrase = '',
    int gapLimit = 20,
    BitcoinChainParams params = kBtcMainnet,
  }) {
    // Synchronous path — kept for tests + any caller that doesn't
    // have an Isolate context. Uses the batched derivation helper
    // so the seed + BIP32 root are computed ONCE and reused for all
    // gap-limit indices (saves ~19 PBKDF2-HMAC-SHA512 rounds vs. the
    // old per-index loop).
    final addrs = deriveBitcoinReceiveAddresses(
      mnemonic: mnemonic,
      passphrase: passphrase,
      count: gapLimit,
      params: params,
    );
    return BitcoinWallet._(
      mnemonic: mnemonic,
      passphrase: passphrase,
      gapLimit: gapLimit,
      addresses: addrs,
      params: params,
    );
  }

  /// Same as [BitcoinWallet.open] but ships the BIP39 → BIP32 →
  /// gap-limit derivation to a background [compute] isolate. The
  /// main isolate keeps rendering while ~200 ms of crypto work
  /// happens off-thread. Returned wallet is identical to the sync
  /// version — same addresses, same params.
  static Future<BitcoinWallet> openAsync({
    required String mnemonic,
    String passphrase = '',
    int gapLimit = 20,
    BitcoinChainParams params = kBtcMainnet,
  }) async {
    final addrs = await compute(
      _deriveAddressesInIsolate,
      _DeriveBitcoinArgs(
        mnemonic: mnemonic,
        passphrase: passphrase,
        gapLimit: gapLimit,
        params: params,
      ),
    );
    return BitcoinWallet._(
      mnemonic: mnemonic,
      passphrase: passphrase,
      gapLimit: gapLimit,
      addresses: addrs,
      params: params,
    );
  }

  final String mnemonic;
  final String passphrase;
  final int gapLimit;
  final List<BitcoinAddressDerivation> addresses;
  /// Which chain this wallet talks to (BTC / LTC / …). Determines
  /// HRP, derivation path, and which mempool-space-compatible
  /// explorer we hit.
  final BitcoinChainParams params;
  final BitcoinExplorer _client;
  bool _closed = false;
  /// Per-address balance snapshot from the most recent [balanceSat]
  /// call. Used by [nextReceiveAddress] to skip past addresses that
  /// already have on-chain history — same heuristic Cake / Sparrow /
  /// Electrum use to rotate receive addresses for privacy. Empty
  /// before the first refresh; consumers fall back to [primaryAddress].
  Map<String, AddressBalance> _perAddressBalances = const {};
  /// Monotonic sequence stamped onto each [balanceSat] call; the
  /// snapshot from sequence N is only committed if no newer call
  /// (N+1, N+2, …) has already landed. Without this, overlapping
  /// refreshes (the 30 s poll fires while a pull-to-refresh is still
  /// awaiting on the Blockchair fallback) could let the slower call
  /// overwrite a fresher snapshot — re-serving an already-rotated
  /// receive address.
  int _balanceCallSeq = 0;
  int _committedBalanceSeq = 0;

  /// The primary receive address. Index 0 on the external chain.
  /// Same address every other BIP84 wallet produces from the same
  /// BIP39 seed — verified by spec-vector test.
  String get primaryAddress => addresses.first.address;

  /// The next unused receive address from the gap-limit window. An
  /// address is "unused" when it has ZERO on-chain activity — neither
  /// received nor spent, confirmed or mempool. We skip spent
  /// activity too because the deterministic change derivation at
  /// [sendBitcoin] picks change indices from this same gap-limit
  /// window: an address that already paid out as change must NOT
  /// be served as a fresh receive (chain analysis would cluster the
  /// new incoming payment with the prior outgoing send).
  ///
  /// The mempool-client populates [_perAddressBalances] on each
  /// refresh; this just iterates derivation indices in order and
  /// returns the first fully-untouched one.
  ///
  /// Falls back to [primaryAddress] when:
  ///   - the wallet hasn't done its first refresh yet (cache empty),
  ///   - every address in the window has prior activity (rare; user
  ///     has run through their gap limit and the auto-expand path
  ///     hasn't widened the window yet).
  ///
  /// Rotating per-session matches Cake's UX: each receive sheet open
  /// shows a fresh address, which prevents a tip jar / pasted-once
  /// address from clustering all the user's incoming payments under
  /// one on-chain identity.
  String get nextReceiveAddress {
    if (_perAddressBalances.isEmpty) return primaryAddress;
    for (final addr in addresses) {
      final bal = _perAddressBalances[addr.address];
      if (bal == null) continue;
      final total = bal.confirmedReceivedSat +
          bal.confirmedSpentSat +
          bal.mempoolReceivedSat +
          bal.mempoolSpentSat;
      if (total == 0) return addr.address;
    }
    return primaryAddress;
  }

  /// All derived addresses (gap-limit window). Used internally for
  /// balance + history aggregation; UI shows just the primary.
  List<String> get watchAddresses =>
      addresses.map((a) => a.address).toList();

  /// Sum of confirmed + mempool balance across the gap-limit window,
  /// in satoshis. Live mempool.space query — call once per UI refresh
  /// tick, not every frame.
  Future<int> balanceSat() async {
    if (_closed) return 0;
    final mySeq = ++_balanceCallSeq;
    try {
      final b = await _client.multiBalance(watchAddresses);
      // Only commit if no newer call has already landed. Without
      // this, a slow refresh resolving after a fast one would
      // regress _perAddressBalances and re-expose a just-rotated
      // receive address.
      if (mySeq > _committedBalanceSeq) {
        _committedBalanceSeq = mySeq;
        _perAddressBalances = b.perAddress;
      }
      PeekLogger.I.log(params.symbol.toLowerCase(),
          'balance fetched: ${b.totalSat} sat (seq $mySeq)');
      return b.totalSat;
    } catch (e) {
      PeekLogger.I.log(params.symbol.toLowerCase(),
          'balance fetch failed: $e (seq $mySeq)');
      rethrow;
    }
  }

  double get _satToBtc => 1.0 / 100000000.0;

  /// Convenience helper for the UI.
  Future<double> balanceBtc() async => (await balanceSat()) * _satToBtc;

  /// Combined history across all watched addresses, newest-first.
  Future<List<BitcoinTx>> transactions() async {
    if (_closed) return const [];
    try {
      return await _client.multiHistory(watchAddresses);
    } catch (e) {
      PeekLogger.I.log(params.symbol.toLowerCase(),
          'history fetch failed: $e');
      return const [];
    }
  }

  /// Chain tip from mempool.space. Used by the coin screen's
  /// "synced through block N" footer.
  Future<int> tipHeight() async {
    if (_closed) return 0;
    try {
      return await _client.tipHeight();
    } catch (_) {
      return 0;
    }
  }

  /// Fetch all UTXOs across the gap-limit window. The send screen
  /// shows the user how much spendable BTC is in confirmed UTXOs
  /// before they pick an amount.
  Future<List<Utxo>> utxos() async {
    if (_closed) return const [];
    return _client.multiUtxos(watchAddresses);
  }

  /// Live fee-rate recommendations from mempool.space.
  Future<FeeRates> feeRates() async => _client.feeRates();

  /// Build, sign and broadcast a Bitcoin transaction.
  ///
  /// - [destAddress]: recipient (must be bech32 P2WPKH, e.g. `bc1q…`).
  /// - [amountSat]: amount to send in satoshis.
  /// - [feeRateSatPerVByte]: fee tier picked by user from mempool's
  ///   recommended rates.
  ///
  /// Coin selection: greedy largest-first across confirmed UTXOs only.
  /// Change goes to a freshly-derived address one beyond the highest
  /// currently-used external index (or address index 1 in the simple
  /// "haven't received anything yet" case). For now we use the LAST
  /// address in the gap-limit window — keeps things deterministic
  /// without yet implementing the proper "next unused address"
  /// tracking that gap-limit wallets normally do.
  ///
  /// On success the txid is returned. The caller should refresh
  /// balances + history after a short delay; mempool.space typically
  /// picks up new broadcasts within a few seconds.
  Future<BuiltBitcoinTransaction> sendBitcoin({
    required String destAddress,
    required int amountSat,
    required int feeRateSatPerVByte,
  }) async {
    if (_closed) {
      throw StateError('Wallet is closed');
    }
    final logTag = params.symbol.toLowerCase();
    PeekLogger.I.log(
      logTag,
      'send requested: $amountSat sat to '
          '${destAddress.length >= 12 ? '${destAddress.substring(0, 8)}…' : destAddress} '
          '@ $feeRateSatPerVByte sat/vB',
    );

    final available = await _client.multiUtxos(watchAddresses);
    final selected = selectUtxosGreedy(
      available: available,
      amountSat: amountSat,
      feeRateSatPerVByte: feeRateSatPerVByte,
    );
    if (selected == null) {
      throw const InsufficientFundsException(
        'Not enough confirmed funds for this amount + fee',
      );
    }

    // Materialize spending keys for the addresses we're spending from.
    // Receive-time we only stored publickey-only derivations; signing
    // needs private keys so we re-derive on demand.
    final signers = <String, BitcoinSpendingKey>{};
    for (final utxo in selected) {
      if (signers.containsKey(utxo.address)) continue;
      final idx = addresses.indexWhere((a) => a.address == utxo.address);
      if (idx < 0) {
        throw StateError(
            'UTXO references unknown address ${utxo.address}');
      }
      signers[utxo.address] = deriveBitcoinSpendingKey(
        mnemonic: mnemonic,
        passphrase: passphrase,
        addressIndex: idx,
        params: params,
      );
    }

    // Change goes to the BIP84 internal (change) chain — a different
    // hierarchy from receive addresses, so the explorer + chain
    // analysis can't trivially cluster every send under the same
    // address. We pick an index derived from the input set: same
    // input set → same change address (idempotent rebuilds), but
    // any two real sends use different change addresses because
    // they spend different UTXOs.
    var seed = 0;
    for (final u in selected) {
      // Mix the txid + vout into a 64-bit accumulator. djb2-style.
      for (final c in u.txid.codeUnits) {
        seed = ((seed * 33) + c) & 0xffffffff;
      }
      seed = ((seed * 33) + u.vout) & 0xffffffff;
    }
    final changeIdx = seed % gapLimit;
    final changeKey = deriveBitcoinSpendingKey(
      mnemonic: mnemonic,
      passphrase: passphrase,
      addressIndex: changeIdx,
      change: true,
      params: params,
    );

    final built = buildAndSignP2WPKH(
      inputs: selected,
      signers: signers,
      destAddress: destAddress,
      amountSat: amountSat,
      changeAddress: changeKey.address,
      feeRateSatPerVByte: feeRateSatPerVByte,
      params: params,
    );

    PeekLogger.I.log(
      logTag,
      'broadcasting tx ${built.txid} '
          '(${built.virtualSize} vB, fee ${built.feeSat} sat)',
    );
    final txid = await _client.broadcast(built.rawHex);
    if (txid != built.txid) {
      // A divergent txid means either the wire bytes got modified in
      // flight (malleation, suspect explorer, MITM) OR our local hash
      // is buggy. Either way it's not safe to silently accept — the
      // user should know they should look up the broadcast txid
      // directly rather than trust the local one.
      PeekLogger.I.log(logTag,
          'TXID MISMATCH: local=${built.txid} explorer=$txid');
      throw Exception(
          'Broadcast succeeded but the explorer returned a different txid '
          '($txid) than we computed (${built.txid}). Verify on a second '
          'explorer before trusting either value.');
    }
    return built;
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _client.close();
  }
}

/// Args for [_deriveAddressesInIsolate]. Plain data so it transits
/// the SendPort cleanly — [BitcoinChainParams] is itself a const
/// value class with only int/String/`List<String>` fields.
class _DeriveBitcoinArgs {
  const _DeriveBitcoinArgs({
    required this.mnemonic,
    required this.passphrase,
    required this.gapLimit,
    required this.params,
  });
  final String mnemonic;
  final String passphrase;
  final int gapLimit;
  final BitcoinChainParams params;
}

/// Top-level entry point shipped to [compute]. Runs the batched
/// derivation in a background isolate so the UI thread doesn't
/// stall during the ~150-200ms PBKDF2 + 20× secp256k1 child derive.
List<BitcoinAddressDerivation> _deriveAddressesInIsolate(
    _DeriveBitcoinArgs args) {
  return deriveBitcoinReceiveAddresses(
    mnemonic: args.mnemonic,
    passphrase: args.passphrase,
    count: args.gapLimit,
    params: args.params,
  );
}
