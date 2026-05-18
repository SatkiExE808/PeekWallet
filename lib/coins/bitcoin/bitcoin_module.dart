// CoinModule for Bitcoin and any BIP143-compatible chain (currently
// Litecoin). The two share derivation (BIP84), address format
// (bech32 P2WPKH), and transaction format (BIP141/143) — the only
// difference is the chain params (HRP, coin_type, explorer base
// URL). Capturing that in [BitcoinChainParams] lets us run a single
// implementation for both.
//
// Seed material map shape: {mnemonic, passphrase}, identical to the
// MoneroModule BIP39 path.

import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter/material.dart';

import '../../wallets/seed_format.dart';
import '../coin_module.dart';
import 'bitcoin_keys.dart';
import 'bitcoin_wallet.dart';
import 'chain_params.dart';

/// CoinModule for a UTXO-based chain that uses BIP84 derivation. The
/// public BitcoinModule and LitecoinModule below are thin wrappers
/// around this with concrete [BitcoinChainParams].
class UtxoCoinModule implements CoinModule {
  const UtxoCoinModule({
    required this.params,
    required this.displayColor,
    required this.displayIcon,
  });

  final BitcoinChainParams params;
  final Color displayColor;
  final IconData displayIcon;

  @override
  String get id => params.id;
  @override
  String get name => params.name;
  @override
  String get symbol => params.symbol;
  @override
  Color get color => displayColor;
  @override
  IconData get icon => displayIcon;

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
            '${params.symbol} doesn\'t support ${format.displayName} for create');
    }
    final mnemonic = bip39.generateMnemonic(strength: strength);
    final addr = deriveBitcoinAddress(
      mnemonic: mnemonic,
      passphrase: passphrase,
      params: params,
    );
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
          '${params.symbol} doesn\'t support ${format.displayName} for restore');
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
    final addr = deriveBitcoinAddress(
      mnemonic: normalised,
      passphrase: passphrase,
      params: params,
    );
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
      params: params,
    );
    onStage?.call('ready');
    return w;
  }
}

class BitcoinModule extends UtxoCoinModule {
  const BitcoinModule()
      : super(
          params: kBtcMainnet,
          displayColor: const Color(0xFFF7931A),
          displayIcon: Icons.currency_bitcoin,
        );
}

class LitecoinModule extends UtxoCoinModule {
  const LitecoinModule()
      : super(
          params: kLtcMainnet,
          displayColor: const Color(0xFFBFBBBB),
          displayIcon: Icons.toll, // round token; Material doesn't ship a LTC glyph
        );
}
