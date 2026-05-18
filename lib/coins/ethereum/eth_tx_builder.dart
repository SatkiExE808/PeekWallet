// EIP-1559 (type 2) Ethereum transaction builder + signer.
//
// Specification references:
//   EIP-1559: Fee market change for ETH 1.0 chain
//   EIP-2718: Typed Transaction Envelope
//   EIP-2930: Optional access lists (we always emit an empty one)
//
// Signing flow:
//   1. RLP-encode the payload:
//        [chainId, nonce, maxPriorityFeePerGas, maxFeePerGas,
//         gasLimit, to, value, data, accessList]
//   2. Compute signing hash:
//        keccak256(0x02 || rlp_payload)
//   3. ECDSA-sign with secp256k1, deterministic-k. Low-s normalize.
//   4. Compute recovery_id (y_parity) by trying both 0 and 1 and
//      seeing which one recovers the wallet's public key.
//   5. RLP-encode again with the signature fields appended:
//        [..., yParity, r, s]
//   6. Final raw tx = 0x02 || rlp([..., yParity, r, s]).
//
// Tested against the EIP-1559 test vectors in
// test/eth_tx_builder_test.dart — if you change anything here those
// MUST still pass.

import 'dart:typed_data';

import 'package:pointycastle/digests/keccak.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/curves/secp256k1.dart';
import 'package:pointycastle/ecc/ecc_fp.dart' as fp;
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/signers/ecdsa_signer.dart';
import 'package:pointycastle/api.dart';

import 'rlp.dart';

class BuiltEthereumTransaction {
  const BuiltEthereumTransaction({
    required this.rawHex,
    required this.txHash,
    required this.gasLimit,
    required this.maxFeeWei,
    required this.maxPriorityFeeWei,
  });
  /// 0x-prefixed hex blob ready to pass to eth_sendRawTransaction.
  final String rawHex;
  /// keccak256(rawTx) — the txid that explorers display.
  final String txHash;
  /// Gas units committed (units, not wei).
  final BigInt gasLimit;
  /// Per-gas-unit ceiling. Total max fee paid = gasLimit * maxFeeWei.
  final BigInt maxFeeWei;
  final BigInt maxPriorityFeeWei;

  /// Worst-case fee in wei. Real fee on inclusion will be lower if
  /// base_fee < (maxFee - priority).
  BigInt get maxFeeTotalWei => gasLimit * maxFeeWei;
}

class InvalidEthereumAddressException implements Exception {
  const InvalidEthereumAddressException(this.message);
  final String message;
  @override
  String toString() => 'InvalidEthereumAddress: $message';
}

