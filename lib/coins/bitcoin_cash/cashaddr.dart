// CashAddr encoding for Bitcoin Cash addresses.
//
// CashAddr uses the same 32-symbol alphabet as bech32 but differs in
// every other meaningful way: a colon separator instead of "1", a
// BCH-specific polymod with a different generator polynomial, a
// version byte that encodes both the address type (P2PKH vs P2SH)
// and the hash size, and a 40-bit checksum (8 base32 chars) instead
// of bech32's 30-bit one.
//
// Spec: https://github.com/bitcoincashorg/bitcoincash.org/blob/master/spec/cashaddr.md
//
// Test vectors are in test/cashaddr_test.dart — the encoder MUST
// reproduce them or every BCH address we generate is wrong.

import 'dart:typed_data';

const String _alphabet = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';

const String _mainnetPrefix = 'bitcoincash';

/// CashAddr type byte. P2PKH = 0, P2SH = 1. We only emit P2PKH today
/// (since BCH doesn't use SegWit and we derive standard hash160
/// addresses).
enum CashAddrType {
  p2pkh,
  p2sh,
}

/// Encode a 20-byte hash160 as a CashAddr-prefixed mainnet address.
/// Output format: `bitcoincash:qpm2qsznhks23z7629mms6s4cwef74vcwvy22gdx`.
String cashaddrEncode({
  required Uint8List hash160,
  CashAddrType type = CashAddrType.p2pkh,
  String prefix = _mainnetPrefix,
}) {
  if (hash160.length != 20) {
    throw ArgumentError(
        'CashAddr payload must be 20 bytes (hash160), got ${hash160.length}');
  }

  // Version byte: (type_bits << 3) | size_bits
  //   type_bits: 0 = P2PKH, 1 = P2SH
  //   size_bits: 0 = 160-bit hash (20 bytes)
  final versionByte = (type == CashAddrType.p2pkh ? 0 : 1) << 3 | 0;
  final payload8 = Uint8List(1 + 20)
    ..[0] = versionByte
    ..setRange(1, 21, hash160);

  // 8→5 bit conversion of the payload.
  final payload5 = _convert8to5(payload8);

  // Build the polymod input: expanded prefix || 0 separator ||
  // payload5 || 8 zero-bytes (placeholder for checksum)
  final hrpExpanded = _expandHrp(prefix);
  final polymodInput = <int>[
    ...hrpExpanded,
    ...payload5,
    0, 0, 0, 0, 0, 0, 0, 0,
  ];
  final polymod = _polymod(polymodInput) ^ 1;

  // Extract 8 base32 symbols (5 bits each) from the 40-bit checksum.
  final checksum5 = List<int>.generate(8, (i) {
    return (polymod >> (5 * (7 - i))) & 0x1f;
  });

  // Concatenate payload5 + checksum5, base32-encode.
  final body = StringBuffer();
  for (final s in [...payload5, ...checksum5]) {
    body.write(_alphabet[s]);
  }

  return '$prefix:${body.toString()}';
}

/// Decode a CashAddr-formatted string into its (type, hash) pair.
/// Returns null on invalid checksum or wrong format.
({CashAddrType type, Uint8List hash})? cashaddrDecode(String input,
    {String expectedPrefix = _mainnetPrefix}) {
  final colon = input.indexOf(':');
  if (colon < 0) return null;
  final prefix = input.substring(0, colon).toLowerCase();
  if (prefix != expectedPrefix) return null;
  final body = input.substring(colon + 1).toLowerCase();
  if (body.length < 8 + 1) return null; // at least 1 payload symbol + 8 checksum

  // base32 decode using our alphabet.
  final symbols = <int>[];
  for (final ch in body.runes) {
    final idx = _alphabet.indexOf(String.fromCharCode(ch));
    if (idx < 0) return null;
    symbols.add(idx);
  }

  // Verify checksum.
  final polymodInput = <int>[..._expandHrp(prefix), ...symbols];
  if (_polymod(polymodInput) != 1) return null;

  // Strip the 8-symbol checksum.
  final payload5 = symbols.sublist(0, symbols.length - 8);
  final payload8 = _convert5to8(payload5);
  if (payload8 == null || payload8.isEmpty) return null;
  final versionByte = payload8[0];
  final typeBits = (versionByte >> 3) & 0x1f;
  if (typeBits != 0 && typeBits != 1) return null;
  final type = typeBits == 0 ? CashAddrType.p2pkh : CashAddrType.p2sh;
  return (
    type: type,
    hash: Uint8List.fromList(payload8.sublist(1)),
  );
}

// ----------------------------------------------------------------------------
// Polymod / 8-bit ⇄ 5-bit conversion. Same shape as bech32's but with
// the CashAddr-specific generator polynomial constants.
// ----------------------------------------------------------------------------

/// BCH polymod over the BCH-specific GF(2^40) generator polynomial.
/// Returns the 40-bit checksum value pre-XOR-with-1.
int _polymod(List<int> values) {
  // We work in 64-bit ints. Generator constants from the cashaddr spec.
  const gen = [
    0x98f2bc8e61,
    0x79b76d99e2,
    0xf33e5fb3c4,
    0xae2eabe2a8,
    0x1e4f43e470,
  ];
  var c = 1;
  for (final d in values) {
    final c0 = (c >> 35) & 0xff;
    c = ((c & 0x07ffffffff) << 5) ^ d;
    for (var i = 0; i < 5; i++) {
      if (((c0 >> i) & 1) == 1) {
        c ^= gen[i];
      }
    }
  }
  return c;
}

/// Expand the human-readable prefix into the polymod input format:
/// each character's low 5 bits, followed by a zero separator.
List<int> _expandHrp(String hrp) {
  final out = <int>[];
  for (var i = 0; i < hrp.length; i++) {
    out.add(hrp.codeUnitAt(i) & 0x1f);
  }
  out.add(0);
  return out;
}

/// Repack 8-bit bytes into 5-bit symbols (big-endian within each
/// symbol). Pads the trailing partial symbol with zero bits.
List<int> _convert8to5(Uint8List data) {
  const fromBits = 8;
  const toBits = 5;
  const maxV = (1 << toBits) - 1;
  var acc = 0;
  var bits = 0;
  final ret = <int>[];
  for (final v in data) {
    acc = (acc << fromBits) | v;
    bits += fromBits;
    while (bits >= toBits) {
      bits -= toBits;
      ret.add((acc >> bits) & maxV);
    }
  }
  if (bits > 0) {
    ret.add((acc << (toBits - bits)) & maxV);
  }
  return ret;
}

/// Inverse: 5-bit symbols → 8-bit bytes. Returns null on invalid
/// padding (residual bits not zero).
List<int>? _convert5to8(List<int> data) {
  const fromBits = 5;
  const toBits = 8;
  const maxV = (1 << toBits) - 1;
  var acc = 0;
  var bits = 0;
  final ret = <int>[];
  for (final v in data) {
    if (v < 0 || (v >> fromBits) != 0) return null;
    acc = (acc << fromBits) | v;
    bits += fromBits;
    while (bits >= toBits) {
      bits -= toBits;
      ret.add((acc >> bits) & maxV);
    }
  }
  if (bits >= fromBits || ((acc << (toBits - bits)) & maxV) != 0) {
    return null;
  }
  return ret;
}
