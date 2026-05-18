import 'dart:async';

import '../../util/peek_logger.dart';
import 'bitcoin_keys.dart';
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
/// Send is intentionally NOT implemented in this commit — PSBT
/// construction + signing + broadcast is its own substantial piece
/// of work. Receive + balance + history make Bitcoin a useful
/// monitor wallet today.
class BitcoinWallet {
  BitcoinWallet._({
    required this.mnemonic,
    required this.passphrase,
    required this.gapLimit,
    required this.addresses,
  }) : _client = MempoolClient();

  /// Open a Bitcoin wallet for the given seed. Derives [gapLimit]
  /// addresses on the external (receive) chain so balance / history
  /// can be summed across all of them. Defaults match the BIP44 gap
  /// limit convention.
  factory BitcoinWallet.open({
    required String mnemonic,
    String passphrase = '',
    int gapLimit = 20,
  }) {
    final addrs = <BitcoinAddressDerivation>[];
    for (var i = 0; i < gapLimit; i++) {
      addrs.add(deriveBitcoinAddress(
        mnemonic: mnemonic,
        passphrase: passphrase,
        addressIndex: i,
      ));
    }
    return BitcoinWallet._(
      mnemonic: mnemonic,
      passphrase: passphrase,
      gapLimit: gapLimit,
      addresses: addrs,
    );
  }

  final String mnemonic;
  final String passphrase;
  final int gapLimit;
  final List<BitcoinAddressDerivation> addresses;
  final MempoolClient _client;
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
      PeekLogger.I.log('btc', 'balance fetched: ${b.totalSat} sat');
      return b.totalSat;
    } catch (e) {
      PeekLogger.I.log('btc', 'balance fetch failed: $e');
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
      PeekLogger.I.log('btc', 'history fetch failed: $e');
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

  void close() {
    if (_closed) return;
    _closed = true;
    _client.close();
  }
}