/// Build, sign, and serialize an EIP-1559 ETH transfer transaction.
///
/// - [chainId]: 1 for mainnet, 11155111 for Sepolia, etc.
/// - [nonce]: account nonce — caller fetches via eth_getTransactionCount.
/// - [maxPriorityFeePerGasWei]: tip to the proposer.
/// - [maxFeePerGasWei]: total cap; must be >= base_fee + priority.
/// - [gasLimit]: usually 21000 for a plain transfer; higher if [data]
///   contains a contract call.
/// - [toAddress]: lowercase or EIP-55-cased 0x… address.
/// - [valueWei]: amount to send. Use [data]=empty for plain transfers.
/// - [privateKey]: 32-byte secp256k1 private key.
/// - [expectedPublicKey]: 33-byte compressed public key (for recovery_id
///   verification — we sign, then check that recovering the pubkey
///   from (r, s, h, v) matches this; ensures we tagged the correct v).
BuiltEthereumTransaction buildAndSignEip1559({
  required int chainId,
  required BigInt nonce,
  required BigInt maxPriorityFeePerGasWei,
  required BigInt maxFeePerGasWei,
  required BigInt gasLimit,
  required String toAddress,
  required BigInt valueWei,
  Uint8List? data,
  required Uint8List privateKey,
  required Uint8List expectedPublicKey,
}) {
  final toBytes = _parseAddress(toAddress);
  final payloadData = data ?? Uint8List(0);

  // Step 1: RLP payload for signing (no signature yet).
  final payload = <dynamic>[
    chainId,
    nonce,
    maxPriorityFeePerGasWei,
    maxFeePerGasWei,
    gasLimit,
    toBytes,
    valueWei,
    payloadData,
    <dynamic>[], // empty access list
  ];
  final rlpPayload = rlpEncode(payload);

  // Step 2: signing hash = keccak256(0x02 || rlp(payload))
  final signingMessage = Uint8List(1 + rlpPayload.length);
  signingMessage[0] = 0x02; // EIP-2718 type byte
  signingMessage.setRange(1, signingMessage.length, rlpPayload);
  final msgHash = _keccak256(signingMessage);

  // Step 3 + 4: sign, compute recovery_id.
  final (r, s, yParity) = _signWithRecoveryId(
    msgHash: msgHash,
    privateKey: privateKey,
    expectedPublicKey: expectedPublicKey,
  );

  // Step 5: append signature fields and re-RLP.
  final signed = <dynamic>[
    ...payload,
    yParity, // yParity ∈ {0, 1}
    r,
    s,
  ];
  final rlpSigned = rlpEncode(signed);

  // Step 6: final raw = 0x02 || rlp(signed).
  final raw = Uint8List(1 + rlpSigned.length);
  raw[0] = 0x02;
  raw.setRange(1, raw.length, rlpSigned);

  // txid = keccak256 of the raw tx bytes (INCLUDING the 0x02 prefix
  // for typed transactions — different from legacy txs which hash
  // the RLP only).
  final txHash = _toHex(_keccak256(raw));

  return BuiltEthereumTransaction(
    rawHex: '0x${_toHex(raw)}',
    txHash: '0x$txHash',
    gasLimit: gasLimit,
    maxFeeWei: maxFeePerGasWei,
    maxPriorityFeeWei: maxPriorityFeePerGasWei,
  );
}

/// Sign [msgHash] with secp256k1 + low-s normalization, then probe
/// recovery_id ∈ {0, 1} to find the one that recovers
/// [expectedPublicKey]. Returns (r, s, recovery_id).
(BigInt, BigInt, int) _signWithRecoveryId({
  required Uint8List msgHash,
  required Uint8List privateKey,
  required Uint8List expectedPublicKey,
}) {
  final curve = ECCurve_secp256k1();
  final privBigInt =
      BigInt.parse(_toHex(privateKey), radix: 16);
  final params = PrivateKeyParameter<ECPrivateKey>(
      ECPrivateKey(privBigInt, curve));

  final signer = ECDSASigner(null, HMac(SHA256Digest(), 64));
  signer.init(true, params);
  final sig = signer.generateSignature(msgHash) as ECSignature;

  // Low-s normalization per BIP62 / EIP-2 — Ethereum requires it.
  final n = curve.n;
  var r = sig.r;
  var s = sig.s;
  if (s.compareTo(n >> 1) > 0) {
    s = n - s;
  }

  // The expected public key is what we'll match recovery against.
  // pointycastle gives us the compressed form (33 bytes); for
  // recovery we work with the EC point directly.
  final expectedPoint = curve.curve.decodePoint(expectedPublicKey)!;

  for (final v in [0, 1]) {
    final recovered = _ecRecover(r, s, msgHash, v, curve);
    if (recovered != null && recovered == expectedPoint) {
      return (r, s, v);
    }
  }
  throw StateError(
      'Failed to determine ECDSA recovery_id (signing produced no '
      'match against the expected public key — should be impossible)');
}

