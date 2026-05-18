import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thin Solana JSON-RPC client. Default endpoint is the Solana
/// Foundation's public mainnet-beta RPC, which is heavily rate-
/// limited but works without an API key. Heavy users should swap in
/// a dedicated provider (Helius, Triton, Alchemy) via the Settings
/// → Custom RPC field once that ships.
class SolanaRpcClient {
  SolanaRpcClient({String? endpoint, http.Client? httpClient})
      : _endpoint = endpoint ?? _defaultEndpoint,
        _http = httpClient ?? http.Client();

  static const _defaultEndpoint = 'https://api.mainnet-beta.solana.com';

  final String _endpoint;
  final http.Client _http;
  int _idCounter = 1;

  Future<dynamic> _rpc(String method, [List<dynamic> params = const []]) async {
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'method': method,
      'params': params,
      'id': _idCounter++,
    });
    final r = await _http
        .post(Uri.parse(_endpoint),
            headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) {
      throw Exception('Solana RPC HTTP ${r.statusCode}: ${r.body.trim()}');
    }
    final json = jsonDecode(r.body) as Map<String, dynamic>;
    if (json.containsKey('error')) {
      final err = json['error'] as Map<String, dynamic>;
      throw Exception(
          'Solana RPC error ${err['code']}: ${err['message']}');
    }
    return json['result'];
  }

  /// Lamports balance for [address]. 1 SOL = 10^9 lamports.
  /// "Finalized" commitment so we don't show optimistic balances
  /// that could roll back.
  Future<int> balanceLamports(String address) async {
    final res = await _rpc('getBalance', [
      address,
      {'commitment': 'finalized'},
    ]) as Map<String, dynamic>;
    return (res['value'] as num).toInt();
  }

  /// Recent transaction signatures involving [address]. Each
  /// signature is a 64-byte ed25519 signature, base58-encoded — same
  /// thing block explorers call a "tx hash".
  Future<List<SolanaTxSummary>> signatures(String address,
      {int limit = 25}) async {
    final res = await _rpc('getSignaturesForAddress', [
      address,
      {'limit': limit},
    ]) as List;
    return res
        .map((m) => SolanaTxSummary.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  /// Resolve a tx signature to a full transaction. The detailed body
  /// is what we use to compute net balance change for our address.
  Future<SolanaTxDetail?> transaction(String signature, String ourAddress) async {
    final res = await _rpc('getTransaction', [
      signature,
      {
        'commitment': 'finalized',
        'maxSupportedTransactionVersion': 0,
        'encoding': 'json',
      },
    ]);
    if (res == null) return null;
    return SolanaTxDetail.fromJson(
        res as Map<String, dynamic>, ourAddress);
  }

  /// Current chain id (a.k.a. "genesis hash" on Solana — we use it
  /// as a guard against accidentally talking to devnet/testnet).
  /// Mainnet's hash is the well-known `5eykt4UsFv8P8NJdTREpY1vzqKqZ…`
  /// — we don't pin it here; instead the wallet just records what it
  /// connected to so logs say "mainnet" vs "devnet" intelligibly.
  Future<String> genesisHash() async {
    final res = await _rpc('getGenesisHash');
    return res as String;
  }

  void close() => _http.close();
}

/// Lightweight tx-list entry. We resolve each one to a SolanaTxDetail
/// for the UI's history list.
class SolanaTxSummary {
  const SolanaTxSummary({
    required this.signature,
    required this.slot,
    required this.blockTimeSec,
    required this.err,
  });

  factory SolanaTxSummary.fromJson(Map<String, dynamic> json) =>
      SolanaTxSummary(
        signature: json['signature'] as String,
        slot: (json['slot'] as num).toInt(),
        blockTimeSec: (json['blockTime'] as num?)?.toInt() ?? 0,
        err: json['err'],
      );

  final String signature;
  /// Solana slot number — analogous to Bitcoin block height but ~400ms
  /// per slot, so the absolute number grows much faster.
  final int slot;
  final int blockTimeSec;
  /// null = success, anything else = failure (the tx still incurred
  /// fees but didn't transfer value).
  final dynamic err;

  bool get confirmed => err == null;
  DateTime get timestamp =>
      DateTime.fromMillisecondsSinceEpoch(blockTimeSec * 1000);
}

/// Full tx with the per-account balance delta worked out for our
/// address — analogous to a Bitcoin tx's `netSat` field.
class SolanaTxDetail {
  const SolanaTxDetail({
    required this.signature,
    required this.netLamports,
    required this.feeLamports,
    required this.slot,
    required this.timestampSec,
    required this.confirmed,
  });

  factory SolanaTxDetail.fromJson(
      Map<String, dynamic> json, String ourAddress) {
    final meta = json['meta'] as Map<String, dynamic>?;
    final tx = json['transaction'] as Map<String, dynamic>?;
    final msg = tx?['message'] as Map<String, dynamic>?;
    final accountKeys = (msg?['accountKeys'] as List?)?.cast<String>() ?? const [];
    final preBalances =
        (meta?['preBalances'] as List?)?.cast<num>() ?? const [];
    final postBalances =
        (meta?['postBalances'] as List?)?.cast<num>() ?? const [];

    var net = 0;
    final idx = accountKeys.indexOf(ourAddress);
    if (idx >= 0 && idx < preBalances.length && idx < postBalances.length) {
      net = postBalances[idx].toInt() - preBalances[idx].toInt();
    }

    return SolanaTxDetail(
      signature: tx?['signatures']?[0] as String? ?? '',
      netLamports: net,
      feeLamports: (meta?['fee'] as num?)?.toInt() ?? 0,
      slot: (json['slot'] as num?)?.toInt() ?? 0,
      timestampSec: (json['blockTime'] as num?)?.toInt() ?? 0,
      confirmed: meta?['err'] == null,
    );
  }

  final String signature;
  /// Positive = net incoming, negative = net outgoing. INCLUDES the
  /// fee in the outgoing case (just like our EthereumTx field).
  final int netLamports;
  final int feeLamports;
  final int slot;
  final int timestampSec;
  final bool confirmed;

  bool get isIncoming => netLamports > 0;
  double get netSol => netLamports / 1000000000.0;
  double get feeSol => feeLamports / 1000000000.0;
  DateTime get timestamp =>
      DateTime.fromMillisecondsSinceEpoch(timestampSec * 1000);
}
