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

  /// Most recent blockhash. Solana transactions include this as anti-
  /// replay protection; the hash expires after ~150 slots (~60 s) so
  /// we fetch it right before signing.
  Future<String> latestBlockhash() async {
    final res = await _rpc('getLatestBlockhash', [
      {'commitment': 'finalized'},
    ]) as Map<String, dynamic>;
    final v = res['value'] as Map<String, dynamic>;
    return v['blockhash'] as String;
  }

  /// Approximate transfer fee (5000 lamports / signature on mainnet
  /// historically). We expose this for the UI's send preview rather
  /// than calling the fee oracle every time — Solana fees are fixed
  /// enough that the static value is fine for showing the user "this
  /// transfer will cost ~0.000005 SOL".
  static const int defaultTransferFeeLamports = 5000;

  /// Broadcast a base64-encoded signed transaction. Returns the
  /// signature (Solana's tx id).
  Future<String> sendTransaction(String base64Tx) async {
    final res = await _rpc('sendTransaction', [
      base64Tx,
      {
        'encoding': 'base64',
        'preflightCommitment': 'finalized',
      },
    ]);
    return res as String;
  }

  /// The first token-account address [owner] holds for [mint], or
  /// null if the owner has no account for this mint (typical for a
  /// fresh wallet that has never received the token). Used by SPL
  /// transfer to find the SOURCE account; the destination side does
  /// the same lookup against the recipient address.
  Future<String?> firstTokenAccountAddress({
    required String ownerBase58,
    required String mintBase58,
  }) async {
    final res = await _rpc('getTokenAccountsByOwner', [
      ownerBase58,
      {'mint': mintBase58},
      {'encoding': 'jsonParsed', 'commitment': 'finalized'},
    ]) as Map<String, dynamic>;
    final value = (res['value'] as List?) ?? const [];
    if (value.isEmpty) return null;
    final entry = value.first as Map<String, dynamic>;
    return entry['pubkey'] as String?;
  }

  /// Sum of SPL token balance for [owner] across all token accounts
  /// holding [mint]. Most users have exactly one account per mint
  /// (the associated token account), but the RPC can return multiple
  /// if the user hand-created extras — we sum them so the wallet
  /// shows the actual spendable total.
  ///
  /// Returns 0 if the user has no token accounts for this mint
  /// (which is the case for a fresh wallet that has never received
  /// the token).
  Future<({BigInt rawAmount, int decimals})> splTokenBalance({
    required String ownerBase58,
    required String mintBase58,
  }) async {
    final res = await _rpc('getTokenAccountsByOwner', [
      ownerBase58,
      {'mint': mintBase58},
      {'encoding': 'jsonParsed', 'commitment': 'finalized'},
    ]) as Map<String, dynamic>;
    final value = (res['value'] as List?) ?? const [];
    if (value.isEmpty) {
      // No token accounts yet — return zero balance. We can't infer
      // decimals from nothing, so probe the mint separately. In
      // practice the caller always knows the decimals from the
      // SplToken catalog so this fallback is rarely hit.
      return (rawAmount: BigInt.zero, decimals: 0);
    }
    var total = BigInt.zero;
    var decimals = 0;
    for (final entry in value) {
      final account = (entry as Map?)?['account'] as Map?;
      final data = account?['data'] as Map?;
      final parsed = data?['parsed'] as Map?;
      final info = parsed?['info'] as Map?;
      final tokenAmount = info?['tokenAmount'] as Map?;
      final amountStr = tokenAmount?['amount'] as String?;
      final dec = (tokenAmount?['decimals'] as num?)?.toInt() ?? 0;
      if (amountStr == null) continue;
      total += BigInt.tryParse(amountStr) ?? BigInt.zero;
      if (dec > 0) decimals = dec;
    }
    return (rawAmount: total, decimals: decimals);
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
