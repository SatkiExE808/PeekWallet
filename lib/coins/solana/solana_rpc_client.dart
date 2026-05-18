import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Thin Solana JSON-RPC client. Default endpoint chain starts with
/// the Solana Foundation's public mainnet-beta RPC, then falls
/// through to a handful of community-run mirrors (Ankr, Blast,
/// PublicNode) on transient failure. mainnet-beta.solana.com is the
/// canonical one but it rate-limits aggressively; the public mirrors
/// give the wallet a soft alternative when that happens.
///
/// Heavy users should still pin their own provider (Helius, Triton,
/// Alchemy) via Settings → Custom RPC; that pin is tried first.
class SolanaRpcClient {
  SolanaRpcClient({List<String>? endpoints, http.Client? httpClient})
      : _endpoints = _normalize(endpoints ?? _defaultEndpoints),
        _http = httpClient ?? http.Client();

  SolanaRpcClient.single(String endpoint, {http.Client? httpClient})
      : _endpoints = _normalize([endpoint]),
        _http = httpClient ?? http.Client();

  static const _defaultEndpoints = <String>[
    'https://api.mainnet-beta.solana.com',
    'https://solana-rpc.publicnode.com',
    'https://solana-mainnet.public.blastapi.io',
    'https://rpc.ankr.com/solana',
  ];

  static List<String> _normalize(List<String> raw) {
    final cleaned = raw
        .map((u) => u.trim().replaceAll(RegExp(r'/$'), ''))
        .where((u) => u.isNotEmpty)
        .toList(growable: false);
    return cleaned.isEmpty ? _defaultEndpoints : cleaned;
  }

  final List<String> _endpoints;
  final http.Client _http;
  int _idCounter = 1;

