import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'bitcoin_explorer.dart';

/// Thin client for mempool.space's public REST API. We use it for
/// balance + transaction-history lookup; their /api/* is rate-
/// limited but reasonable for an interactive wallet (a single user's
/// poll cadence won't trip the limits).
///
/// The client accepts a *list* of base URLs and tries them in order
/// on 5xx / timeout / socket failure. This gives Litecoin in
/// particular some resilience — litecoinspace.org has gone Cloudflare-
/// 521 multiple times this year, but the mempool.space API surface
/// is implemented identically on a few other community-run mirrors.
///
/// We DON'T send anything sensitive — only addresses (which are
/// already public on-chain). The user's IP is exposed to the explorer
/// the way any block explorer query would expose it; that's the same
/// privacy tradeoff every BTC light wallet makes.
///
/// Future: route through Tor when we add the Tor support roadmap item.
class MempoolClient implements BitcoinExplorer {
  MempoolClient({List<String>? baseUrls, http.Client? httpClient})
      : _bases = _normalize(baseUrls ?? const [_defaultBase]),
        _http = httpClient ?? http.Client();

  /// Convenience constructor for callers that only have a single URL
  /// (e.g. a user-supplied Custom RPC override). Internally always
  /// stored as a list so the retry path is unified.
  MempoolClient.single(String baseUrl, {http.Client? httpClient})
      : _bases = _normalize([baseUrl]),
        _http = httpClient ?? http.Client();

  static const _defaultBase = 'https://mempool.space/api';

  static List<String> _normalize(List<String> urls) {
    if (urls.isEmpty) return const [_defaultBase];
    return urls
        .map((u) => u.replaceAll(RegExp(r'/$'), ''))
        .where((u) => u.isNotEmpty)
        .toList(growable: false);
  }

  final List<String> _bases;
  final http.Client _http;

  /// Balance for a single address in satoshis. Returns (chain, mempool)
  /// — chain is confirmed, mempool is in-flight. Total spendable on a
  /// receive address: `chain.received - chain.spent` minus any pending
  /// spends; UI usually just shows the sum.
  Future<AddressBalance> balance(String address) async {
    return _tryAll(
      path: '/address/$address',
      timeout: const Duration(seconds: 10),
      parse: (body) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        final chain = json['chain_stats'] as Map<String, dynamic>;
        final memp = json['mempool_stats'] as Map<String, dynamic>;
        return AddressBalance(
          confirmedReceivedSat: (chain['funded_txo_sum'] as num).toInt(),
          confirmedSpentSat: (chain['spent_txo_sum'] as num).toInt(),
          mempoolReceivedSat: (memp['funded_txo_sum'] as num).toInt(),
          mempoolSpentSat: (memp['spent_txo_sum'] as num).toInt(),
        );
      },
    );
  }

  /// Aggregated balance across many addresses. Issues parallel calls;
  /// short-circuits on the first error. Returns the running total +
  /// per-address balances so the UI can show "wallet has 0.5 BTC
  /// across 3 addresses".
  @override
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
    return _tryAll(
      path: '/address/$address/txs',
      timeout: const Duration(seconds: 10),
      parse: (body) {
        final list = jsonDecode(body) as List;
        return list
            .map((m) => BitcoinTx.fromJson(m as Map<String, dynamic>, address))
            .toList();
      },
    );
  }

  /// Aggregated history across addresses. Sorts by timestamp desc and
  /// deduplicates txids (a single tx can touch multiple of our
  /// addresses, but we only want to show it once).
  @override
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
  @override
  Future<int> tipHeight() async {
    return _tryAll(
      path: '/blocks/tip/height',
      timeout: const Duration(seconds: 8),
      parse: (body) => int.parse(body.trim()),
    );
  }

  /// Unspent outputs for a single address. Each Utxo carries enough
  /// info to spend it: txid, vout index, value, scriptPubKey hint
  /// (we don't actually need scriptPubKey for P2WPKH; the recipient
  /// address is enough to reconstruct it client-side).
  Future<List<Utxo>> utxos(String address) async {
    return _tryAll(
      path: '/address/$address/utxo',
      timeout: const Duration(seconds: 10),
      parse: (body) {
        final list = jsonDecode(body) as List;
        return list
            .map((m) => Utxo.fromJson(m as Map<String, dynamic>, address))
            .toList();
      },
    );
  }

  /// Aggregate UTXOs across many addresses (the gap-limit window of
  /// receive addresses derived from the seed). Each UTXO retains its
  /// owning address so the signer knows which derivation index's
  /// private key to use.
  @override
  Future<List<Utxo>> multiUtxos(List<String> addresses) async {
    if (addresses.isEmpty) return const [];
    final per = await Future.wait(addresses.map(utxos));
    final all = <Utxo>[];
    for (final list in per) {
      all.addAll(list);
    }
    return all;
  }

  /// Current recommended fee rates from mempool.space — sat/vB for
  /// each priority tier. Cached server-side, refreshed every ~30 s.
  @override
  Future<FeeRates> feeRates() async {
    return _tryAll(
      path: '/v1/fees/recommended',
      timeout: const Duration(seconds: 8),
      parse: (body) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        return FeeRates(
          fastestSatPerVByte: (json['fastestFee'] as num).toInt(),
          halfHourSatPerVByte: (json['halfHourFee'] as num).toInt(),
          hourSatPerVByte: (json['hourFee'] as num).toInt(),
          economySatPerVByte: (json['economyFee'] as num).toInt(),
          minimumSatPerVByte: (json['minimumFee'] as num).toInt(),
        );
      },
    );
  }

  /// Broadcast a fully signed transaction. Body is the raw tx hex.
  /// Returns the txid on success; throws with mempool.space's error
  /// message on rejection (insufficient fee, double-spend, etc.).
  @override
  Future<String> broadcast(String txHex) async {
    Object? lastErr;
    for (final base in _bases) {
      try {
        final r = await _http
            .post(
              Uri.parse('$base/tx'),
              headers: {'Content-Type': 'text/plain'},
              body: txHex,
            )
            .timeout(const Duration(seconds: 15));
        if (r.statusCode == 200) return r.body.trim();
        // 4xx is a real rejection (insufficient fee, double-spend, etc.)
        // — don't retry on a different endpoint, the tx is bad.
        if (r.statusCode >= 400 && r.statusCode < 500) {
          throw Exception(
              'Broadcast rejected (${r.statusCode}): ${r.body.trim()}');
        }
        lastErr = Exception(
            'Broadcast (${r.statusCode}) at $base: ${r.body.trim()}');
      } on SocketException catch (e) {
        lastErr = e;
      } on TimeoutException catch (e) {
        lastErr = e;
      } on HandshakeException catch (e) {
        lastErr = e;
      }
    }
    throw lastErr ?? Exception('Broadcast failed against every endpoint');
  }

  /// Run [path] (GET) against each base URL in turn, parsing on the
  /// first 2xx and short-circuiting. Retries on 5xx, socket failure,
  /// or TLS handshake errors — these are all "this endpoint is broken
  /// right now" signals. A 4xx is propagated immediately because the
  /// next mirror would just return the same client-side error.
  Future<T> _tryAll<T>({
    required String path,
    required Duration timeout,
    required T Function(String body) parse,
  }) async {
    Object? lastErr;
    int? lastStatus;
    String? lastEndpoint;
    for (final base in _bases) {
      lastEndpoint = base;
      try {
        final r = await _http
            .get(Uri.parse('$base$path'))
            .timeout(timeout);
        if (r.statusCode == 200) return parse(r.body);
        lastStatus = r.statusCode;
        // 4xx — endpoint-level rejection. The next mirror would
        // most likely respond identically; propagate immediately.
        if (r.statusCode >= 400 && r.statusCode < 500) {
          throw _MempoolApiError(r.statusCode, base);
        }
        // 5xx — try the next mirror.
        lastErr = _MempoolApiError(r.statusCode, base);
      } on SocketException catch (e) {
        lastErr = e;
      } on TimeoutException catch (e) {
        lastErr = e;
      } on HandshakeException catch (e) {
        lastErr = e;
      } on http.ClientException catch (e) {
        // Network-level errors (DNS resolution, connection refused).
        lastErr = e;
      }
    }
    if (lastErr is _MempoolApiError) throw lastErr;
    if (lastStatus != null && lastEndpoint != null) {
      throw _MempoolApiError(lastStatus, lastEndpoint);
    }
    throw lastErr ?? Exception('All explorer endpoints failed');
  }

  @override
  void close() => _http.close();
}

