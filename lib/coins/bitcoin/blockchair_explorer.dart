import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'bitcoin_explorer.dart';
import 'mempool_client.dart';

/// Blockchair-API adapter conforming to [BitcoinExplorer]. Used as a
/// hard fallback for chains where mempool.space-compatible mirrors
/// are scarce — most notably Litecoin, where litecoinspace.org is
/// the only canonical Esplora node and it has gone 521 multiple
/// times. Blockchair is a separate provider with its own
/// infrastructure, so a litecoinspace outage rarely affects them
/// simultaneously.
///
/// The Blockchair API is REST-ish but its response shapes differ
/// from Esplora; this class translates them into the [BitcoinTx],
/// [Utxo], [FeeRates] etc. types BitcoinWallet already consumes.
///
/// Blockchair is rate-limited; their public tier allows ~30 reqs/
/// minute per IP without an API key, which fits a polling wallet
/// fine. Heavy users would set their own Blockchair endpoint via
/// Settings → Custom RPC (not wired through this adapter yet — a
/// future hook).
class BlockchairExplorer implements BitcoinExplorer {
  BlockchairExplorer({
    required String chain,
    http.Client? httpClient,
  })  : _chain = chain,
        _http = httpClient ?? http.Client();

  static const _base = 'https://api.blockchair.com';

  /// Blockchair chain slug ("litecoin", "bitcoin", "bitcoin-cash").
  /// Set per-instance by [forLitecoin] / [forBitcoin] / [forBitcoinCash].
  final String _chain;
  final http.Client _http;

  /// Convenience factory for the LTC fallback path.
  factory BlockchairExplorer.forLitecoin({http.Client? httpClient}) =>
      BlockchairExplorer(chain: 'litecoin', httpClient: httpClient);

  factory BlockchairExplorer.forBitcoin({http.Client? httpClient}) =>
      BlockchairExplorer(chain: 'bitcoin', httpClient: httpClient);

  factory BlockchairExplorer.forBitcoinCash({http.Client? httpClient}) =>
      BlockchairExplorer(chain: 'bitcoin-cash', httpClient: httpClient);

  @override
  Future<MultiAddressBalance> multiBalance(List<String> addresses) async {
    if (addresses.isEmpty) {
      return MultiAddressBalance(perAddress: const {}, totalSat: 0);
    }
    // Blockchair's multi-address dashboard endpoint
    // (/dashboards/addresses/<a>,<b>,...) is paywalled on the free
    // tier as of 2026 ("402 This function requires an API token").
    // The per-address dashboard endpoint is still free, so fan out
    // sequentially. Slow with a 20-address gap-limit window but only
    // hit when the primary mempool.space mirror is down, and short-
    // circuited individually by the cached-balance fallback in the
    // UI if any single call times out.
    final map = <String, AddressBalance>{};
    var anySuccess = false;
    Object? lastErr;
    for (final addr in addresses) {
      try {
        final info = await _singleAddressInfo(addr, swallow: false);
        if (info == null) {
          map[addr] = const AddressBalance(
            confirmedReceivedSat: 0,
            confirmedSpentSat: 0,
            mempoolReceivedSat: 0,
            mempoolSpentSat: 0,
          );
          anySuccess = true;
          continue;
        }
        final received = (info['received'] as num?)?.toInt() ?? 0;
        final spent = (info['spent'] as num?)?.toInt() ?? 0;
        map[addr] = AddressBalance(
          confirmedReceivedSat: received,
          confirmedSpentSat: spent,
          mempoolReceivedSat: 0,
          mempoolSpentSat: 0,
        );
        anySuccess = true;
      } catch (e) {
        lastErr = e;
        // Keep iterating — a transient per-address failure shouldn't
        // doom the whole refresh; below we throw if NONE succeeded so
        // the wallet's cached-balance fallback engages cleanly.
      }
    }
    if (!anySuccess) {
      throw lastErr ?? Exception('Blockchair: every address fetch failed');
    }
    final total = map.values.fold<int>(0, (s, b) => s + b.totalSat);
    return MultiAddressBalance(perAddress: map, totalSat: total);
  }

  @override
  Future<List<BitcoinTx>> multiHistory(List<String> addresses) async {
    if (addresses.isEmpty) return const [];
    // Blockchair's multi-address dashboard returns combined
    // transaction hashes (no balance_change per address). Fetching
    // per-tx details is one call each, which gets expensive — so we
    // request per-address and aggregate, dedup'ing hashes.
    final seen = <String>{};
    final out = <BitcoinTx>[];
    for (final addr in addresses) {
      final list = await _addressTransactions(addr, limit: 50);
      for (final tx in list) {
        if (seen.add(tx.txid)) out.add(tx);
      }
    }
    out.sort((a, b) => b.timestampSec.compareTo(a.timestampSec));
    return out;
  }

  @override
  Future<List<Utxo>> multiUtxos(List<String> addresses) async {
    if (addresses.isEmpty) return const [];
    final out = <Utxo>[];
    // Per-address again — Blockchair's combined endpoint returns a
    // single utxo list without per-address attribution, which the
    // wallet signer needs to look up the right private key.
    for (final addr in addresses) {
      out.addAll(await _addressUtxos(addr));
    }
    return out;
  }

  @override
  Future<int> tipHeight() async {
    final body = await _get('/$_chain/stats', timeout: 8);
    final json = jsonDecode(body) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>;
    return (data['blocks'] as num).toInt() - 1;
  }

