import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thin TronGrid v1 client. Public endpoint at api.trongrid.io is
/// open without an API key for low-volume usage; heavier users would
/// pin their own via Settings → Custom node (a future hook).
///
/// We deliberately stick to the v1 REST surface (GET /v1/accounts/…)
/// rather than the older `/wallet/getaccount` POST path because v1
/// returns JSON-shaped data instead of protobuf-flavored maps with
/// snake-case keys.
class TronGridClient {
  TronGridClient({String? baseUrl, http.Client? httpClient})
      : _base = (baseUrl ?? _defaultBase).replaceAll(RegExp(r'/$'), ''),
        _http = httpClient ?? http.Client();

  static const _defaultBase = 'https://api.trongrid.io';

  final String _base;
  final http.Client _http;

  /// TRX balance for [base58Address] in sun (1 TRX = 10^6 sun).
  /// Returns 0 for a fresh / never-funded address.
  Future<int> balanceSun(String base58Address) async {
    final r = await _http
        .get(Uri.parse('$_base/v1/accounts/$base58Address'))
        .timeout(const Duration(seconds: 10));
    if (r.statusCode != 200) {
      throw Exception('TronGrid API returned ${r.statusCode}');
    }
    final json = jsonDecode(r.body) as Map<String, dynamic>;
    if (json['success'] != true) {
      // success=false typically means the address has no on-chain
      // record yet — return 0 instead of throwing.
      return 0;
    }
    final data = (json['data'] as List?) ?? const [];
    if (data.isEmpty) return 0;
    final acct = data.first as Map<String, dynamic>;
    return (acct['balance'] as num?)?.toInt() ?? 0;
  }

  /// Recent transactions involving [base58Address]. Each entry
  /// carries the TRX amount transferred (if any), timestamp, and
  /// hash. Limited to 50 by default.
  Future<List<TronTx>> transactions(String base58Address,
      {int limit = 50}) async {
    final uri = Uri.parse(
        '$_base/v1/accounts/$base58Address/transactions'
        '?limit=$limit&only_confirmed=true');
    final r = await _http.get(uri).timeout(const Duration(seconds: 12));
    if (r.statusCode != 200) {
      throw Exception('TronGrid API returned ${r.statusCode}');
    }
    final json = jsonDecode(r.body) as Map<String, dynamic>;
    if (json['success'] != true) return const [];
    final list = (json['data'] as List?) ?? const [];
    return list
        .map((m) =>
            TronTx.fromJson(m as Map<String, dynamic>, base58Address))
        .whereType<TronTx>()
        .toList();
  }

  /// Call a view method on a smart contract. Wraps TronGrid's
  /// `/wallet/triggerconstantcontract` — Tron's equivalent of
  /// Ethereum's `eth_call`. Returns the raw hex of the first
  /// `constant_result` entry; the caller decodes it as needed
  /// (uint256 for balanceOf, etc.).
  ///
  /// All addresses passed here MUST be in the "41…" hex form (no
  /// 0x prefix, no base58 T-prefix); TronGrid rejects mixed forms
  /// with cryptic errors. The trc20 module's _normalizeAddress
  /// helper does the conversion.
  Future<String> triggerConstantContract({
    required String ownerHexAddress,
    required String contractHexAddress,
    required String functionSelector,
    required String parameterHex,
  }) async {
    final body = jsonEncode({
      'owner_address': ownerHexAddress,
      'contract_address': contractHexAddress,
      'function_selector': functionSelector,
      'parameter': parameterHex,
      'visible': false,
    });
    final r = await _http
        .post(
          Uri.parse('$_base/wallet/triggerconstantcontract'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 10));
    if (r.statusCode != 200) {
      throw Exception(
          'TronGrid contract call returned ${r.statusCode}');
    }
    final json = jsonDecode(r.body) as Map<String, dynamic>;
    final result = (json['constant_result'] as List?) ?? const [];
    if (result.isEmpty) return '';
    return (result.first as String?) ?? '';
  }

  /// Have TronGrid build an UNSIGNED native-TRX transfer transaction.
  /// Returns the parsed response — caller signs raw_data_hex locally,
  /// then submits the signed payload to /wallet/broadcasttransaction.
  ///
  /// All addresses passed here are 41-prefixed hex form.
  Future<TronUnsignedTx> createNativeTransaction({
    required String ownerHexAddress,
    required String toHexAddress,
    required int amountSun,
  }) async {
    final body = jsonEncode({
      'owner_address': ownerHexAddress,
      'to_address': toHexAddress,
      'amount': amountSun,
      'visible': false,
    });
    final r = await _http
        .post(
          Uri.parse('$_base/wallet/createtransaction'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 12));
    if (r.statusCode != 200) {
      throw Exception(
          'TronGrid createtransaction returned ${r.statusCode}: ${r.body.trim()}');
    }
    final json = jsonDecode(r.body) as Map<String, dynamic>;
    if (json['Error'] != null) {
      throw Exception('TronGrid: ${json['Error']}');
    }
    return TronUnsignedTx.fromJson(json);
  }

