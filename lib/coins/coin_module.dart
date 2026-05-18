import 'package:flutter/material.dart';

import '../wallets/seed_format.dart';

/// Coin-agnostic interface for wallet lifecycle operations. Each
/// coin (XMR today; BTC, ETH, LTC, etc. coming) provides one
/// implementation of this. The Wallet-creation UI and the active-
/// wallet boot path call into the module instead of branching on
/// coin id everywhere.
///
/// State management:
///   - generateNew / restoreFrom produce the persistable seed
///     material (handed off to WalletStore.create).
///   - open boots whatever native engine the coin needs and returns
///     an opaque "live wallet handle" the UI polls for balance,
///     sync %, history, etc.
///
/// We use [dynamic] for the live wallet handle to keep this layer
/// out of FFI specifics — coin-specific UI code casts to the real
/// type (e.g., MoneroWallet) when it needs the typed methods.
abstract class CoinModule {
  String get id;            // 'XMR', 'BTC', ...
  String get name;          // 'Monero', 'Bitcoin', ...
  String get symbol;        // 'XMR', 'BTC', ...
  Color get color;
  IconData get icon;

  /// Formats the user can choose when CREATING a fresh wallet. We
  /// generate the seed material; the user just sees it.
  List<SeedFormat> get supportedCreateFormats;

  /// Formats accepted when the user RESTORES an existing wallet.
  /// Superset of [supportedCreateFormats] for coins that also accept
  /// keys-only / external seed formats.
  List<SeedFormat> get supportedRestoreFormats;

  /// Generate a fresh wallet of this coin in the given format.
  /// May involve calling into native code (e.g., monero_c's
  /// `WalletManager_createWallet` mints a 25-word seed).
  ///
  /// [walletId] is the id WalletStore will eventually assign — the
  /// caller pre-allocates it via [WalletStore.generateId] so the
  /// on-disk wallet file lands at its final path immediately,
  /// avoiding a rename after store-create. Pass the same id to
  /// WalletStore.create's `withId` parameter.
  ///
  /// Returns the persistable seedMaterial map + the user-facing seed
  /// presentation (words to write down, or keys to record for the
  /// keysOnly flow).
  Future<NewWalletMaterial> generateNew({
    required String walletId,
    required SeedFormat format,
    required String walletFilePassword,
    String passphrase = '',
  });

  /// Restore from user-supplied material. Validates the input and
  /// constructs the seedMaterial map ready for WalletStore.create.
  /// Throws [CoinModuleError] on invalid input (wrong-length phrase,
  /// failed checksum, etc.) — caller surfaces the message verbatim.
  Future<RestoredWalletMaterial> restoreFrom({
    required String walletId,
    required SeedFormat format,
    required Map<String, String> input,
    required String walletFilePassword,
    int? restoreHeight,
  });

  /// Boot an opened wallet. Called from WalletSession after
  /// WalletStore.open has produced the seedMaterial. Returns the
  /// live wallet handle (MoneroWallet for XMR, etc.) which the UI
  /// polls.
  Future<dynamic> open({
    required String walletId,
    required SeedFormat format,
    required Map<String, dynamic> seedMaterial,
    required String walletFilePassword,
    required String daemonUri,
    required int restoreHeight,
    void Function(String stage)? onStage,
  });
}

/// Output of [CoinModule.generateNew]. Both fields are needed:
///   - [seedMaterial] is what we persist (encrypted) for re-opening
///   - [revealableSeed] is what we SHOW the user once to write down
///     (could be the same content shown differently, or could be a
///     pretty-printed format)
class NewWalletMaterial {
  const NewWalletMaterial({
    required this.seedMaterial,
    required this.revealableSeed,
    required this.primaryAddress,
    this.restoreHeight,
  });

  /// Persistable map. Schema is format-dependent — see [SeedFormat]
  /// for the per-format documentation.
  final Map<String, dynamic> seedMaterial;

  /// Human-readable seed for the "write this down" screen. For
  /// 12 / 24 / 25 / 14 word formats, this is the space-separated
  /// phrase. For keysOnly, it's the spend key hex.
  final String revealableSeed;

  /// Primary on-chain address. Cached in WalletMeta for the wallets
  /// list to render without re-deriving on every paint.
  final String primaryAddress;

  /// Monero only: where the wallet should start scanning. Cached so
  /// future opens skip the daemon-tip RPC.
  final int? restoreHeight;
}

class RestoredWalletMaterial {
  const RestoredWalletMaterial({
    required this.seedMaterial,
    required this.primaryAddress,
    this.restoreHeight,
  });

  final Map<String, dynamic> seedMaterial;
  final String primaryAddress;
  final int? restoreHeight;
}

class CoinModuleError implements Exception {
  const CoinModuleError(this.message);
  final String message;
  @override
  String toString() => message;
}
