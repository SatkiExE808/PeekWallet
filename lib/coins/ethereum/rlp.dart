// Pure-Dart RLP (Recursive Length Prefix) encoder, per the Ethereum
// Yellow Paper appendix B.
//
// Encoding rules:
//   - Single byte 0x00–0x7f: encoded as itself.
//   - Bytes of length 0–55:   [0x80 + length] + payload.
//   - Bytes of length >55:    [0xb7 + len_of_len] + len + payload.
//   - List, payload 0–55 B:   [0xc0 + length] + payload.
//   - List, payload >55 B:    [0xf7 + len_of_len] + len + payload.
//
// For integers we encode as the MINIMAL big-endian byte string —
// no leading zero bytes, and BigInt.zero is encoded as the empty
// string (0x80). This convention is essential for EIP-155/1559 to
// produce canonical transaction hashes that match consensus.
//
// Test coverage in test/eth_rlp_test.dart pins this against well-
// known vectors. Tweaking anything here MUST keep those passing.

import 'dart:typed_data';

/// Encode a tree of RLP items. Accepted types:
///   - `Uint8List` / `List<int>` (treated as bytes)
///   - `BigInt` / `int` (encoded as minimal big-endian unsigned)
///   - `String` (interpreted as 0x-prefixed hex or raw ASCII; we
///      err toward hex if it starts with `0x` to avoid ambiguity)
///   - `List<dynamic>` (recursive list)
/// Throws ArgumentError on any other type, including negative integers.
Uint8List rlpEncode(dynamic value) {
  if (value is List && value is! Uint8List && value is! List<int>) {
    final encodedItems = value.map(rlpEncode).toList();
    final payloadLen = encodedItems.fold<int>(0, (a, b) => a + b.length);
    final lenPrefix = _lengthPrefix(payloadLen, listOffset: 0xc0);
    final out = Uint8List(lenPrefix.length + payloadLen);
    out.setRange(0, lenPrefix.length, lenPrefix);
    var pos = lenPrefix.length;
    for (final e in encodedItems) {
      out.setRange(pos, pos + e.length, e);
      pos += e.length;
    }
    return out;
  }
  final bytes = _toBytes(value);
  return _encodeBytes(bytes);
}

/// Encode an integer as the canonical minimal big-endian unsigned
/// byte string. 0 → empty bytes. Used both as a primitive and as a
/// helper outside RLP for tx-type byte construction.
Uint8List encodeUint(BigInt n) {
  if (n < BigInt.zero) {
    throw ArgumentError('Cannot RLP-encode a negative integer');
  }
  if (n == BigInt.zero) return Uint8List(0);
  var hex = n.toRadixString(16);
  if (hex.length.isOdd) hex = '0$hex';
  final out = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(hex.substring(2 * i, 2 * i + 2), radix: 16);
  }
  return out;
}

Uint8List _encodeBytes(Uint8List bytes) {
  if (bytes.length == 1 && bytes[0] < 0x80) {
    return Uint8List.fromList([bytes[0]]);
  }
  final prefix = _lengthPrefix(bytes.length, listOffset: 0x80);
  final out = Uint8List(prefix.length + bytes.length);
  out.setRange(0, prefix.length, prefix);
  out.setRange(prefix.length, out.length, bytes);
  return out;
}

/// Build a length prefix for either a byte-string (listOffset=0x80)
/// or a list (listOffset=0xc0). Same algorithm; only the base byte
/// differs.
Uint8List _lengthPrefix(int length, {required int listOffset}) {
  if (length < 56) {
    return Uint8List.fromList([listOffset + length]);
  }
  final lenBytes = encodeUint(BigInt.from(length));
  return Uint8List.fromList(
      [listOffset + 55 + lenBytes.length, ...lenBytes]);
}

Uint8List _toBytes(dynamic v) {
  if (v is Uint8List) return v;
  if (v is List<int>) return Uint8List.fromList(v);
  if (v is BigInt) return encodeUint(v);
  if (v is int) {
    if (v < 0) {
      throw ArgumentError('Cannot RLP-encode a negative integer');
    }
    return encodeUint(BigInt.from(v));
  }
  if (v is String) {
    if (v.startsWith('0x') || v.startsWith('0X')) {
      return _hexToBytes(v.substring(2));
    }
    return Uint8List.fromList(v.codeUnits);
  }
  throw ArgumentError(
      'RLP cannot encode value of type ${v.runtimeType}');
}

Uint8List _hexToBytes(String hex) {
  var clean = hex;
  if (clean.length.isOdd) clean = '0$clean';
  final out = Uint8List(clean.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(clean.substring(2 * i, 2 * i + 2), radix: 16);
  }
  return out;
}
