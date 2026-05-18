// Pure-Dart Ethereum address derivation.
//
// Path: m/44'/60'/0'/0/{addressIndex}
//   44'  = BIP44
//   60'  = Ethereum (SLIP-0044 coin type)
//   0'   = account 0
//   0/   = external/internal flag (Ethereum doesn't use change like
//          UTXO chains, so we always use 0)
//   /N   = address index
//
// Address is the lowercase hex of the LAST 20 bytes of
//   Keccak-256(uncompressedPubKey[1:])
// — where uncompressedPubKey is the 65-byte 0x04|X|Y form. EIP-55
// re-cases the hex to produce a checksummed form so typos in the
// middle of an address can be caught visually.

import 'dart:typed_data';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:pointycastle/digests/keccak.dart';
import 'package:pointycastle/ecc/curves/secp256k1.dart';

/// Result of deriving a single Ethereum address. [address] is the
/// EIP-55 checksummed form (mixed case); [addressLower] is the
/// lowercase form used internally for RPC calls. [path] is what
/// hardware wallet importers / Sparrow / etc. expect for verification.
class EthereumAddressDerivation {
  const EthereumAddressDerivation({
    required this.address,
    required this.addressLower,
    required this.path,
    required this.publicKey,
  });
  /// EIP-55 mixed-case display form. UI uses this.
  final String address;
  /// All-lowercase form. RPC calls use this; some endpoints reject
  /// the mixed-case form even though it's the same address.
  final String addressLower;
  final String path;
  /// Compressed (33-byte) secp256k1 public key. Stored mostly for
  /// debug — the address itself is the only thing we put on-chain.
  final Uint8List publicKey;
}

/// Derive the Ethereum address at the given BIP44 [addressIndex].
/// Defaults match what every Ethereum wallet (MetaMask, Trezor, Ledger
/// Live, Rabby) produces, so the same BIP39 seed yields the same
/// addresses across apps.
EthereumAddressDerivation deriveEthereumAddress({
  required String mnemonic,
  String passphrase = '',
  int account = 0,
  int addressIndex = 0,
}) {
  final seed = bip39.mnemonicToSeed(mnemonic, passphrase: passphrase);
  final root = bip32.BIP32.fromSeed(Uint8List.fromList(seed));
  final path = "m/44'/60'/$account'/0/$addressIndex";
  final child = root.derivePath(path);

  // bip32 gives us the compressed pubkey (33 bytes, 0x02/0x03 prefix).
  // For Ethereum we need the uncompressed form (65 bytes, 0x04|X|Y).
  // Decompress by reconstructing the curve point from the X coordinate.
  final compressed = Uint8List.fromList(child.publicKey);
  final uncompressed = _decompressSecp256k1(compressed);

  // Drop the 0x04 prefix, keccak-256 over X||Y, take last 20 bytes.
  final hash = _keccak256(uncompressed.sublist(1));
  final addrBytes = hash.sublist(hash.length - 20);
  final lower = '0x${_toHex(addrBytes)}';
  return EthereumAddressDerivation(
    address: _eip55(lower),
    addressLower: lower,
    path: path,
    publicKey: compressed,
  );
}

/// EIP-55 checksum encoding: uppercase the hex digit if the
/// corresponding nibble of keccak-256(lowercase_addr_without_0x) is
/// >= 8. Catches typos in the middle of an address.
String _eip55(String lowercaseWith0x) {
  if (!lowercaseWith0x.startsWith('0x')) {
    throw ArgumentError('Expected 0x-prefixed lowercase hex');
  }
  final hex = lowercaseWith0x.substring(2);
  final hashHex = _toHex(_keccak256(Uint8List.fromList(hex.codeUnits)));
  final sb = StringBuffer('0x');
  for (var i = 0; i < hex.length; i++) {
    final c = hex[i];
    if (RegExp(r'[0-9]').hasMatch(c)) {
      sb.write(c);
    } else {
      // Compare against the hex digit of the hash at the same nibble
      // position. >= 8 means uppercase, < 8 means lowercase.
      final hashNibble = int.parse(hashHex[i], radix: 16);
      sb.write(hashNibble >= 8 ? c.toUpperCase() : c);
    }
  }
  return sb.toString();
}

/// Reconstruct the uncompressed secp256k1 point (65 bytes, 0x04|X|Y)
/// from the compressed form (33 bytes, 0x02|X or 0x03|X).
///
/// Compressed form prefix byte tells us the parity of Y:
///   0x02 → Y is even
///   0x03 → Y is odd
/// We compute Y from Y^2 = X^3 + 7 (mod p), pick the right parity.
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
  // 32 bytes each, big-endian, left-padded with zeros.
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
  // Keccak-256 (NIST SHA-3 predecessor) — NOT the same as SHA3-256.
  // Ethereum uses the original Keccak with the pre-standardization
  // padding rule, which is what pointycastle's KeccakDigest(256)
  // gives us.
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
