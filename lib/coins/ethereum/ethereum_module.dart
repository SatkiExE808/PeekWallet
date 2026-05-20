// CoinModule for any EVM-compatible chain (Ethereum, Polygon,
// Arbitrum, Optimism, BSC, etc.). They share derivation (BIP44
// coin_type=60 by MetaMask convention), address format (0x… +
// EIP-55), and transaction format (EIP-1559 typed-tx) — only the
// chainId, ticker, and explorer/RPC endpoints differ. Capturing
// those in [EthereumNetwork] lets us run a single implementation
// for every EVM chain.
//
// Seed material map shape: {mnemonic, passphrase}, identical to
// the Bitcoin module.

import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter/material.dart';

import '../../wallets/seed_format.dart';
import '../coin_module.dart';
import 'eth_network.dart';
import 'ethereum_keys.dart';
import 'ethereum_wallet.dart';

/// CoinModule for an EVM-compatible chain. EthereumModule and
/// PolygonModule below are thin subclasses with concrete networks.
class EvmCoinModule implements CoinModule {
  const EvmCoinModule({
    required this.network,
    required this.displayColor,
    required this.displayIcon,
  });

  final EthereumNetwork network;
  final Color displayColor;
  final IconData displayIcon;

  @override
  String get id => network.id;
  @override
  String get name => network.name;
  @override
  String get symbol => network.symbol;
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
            '${network.symbol} doesn\'t support ${format.displayName} for create');
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
          '${network.symbol} doesn\'t support ${format.displayName} for restore');
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
    final w = await EthereumWallet.openAsync(
      mnemonic:
          extractBip39Mnemonic(seedMaterial, coinSymbol: network.symbol),
      passphrase: (seedMaterial['passphrase'] as String?) ?? '',
      network: network,
    );
    onStage?.call('ready');
    return w;
  }
}

class EthereumModule extends EvmCoinModule {
  const EthereumModule()
      : super(
          network: kEthMainnet,
          displayColor: const Color(0xFF627EEA),
          displayIcon: Icons.diamond,
        );
}

class PolygonModule extends EvmCoinModule {
  const PolygonModule()
      : super(
          network: kPolygonMainnet,
          displayColor: const Color(0xFF8247E5),
          displayIcon: Icons.hexagon,
        );
}
