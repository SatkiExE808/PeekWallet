import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Thin client for an Etherscan-compatible API (Etherscan itself,
/// Blockscout, Routescan, etc.). We default to Blockscout's public
/// Ethereum mainnet instance because it requires no API key — same
/// privacy tradeoff as mempool.space for Bitcoin (your IP plus the
/// address you're looking at is visible to the provider).
///
/// Accepts a list of base URLs and tries each in order on transient
/// failure (5xx / timeout / socket). Different Blockscout instances
/// behave slightly differently, but the Etherscan API surface they
/// implement is the same across them — same parameters, same JSON
/// response shape — so they're interchangeable for read-path calls.
///
/// Future: route through Tor when we add the Tor support roadmap item.
class EtherscanClient {
  EtherscanClient({List<String>? baseUrls, http.Client? httpClient})
      : _bases = _normalize(baseUrls ?? const [_defaultBase]),
        _http = httpClient ?? http.Client();

  EtherscanClient.single(String baseUrl, {http.Client? httpClient})
      : _bases = _normalize([baseUrl]),
        _http = httpClient ?? http.Client();

  /// Blockscout's hosted Ethereum mainnet API. The Etherscan-
  /// compatible surface lives at /api with module=… parameters.
  /// For Polygon and other EVM chains we override via [baseUrls].
  static const _defaultBase = 'https://eth.blockscout.com/api';

  static List<String> _normalize(List<String> raw) {
    final cleaned = raw
        .map((u) => u.replaceAll(RegExp(r'/$'), ''))
        .where((u) => u.isNotEmpty)
        .toList(growable: false);
    return cleaned.isEmpty ? const [_defaultBase] : cleaned;
  }

  final List<String> _bases;
  final http.Client _http;

  /// Wei balance for a single address. Etherscan-style endpoint
  /// returns the value as a decimal STRING (because wei is uint256
  /// and can exceed Dart's int range), so we parse to BigInt.
  Future<BigInt> balanceWei(String address) async {
    return _tryAll(
      query: '?module=account&action=balance&address=$address&tag=latest',
      timeout: const Duration(seconds: 10),
      parse: (body) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        final status = json['status']?.toString();
        if (status != '1') {
          final msg = json['message']?.toString() ?? '';
          if (msg.contains('No transactions') || msg.contains('not found')) {
            return BigInt.zero;
          }
          throw Exception('Etherscan-compat error: ${json['message']}');
        }
        final result = json['result']?.toString();
        if (result == null) return BigInt.zero;
        return BigInt.parse(result);
      },
    );
  }

  /// Recent transactions for an address. Blockscout's txlist endpoint
  /// returns up to 10000 records — we cap to 50 for the UI.
  Future<List<EthereumTx>> transactions(String address,
      {int limit = 50}) async {
    final addrLower = address.toLowerCase();
    return _tryAll(
      query: '?module=account&action=txlist&address=$address'
          '&startblock=0&endblock=99999999&sort=desc&page=1&offset=$limit',
      timeout: const Duration(seconds: 12),
      parse: (body) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        if (json['status']?.toString() != '1') return const <EthereumTx>[];
        final list = (json['result'] as List?) ?? const [];
        return list
            .map((m) =>
                EthereumTx.fromJson(m as Map<String, dynamic>, addrLower))
            .toList();
      },
    );
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
    final addrLower = address.toLowerCase();
    return _tryAll(
      query: '?module=account&action=tokentx'
          '&address=$address&sort=desc&page=1&offset=$limit',
      timeout: const Duration(seconds: 12),
      parse: (body) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        if (json['status']?.toString() != '1') return const <TokenTransfer>[];
        final list = (json['result'] as List?) ?? const [];
        return list
            .map((m) =>
                TokenTransfer.fromJson(m as Map<String, dynamic>, addrLower))
            .toList();
      },
    );
  }

  Future<T> _tryAll<T>({
    required String query,
    required Duration timeout,
    required T Function(String body) parse,
  }) async {
    Object? lastErr;
    for (final base in _bases) {
      try {
        final r = await _http
            .get(Uri.parse('$base$query'))
            .timeout(timeout);
        if (r.statusCode >= 500) {
          lastErr = Exception('Etherscan-compat HTTP ${r.statusCode} at $base');
          continue;
        }
        if (r.statusCode != 200) {
          throw Exception(
              'Etherscan-compat at $base returned ${r.statusCode}');
        }
        return parse(r.body);
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
    throw lastErr ?? Exception('All Etherscan-compat endpoints failed');
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

    BigInt net;
    if (from == ourAddress && to == ourAddress) {
      net = BigInt.zero - gasFee;
    } else if (from == ourAddress) {
      net = BigInt.zero - value - gasFee;
    } else if (to == ourAddress) {
      net = value;
    } else {
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
