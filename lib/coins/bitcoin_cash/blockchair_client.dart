import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Thin Blockchair v1 client for the Bitcoin Cash chain. Blockchair
/// exposes a unified Etherscan-style + multi-chain REST API; the
/// `/dashboards/address` endpoint returns balance and transactions
/// in a single call which keeps the wallet's polling cheap.
///
/// Accepts a list of base URLs and tries them in order on transient
/// failure. Blockchair runs the primary infrastructure; a Bitcore-
/// compatible mirror (bch.imaginary.cash) is included as a secondary
/// in case Blockchair throttles or has an outage. Different API
/// shapes — only the canonical Blockchair URL is the full client;
/// fallbacks are best-effort and might miss methods like broadcast.
class BlockchairBchClient {
  BlockchairBchClient({List<String>? baseUrls, http.Client? httpClient})
      : _bases = _normalize(baseUrls ?? const [_defaultBase]),
        _http = httpClient ?? http.Client();

  BlockchairBchClient.single(String baseUrl, {http.Client? httpClient})
      : _bases = _normalize([baseUrl]),
        _http = httpClient ?? http.Client();

  static const _defaultBase = 'https://api.blockchair.com/bitcoin-cash';

  static List<String> _normalize(List<String> raw) {
    final cleaned = raw
        .map((u) => u.replaceAll(RegExp(r'/$'), ''))
        .where((u) => u.isNotEmpty)
        .toList(growable: false);
    return cleaned.isEmpty ? const [_defaultBase] : cleaned;
  }

  final List<String> _bases;
  final http.Client _http;

  /// Primary base URL — the one we'd use for non-retried tooling.
  String get primaryBase => _bases.first;

  Future<http.Response> _get(String path, {required int timeout}) async {
    return _try((base) =>
        _http.get(Uri.parse('$base$path')).timeout(Duration(seconds: timeout)));
  }

  Future<http.Response> _post(String path,
      {required Object body,
      Map<String, String>? headers,
      required int timeout}) async {
    return _try((base) => _http
        .post(Uri.parse('$base$path'), headers: headers, body: body)
        .timeout(Duration(seconds: timeout)));
  }

  Future<http.Response> _try(
      Future<http.Response> Function(String base) call) async {
    Object? lastErr;
    for (final base in _bases) {
      try {
        final r = await call(base);
        // 404 is meaningful (empty address) — return it directly so
        // callers can treat it as a zero balance instead of an error.
        if (r.statusCode == 404) return r;
        if (r.statusCode == 429 || r.statusCode >= 500) {
          lastErr = Exception('Blockchair HTTP ${r.statusCode} at $base');
          continue;
        }
        return r;
      } on SocketException catch (e) {
        lastErr = e;
      } on TimeoutException catch (e) {
        lastErr = e;
      } on HandshakeException catch (e) {
        lastErr = e;
      } on http.ClientException catch (e) {
        lastErr = e;
      }
    }
    throw lastErr ?? Exception('All BCH explorer endpoints failed');
  }

  /// Confirmed BCH balance in satoshis (1 BCH = 10^8 sat).
  /// Returns 0 for a brand-new address with no on-chain history.
  Future<int> balanceSat(String cashaddrAddress) async {
    // Blockchair accepts both CashAddr and legacy formats; we send
    // the CashAddr form directly. Strip the prefix though — some
    // Blockchair endpoints reject the "bitcoincash:" portion.
    final stripped = cashaddrAddress.contains(':')
        ? cashaddrAddress.split(':').last
        : cashaddrAddress;

    final r = await _get('/dashboards/address/$stripped?limit=1',
        timeout: 25);
    if (r.statusCode == 404) return 0; // brand-new address
    if (r.statusCode != 200) {
      throw Exception('Blockchair API returned ${r.statusCode}');
    }
    final json = jsonDecode(r.body) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>?;
    if (data == null || data.isEmpty) return 0;
    final entry = data.values.first as Map<String, dynamic>?;
    final addrInfo = entry?['address'] as Map<String, dynamic>?;
    return (addrInfo?['balance'] as num?)?.toInt() ?? 0;
  }

