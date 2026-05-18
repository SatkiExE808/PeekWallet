import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thin client for an Etherscan-compatible API (Etherscan itself,
/// Blockscout, Routescan, etc.). We default to Blockscout's public
/// Ethereum mainnet instance because it requires no API key — same
/// privacy tradeoff as mempool.space for Bitcoin (your IP plus the
/// address you're looking at is visible to the provider).
///
/// Future: route through Tor when we add the Tor support roadmap item.
class EtherscanClient {
  EtherscanClient({String? baseUrl, http.Client? httpClient})
      : _base = (baseUrl ?? _defaultBase).replaceAll(RegExp(r'/$'), ''),
        _http = httpClient ?? http.Client();

  /// Blockscout's hosted Ethereum mainnet API. The Etherscan-
  /// compatible surface lives at /api with module=… parameters.
  /// For Polygon and other EVM chains we override via [baseUrl].
  static const _defaultBase = 'https://eth.blockscout.com/api';

  final String _base;
  final http.Client _http;

  /// Wei balance for a single address. Etherscan-style endpoint
  /// returns the value as a decimal STRING (because wei is uint256
  /// and can exceed Dart's int range), so we parse to BigInt.
  Future<BigInt> balanceWei(String address) async {
    final uri = Uri.parse(
        '$_base?module=account&action=balance&address=$address&tag=latest');
    final r = await _http.get(uri).timeout(const Duration(seconds: 8));
    if (r.statusCode != 200) {
      throw Exception('Etherscan-compat API returned ${r.statusCode}');
    }
    final json = jsonDecode(r.body) as Map<String, dynamic>;
    final status = json['status']?.toString();
    if (status != '1') {
      // status "0" + message "No transactions found" is legitimate
      // (a brand-new address with zero balance). Detect that case
      // and return 0; everything else is a real error.
      final msg = json['message']?.toString() ?? '';
      if (msg.contains('No transactions') || msg.contains('not found')) {
        return BigInt.zero;
      }
      throw Exception('Etherscan-compat error: ${json['message']}');
    }
    final result = json['result']?.toString();
    if (result == null) return BigInt.zero;
    return BigInt.parse(result);
  }

  /// Recent transactions for an address. Blockscout's txlist endpoint
  /// returns up to 10000 records — we cap to 50 for the UI.
  Future<List<EthereumTx>> transactions(String address, {int limit = 50}) async {
    final uri = Uri.parse(
      '$_base?module=account&action=txlist&address=$address'
      '&startblock=0&endblock=99999999&sort=desc&page=1&offset=$limit',
    );
    final r = await _http.get(uri).timeout(const Duration(seconds: 10));
    if (r.statusCode != 200) {
      throw Exception('Etherscan-compat API returned ${r.statusCode}');
    }
    final json = jsonDecode(r.body) as Map<String, dynamic>;
    final status = json['status']?.toString();
    if (status != '1') {
      // "No transactions found" is the documented response when an
      // address has no on-chain activity — surface it as an empty
      // list, not an error.
      return const [];
    }
    final list = (json['result'] as List?) ?? const [];
    return list
        .map((m) => EthereumTx.fromJson(
            m as Map<String, dynamic>, address.toLowerCase()))
        .toList();
  }

  /// ERC-20 token transfer events for [address]. Blockscout's
  /// Etherscan-compat endpoint returns every Transfer log involving
  /// the address — both incoming and outgoing, across every token
  /// the user has ever touched. Newest first, capped to [limit].
  ///
  /// We don't filter by specific token contract here; the wallet
  /// will keep the entries whose contract matches a token it knows
  /// about (defaults + custom) so unrelated airdrops don't clutter
  /// the history.
  Future<List<TokenTransfer>> tokenTransfers(String address,
      {int limit = 50}) async {
    final uri = Uri.parse('$_base?module=account&action=tokentx'
        '&address=$address&sort=desc&page=1&offset=$limit');
    final r = await _http.get(uri).timeout(const Duration(seconds: 10));
    if (r.statusCode != 200) {
      throw Exception('Etherscan-compat tokentx returned ${r.statusCode}');
    }
    final json = jsonDecode(r.body) as Map<String, dynamic>;
    if (json['status']?.toString() != '1') return const [];
    final list = (json['result'] as List?) ?? const [];
    return list
        .map((m) => TokenTransfer.fromJson(
            m as Map<String, dynamic>, address.toLowerCase()))
        .toList();
  }

  void close() => _http.close();
}

/// One ERC-20 Transfer event from the user's perspective. Direction
/// is recorded so the UI can show a "+" or "−" without recomputing
/// it from from/to comparisons.
class TokenTransfer {
  const TokenTransfer({
    required this.hash,
    required this.contract,
    required this.tokenSymbol,
    required this.tokenDecimals,
    required this.rawAmount,
    required this.timestampSec,
    required this.confirmed,
    required this.from,
    required this.to,
    required this.isIncoming,
  });

  factory TokenTransfer.fromJson(
      Map<String, dynamic> json, String ourAddress) {
    String s(dynamic v) => v?.toString() ?? '';
    final from = s(json['from']).toLowerCase();
    final to = s(json['to']).toLowerCase();
    return TokenTransfer(
      hash: s(json['hash']),
      contract: s(json['contractAddress']).toLowerCase(),
      tokenSymbol: s(json['tokenSymbol']),
      tokenDecimals: int.tryParse(s(json['tokenDecimal'])) ?? 18,
      rawAmount: BigInt.tryParse(s(json['value'])) ?? BigInt.zero,
      timestampSec: int.tryParse(s(json['timeStamp'])) ?? 0,
      confirmed: (int.tryParse(s(json['confirmations'])) ?? 0) > 0,
      from: from,
      to: to,
      isIncoming: to == ourAddress,
    );
  }

  final String hash;
  final String contract;
  final String tokenSymbol;
  final int tokenDecimals;
  /// Raw transferred amount in base units (not display units).
  final BigInt rawAmount;
  final int timestampSec;
  final bool confirmed;
  final String from;
  final String to;
  final bool isIncoming;

  DateTime get timestamp =>
      DateTime.fromMillisecondsSinceEpoch(timestampSec * 1000);

  /// Display amount with the token's own decimals applied.
  double get displayAmount =>
      rawAmount.toDouble() /
      BigInt.from(10).pow(tokenDecimals).toDouble();
}

/// One on-chain transaction as seen from the perspective of one of
/// our addresses. netWei is positive for incoming, negative for
/// outgoing. Gas is the fee paid (= gasUsed * gasPrice).
class EthereumTx {
  const EthereumTx({
    required this.hash,
    required this.netWei,
    required this.timestampSec,
    required this.blockHeight,
    required this.confirmed,
    required this.gasFeeWei,
    required this.from,
    required this.to,
  });

  factory EthereumTx.fromJson(Map<String, dynamic> json, String ourAddress) {
    String s(dynamic v) => v?.toString() ?? '';
    BigInt b(dynamic v) => BigInt.tryParse(s(v)) ?? BigInt.zero;

    final from = s(json['from']).toLowerCase();
    final to = s(json['to']).toLowerCase();
    final value = b(json['value']);
    final gasUsed = b(json['gasUsed']);
    final gasPrice = b(json['gasPrice']);
    final gasFee = gasUsed * gasPrice;

    // Net from our perspective:
    //   + if we received (to == us)
    //   - value - gasFee if we sent (from == us)
    BigInt net;
    if (from == ourAddress && to == ourAddress) {
      net = BigInt.zero - gasFee; // self-send, only fee
    } else if (from == ourAddress) {
      net = BigInt.zero - value - gasFee;
    } else if (to == ourAddress) {
      net = value;
    } else {
      // Internal tx or contract — should be rare in txlist mode.
      net = BigInt.zero;
    }

    return EthereumTx(
      hash: s(json['hash']),
      netWei: net,
      timestampSec: int.tryParse(s(json['timeStamp'])) ?? 0,
      blockHeight: int.tryParse(s(json['blockNumber'])) ?? 0,
      confirmed: (int.tryParse(s(json['confirmations'])) ?? 0) > 0,
      gasFeeWei: gasFee,
      from: from,
      to: to,
    );
  }

  final String hash;
  /// Positive = net incoming. Negative = net outgoing. Includes gas
  /// fee in the outgoing case.
  final BigInt netWei;
  final int timestampSec;
  final int blockHeight;
  final bool confirmed;
  final BigInt gasFeeWei;
  final String from;
  final String to;

  bool get isIncoming => netWei > BigInt.zero;
  DateTime get timestamp =>
      DateTime.fromMillisecondsSinceEpoch(timestampSec * 1000);

  /// Convert wei → ETH for display. ETH has 18 decimals.
  static double weiToEth(BigInt wei) =>
      wei.toDouble() / 1000000000000000000.0;

  double get netEth => weiToEth(netWei);
  double get gasFeeEth => weiToEth(gasFeeWei);
}
