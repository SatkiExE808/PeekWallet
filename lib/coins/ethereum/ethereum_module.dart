// Ethereum CoinModule. Supports:
//   - bip39_12 / bip39_24 create + restore. Same BIP39 mechanic as
//     Bitcoin; the only thing that changes is the SLIP-0044 coin
//     type (60 for Ethereum vs 0 for Bitcoin).
//
// Seed material map shape: {mnemonic, passphrase}, identical to the
// Bitcoin module.

import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter/material.dart';

import '../../wallets/seed_format.dart';
import '../coin_module.dart';
import 'ethereum_keys.dart';
import 'ethereum_wallet.dart';

class EthereumModule implements CoinModule {
  const EthereumModule();

  @override
  String get id => 'ETH';
  @override
  String get name => 'Ethereum';
  @override
  String get symbol => 'ETH';
  @override
  Color get color => const Color(0xFF627EEA);
  @override
  IconData get icon => Icons.diamond;

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
            'Ethereum doesn\'t support ${format.displayName} for create');
    }
    final mnemonic = bip39.generateMnemonic(strength: strength);
    final addr =
        deriveEthereumAddress(mnemonic: mnemonic, passphrase: passphrase);
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
          'Ethereum doesn\'t support ${format.displayName} for restore');
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
        deriveEthereumAddress(mnemonic: normalised, passphrase: passphrase);
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
    onStage?.call('deriving BIP44 address');
    final w = EthereumWallet.open(
      mnemonic: seedMaterial['mnemonic'] as String,
      passphrase: (seedMaterial['passphrase'] as String?) ?? '',
    );
    onStage?.call('ready');
    return w;
  }
}