  @override
  Future<FeeRates> feeRates() async {
    final body = await _get('/$_chain/stats', timeout: 8);
    final json = jsonDecode(body) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>;
    final rate = (data['suggested_transaction_fee_per_byte_sat'] as num?)
            ?.toInt() ??
        2;
    // Blockchair only exposes one rate. Map it across all tiers so
    // the wallet's fee-picker has values; relative priorities are
    // approximations.
    return FeeRates(
      fastestSatPerVByte: rate * 2,
      halfHourSatPerVByte: rate,
      hourSatPerVByte: (rate * 0.75).ceil(),
      economySatPerVByte: (rate * 0.5).ceil().clamp(1, 1 << 30),
      minimumSatPerVByte: 1,
    );
  }

  @override
  Future<String> broadcast(String txHex) async {
    final r = await _http
        .post(
          Uri.parse('$_base/$_chain/push/transaction'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: 'data=$txHex',
        )
        .timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) {
      throw Exception(
          'Blockchair broadcast (${r.statusCode}): ${r.body.trim()}');
    }
    final json = jsonDecode(r.body) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>?;
    final hash = data?['transaction_hash'] as String?;
    if (hash == null) {
      throw Exception('Blockchair broadcast: unexpected ${r.body.trim()}');
    }
    return hash;
  }

  /// Fetch the `address` sub-object from Blockchair's single-address
  /// dashboard. Free on the public tier (unlike the multi-address
  /// endpoint). If [swallow] is true, errors return null instead of
  /// throwing — used by the history/utxo paths where one failed
  /// address shouldn't kill the whole refresh.
  Future<Map<String, dynamic>?> _singleAddressInfo(String addr,
      {bool swallow = true}) async {
    try {
      final body = await _get(
        '/$_chain/dashboards/address/$addr?limit=0,0',
        timeout: 12,
      );
      final json = jsonDecode(body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>?;
      if (data == null || data.isEmpty) return null;
      final entry = data.values.first as Map<String, dynamic>?;
      return entry?['address'] as Map<String, dynamic>?;
    } catch (_) {
      if (swallow) return null;
      rethrow;
    }
  }

  Future<List<BitcoinTx>> _addressTransactions(String addr,
      {int limit = 50}) async {
    final body = await _get(
      '/$_chain/dashboards/address/$addr?limit=$limit',
      timeout: 12,
    );
    final json = jsonDecode(body) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>?;
    if (data == null || data.isEmpty) return const [];
    final entry = data.values.first as Map<String, dynamic>?;
    if (entry == null) return const [];

    final addrInfo = entry['address'] as Map<String, dynamic>?;
    final txes = (entry['transactions'] as List?) ?? const [];

    // Blockchair returns either a list of hashes (older API) or a
    // list of objects with balance_change + block_id + time. Detect
    // and parse accordingly.
    final out = <BitcoinTx>[];
    for (final t in txes) {
      if (t is String) {
        // Hash-only — we can't compute net amount without a second
        // call per tx, which is too expensive for the polling path.
        // Stash it as a placeholder so the count is right at least.
        out.add(BitcoinTx(
          txid: t,
          netSat: 0,
          timestampSec: 0,
          blockHeight: 0,
          confirmed: true,
          feeSat: 0,
        ));
        continue;
      }
      if (t is! Map) continue;
      final m = t.cast<String, dynamic>();
      final hash = m['hash'] as String?;
      if (hash == null) continue;
      out.add(BitcoinTx(
        txid: hash,
        netSat: (m['balance_change'] as num?)?.toInt() ?? 0,
        timestampSec: _parseBlockchairTime(m['time']),
        blockHeight: (m['block_id'] as num?)?.toInt() ?? 0,
        confirmed: ((m['block_id'] as num?)?.toInt() ?? -1) > 0,
        feeSat: 0,
      ));
    }
    // Defensive: if addrInfo is null we still got txs out via the
    // above, no further fixup needed.
    addrInfo;
    return out;
  }

  Future<List<Utxo>> _addressUtxos(String addr) async {
    final body = await _get(
      '/$_chain/dashboards/address/$addr?limit=0,100',
      timeout: 12,
    );
    final json = jsonDecode(body) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>?;
    if (data == null || data.isEmpty) return const [];
    final entry = data.values.first as Map<String, dynamic>?;
    if (entry == null) return const [];
    final list = (entry['utxo'] as List?) ?? const [];
    return list.map((u) {
      final m = (u as Map).cast<String, dynamic>();
      return Utxo(
        txid: m['transaction_hash'] as String,
        vout: (m['index'] as num).toInt(),
        valueSat: (m['value'] as num).toInt(),
        address: addr,
        confirmed: ((m['block_id'] as num?)?.toInt() ?? 0) > 0,
        blockHeight: (m['block_id'] as num?)?.toInt(),
      );
    }).toList();
  }

  Future<String> _get(String path, {required int timeout}) async {
    try {
      final r = await _http
          .get(Uri.parse('$_base$path'))
          .timeout(Duration(seconds: timeout));
      if (r.statusCode == 200) return r.body;
      throw Exception('Blockchair $path → ${r.statusCode}: ${r.body.trim()}');
    } on SocketException catch (e) {
      throw Exception('Blockchair $path: $e');
    } on TimeoutException {
      throw Exception('Blockchair $path: timeout after ${timeout}s');
    }
  }

  /// Blockchair returns timestamps as "YYYY-MM-DD HH:MM:SS" UTC. We
  /// parse to seconds-since-epoch so the BitcoinTx model matches the
  /// mempool.space-compat path.
  static int _parseBlockchairTime(Object? raw) {
    if (raw == null) return 0;
    if (raw is num) return raw.toInt();
    if (raw is! String) return 0;
    final iso = '${raw.replaceFirst(' ', 'T')}Z';
    return DateTime.tryParse(iso)?.millisecondsSinceEpoch == null
        ? 0
        : (DateTime.parse(iso).millisecondsSinceEpoch ~/ 1000);
  }

  @override
  void close() => _http.close();
}