  /// Have TronGrid build an UNSIGNED TRC-20 transfer transaction.
  /// Same hosted-build, local-sign, hosted-broadcast pattern as
  /// [createNativeTransaction] — only the underlying contract call
  /// differs.
  Future<TronUnsignedTx> createTrc20Transfer({
    required String ownerHexAddress,
    required String contractHexAddress,
    required String toHexAddress,
    required BigInt amountBaseUnits,
    int feeLimit = 100000000, // 100 TRX fee cap; way more than needed
  }) async {
    // ABI parameter for transfer(address,uint256):
    //   [32-byte padded to-address][32-byte padded amount]
    final toPadded = ('0' * 24) + toHexAddress.substring(2); // strip 41 prefix
    final amountHex = amountBaseUnits.toRadixString(16);
    final amountPadded = amountHex.padLeft(64, '0');
    final parameter = '$toPadded$amountPadded';

    final body = jsonEncode({
      'owner_address': ownerHexAddress,
      'contract_address': contractHexAddress,
      'function_selector': 'transfer(address,uint256)',
      'parameter': parameter,
      'fee_limit': feeLimit,
      'call_value': 0,
      'visible': false,
    });
    final r = await _http
        .post(
          Uri.parse('$_base/wallet/triggersmartcontract'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 12));
    if (r.statusCode != 200) {
      throw Exception(
          'TronGrid triggersmartcontract returned ${r.statusCode}: ${r.body.trim()}');
    }
    final json = jsonDecode(r.body) as Map<String, dynamic>;
    // The contract trigger response wraps the tx in a "transaction"
    // field rather than at the top level.
    final tx = json['transaction'] as Map<String, dynamic>?;
    if (tx == null) {
      final err = json['result']?['message'] ?? json['Error'] ?? 'unknown';
      throw Exception('TronGrid trc20 build failed: $err');
    }
    return TronUnsignedTx.fromJson(tx);
  }

  /// Broadcast a signed transaction. Returns the txid on success.
  Future<String> broadcastTransaction(TronSignedTx signed) async {
    final r = await _http
        .post(
          Uri.parse('$_base/wallet/broadcasttransaction'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(signed.toJson()),
        )
        .timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) {
      throw Exception(
          'TronGrid broadcast returned ${r.statusCode}: ${r.body.trim()}');
    }
    final json = jsonDecode(r.body) as Map<String, dynamic>;
    if (json['result'] != true) {
      final msg = json['message']?.toString() ?? json.toString();
      // The error message is sometimes a hex-encoded UTF-8 string —
      // try to decode it for the user, fall back to the raw form.
      String pretty = msg;
      try {
        if (RegExp(r'^[0-9a-fA-F]+$').hasMatch(msg)) {
          final bytes = <int>[];
          for (var i = 0; i < msg.length; i += 2) {
            bytes.add(int.parse(msg.substring(i, i + 2), radix: 16));
          }
          pretty = String.fromCharCodes(bytes);
        }
      } catch (_) {/* keep raw */}
      throw Exception('Tron broadcast rejected: $pretty');
    }
    return signed.txid;
  }

  void close() => _http.close();
}

/// Parsed response from /wallet/createtransaction or the wrapped
/// "transaction" sub-object of /wallet/triggersmartcontract. Holds
/// just enough to sign + rebroadcast.
class TronUnsignedTx {
  const TronUnsignedTx({
    required this.txid,
    required this.rawData,
    required this.rawDataHex,
  });

  factory TronUnsignedTx.fromJson(Map<String, dynamic> json) {
    return TronUnsignedTx(
      txid: json['txID'] as String? ?? '',
      rawData: json['raw_data'] as Map<String, dynamic>,
      rawDataHex: json['raw_data_hex'] as String? ?? '',
    );
  }

  /// The txid TronGrid computed for the unsigned bytes. We re-validate
  /// this client-side after signing (sha256 of raw_data_hex should
  /// match) so a malicious node can't trick us into broadcasting
  /// against a forged txid.
  final String txid;
  final Map<String, dynamic> rawData;
  final String rawDataHex;
}

class TronSignedTx {
  const TronSignedTx({
    required this.txid,
    required this.rawData,
    required this.rawDataHex,
    required this.signatureHex,
  });

  Map<String, dynamic> toJson() => {
        'txID': txid,
        'raw_data': rawData,
        'raw_data_hex': rawDataHex,
        'signature': [signatureHex],
      };

  final String txid;
  final Map<String, dynamic> rawData;
  final String rawDataHex;
  /// 65-byte (r||s||v) compact signature, hex-encoded.
  final String signatureHex;
}

/// One on-chain Tron transaction, simplified for the UI. We extract
/// only the native TRX transfer details — TRC-20 token transfers
/// (USDT etc.) appear here too but they don't carry a "value" field
/// and would need separate per-token decoding to display sensibly.
class TronTx {
  const TronTx({
    required this.hash,
    required this.netSun,
    required this.timestampSec,
    required this.confirmed,
    required this.feeSun,
  });

