import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thin client for mempool.space's public REST API. We use it for
/// balance + transaction-history lookup; their /api/* is rate-
/// limited but reasonable for an interactive wallet (a single user's
/// poll cadence won't trip the limits).
///
/// We DON'T send anything sensitive — only addresses (which are
/// already public on-chain). The user's IP is exposed to mempool.space
/// the way any block explorer query would expose it; that's the same
/// privacy tradeoff every BTC light wallet makes.
///
/// Future: route through Tor when we add the Tor support roadmap item.
class MempoolClient {
  MempoolClient({String? baseUrl, http.Client? httpClient})
      : _base = (baseUrl ?? _defaultBase).replaceAll(RegExp(r'/$'), ''),
        _http = httpClient ?? http.Client();

  static const _defaultBase = 'https://mempool.space/api';

  final String _base;
  final http.Client _http;

  /// Balance for a single address in satoshis. Returns (chain, mempool)
  /// — chain is confirmed, mempool is in-flight. Total spendable on a
  /// receive address: `chain.received - chain.spent` minus any pending
  /// spends; UI usually just shows the sum.
  Future<AddressBalance> balance(String address) async {
    final r = await _http.get(
      Uri.parse('$_base/address/$address'),
    ).timeout(const Duration(seconds: 8));
    if (r.statusCode != 200) {
      throw Exception('Mempool API returned ${r.statusCode}');
    }
    final json = jsonDecode(r.body) as Map<String, dynamic>;
    final chain = json['chain_stats'] as Map<String, dynamic>;
    final memp = json['mempool_stats'] as Map<String, dynamic>;
    return AddressBalance(
      confirmedReceivedSat: (chain['funded_txo_sum'] as num).toInt(),
      confirmedSpentSat: (chain['spent_txo_sum'] as num).toInt(),
      mempoolReceivedSat: (memp['funded_txo_sum'] as num).toInt(),
      mempoolSpentSat: (memp['spent_txo_sum'] as num).toInt(),
    );
  }

  /// Aggregated balance across many addresses. Issues parallel calls;
  /// short-circuits on the first error. Returns the running total +
  /// per-address balances so the UI can show "wallet has 0.5 BTC
  /// across 3 addresses".
  Future<MultiAddressBalance> multiBalance(List<String> addresses) async {
    if (addresses.isEmpty) {
      return MultiAddressBalance(perAddress: const {}, totalSat: 0);
    }
    final entries = await Future.wait(
      addresses.map((a) async => MapEntry(a, await balance(a))),
    );
    final map = Map<String, AddressBalance>.fromEntries(entries);
    final total = map.values
        .fold<int>(0, (sum, b) => sum + b.totalSat);
    return MultiAddressBalance(perAddress: map, totalSat: total);
  }

  /// Recent transactions for an address. Mempool returns
  /// confirmed+mempool TXes merged with status flags. Capped to
  /// ~50 by their API — paging via `txs/chain/{last_txid}` for older
  /// history is a follow-up.
  Future<List<BitcoinTx>> transactions(String address) async {
    final r = await _http.get(
      Uri.parse('$_base/address/$address/txs'),
    ).timeout(const Duration(seconds: 8));
    if (r.statusCode != 200) {
      throw Exception('Mempool API returned ${r.statusCode}');
    }
    final list = jsonDecode(r.body) as List;
    return list
        .map((m) => BitcoinTx.fromJson(m as Map<String, dynamic>, address))
        .toList();
  }

  /// Aggregated history across addresses. Sorts by timestamp desc and
  /// deduplicates txids (a single tx can touch multiple of our
  /// addresses, but we only want to show it once).
  Future<List<BitcoinTx>> multiHistory(List<String> addresses) async {
    if (addresses.isEmpty) return const [];
    final per = await Future.wait(addresses.map(transactions));
    final seen = <String>{};
    final all = <BitcoinTx>[];
    for (final list in per) {
      for (final tx in list) {
        if (seen.add(tx.txid)) all.add(tx);
      }
    }
    all.sort((a, b) => b.timestampSec.compareTo(a.timestampSec));
    return all;
  }

  /// Current chain tip. Used by sync-progress UI ("we're caught up").
  Future<int> tipHeight() async {
    final r = await _http
        .get(Uri.parse('$_base/blocks/tip/height'))
        .timeout(const Duration(seconds: 6));
    if (r.statusCode != 200) {
      throw Exception('Mempool tip API returned ${r.statusCode}');
    }
    return int.parse(r.body.trim());
  }

  void close() => _http.close();
}

class AddressBalance {
  const AddressBalance({
    required this.confirmedReceivedSat,
    required this.confirmedSpentSat,
    required this.mempoolReceivedSat,
    required this.mempoolSpentSat,
  });
  final int confirmedReceivedSat;
  final int confirmedSpentSat;
  final int mempoolReceivedSat;
  final int mempoolSpentSat;

  int get confirmedSat => confirmedReceivedSat - confirmedSpentSat;
  int get pendingSat => mempoolReceivedSat - mempoolSpentSat;
  int get totalSat => confirmedSat + pendingSat;
}

class MultiAddressBalance {
  const MultiAddressBalance({required this.perAddress, required this.totalSat});
  final Map<String, AddressBalance> perAddress;
  final int totalSat;
  double get totalBtc => totalSat / 100000000.0;
}

class BitcoinTx {
  const BitcoinTx({
    required this.txid,
    required this.netSat,
    required this.timestampSec,
    required this.blockHeight,
    required this.confirmed,
    required this.feeSat,
  });

  /// Parse a mempool.space tx record from the perspective of one of
  /// our addresses — netSat is positive if the address received funds,
  /// negative if it sent them.
  factory BitcoinTx.fromJson(Map<String, dynamic> json, String ourAddress) {
    final txid = json['txid'] as String;
    final status = json['status'] as Map<String, dynamic>?;
    final confirmed = (status?['confirmed'] as bool?) ?? false;
    final blockHeight = (status?['block_height'] as int?) ?? 0;
    final blockTime = (status?['block_time'] as int?) ?? 0;
    final fee = (json['fee'] as int?) ?? 0;
    // Sum vouts paying to us minus vins spending from us.
    int incoming = 0;
    final vouts = (json['vout'] as List?) ?? const [];
    for (final v in vouts) {
      final m = v as Map?;
      if (m == null) continue;
      final addr = m['scriptpubkey_address'] as String?;
      if (addr == ourAddress) {
        incoming += (m['value'] as int? ?? 0);
      }
    }
    int outgoing = 0;
    final vins = (json['vin'] as List?) ?? const [];
    for (final v in vins) {
      final prev = (v as Map?)?['prevout'] as Map?;
      final addr = prev?['scriptpubkey_address'] as String?;
      if (addr == ourAddress) {
        outgoing += (prev!['value'] as int? ?? 0);
      }
    }
    final net = incoming - outgoing;
    return BitcoinTx(
      txid: txid,
      netSat: net,
      timestampSec: blockTime,
      blockHeight: blockHeight,
      confirmed: confirmed,
      feeSat: fee,
    );
  }

  final String txid;
  /// Positive: net incoming. Negative: net outgoing (you spent more
  /// than you received in this tx). Fee NOT subtracted — that's a
  /// separate field so the UI can decide how to display it.
  final int netSat;
  final int timestampSec;
  final int blockHeight;
  final bool confirmed;
  final int feeSat;

  bool get isIncoming => netSat > 0;
  double get netBtc => netSat / 100000000.0;
  double get feeBtc => feeSat / 100000000.0;
  DateTime get timestamp =>
      DateTime.fromMillisecondsSinceEpoch(timestampSec * 1000);
}
