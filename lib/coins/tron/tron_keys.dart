// Pure-Dart Tron (TRX) address derivation.
//
// Path: m/44'/195'/0'/0/{addressIndex}
//   44'  = BIP44
//   195' = Tron (SLIP-0044 coin type)
//   0'   = account 0
//   0/   = external chain
//   /N   = address index
//
// Address format:
//   - secp256k1 pubkey, decompressed → 65 bytes (0x04 || X || Y)
//   - Keccak-256 over X||Y (the same as Ethereum's address step)
//   - Take the LAST 20 bytes of the hash (just like Ethereum)
//   - Prepend 0x41 (Tron's network version byte) → 21 bytes
//   - base58check encode → result starts with "T"
//
// "base58check" = base58(payload || sha256d(payload)[0:4]) — the
// standard Bitcoin checksum form. Tron uses it rather than EIP-55
// (which is hex-case checksumming).

import 'dart:typed_data';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:crypto/crypto.dart';
import 'package:pointycastle/digests/keccak.dart';
import 'package:pointycastle/ecc/curves/secp256k1.dart';

import '../solana/solana_keys.dart' show base58Encode;

/// Single TRX address derivation. [address] is the user-facing
/// base58check form starting with "T"; [hexAddress] is the 21-byte
/// "0x41…" form used by the TRON RPC's wallet/get* endpoints.
class TronAddressDerivation {
  const TronAddressDerivation({
    required this.address,
    required this.hexAddress,
    required this.path,
    required this.publicKey,
  });
  /// Base58check form, e.g. TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t.
  final String address;
  /// Hex form including the 0x41 prefix, lower-case, 42 chars.
  /// Some TRON HTTP endpoints accept ONLY this form, not base58.
  final String hexAddress;
  final String path;
  /// Compressed (33-byte) secp256k1 public key.
  final Uint8List publicKey;
}

TronAddressDerivation deriveTronAddress({
  required String mnemonic,
  String passphrase = '',
  int account = 0,
  int addressIndex = 0,
}) {
  final seed = bip39.mnemonicToSeed(mnemonic, passphrase: passphrase);
  final root = bip32.BIP32.fromSeed(Uint8List.fromList(seed));
  final path = "m/44'/195'/$account'/0/$addressIndex";
  final child = root.derivePath(path);

  final compressed = Uint8List.fromList(child.publicKey);
  final uncompressed = _decompressSecp256k1(compressed);

  // Drop the 0x04 prefix, keccak-256 over X||Y, take last 20 bytes.
  final hash = _keccak256(uncompressed.sublist(1));
  final addr20 = hash.sublist(hash.length - 20);

  // Prepend network version byte 0x41 (Tron mainnet).
  final addr21 = Uint8List(21);
  addr21[0] = 0x41;
  addr21.setRange(1, 21, addr20);

  return TronAddressDerivation(
    address: _base58Check(addr21),
    hexAddress: _toHex(addr21),
    path: path,
    publicKey: compressed,
  );
}

/// base58check = base58(payload || sha256d(payload)[0:4]).
String _base58Check(Uint8List payload) {
  final checksum = _sha256d(payload).sublist(0, 4);
  final combined = Uint8List(payload.length + 4);
  combined.setRange(0, payload.length, payload);
  combined.setRange(payload.length, combined.length, checksum);
  return base58Encode(combined);
}

Uint8List _sha256d(Uint8List input) {
  final a = sha256.convert(input).bytes;
  return Uint8List.fromList(sha256.convert(a).bytes);
}

Uint8List _decompressSecp256k1(Uint8List compressed) {
  if (compressed.length != 33) {
    throw ArgumentError('Compressed pubkey must be 33 bytes');
  }
  final curve = ECCurve_secp256k1();
  final point = curve.curve.decodePoint(compressed);
  if (point == null) {
    throw ArgumentError('Failed to decode secp256k1 point');
  }
  final x = point.x!.toBigInteger()!;
  final y = point.y!.toBigInteger()!;
  return Uint8List.fromList([
    0x04,
    ..._bigIntTo32(x),
    ..._bigIntTo32(y),
  ]);
}

Uint8List _bigIntTo32(BigInt n) {
  final hex = n.toRadixString(16).padLeft(64, '0');
  final out = Uint8List(32);
  for (var i = 0; i < 32; i++) {
    out[i] = int.parse(hex.substring(2 * i, 2 * i + 2), radix: 16);
  }
  return out;
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