/// Friendlier error than a bare "API returned 521" — includes the
/// failing endpoint so the user knows whether it was their custom
/// override or the public default, and a hint about how to recover.
/// 5xx codes mean the explorer is down (Cloudflare 521 = origin
/// down, common with litecoinspace.org); 4xx codes usually mean the
/// endpoint URL is wrong.
class _MempoolApiError implements Exception {
  const _MempoolApiError(this.statusCode, this.endpoint);
  final int statusCode;
  final String endpoint;

  @override
  String toString() {
    final hint = statusCode >= 500
        ? 'The explorer at $endpoint is down or unreachable. '
            'Try again in a minute, or set a different endpoint via '
            'Settings → Custom RPC endpoints.'
        : statusCode == 404
            ? 'Address not found at $endpoint. This usually means a '
                'brand-new address with no on-chain history — balance is 0.'
            : 'Endpoint $endpoint rejected the request with status '
                '$statusCode. If you set a custom URL, double-check the path.';
    return 'Explorer error ($statusCode): $hint';
  }
}

/// Unspent output ready to be consumed by a new transaction.
class Utxo {
  const Utxo({
    required this.txid,
    required this.vout,
    required this.valueSat,
    required this.address,
    required this.confirmed,
    this.blockHeight,
  });

  factory Utxo.fromJson(Map<String, dynamic> json, String ownerAddress) {
    final status = json['status'] as Map<String, dynamic>?;
    return Utxo(
      txid: json['txid'] as String,
      vout: (json['vout'] as num).toInt(),
      valueSat: (json['value'] as num).toInt(),
      address: ownerAddress,
      confirmed: (status?['confirmed'] as bool?) ?? false,
      blockHeight: status?['block_height'] as int?,
    );
  }

  final String txid;
  final int vout;
  final int valueSat;
  /// Which one of our addresses this UTXO pays to — used by the
  /// signer to look up the matching private key from the BIP84
  /// derivation chain.
  final String address;
  final bool confirmed;
  final int? blockHeight;
}

class FeeRates {
  const FeeRates({
    required this.fastestSatPerVByte,
    required this.halfHourSatPerVByte,
    required this.hourSatPerVByte,
    required this.economySatPerVByte,
    required this.minimumSatPerVByte,
  });

  /// ~10 min confirm target.
  final int fastestSatPerVByte;
  /// ~30 min confirm target.
  final int halfHourSatPerVByte;
  /// ~1 hour confirm target.
  final int hourSatPerVByte;
  final int economySatPerVByte;
  /// Floor — below this, mempool nodes will drop the tx.
  final int minimumSatPerVByte;
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
