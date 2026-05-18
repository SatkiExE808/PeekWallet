// Solana Program-Derived-Address (PDA) helpers.
//
// A PDA is a 32-byte address that is NOT a valid ed25519 public key
// — meaning no one holds the private key for it, so only the
// owning program can authorise actions on accounts at that address.
// Solana derives them deterministically from (seeds, program_id)
// via find_program_address:
//
//   for nonce in 255..0:
//     candidate = sha256(seeds || nonce || program_id || "ProgramDerivedAddress")
//     if candidate is NOT a valid ed25519 point:
//       return (candidate, nonce)
//
// In practice the first nonce or two succeeds for any given seeds
// (random 32-byte values are off-curve roughly 7/8 of the time on
// ed25519). The off-curve check needs real elliptic-curve math
// though: parsing y, computing x² from the curve equation, checking
// that sqrt(x²) exists mod p. We implement it from the spec.
//
// We use this for one specific thing today: deriving Associated
// Token Account (ATA) addresses so we can auto-create them when
// sending SPL tokens to a recipient who's never received that mint.

import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'solana_keys.dart' show base58Decode;

/// SPL Token Program ID (TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA).
final Uint8List splTokenProgramId =
    base58Decode('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA')!;

/// Associated Token Account program ID
/// (ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL).
final Uint8List ataProgramId =
    base58Decode('ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL')!;

/// System program ID (all zeros, "11111111111111111111111111111111").
final Uint8List systemProgramId = Uint8List(32);

/// Derive the Associated Token Account address for [owner] holding
/// [mint]. Both inputs are raw 32-byte pubkey bytes; the output is
/// the 32-byte ATA address.
Uint8List associatedTokenAddress({
  required Uint8List owner,
  required Uint8List mint,
}) {
  final result = findProgramAddress(
    seeds: [owner, splTokenProgramId, mint],
    programId: ataProgramId,
  );
  return result.address;
}

/// Solana's find_program_address. Try nonces from 255 down to 0 and
/// return the first one whose sha256 hash is NOT a valid ed25519
/// point. Throws if no off-curve hash exists (cryptographically
/// impossible in practice — included for completeness).
({Uint8List address, int bump}) findProgramAddress({
  required List<Uint8List> seeds,
  required Uint8List programId,
}) {
  for (var nonce = 255; nonce >= 0; nonce--) {
    final hash = _hashPDA(seeds, nonce, programId);
    if (!isOnCurve(hash)) {
      return (address: hash, bump: nonce);
    }
  }
  throw StateError(
      'find_program_address: no off-curve nonce found (cryptographically '
      'unreachable — something is very wrong with the inputs)');
}

Uint8List _hashPDA(
    List<Uint8List> seeds, int nonce, Uint8List programId) {
  final bytes = <int>[];
  for (final s in seeds) {
    bytes.addAll(s);
  }
  bytes.add(nonce);
  bytes.addAll(programId);
  bytes.addAll('ProgramDerivedAddress'.codeUnits);
  final digest = sha256.convert(bytes);
  return Uint8List.fromList(digest.bytes);
}

/// True iff [point32] decodes as a valid compressed ed25519 point.
/// The check is: parse y (32-byte LE, high bit cleared), compute
/// x² from the curve equation, verify that sqrt(x²) exists mod p.
///
/// Used by find_program_address: if the candidate IS on-curve, it's
/// a possible private-key holder and not a usable PDA — try the
/// next nonce.
bool isOnCurve(Uint8List point32) {
  if (point32.length != 32) return false;

  // Strip the sign bit; we only need the y-coordinate for the
  // on-curve check (the sign bit selects between two valid points
  // if any, but if there are NONE the sign bit is irrelevant).
  final yBytes = Uint8List.fromList(point32);
  yBytes[31] &= 0x7f;
  final y = _bigIntFromBytesLE(yBytes);
  if (y >= _p) return false;

  // x² = (y² - 1) / (d·y² + 1) mod p
  final ySq = (y * y) % _p;
  final u = (ySq - BigInt.one) % _p;
  final vDenom = (_d * ySq + BigInt.one) % _p;
  if (vDenom == BigInt.zero) return false;
  final xSq = (u * vDenom.modInverse(_p)) % _p;

  // Try sqrt(xSq) via x = xSq^((p+3)/8). For p ≡ 5 (mod 8), this
  // gives EITHER sqrt(xSq) OR sqrt(xSq) * sqrt(-1). Test both.
  final candidate = xSq.modPow((_p + BigInt.from(3)) >> 3, _p);
  if ((candidate * candidate) % _p == xSq) return true;
  final candidate2 = (candidate * _sqrtNeg1) % _p;
  return (candidate2 * candidate2) % _p == xSq;
}

BigInt _bigIntFromBytesLE(Uint8List bytes) {
  var result = BigInt.zero;
  for (var i = bytes.length - 1; i >= 0; i--) {
    result = (result << 8) | BigInt.from(bytes[i]);
  }
  return result;
}

// Curve constants for ed25519.
// p = 2^255 - 19
final BigInt _p = (BigInt.one << 255) - BigInt.from(19);
// d = -121665 / 121666 mod p (the ed25519 curve constant)
final BigInt _d = BigInt.parse(
    '37095705934669439343138083508754565189542113879843219016388785533085940283555');
// sqrt(-1) mod p = 2^((p-1)/4) mod p. Pre-computed.
final BigInt _sqrtNeg1 = BigInt.parse(
    '19681161376707505956807428261136712985053072145130937220197185517256604439631');
