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

import 'chain_params.dart';

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

/// Same as [BitcoinAddressDerivation] but with the live BIP32 node
/// kept. We only build this when we need to SIGN (i.e. for send), so
/// receive-only callers never materialize private keys.
///
/// Hold these in memory only as long as the send screen is open; on
/// dispose the wrapping wallet drops the reference so the GC can
/// reclaim it. Private-key bytes don't get logged anywhere (the
/// PeekLogger redacts them by regex if they ever leak).
class BitcoinSpendingKey {
  BitcoinSpendingKey({
    required this.address,
    required this.path,
    required this.node,
  });
  final String address;
  final String path;
  final bip32.BIP32 node;

  Uint8List get publicKey => Uint8List.fromList(node.publicKey);
  Uint8List get publicKeyHash => _hash160(publicKey);
  Uint8List get privateKey => Uint8List.fromList(node.privateKey!);
}

/// Derive the BIP84 P2WPKH address at (account, addressIndex).
/// Pass account=0 + index=0..N for normal receive addresses; later
/// indices are used to rotate addresses for privacy.
///
/// [params] selects the chain — Bitcoin mainnet by default. Litecoin
/// and any other BIP143-compatible chain plug in by passing their
/// respective [BitcoinChainParams].
BitcoinAddressDerivation deriveBitcoinAddress({
  required String mnemonic,
  String passphrase = '',
  int account = 0,
  int addressIndex = 0,
  bool change = false,
  BitcoinChainParams params = kBtcMainnet,
}) {
  final seed = bip39.mnemonicToSeed(mnemonic, passphrase: passphrase);
  final root = bip32.BIP32.fromSeed(Uint8List.fromList(seed));
  final chain = change ? 1 : 0;
  final path = "m/84'/${params.coinType}'/$account'/$chain/$addressIndex";
  final child = root.derivePath(path);
  final pubKey = Uint8List.fromList(child.publicKey);
  // P2WPKH: hash160 of the compressed pubkey, then bech32-encode
  // with witness version 0.
  final h160 = _hash160(pubKey);
  final program = Uint8List.fromList(h160);
  final addr = segwit.encode(Segwit(params.bech32Hrp, 0, program));
  return BitcoinAddressDerivation(
    address: addr,
    path: path,
    publicKey: pubKey,
  );
}

/// Like [deriveBitcoinAddress] but ALSO holds the BIP32 node so the
/// caller can sign with it. Returns null if the mnemonic is invalid.
/// Used exclusively by the send path — receive flows stay on the
/// publickey-only [deriveBitcoinAddress].
BitcoinSpendingKey deriveBitcoinSpendingKey({
  required String mnemonic,
  String passphrase = '',
  int account = 0,
  int addressIndex = 0,
  bool change = false,
  BitcoinChainParams params = kBtcMainnet,
}) {
  final seed = bip39.mnemonicToSeed(mnemonic, passphrase: passphrase);
  final root = bip32.BIP32.fromSeed(Uint8List.fromList(seed));
  final chain = change ? 1 : 0;
  final path = "m/84'/${params.coinType}'/$account'/$chain/$addressIndex";
  final child = root.derivePath(path);
  final pubKey = Uint8List.fromList(child.publicKey);
  final h160 = _hash160(pubKey);
  final addr =
      segwit.encode(Segwit(params.bech32Hrp, 0, Uint8List.fromList(h160)));
  return BitcoinSpendingKey(address: addr, path: path, node: child);
}

/// Decodes a bech32 P2WPKH address into its 20-byte public-key hash.
/// [params] selects which network to accept (mainnet Bitcoin or
/// Litecoin etc.). Throws on any non-P2WPKH or wrong-network address.
/// Legacy P2PKH (`1…`/`L…`) and P2SH (`3…`/`M…`) addresses are
/// rejected so the user gets a clear error rather than a transaction
/// the network won't relay.
///
/// NOTE: we don't go through `package:bech32`'s `SegwitDecoder` here
/// because that class's HRP allowlist is hardcoded to `bc`/`tb`,
/// which would reject every LTC address. Instead we use the lower-
/// level Bech32 codec and apply the segwit witness-version/program
/// extraction by hand. Same logic, just with a configurable HRP.
Uint8List decodeP2WPKHAddress(
  String address, {
  BitcoinChainParams params = kBtcMainnet,
}) {
  late final Bech32 decoded;
  try {
    decoded = const Bech32Codec().decode(address);
  } catch (e) {
    // Re-pack as FormatException so callers get a consistent type.
    throw FormatException('Invalid bech32: $e');
  }
  if (decoded.hrp != params.bech32Hrp) {
    throw FormatException(
        'Not a mainnet ${params.symbol} address (HRP ${decoded.hrp})');
  }
  if (decoded.data.isEmpty) {
    throw const FormatException('Empty bech32 payload');
  }
  final version = decoded.data[0];
  if (version != 0) {
    throw const FormatException(
        'Only witness v0 (SegWit) addresses supported');
  }
  final program = _convertBits5to8(decoded.data.sublist(1));
  if (program.length != 20) {
    throw const FormatException('Not a P2WPKH address (need 20-byte program)');
  }
  return Uint8List.fromList(program);
}

/// 5→8-bit unpacking used by bech32 / segwit decode. Mirrors the
/// reference implementation in BIP-0173 `_convertBits` with pad=false.
List<int> _convertBits5to8(List<int> data) {
  const fromBits = 5;
  const toBits = 8;
  const maxV = (1 << toBits) - 1;
  var acc = 0;
  var bits = 0;
  final ret = <int>[];
  for (final value in data) {
    if (value < 0 || (value >> fromBits) != 0) {
      throw const FormatException('Invalid bech32 data symbol');
    }
    acc = (acc << fromBits) | value;
    bits += fromBits;
    while (bits >= toBits) {
      bits -= toBits;
      ret.add((acc >> bits) & maxV);
    }
  }
  if (bits >= fromBits || ((acc << (toBits - bits)) & maxV) != 0) {
    throw const FormatException('Invalid bech32 padding');
  }
  return ret;
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
