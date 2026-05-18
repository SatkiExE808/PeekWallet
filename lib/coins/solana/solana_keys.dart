// Pure-Dart Solana address derivation.
//
// Path: m/44'/501'/0'/0' — the "Phantom" standard. All major Solana
// wallets (Phantom, Solflare, Backpack, Trust) derive the first
// account from this path. Some wallets also expose m/44'/501'/0'
// (the "shorter" form) — Phantom's mobile app, for example, used
// this for legacy accounts. We default to the 4-component form but
// expose the option for restoring older wallets.
//
// Derivation: SLIP-0010 over ed25519. Different from secp256k1's
// BIP32 because the curve can't tolerate the same scalar-tweak
// algebra — instead, every step is HARDENED-only, and each child
// key is independent of the parent's public key.
//
// Address format: base58 of the 32-byte ed25519 public key, no
// version prefix, no checksum. Solana addresses are ~32–44 chars
// because base58 is roughly log(256)/log(58) ≈ 1.37× the byte length.

import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:crypto/crypto.dart' as dart_crypto;
import 'package:cryptography/cryptography.dart';

/// Result of deriving a single Solana address.
class SolanaAddressDerivation {
  const SolanaAddressDerivation({
    required this.address,
    required this.path,
    required this.publicKey,
    required this.privateSeed,
  });
  /// Base58-encoded 32-byte public key. What block explorers and
  /// other wallets show.
  final String address;
  /// Derivation path string, e.g. "m/44'/501'/0'/0'".
  final String path;
  /// Raw 32-byte ed25519 public key.
  final Uint8List publicKey;
  /// 32-byte ed25519 private seed. Holding this in memory enables
  /// signing without re-deriving from the mnemonic; the wallet keeps
  /// it only as long as the runtime handle is alive.
  final Uint8List privateSeed;
}

/// Derive a Solana address from a BIP39 mnemonic. Default path is
/// m/44'/501'/account'/0' (the Phantom standard).
Future<SolanaAddressDerivation> deriveSolanaAddress({
  required String mnemonic,
  String passphrase = '',
  int account = 0,
  bool legacyShortPath = false,
}) async {
  final seed = bip39.mnemonicToSeed(mnemonic, passphrase: passphrase);
  final path = legacyShortPath
      ? "m/44'/501'/$account'"
      : "m/44'/501'/$account'/0'";
  final privateSeed = _slip0010Derive(Uint8List.fromList(seed), path);

  final alg = Ed25519();
  final keyPair = await alg.newKeyPairFromSeed(privateSeed);
  final pub = await keyPair.extractPublicKey();
  final pubBytes = Uint8List.fromList(pub.bytes);

  return SolanaAddressDerivation(
    address: base58Encode(pubBytes),
    path: path,
    publicKey: pubBytes,
    privateSeed: privateSeed,
  );
}

/// SLIP-0010 ed25519 derivation. Returns the 32-byte private key
/// (a.k.a. "seed" in Ed25519 terminology) at the given path. Only
/// hardened derivation is allowed for ed25519 — any non-hardened
/// step throws.
///
/// Visible to tests (via the @visibleForTesting wrapper below) so we
/// can pin behavior against the SLIP-0010 spec vectors. Production
/// callers should go through [deriveSolanaAddress].
Uint8List slip0010DeriveForTesting(Uint8List seed, String path) =>
    _slip0010Derive(seed, path);

Uint8List _slip0010Derive(Uint8List seed, String path) {
  // Master node: HMAC-SHA512(key="ed25519 seed", msg=seed)
  var I = _hmacSha512(
      key: Uint8List.fromList('ed25519 seed'.codeUnits), data: seed);
  var key = I.sublist(0, 32);
  var chainCode = I.sublist(32, 64);

  // Drop the leading "m" component if present, then iterate.
  final parts = path.replaceFirst(RegExp(r'^m/?'), '').split('/');
  for (final p in parts.where((s) => s.isNotEmpty)) {
    if (!p.endsWith("'")) {
      throw FormatException(
          'SLIP-0010 ed25519 requires hardened derivation; '
          'non-hardened "$p" in path "$path"');
    }
    final index = int.parse(p.substring(0, p.length - 1)) | 0x80000000;
    // data = 0x00 || parent_key || ser32(index)
    final data = Uint8List(1 + 32 + 4);
    data[0] = 0;
    data.setRange(1, 33, key);
    data[33] = (index >> 24) & 0xff;
    data[34] = (index >> 16) & 0xff;
    data[35] = (index >> 8) & 0xff;
    data[36] = index & 0xff;
    I = _hmacSha512(key: chainCode, data: data);
    key = I.sublist(0, 32);
    chainCode = I.sublist(32, 64);
  }
  return key;
}

Uint8List _hmacSha512({required Uint8List key, required Uint8List data}) {
  final mac = dart_crypto.Hmac(dart_crypto.sha512, key);
  return Uint8List.fromList(mac.convert(data).bytes);
}

// ----------------------------------------------------------------------------
// Base58 encode/decode (Bitcoin alphabet, also used by Solana).
//
// We don't depend on a package for this — it's ~30 lines of arithmetic
// and avoids pulling in another transitive tree. We've already got
// our own base58 in the Monero implementation but that's a DIFFERENT
// variant (monero base58 encodes 8-byte blocks separately). For
// Solana, regular Bitcoin-alphabet base58 over the whole 32-byte
// pubkey is the right thing.
// ----------------------------------------------------------------------------

const String _b58Alphabet =
    '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

/// Base58-encode a byte array. Returns the canonical Solana form.
String base58Encode(Uint8List bytes) {
  if (bytes.isEmpty) return '';

  // Count leading zero bytes — those become leading '1' chars.
  var leadingZeros = 0;
  for (var i = 0; i < bytes.length && bytes[i] == 0; i++) {
    leadingZeros++;
  }

  // Convert the big-endian bytes to a BigInt, then to base58 digits.
  var n = BigInt.zero;
  for (final b in bytes) {
    n = n * BigInt.from(256) + BigInt.from(b);
  }
  final sb = StringBuffer();
  final big58 = BigInt.from(58);
  while (n > BigInt.zero) {
    final rem = n % big58;
    n = n ~/ big58;
    sb.write(_b58Alphabet[rem.toInt()]);
  }
  // Add the leading-zero '1's.
  for (var i = 0; i < leadingZeros; i++) {
    sb.write('1');
  }
  // sb is reversed (we appended LSB-first); flip it.
  return sb.toString().split('').reversed.join();
}

/// Base58-decode a Solana-style string back to bytes. Returns null if
/// the input contains any non-alphabet character.
Uint8List? base58Decode(String s) {
  if (s.isEmpty) return Uint8List(0);
  var n = BigInt.zero;
  final big58 = BigInt.from(58);
  for (final ch in s.runes) {
    final idx = _b58Alphabet.indexOf(String.fromCharCode(ch));
    if (idx < 0) return null;
    n = n * big58 + BigInt.from(idx);
  }
  // Convert BigInt back to bytes.
  final tmp = <int>[];
  while (n > BigInt.zero) {
    tmp.add((n % BigInt.from(256)).toInt());
    n = n ~/ BigInt.from(256);
  }
  // Leading '1's in input → leading 0x00 bytes in output.
  var leadingOnes = 0;
  for (var i = 0; i < s.length && s[i] == '1'; i++) {
    leadingOnes++;
  }
  final out = Uint8List(leadingOnes + tmp.length);
  for (var i = 0; i < tmp.length; i++) {
    out[leadingOnes + i] = tmp[tmp.length - 1 - i];
  }
  return out;
}