  Future<dynamic> _rpc(String method,
      [List<dynamic> params = const []]) async {
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'method': method,
      'params': params,
      'id': _idCounter++,
    });
    Object? lastErr;
    for (final endpoint in _endpoints) {
      try {
        final r = await _http
            .post(Uri.parse(endpoint),
                headers: {'Content-Type': 'application/json'}, body: body)
            .timeout(const Duration(seconds: 15));
        if (r.statusCode == 429 || r.statusCode >= 500) {
          // Rate-limited or infrastructure failure — try the next.
          lastErr = Exception('Solana RPC HTTP ${r.statusCode} at $endpoint');
          continue;
        }
        if (r.statusCode != 200) {
          throw Exception(
              'Solana RPC HTTP ${r.statusCode}: ${r.body.trim()}');
        }
        final json = jsonDecode(r.body) as Map<String, dynamic>;
        if (json.containsKey('error')) {
          final err = json['error'] as Map<String, dynamic>;
          throw Exception(
              'Solana RPC error ${err['code']}: ${err['message']}');
        }
        return json['result'];
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
    throw lastErr ?? Exception('All Solana RPC endpoints failed');
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

  /// Fetch the SPL token transfers involving [tokenAccountAddress]
  /// (the user's ATA for the mint we care about). Returns the
  /// transfers newest-first, decoded from the parsed-transaction
  /// payloads.
  ///
  /// Solana doesn't have an "ERC-20 tokentx" endpoint like Etherscan-
  /// compat does, so this is N+1 round-trips: one
  /// getSignaturesForAddress + one getTransaction per signature.
  /// At [limit]=15 that's 16 RPC calls per token; bounded and
  /// acceptable for a periodic refresh.
  Future<List<SolanaTokenTx>> tokenTransfers({
    required String tokenAccountAddress,
    required String mintAddress,
    required String tokenSymbol,
    required int tokenDecimals,
    required String walletOwnerAddress,
    int limit = 15,
  }) async {
    final sigsRes = await _rpc('getSignaturesForAddress', [
      tokenAccountAddress,
      {'limit': limit},
    ]) as List;
    if (sigsRes.isEmpty) return const [];

    final out = <SolanaTokenTx>[];
    for (final sigEntry in sigsRes) {
      final sigMap = sigEntry as Map<String, dynamic>;
      final sig = sigMap['signature'] as String?;
      if (sig == null) continue;
      // Skip failed transactions — they don't move money.
      if (sigMap['err'] != null) continue;

      final tx = await _rpc('getTransaction', [
        sig,
        {
          'commitment': 'finalized',
          'maxSupportedTransactionVersion': 0,
          'encoding': 'jsonParsed',
        },
      ]);
      if (tx == null) continue;

      final parsed = SolanaTokenTx.fromParsedTransaction(
        json: tx as Map<String, dynamic>,
        signature: sig,
        mintAddress: mintAddress,
        tokenSymbol: tokenSymbol,
        tokenDecimals: tokenDecimals,
        walletOwnerAddress: walletOwnerAddress,
      );
      if (parsed != null) out.add(parsed);
    }
    return out;
  }

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

/// One SPL token transfer involving our wallet, decoded from a
/// jsonParsed transaction. The wire layout is:
///
///   tx.transaction.message.instructions[i] = {
///     program: "spl-token",
///     programId: "Tokenkeg…",
///     parsed: {
///       type: "transfer" OR "transferChecked",
///       info: {
///         amount: "1234567",     // base units, string
///         source: sourceATA pubkey,
///         destination: destATA pubkey,
///         authority: owner pubkey,
///         // transferChecked also has tokenAmount.{amount,decimals,uiAmount,uiAmountString} and mint
///       },
///     },
///   }
///
/// We accept both "transfer" and "transferChecked"; the latter is
/// the post-2021 default and carries the mint inline.
class SolanaTokenTx {
  const SolanaTokenTx({
    required this.signature,
    required this.mintAddress,
    required this.tokenSymbol,
    required this.tokenDecimals,
    required this.rawAmount,
    required this.timestampSec,
    required this.from,
    required this.to,
    required this.isIncoming,
  });

  /// Decode an SPL transfer from a getTransaction (jsonParsed)
  /// payload. Returns null if no spl-token transfer matches our
  /// mint (the tx might be unrelated activity that happened to
  /// touch our ATA — rare but possible).
  static SolanaTokenTx? fromParsedTransaction({
    required Map<String, dynamic> json,
    required String signature,
    required String mintAddress,
    required String tokenSymbol,
    required int tokenDecimals,
    required String walletOwnerAddress,
  }) {
    final blockTime = (json['blockTime'] as num?)?.toInt() ?? 0;
    final tx = json['transaction'] as Map<String, dynamic>?;
    final message = tx?['message'] as Map<String, dynamic>?;
    final instructions = (message?['instructions'] as List?) ?? const [];

    // Find the spl-token transfer instruction that touches our mint.
    for (final instr in instructions) {
      final m = instr as Map<String, dynamic>?;
      if (m == null) continue;
      if (m['program'] != 'spl-token') continue;
      final parsed = m['parsed'] as Map<String, dynamic>?;
      if (parsed == null) continue;
      final type = parsed['type'] as String?;
      if (type != 'transfer' && type != 'transferChecked') continue;

      final info = parsed['info'] as Map<String, dynamic>?;
      if (info == null) continue;

      // For transferChecked the mint is explicit; for the older
      // "transfer" type we have to trust that the source ATA we
      // looked up actually points at our mint (the caller filtered
      // by ATA, so this should always be the case).
      if (type == 'transferChecked') {
        final txMint = info['mint'] as String?;
        if (txMint != null && txMint != mintAddress) continue;
      }

      String s(dynamic v) => v?.toString() ?? '';
      final source = s(info['source']);
      final destination = s(info['destination']);
      final authority = s(info['authority']);

      // Amount: legacy "transfer" puts it in info.amount as a
      // base-units string; transferChecked puts it under
      // info.tokenAmount.amount.
      String? rawStr;
      if (type == 'transferChecked') {
        final tokenAmount = info['tokenAmount'] as Map<String, dynamic>?;
        rawStr = tokenAmount?['amount'] as String?;
      } else {
        rawStr = info['amount'] as String?;
      }
      final raw = BigInt.tryParse(rawStr ?? '') ?? BigInt.zero;
      if (raw == BigInt.zero) continue;

      // Direction: the user's WALLET address is the signer/authority
      // for outgoing transfers (their own ATA's authority is the
      // wallet pubkey). For incoming, the source ATA's authority
      // is someone else and the destination's authority would be
      // ours — but we don't have that without an extra account
      // lookup, so we infer direction from whether the OUR ATA is
      // the source (out) or the destination (in).
      //
      // Approximation: if the authority matches our wallet owner
      // address, it's outgoing. Otherwise it's incoming.
      final isIncoming = authority != walletOwnerAddress;

      return SolanaTokenTx(
        signature: signature,
        mintAddress: mintAddress,
        tokenSymbol: tokenSymbol,
        tokenDecimals: tokenDecimals,
        rawAmount: raw,
        timestampSec: blockTime,
        from: source,
        to: destination,
        isIncoming: isIncoming,
      );
    }
    return null;
  }

  final String signature;
  final String mintAddress;
  final String tokenSymbol;
  final int tokenDecimals;
  final BigInt rawAmount;
  final int timestampSec;
  /// Source token account address (the ATA, not the wallet owner).
  final String from;
  /// Destination token account address.
  final String to;
  final bool isIncoming;

  DateTime get timestamp =>
      DateTime.fromMillisecondsSinceEpoch(timestampSec * 1000);

  double get displayAmount =>
      rawAmount.toDouble() /
      BigInt.from(10).pow(tokenDecimals).toDouble();
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
