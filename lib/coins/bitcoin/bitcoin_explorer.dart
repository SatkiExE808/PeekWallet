import 'dart:async';

import 'mempool_client.dart';

/// Provider-agnostic surface BitcoinWallet talks to. Used to plug in
/// alternative explorers (mempool.space-compat, Blockchair, a future
/// Blockbook adapter, …) behind the same wallet code.
///
/// Anything that needs to round-trip the chain — balances, history,
/// UTXOs, fee suggestions, broadcast — lives here. Address derivation
/// and tx-building are local concerns, so they don't.
abstract class BitcoinExplorer {
  Future<MultiAddressBalance> multiBalance(List<String> addresses);
  Future<List<BitcoinTx>> multiHistory(List<String> addresses);
  Future<List<Utxo>> multiUtxos(List<String> addresses);
  Future<int> tipHeight();
  Future<FeeRates> feeRates();
  Future<String> broadcast(String txHex);
  void close();
}

/// Composes a primary explorer with one or more fallbacks. Each
/// method tries the primary first; on failure it falls through to
/// the next explorer in [_fallbacks] until one succeeds, then
/// throws the last error if all are exhausted.
///
/// Per-call. There's no sticky preference — every refresh starts at
/// the primary so a transient incident doesn't permanently downgrade
/// the wallet to a slower/less-accurate provider. Worth revisiting
/// if we observe steady-state outages.
class CompositeExplorer implements BitcoinExplorer {
  CompositeExplorer({
    required BitcoinExplorer primary,
    required List<BitcoinExplorer> fallbacks,
  })  : _primary = primary,
        _fallbacks = fallbacks;

  final BitcoinExplorer _primary;
  final List<BitcoinExplorer> _fallbacks;

  Iterable<BitcoinExplorer> get _all sync* {
    yield _primary;
    yield* _fallbacks;
  }

  Future<T> _race<T>(Future<T> Function(BitcoinExplorer e) call) async {
    Object? lastErr;
    StackTrace? lastStack;
    for (final e in _all) {
      try {
        return await call(e);
      } catch (err, st) {
        lastErr = err;
        lastStack = st;
      }
    }
    Error.throwWithStackTrace(
        lastErr ?? Exception('No explorer available'),
        lastStack ?? StackTrace.current);
  }

  @override
  Future<MultiAddressBalance> multiBalance(List<String> addresses) =>
      _race((e) => e.multiBalance(addresses));

  @override
  Future<List<BitcoinTx>> multiHistory(List<String> addresses) =>
      _race((e) => e.multiHistory(addresses));

  @override
  Future<List<Utxo>> multiUtxos(List<String> addresses) =>
      _race((e) => e.multiUtxos(addresses));

  @override
  Future<int> tipHeight() => _race((e) => e.tipHeight());

  @override
  Future<FeeRates> feeRates() => _race((e) => e.feeRates());

  @override
  Future<String> broadcast(String txHex) => _race((e) => e.broadcast(txHex));

  @override
  void close() {
    for (final e in _all) {
      e.close();
    }
  }
}
