// Bitcoin Cash address derivation.
//
// Path: m/44'/145'/0'/0/{addressIndex}
//   44'  = BIP44
//   145' = Bitcoin Cash (SLIP-0044 coin type)
//   0'   = account 0
//   0/   = external chain
//   /N   = address index
//
// BCH doesn't use SegWit (rejected the upgrade). Addresses are
// "legacy" P2PKH-style: hash160(compressed_pubkey) wrapped in
// CashAddr encoding (the BCH-specific bech32-like format we
// implemented separately).

import 'dart:typed_data';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:crypto/crypto.dart';
import 'package:pointycastle/digests/ripemd160.dart';

import 'cashaddr.dart';

class BitcoinCashAddressDerivation {
  const BitcoinCashAddressDerivation({
    required this.address,
    required this.path,
    required this.publicKey,
    required this.hash160,
  });
  /// CashAddr form, e.g. bitcoincash:qpm2qsznhks23z7629mms6s4cwef74vcwvy22gdx6a.
  final String address;
  final String path;
  final Uint8List publicKey;
  /// Raw 20-byte hash — useful when querying explorers that accept
  /// either form (some do, some don't).
  final Uint8List hash160;
}

BitcoinCashAddressDerivation deriveBitcoinCashAddress({
  required String mnemonic,
  String passphrase = '',
  int account = 0,
  int addressIndex = 0,
}) {
  final seed = bip39.mnemonicToSeed(mnemonic, passphrase: passphrase);
  final root = bip32.BIP32.fromSeed(Uint8List.fromList(seed));
  final path = "m/44'/145'/$account'/0/$addressIndex";
  final child = root.derivePath(path);
  final pubKey = Uint8List.fromList(child.publicKey);
  final h160 = _hash160(pubKey);
  return BitcoinCashAddressDerivation(
    address: cashaddrEncode(hash160: h160),
    path: path,
    publicKey: pubKey,
    hash160: h160,
  );
}

Uint8List _hash160(Uint8List input) {
  final sha = sha256.convert(input).bytes;
  final rip = RIPEMD160Digest();
  rip.update(Uint8List.fromList(sha), 0, sha.length);
  final out = Uint8List(20);
  rip.doFinal(out, 0);
  return out;
}