  /// Parse a TronGrid tx entry from the perspective of [ourAddress].
  /// Returns null if the entry isn't a TransferContract (e.g., TRC-20
  /// transactions, vote operations, etc.) — those need separate
  /// handling and we don't show them yet.
  static TronTx? fromJson(Map<String, dynamic> json, String ourBase58) {
    final raw = json['raw_data'] as Map<String, dynamic>?;
    final contracts = (raw?['contract'] as List?) ?? const [];
    if (contracts.isEmpty) return null;
    final first = contracts.first as Map<String, dynamic>;
    final type = first['type'] as String?;
    if (type != 'TransferContract') {
      // Skip TRC-20 / vote / freeze / etc. for the native-TRX history.
      return null;
    }
    final value = first['parameter']?['value'] as Map<String, dynamic>?;
    final amount = (value?['amount'] as num?)?.toInt() ?? 0;
    final fromHex = value?['owner_address'] as String?;
    final toHex = value?['to_address'] as String?;

    // TronGrid returns hex addresses inside contract.value; the v1
    // listing endpoint accepts base58 input but emits hex output.
    // Compare our own base58 address against the hex by converting
    // the BASE58 to its hex form. We don't have a base58check decoder
    // exposed here, so use a cheap heuristic: TronGrid also includes
    // a top-level "ret"/"signature" field, and the from-address in
    // hex form for the SAME owner_address can be matched if we
    // upcase. As a simple approximation, treat the value as net-
    // outgoing if owner_address (hex) appears in the response and we
    // are the sender (best-effort flagging only).
    //
    // For accuracy: derive base58 from hex via the same checksum
    // logic. We do that inline here:
    final ourHex = _addressBase58ToHex(ourBase58);
    int net = 0;
    int fee = (json['ret'] is List
        ? ((json['ret'] as List).isEmpty
            ? 0
            : ((json['ret'].first as Map?)?['fee'] as num?)?.toInt() ?? 0)
        : 0);
    if (fromHex != null && fromHex.toLowerCase() == ourHex.toLowerCase()) {
      net = -amount - fee;
    } else if (toHex != null && toHex.toLowerCase() == ourHex.toLowerCase()) {
      net = amount;
    }

    final blockTime = (json['block_timestamp'] as num?)?.toInt() ?? 0;
    final retList = json['ret'] as List?;
    final bool retOk;
    if (retList != null && retList.isNotEmpty) {
      final first = retList.first as Map?;
      retOk = first?['contractRet'] == 'SUCCESS';
    } else {
      retOk = true;
    }

    return TronTx(
      hash: json['txID'] as String? ?? '',
      netSun: net,
      timestampSec: blockTime ~/ 1000, // ms → s
      confirmed: retOk,
      feeSun: fee,
    );
  }

  final String hash;
  final int netSun;
  final int timestampSec;
  final bool confirmed;
  final int feeSun;

  bool get isIncoming => netSun > 0;
  double get netTrx => netSun / 1000000.0;
  double get feeTrx => feeSun / 1000000.0;
  DateTime get timestamp =>
      DateTime.fromMillisecondsSinceEpoch(timestampSec * 1000);
}

/// Convert a Tron base58check address back to its 21-byte hex form
/// (with the leading 0x41 byte). Used to match own-address against
/// TronGrid's hex output. Returns empty string on decode error.
///
/// This is a localized helper rather than a public utility because
/// TronGrid is the only place we need the round-trip; the wallet's
/// derivation already produces the hex form directly.
String _addressBase58ToHex(String base58) {
  try {
    final decoded = _base58Decode(base58);
    if (decoded == null || decoded.length < 21) return '';
    // Strip the 4-byte checksum at the end.
    final payload = decoded.sublist(0, decoded.length - 4);
    return payload
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  } catch (_) {
    return '';
  }
}

/// Local base58 decode (same as solana_keys.dart's, copied here so
/// this file is self-contained for TronGrid use). Returns null on
/// invalid input.
List<int>? _base58Decode(String s) {
  if (s.isEmpty) return [];
  const alphabet =
      '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  var n = BigInt.zero;
  final big58 = BigInt.from(58);
  for (final ch in s.runes) {
    final idx = alphabet.indexOf(String.fromCharCode(ch));
    if (idx < 0) return null;
    n = n * big58 + BigInt.from(idx);
  }
  final tmp = <int>[];
  while (n > BigInt.zero) {
    tmp.add((n % BigInt.from(256)).toInt());
    n = n ~/ BigInt.from(256);
  }
  var leadingOnes = 0;
  for (var i = 0; i < s.length && s[i] == '1'; i++) {
    leadingOnes++;
  }
  final out = List<int>.filled(leadingOnes + tmp.length, 0);
  for (var i = 0; i < tmp.length; i++) {
    out[leadingOnes + i] = tmp[tmp.length - 1 - i];
  }
  return out;
}
