import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thin Blockchair v1 client for the Bitcoin Cash chain. Blockchair
/// exposes a unified Etherscan-style + multi-chain REST API; the
/// `/dashboards/address` endpoint returns balance and transactions
/// in a single call which keeps the wallet's polling cheap.
///
/// No API key required for low-volume usage. Heavier users would pin
/// their own provider via Settings → Custom Node (a future hook).
class BlockchairBchClient {
  BlockchairBchClient({String? baseUrl, http.Client? httpClient})
      : _base = (baseUrl ?? _defaultBase).replaceAll(RegExp(r'/$'), ''),
        _http = httpClient ?? http.Client();

  static const _defaultBase = 'https://api.blockchair.com/bitcoin-cash';

  final String _base;
  final http.Client _http;

  /// Confirmed BCH balance in satoshis (1 BCH = 10^8 sat).
  /// Returns 0 for a brand-new address with no on-chain history.
  Future<int> balanceSat(String cashaddrAddress) async {
    // Blockchair accepts both CashAddr and legacy formats; we send
    // the CashAddr form directly. Strip the prefix though — some
    // Blockchair endpoints reject the "bitcoincash:" portion.
    final stripped = cashaddrAddress.contains(':')
        ? cashaddrAddress.split(':').last
        : cashaddrAddress;

    final r = await _http
        .get(Uri.parse('$_base/dashboards/address/$stripped?limit=1'))
        .timeout(const Duration(seconds: 10));
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

    final r = await _http
        .get(Uri.parse('$_base/dashboards/address/$stripped?limit=$limit'))
        .timeout(const Duration(seconds: 12));
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

  void close() => _http.close();
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
