// Tron transaction signing.
//
// Tron's wire format is protobuf-encoded with a recent block
// reference, which is non-trivial to assemble from scratch. The
// usable compromise: have TronGrid build the unsigned tx for us
// (it knows the latest block hash, computes the right expiration,
// formats the protobuf), then we sign the resulting raw_data_hex
// locally with secp256k1 + sha256 and submit the signed payload
// back to /wallet/broadcasttransaction.
//
// Security note: the hosted-build model trusts TronGrid to return
// a tx that actually transfers what the user asked. A malicious
// node could swap the destination or amount before signing — the
// user wouldn't notice unless they re-decode the raw_data_hex.
// For the receive-and-spend retail flows this is the same trust
// model as most Tron mobile wallets (TronLink included). A future
// enhancement could re-parse the raw_data_hex client-side and
// abort if (to, amount) differ from what we asked.

import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/curves/secp256k1.dart';
import 'package:pointycastle/ecc/ecc_fp.dart' as fp;
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/signers/ecdsa_signer.dart';

/// Sign a Tron transaction's raw_data_hex and return the 65-byte
/// (r||s||v) compact signature as hex. The v byte is 0 or 1 — same
/// convention as EIP-1559's yParity.
///
/// Tron computes the tx hash as sha256(raw_data_hex_bytes) and signs
/// that with the wallet's secp256k1 key.
///
/// [expectedPublicKey] is the compressed (33-byte) public key
/// matching the private key. We use it to disambiguate the recovery
/// id — same trick as the EIP-1559 signer.
String signTronTransaction({
  required String rawDataHex,
  required Uint8List privateKey,
  required Uint8List expectedPublicKey,
}) {
  final txBytes = _hexToBytes(rawDataHex);
  // Tron's txid is sha256d-less: just sha256(raw_data).
  final hash = Uint8List.fromList(sha256.convert(txBytes).bytes);

  final (r, s, v) = _signWithRecoveryId(
    msgHash: hash,
    privateKey: privateKey,
    expectedPublicKey: expectedPublicKey,
  );

  // 65-byte compact: r (32) || s (32) || v (1).
  final out = Uint8List(65);
  final rBytes = _bigIntTo32(r);
  final sBytes = _bigIntTo32(s);
  out.setRange(0, 32, rBytes);
  out.setRange(32, 64, sBytes);
  out[64] = v;
  return _toHex(out);
}

/// Same secp256k1 + RFC-6979 + low-s + manual ec-recover path as
/// the EIP-1559 signer. Duplicated here because the eth tx builder
/// keeps it private; a future cleanup could pull this into a shared
/// crypto module used by both Tron and Ethereum.
(BigInt, BigInt, int) _signWithRecoveryId({
  required Uint8List msgHash,
  required Uint8List privateKey,
  required Uint8List expectedPublicKey,
}) {
  final curve = ECCurve_secp256k1();
  final privBigInt = BigInt.parse(_toHex(privateKey), radix: 16);
  final params = PrivateKeyParameter<ECPrivateKey>(
      ECPrivateKey(privBigInt, curve));

  final signer = ECDSASigner(null, HMac(SHA256Digest(), 64));
  signer.init(true, params);
  final sig = signer.generateSignature(msgHash) as ECSignature;

  final n = curve.n;
  var r = sig.r;
  var s = sig.s;
  if (s.compareTo(n >> 1) > 0) {
    s = n - s;
  }

  final expectedPoint = curve.curve.decodePoint(expectedPublicKey)!;
  for (final v in [0, 1]) {
    final recovered = _ecRecover(r, s, msgHash, v, curve);
    if (recovered != null && recovered == expectedPoint) {
      return (r, s, v);
    }
  }
  throw StateError(
      'Failed to determine ECDSA recovery_id for Tron sig (signing produced no match)');
}

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
  final fieldP = (curve.curve as fp.ECCurve).q!;
  final R = _liftX(r, v, curve, fieldP);
  if (R == null) return null;

  final e = _bytesToBigInt(msgHash);
  final rInv = r.modInverse(n);
  final sR = R * s;
  final eG = curve.G * e;
  final eGNeg = -eG!;
  final sum = sR! + eGNeg;
  final Q = sum! * rInv;
  return Q;
}

ECPoint? _liftX(
  BigInt x,
  int yParity,
  ECDomainParameters curve,
  BigInt p,
) {
  if (x >= p) return null;
  final alpha = (x.modPow(BigInt.from(3), p) + BigInt.from(7)) % p;
  final beta = alpha.modPow((p + BigInt.one) >> 2, p);
  if (beta.modPow(BigInt.two, p) != alpha) return null;
  final y = (beta.isEven == (yParity == 0)) ? beta : (p - beta);
  final encoded = Uint8List.fromList([0x04, ..._bigIntTo32(x), ..._bigIntTo32(y)]);
  return curve.curve.decodePoint(encoded);
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

Uint8List _hexToBytes(String hex) {
  var clean = hex.startsWith('0x') || hex.startsWith('0X')
      ? hex.substring(2)
      : hex;
  if (clean.length.isOdd) clean = '0$clean';
  final out = Uint8List(clean.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(clean.substring(2 * i, 2 * i + 2), radix: 16);
  }
  return out;
}

String _toHex(Uint8List bytes) {
  final sb = StringBuffer();
  for (final b in bytes) {
    sb.write(b.toRadixString(16).padLeft(2, '0'));
  }
  return sb.toString();
}
