// Pure-Dart Bitcoin BIP84 (Native SegWit) derivation.
//
// Path: m/84'/0'/0'/0/{index}
//   84'  = BIP84 (bech32 native SegWit, P2WPKH)
//   0'   = Bitcoin mainnet
//   0'   = account 0
//   0/   = external (receive) chain
//   /N   = address index, 0-based, incremented per fresh receive address
//
// Produces bech32 addresses starting with `bc1q` — universally
// understood by every modern Bitcoin wallet (Sparrow, Electrum,
// BlueWallet, Bitcoin Core post-0.16, every hardware wallet on
// firmware from 2018+).
//
// We use the public BIP32 library for the elliptic-curve math and
// the bech32 library for SegWit address encoding. Adding our own
// secp256k1 implementation would duplicate well-trodden code.

import 'dart:typed_data';

import 'package:bech32/bech32.dart';
import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:crypto/crypto.dart';
import 'package:pointycastle/digests/ripemd160.dart';

/// Bitcoin mainnet bech32 HRP. Other networks (testnet `tb`, signet
/// `tb`, regtest `bcrt`) would slot in here when we add network-
/// picker support.
const String _hrpMainnet = 'bc';

/// BIP84 derivation result for a single (account, index). Addresses
/// are bech32; the [publicKey] is the compressed 33-byte secp256k1
/// point we hash into the address. The [path] string is what wallet
/// importers (Sparrow, Electrum) expect to see when verifying
/// "the same BIP39 seed produces the same address" — useful for
/// debug + the address-self-test screen.
class BitcoinAddressDerivation {
  const BitcoinAddressDerivation({
    required this.address,
    required this.path,
    required this.publicKey,
  });
  final String address;
  final String path;
  final Uint8List publicKey;
}

/// Derive the BIP84 P2WPKH address at (account, addressIndex).
/// Pass account=0 + index=0..N for normal receive addresses; later
/// indices are used to rotate addresses for privacy.
BitcoinAddressDerivation deriveBitcoinAddress({
  required String mnemonic,
  String passphrase = '',
  int account = 0,
  int addressIndex = 0,
  bool change = false,
}) {
  final seed = bip39.mnemonicToSeed(mnemonic, passphrase: passphrase);
  final root = bip32.BIP32.fromSeed(Uint8List.fromList(seed));
  final chain = change ? 1 : 0;
  final path = "m/84'/0'/$account'/$chain/$addressIndex";
  final child = root.derivePath(path);
  final pubKey = Uint8List.fromList(child.publicKey);
  // P2WPKH: hash160 of the compressed pubkey, then bech32-encode
  // with witness version 0.
  final h160 = _hash160(pubKey);
  final program = Uint8List.fromList(h160);
  final addr = segwit.encode(Segwit(_hrpMainnet, 0, program));
  return BitcoinAddressDerivation(
    address: addr,
    path: path,
    publicKey: pubKey,
  );
}

/// SHA-256 then RIPEMD-160 — the standard "hash160" used everywhere
/// Bitcoin needs to derive an address from a pubkey.
Uint8List _hash160(Uint8List input) {
  final sha = sha256.convert(input).bytes;
  final rip = RIPEMD160Digest();
  rip.update(Uint8List.fromList(sha), 0, sha.length);
  final out = Uint8List(20);
  rip.doFinal(out, 0);
  return out;
}
