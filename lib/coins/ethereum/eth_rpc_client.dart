import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Minimal Ethereum JSON-RPC client. Separate from EtherscanClient
/// because the send-path calls are RPC methods (eth_getTransactionCount,
/// eth_sendRawTransaction, etc.) that block explorers don't always
/// expose, while the read-path calls (balance, history) are Etherscan-
/// style indexed endpoints that RPC nodes don't expose.
///
/// Accepts a list of endpoints and tries them in order on transient
/// failure (HTTP 5xx, timeout, socket error, TLS error). Per-call,
/// not sticky — every refresh starts at the primary so a brief
/// outage doesn't permanently demote the wallet to a slower mirror.
///
/// Default endpoints: llamarpc.com (primary) + cloudflare-eth.com +
/// publicnode + ankr — all no-auth mainnet RPCs. Users on heavy
/// load can pin their own via Settings → Custom RPC.
class EthRpcClient {
  EthRpcClient({List<String>? endpoints, http.Client? httpClient})
      : _endpoints = _normalize(endpoints ?? _defaultEthEndpoints),
        _http = httpClient ?? http.Client();

  /// Single-endpoint convenience constructor.
  EthRpcClient.single(String endpoint, {http.Client? httpClient})
      : _endpoints = _normalize([endpoint]),
        _http = httpClient ?? http.Client();

  static const _defaultEthEndpoints = <String>[
    'https://eth.llamarpc.com',
    'https://cloudflare-eth.com',
    'https://ethereum-rpc.publicnode.com',
    'https://rpc.ankr.com/eth',
  ];

  static List<String> _normalize(List<String> raw) {
    final cleaned = raw
        .map((u) => u.trim().replaceAll(RegExp(r'/$'), ''))
        .where((u) => u.isNotEmpty)
        .toList(growable: false);
    return cleaned.isEmpty ? _defaultEthEndpoints : cleaned;
  }

  final List<String> _endpoints;
  final http.Client _http;
  int _idCounter = 1;

  Future<dynamic> _rpc(String method, List<dynamic> params) async {
    final id = _idCounter++;
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'method': method,
      'params': params,
      'id': id,
    });
    Object? lastErr;
    for (final endpoint in _endpoints) {
      try {
        final r = await _http
            .post(Uri.parse(endpoint),
                headers: {'Content-Type': 'application/json'}, body: body)
            .timeout(const Duration(seconds: 15));
        if (r.statusCode >= 500) {
          // Infra-level — try the next mirror.
          lastErr = Exception('RPC HTTP ${r.statusCode} at $endpoint');
          continue;
        }
        if (r.statusCode != 200) {
          // 4xx — endpoint rejected the request shape; same shape would
          // fail elsewhere too. Propagate.
          throw Exception('RPC HTTP ${r.statusCode}: ${r.body.trim()}');
        }
        final json = jsonDecode(r.body) as Map<String, dynamic>;
        if (json.containsKey('error')) {
          final err = json['error'] as Map<String, dynamic>;
          // JSON-RPC-level error — semantic failure (nonce too low,
          // out of gas, method not found). Don't try the next endpoint
          // by default; for some methods like eth_maxPriorityFeePerGas
          // a "method not found" should be silenced by the caller.
          throw Exception(
              'RPC error: ${err['message']} (code ${err['code']})');
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
    throw lastErr ?? Exception('All RPC endpoints failed');
  }

  /// Next nonce for [address]. We use "pending" (not "latest") so
  /// we don't double-spend the nonce if the user has a tx still in
  /// the mempool.
  Future<BigInt> getTransactionCount(String address) async {
    final res = await _rpc('eth_getTransactionCount', [address, 'pending']);
    return _hexToBigInt(res as String);
  }

  /// Current chain base fee. We use this together with priority fee
  /// to compute maxFeePerGas: maxFee = baseFee * 2 + maxPriority.
  /// The 2x base-fee buffer protects against the base fee climbing
  /// between when we sign and when the tx actually gets included.
  Future<BigInt> baseFeePerGas() async {
    final res = await _rpc('eth_feeHistory', [
      '0x1',
      'latest',
      <int>[],
    ]) as Map<String, dynamic>;
    final list = (res['baseFeePerGas'] as List?) ?? const [];
    if (list.isEmpty) throw Exception('Empty baseFeePerGas response');
    return _hexToBigInt(list.last as String);
  }

  /// Suggested priority fee (tip to the proposer). Free RPCs return
  /// this via eth_maxPriorityFeePerGas; we fall back to 1.5 gwei
  /// (the long-time MetaMask default) if the call isn't supported.
  Future<BigInt> maxPriorityFeePerGas() async {
    try {
      final res = await _rpc('eth_maxPriorityFeePerGas', []);
      return _hexToBigInt(res as String);
    } catch (_) {
      return BigInt.from(1500000000); // 1.5 gwei
    }
  }

  /// Gas units the chain will need to execute the tx. For a plain
  /// 21000-gas transfer we could skip this, but estimating is safer
  /// in case the recipient is a smart-contract account.
  Future<BigInt> estimateGas({
    required String from,
    required String to,
    required BigInt valueWei,
    String? dataHex,
  }) async {
    final params = <String, dynamic>{
      'from': from,
      'to': to,
      'value': '0x${valueWei.toRadixString(16)}',
    };
    if (dataHex != null && dataHex.isNotEmpty) {
      params['data'] = dataHex;
    }
    final res = await _rpc('eth_estimateGas', [params]);
    return _hexToBigInt(res as String);
  }

  /// Broadcast a signed transaction. Returns the txid on success.
  Future<String> sendRawTransaction(String rawHex) async {
    final res = await _rpc('eth_sendRawTransaction', [rawHex]);
    return res as String;
  }

  /// Generic eth_call. Used for reading ERC-20 view methods
  /// (balanceOf, decimals, etc.) without sending a transaction.
  /// Returns the result as a 0x-prefixed hex string.
  Future<String> ethCall({
    required String to,
    required String data,
    String tag = 'latest',
  }) async {
    final res = await _rpc('eth_call', [
      {'to': to, 'data': data},
      tag,
    ]);
    return res as String;
  }

  /// Chain id reported by the RPC. Mainnet = 1, Sepolia = 11155111.
  /// Used as a sanity check before signing — we don't want to sign
  /// a mainnet tx against a testnet endpoint.
  Future<int> chainId() async {
    final res = await _rpc('eth_chainId', []);
    return _hexToBigInt(res as String).toInt();
  }

  void close() => _http.close();
}

/// Default endpoint list for the Polygon mainnet RPC. Same trade-off
/// space as Ethereum — keep widely-available no-auth nodes first so a
/// brand-new install can sync without any user configuration.
const kDefaultPolygonRpcEndpoints = <String>[
  'https://polygon-rpc.com',
  'https://polygon-bor-rpc.publicnode.com',
  'https://rpc.ankr.com/polygon',
  'https://polygon.llamarpc.com',
];

BigInt _hexToBigInt(String hex) {
  var clean = hex.startsWith('0x') ? hex.substring(2) : hex;
  if (clean.isEmpty) return BigInt.zero;
  return BigInt.parse(clean, radix: 16);
}
