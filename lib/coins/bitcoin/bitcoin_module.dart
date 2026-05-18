// Bitcoin implementation of CoinModule. Supports:
//   - bip39_12 / bip39_24 create + restore (no Bitcoin-native seed
//     format — BIP39 is the universal Bitcoin standard since Trezor
//     popularized it in 2014).
//
// Seed material map shape: {mnemonic, passphrase}, identical to the
// MoneroModule BIP39 path.
//
// Wallet opening: BitcoinWallet derives a gap-limit window of
// addresses + talks to mempool.space for balance / history. No
// long-running native sync thread to manage (vs Monero); the
// "live" wallet is just an HTTP client + a static address list.
//
// Send is NOT yet implemented — see lib/coins/bitcoin/bitcoin_wallet.dart.

import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter/material.dart';

import '../../wallets/seed_format.dart';
import '../coin_module.dart';
import 'bitcoin_keys.dart';
import 'bitcoin_wallet.dart';

class BitcoinModule implements CoinModule {
  const BitcoinModule();

  @override
  String get id => 'BTC';
  @override
  String get name => 'Bitcoin';
  @override
  String get symbol => 'BTC';
  @override
  Color get color => const Color(0xFFF7931A);
  @override
  IconData get icon => Icons.currency_bitcoin;

  @override
  List<SeedFormat> get supportedCreateFormats => const [
        SeedFormat.bip39_12,
        SeedFormat.bip39_24,
      ];

  @override
  List<SeedFormat> get supportedRestoreFormats => const [
        SeedFormat.bip39_12,
        SeedFormat.bip39_24,
      ];

  @override
  Future<NewWalletMaterial> generateNew({
    required String walletId,
    required SeedFormat format,
    required String walletFilePassword,
    String passphrase = '',
  }) async {
    int strength;
    switch (format) {
      case SeedFormat.bip39_12:
        strength = 128;
        break;
      case SeedFormat.bip39_24:
        strength = 256;
        break;
      default:
        throw CoinModuleError(
            'Bitcoin doesn\'t support ${format.displayName} for create');
    }
    final mnemonic = bip39.generateMnemonic(strength: strength);
    final addr = deriveBitcoinAddress(mnemonic: mnemonic, passphrase: passphrase);
    return NewWalletMaterial(
      seedMaterial: {
        'mnemonic': mnemonic,
        'passphrase': passphrase,
      },
      revealableSeed: mnemonic,
      primaryAddress: addr.address,
    );
  }

  @override
  Future<RestoredWalletMaterial> restoreFrom({
    required String walletId,
    required SeedFormat format,
    required Map<String, String> input,
    required String walletFilePassword,
    int? restoreHeight,
  }) async {
    if (format != SeedFormat.bip39_12 && format != SeedFormat.bip39_24) {
      throw CoinModuleError(
          'Bitcoin doesn\'t support ${format.displayName} for restore');
    }
    final mnemonic = (input['mnemonic'] ?? '').trim().toLowerCase();
    final passphrase = input['passphrase'] ?? '';
    final words = mnemonic
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final expectedLen = format == SeedFormat.bip39_12 ? 12 : 24;
    if (words.length != expectedLen) {
      throw CoinModuleError(
          'Expected $expectedLen words; got ${words.length}.');
    }
    final normalised = words.join(' ');
    if (!bip39.validateMnemonic(normalised)) {
      throw const CoinModuleError(
          'Invalid recovery phrase (BIP39 checksum failed).');
    }
    final addr =
        deriveBitcoinAddress(mnemonic: normalised, passphrase: passphrase);
    return RestoredWalletMaterial(
      seedMaterial: {
        'mnemonic': normalised,
        'passphrase': passphrase,
      },
      primaryAddress: addr.address,
    );
  }

  @override
  Future<dynamic> open({
    required String walletId,
    required SeedFormat format,
    required Map<String, dynamic> seedMaterial,
    required String walletFilePassword,
    required String daemonUri,
    required int restoreHeight,
    void Function(String stage)? onStage,
  }) async {
    onStage?.call('deriving BIP84 addresses');
    final w = BitcoinWallet.open(
      mnemonic: seedMaterial['mnemonic'] as String,
      passphrase: (seedMaterial['passphrase'] as String?) ?? '',
    );
    onStage?.call('ready');
    return w;
  }
}
