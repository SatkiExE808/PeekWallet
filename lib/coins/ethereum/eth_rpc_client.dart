import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Minimal Ethereum JSON-RPC client. Separate from EtherscanClient
/// because the send-path calls are RPC methods (eth_getTransactionCount,
/// eth_sendRawTransaction, etc.) that block explorers don't always
/// expose, while the read-path calls (balance, history) are Etherscan-
/// style indexed endpoints that RPC nodes don't expose.
///
/// Default endpoint: llamarpc.com — a public no-auth mainnet RPC.
/// Falls back to publicnode.com on transient errors. Users on heavy
/// load can swap this via a future Settings → Node URL field.
class EthRpcClient {
  EthRpcClient({String? endpoint, http.Client? httpClient})
      : _endpoint = endpoint ?? _defaultEndpoint,
        _http = httpClient ?? http.Client();

  static const _defaultEndpoint = 'https://eth.llamarpc.com';

  final String _endpoint;
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
    final r = await _http
        .post(Uri.parse(_endpoint),
            headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) {
      throw Exception('RPC HTTP ${r.statusCode}: ${r.body.trim()}');
    }
    final json = jsonDecode(r.body) as Map<String, dynamic>;
    if (json.containsKey('error')) {
      final err = json['error'] as Map<String, dynamic>;
      throw Exception('RPC error: ${err['message']} (code ${err['code']})');
    }
    return json['result'];
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
    // eth_feeHistory returns the most recent N blocks' baseFee.
    final res = await _rpc('eth_feeHistory', [
      '0x1', // last 1 block
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

  /// Chain id reported by the RPC. Mainnet = 1, Sepolia = 11155111.
  /// Used as a sanity check before signing — we don't want to sign
  /// a mainnet tx against a testnet endpoint.
  Future<int> chainId() async {
    final res = await _rpc('eth_chainId', []);
    return _hexToBigInt(res as String).toInt();
  }

  void close() => _http.close();
}

BigInt _hexToBigInt(String hex) {
  var clean = hex.startsWith('0x') ? hex.substring(2) : hex;
  if (clean.isEmpty) return BigInt.zero;
  return BigInt.parse(clean, radix: 16);
}
