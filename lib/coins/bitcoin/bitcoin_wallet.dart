import 'dart:async';

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
    final addrs = <BitcoinAddressDerivation>[];
    for (var i = 0; i < gapLimit; i++) {
      addrs.add(deriveBitcoinAddress(
        mnemonic: mnemonic,
        passphrase: passphrase,
        addressIndex: i,
        params: params,
      ));
    }
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

  /// The primary receive address. Index 0 on the external chain.
  /// Same address every other BIP84 wallet produces from the same
  /// BIP39 seed — verified by spec-vector test.
  String get primaryAddress => addresses.first.address;

  /// All derived addresses (gap-limit window). Used internally for
  /// balance + history aggregation; UI shows just the primary.
  List<String> get watchAddresses =>
      addresses.map((a) => a.address).toList();

  /// Sum of confirmed + mempool balance across the gap-limit window,
  /// in satoshis. Live mempool.space query — call once per UI refresh
  /// tick, not every frame.
  Future<int> balanceSat() async {
    if (_closed) return 0;
    try {
      final b = await _client.multiBalance(watchAddresses);
      PeekLogger.I.log(params.symbol.toLowerCase(),
          'balance fetched: ${b.totalSat} sat');
      return b.totalSat;
    } catch (e) {
      PeekLogger.I.log(params.symbol.toLowerCase(),
          'balance fetch failed: $e');
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
      PeekLogger.I.log(logTag,
          'WARNING: explorer returned txid $txid but we computed ${built.txid}');
    }
    return built;
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _client.close();
  }
}