/// ECDSA public-key recovery for secp256k1.
///
/// Given (r, s, msgHash, v) we recover the public key Q such that
/// the signature verifies. Used to compute the recovery_id for
/// EIP-1559 — we try both v∈{0,1} and pick the one whose Q matches
/// the signer's actual public key.
///
/// Math (yellow paper appendix F):
///   x = r  (we skip r > N case; cryptographically negligible)
///   R = point with x-coordinate x and y-parity = v
///   Q = r^(-1) * (s*R - h*G)
ECPoint? _ecRecover(
  BigInt r,
  BigInt s,
  Uint8List msgHash,
  int v,
  ECDomainParameters curve,
) {
  final n = curve.n;
  if (r <= BigInt.zero || r >= n) return null;
  if (s <= BigInt.zero || s >= n) return null;

  final fieldP =
      (curve.curve as fp.ECCurve).q!; // secp256k1 prime field
  // Recover R from x = r and y-parity = v.
  // For y-parity 0 we want y EVEN; for parity 1 we want y ODD.
  final R = _liftX(r, v, curve, fieldP);
  if (R == null) return null;

  final e = _bytesToBigInt(msgHash);
  final rInv = r.modInverse(n);

  // Q = r^-1 * (s*R - e*G)
  final sR = R * s;
  final eG = curve.G * e;
  final eGNeg = -eG!;
  final sum = sR! + eGNeg;
  final Q = sum! * rInv;
  return Q;
}

/// Given x ∈ [0, p), find a point on secp256k1 with that x and the
/// specified y-parity (0 = even, 1 = odd). Returns null if x doesn't
/// correspond to a valid curve point (i.e., no quadratic residue).
ECPoint? _liftX(
  BigInt x,
  int yParity,
  ECDomainParameters curve,
  BigInt p,
) {
  if (x >= p) return null;
  // y² = x³ + 7 mod p
  final alpha = (x.modPow(BigInt.from(3), p) + BigInt.from(7)) % p;
  // β = sqrt(alpha) mod p. For secp256k1, p ≡ 3 mod 4 so we can use
  // β = alpha^((p+1)/4) mod p.
  final beta = alpha.modPow((p + BigInt.one) >> 2, p);
  if (beta.modPow(BigInt.two, p) != alpha) return null;
  // Pick the y with the requested parity.
  final y = (beta.isEven == (yParity == 0)) ? beta : (p - beta);
  // Encode as 0x04|x|y and decode through the curve so pointycastle
  // gives us a proper ECPoint we can do scalar ops on.
  final encoded = Uint8List.fromList([0x04, ..._bigIntTo32(x), ..._bigIntTo32(y)]);
  return curve.curve.decodePoint(encoded);
}

Uint8List _parseAddress(String s) {
  var trimmed = s.trim();
  if (trimmed.startsWith('0x') || trimmed.startsWith('0X')) {
    trimmed = trimmed.substring(2);
  }
  if (trimmed.length != 40) {
    throw InvalidEthereumAddressException(
        'Ethereum address must be 40 hex chars, got ${trimmed.length}');
  }
  if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(trimmed)) {
    throw const InvalidEthereumAddressException(
        'Address contains non-hex characters');
  }
  final out = Uint8List(20);
  for (var i = 0; i < 20; i++) {
    out[i] = int.parse(trimmed.substring(2 * i, 2 * i + 2), radix: 16);
  }
  return out;
}

Uint8List _bigIntTo32(BigInt n) {
  final hex = n.toRadixString(16).padLeft(64, '0');
  final out = Uint8List(32);
  for (var i = 0; i < 32; i++) {
    out[i] = int.parse(hex.substring(2 * i, 2 * i + 2), radix: 16);
  }
  return out;
}

BigInt _bytesToBigInt(Uint8List b) {
  if (b.isEmpty) return BigInt.zero;
  return BigInt.parse(_toHex(b), radix: 16);
}

Uint8List _keccak256(Uint8List input) {
  final d = KeccakDigest(256);
  d.update(input, 0, input.length);
  final out = Uint8List(32);
  d.doFinal(out, 0);
  return out;
}

String _toHex(Uint8List bytes) {
  final sb = StringBuffer();
  for (final b in bytes) {
    sb.write(b.toRadixString(16).padLeft(2, '0'));
  }
  return sb.toString();
}