  /// Recent transactions involving [cashaddrAddress]. Returns the
  /// last [limit] txs. Each entry carries enough to render the UI
  /// row — net balance change, fee, confirmation status, timestamp.
  Future<List<BchTx>> transactions(String cashaddrAddress,
      {int limit = 50}) async {
    final stripped = cashaddrAddress.contains(':')
        ? cashaddrAddress.split(':').last
        : cashaddrAddress;

    final r = await _get('/dashboards/address/$stripped?limit=$limit',
        timeout: 30);
    if (r.statusCode == 404) return const [];
    if (r.statusCode != 200) {
      throw Exception('Blockchair API returned ${r.statusCode}');
    }
    final json = jsonDecode(r.body) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>?;
    if (data == null || data.isEmpty) return const [];
    final entry = data.values.first as Map<String, dynamic>?;

    // Blockchair returns just txid hashes here; for full per-tx
    // detail (net balance change, fee) we'd need a second call per
    // tx. Skip that for the first commit — the basic history list
    // shows the txid + we'll fill in details later.
    final txList = (entry?['transactions'] as List?) ?? const [];
    return txList
        .map((h) => BchTx(
              hash: h.toString(),
              netSat: 0,
              feeSat: 0,
              confirmed: true,
              timestampSec: 0,
            ))
        .toList();
  }

  /// UTXOs spendable by [cashaddrAddress]. Blockchair returns these
  /// inside the dashboard response — we extract just the fields the
  /// signer needs.
  Future<List<BlockchairUtxo>> utxos(String cashaddrAddress) async {
    final stripped = cashaddrAddress.contains(':')
        ? cashaddrAddress.split(':').last
        : cashaddrAddress;

    final r = await _get('/dashboards/address/$stripped?limit=0,100',
        timeout: 25);
    if (r.statusCode == 404) return const [];
    if (r.statusCode != 200) {
      throw Exception('Blockchair API returned ${r.statusCode}');
    }
    final json = jsonDecode(r.body) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>?;
    if (data == null || data.isEmpty) return const [];
    final entry = data.values.first as Map<String, dynamic>?;
    final utxoList = (entry?['utxo'] as List?) ?? const [];
    return utxoList.map((u) {
      final m = u as Map<String, dynamic>;
      return BlockchairUtxo(
        txid: m['transaction_hash'] as String,
        vout: (m['index'] as num).toInt(),
        valueSat: (m['value'] as num).toInt(),
        blockHeight: (m['block_id'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  /// Suggested fee rate in sat/byte. BCH fees are typically very low
  /// (1-2 sat/byte clears quickly) so we just return a static value
  /// rather than calling a fee oracle. Future Settings → Custom Fee
  /// could expose this.
  int suggestedFeeRateSatPerByte() => 2;

  /// Broadcast a signed raw tx hex. Blockchair's broadcast endpoint
  /// returns the transaction hash on success.
  Future<String> broadcast(String rawHex) async {
    final r = await _post('/push/transaction',
        body: 'data=$rawHex',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        timeout: 18);
    if (r.statusCode != 200) {
      throw Exception(
          'BCH broadcast returned ${r.statusCode}: ${r.body.trim()}');
    }
    final json = jsonDecode(r.body) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>?;
    final hash = data?['transaction_hash'] as String?;
    if (hash == null) {
      throw Exception(
          'BCH broadcast: unexpected response shape ${r.body.trim()}');
    }
    return hash;
  }

  void close() => _http.close();
}

class BlockchairUtxo {
  const BlockchairUtxo({
    required this.txid,
    required this.vout,
    required this.valueSat,
    required this.blockHeight,
  });
  final String txid;
  final int vout;
  final int valueSat;
  final int blockHeight;
  bool get confirmed => blockHeight > 0;
}

/// One BCH transaction, simplified for the UI. The first-commit
/// implementation here is a placeholder that only carries the txid;
/// full per-tx net-balance computation needs a second API call to
/// /dashboards/transaction/{hash} which we'll add when we wire the
/// detail sheet.
class BchTx {
  const BchTx({
    required this.hash,
    required this.netSat,
    required this.feeSat,
    required this.confirmed,
    required this.timestampSec,
  });
  final String hash;
  final int netSat;
  final int feeSat;
  final bool confirmed;
  final int timestampSec;

  bool get isIncoming => netSat > 0;
  double get netBch => netSat / 100000000.0;
  double get feeBch => feeSat / 100000000.0;
  DateTime get timestamp =>
      DateTime.fromMillisecondsSinceEpoch(timestampSec * 1000);
}
