import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

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

  /// Broadcast is NOT raced across providers like the read-path
  /// methods. A 4xx-class failure from the primary (insufficient
  /// fee, double-spend, malformed tx) is a real rejection that the
  /// next provider would handle the same way — retrying it on
  /// Blockchair after mempool said "no" risks broadcasting bytes
  /// the user thought were rejected.
  ///
  /// Only infrastructure failures (timeout, socket, TLS, 5xx,
  /// transient I/O) fall through to the next provider. Anything
  /// else — including a generic `Exception` from a provider that
  /// rejected the tx — propagates immediately.
  @override
  Future<String> broadcast(String txHex) async {
    Object? lastErr;
    StackTrace? lastStack;
    for (final e in _all) {
      try {
        return await e.broadcast(txHex);
      } on SocketException catch (err, st) {
        lastErr = err;
        lastStack = st;
      } on TimeoutException catch (err, st) {
        lastErr = err;
        lastStack = st;
      } on HandshakeException catch (err, st) {
        lastErr = err;
        lastStack = st;
      } on http.ClientException catch (err, st) {
        lastErr = err;
        lastStack = st;
      } catch (err, st) {
        // Everything else — provider-shaped errors (insufficient
        // fee, double-spend, malformed tx) — is a real rejection.
        // Propagate immediately so the user sees the actual reason
        // instead of a misleading "broadcast OK" from a downstream
        // provider that didn't know better.
        Error.throwWithStackTrace(err, st);
      }
    }
    Error.throwWithStackTrace(
        lastErr ?? Exception('No explorer available'),
        lastStack ?? StackTrace.current);
  }

  @override
  void close() {
    for (final e in _all) {
      e.close();
    }
  }
}
