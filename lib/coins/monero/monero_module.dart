// Monero implementation of CoinModule. Handles every restore /
// create path we expose:
//   - bip39_12 / bip39_24: pure-Dart derivation, vault-wallet seed
//     interop. The seedMaterial map is {mnemonic, passphrase}; we
//     derive spend + view keys + address, then hand the keys to
//     WalletManager_createWalletFromKeys at open time.
//   - monero25: native 25-word seed minted by WalletManager_createWallet
//     (or restored via WalletManager_recoveryWallet). seedMaterial is
//     {seed, seedOffset} where seedOffset is the optional encryption
//     passphrase for the 25-word seed (separate from BIP39's 25th
//     word — different scheme).
//   - moneroPolyseed: 14-word polyseed via WalletManager_create-
//     WalletFromPolyseed. Encodes restoreHeight in the words.
//   - keysOnly: WalletManager_createWalletFromKeys with user-supplied
//     spend + view + address + restore height.
//
// Same MoneroWallet runtime serves all four — only the on-disk wallet
// file creation differs.

// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';

import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter/material.dart';
import 'package:monero/monero.dart' as monero;
import 'package:path_provider/path_provider.dart';

import '../../wallets/seed_format.dart';
import '../coin_module.dart';
import 'monero_keys.dart';
import 'monero_wallet.dart';

class MoneroModule implements CoinModule {
  const MoneroModule();

  @override
  String get id => 'XMR';
  @override
  String get name => 'Monero';
  @override
  String get symbol => 'XMR';
  @override
  Color get color => const Color(0xFFFF6600);
  @override
  IconData get icon => Icons.privacy_tip;

  @override
  List<SeedFormat> get supportedCreateFormats => const [
        SeedFormat.monero25,
        SeedFormat.moneroPolyseed,
        SeedFormat.bip39_12,
      ];

  @override
  List<SeedFormat> get supportedRestoreFormats => const [
        SeedFormat.bip39_12,
        SeedFormat.bip39_24,
        SeedFormat.monero25,
        SeedFormat.moneroPolyseed,
        SeedFormat.keysOnly,
      ];

  @override
  Future<NewWalletMaterial> generateNew({
    required String walletId,
    required SeedFormat format,
    required String walletFilePassword,
    String passphrase = '',
  }) async {
    switch (format) {
      case SeedFormat.bip39_12:
        // Pure-Dart path — matches vault-wallet exactly.
        final mnemonic = bip39.generateMnemonic(strength: 128);
        final keys = deriveMoneroKeys(mnemonic, passphrase: passphrase);
        return NewWalletMaterial(
          seedMaterial: {
            'mnemonic': mnemonic,
            'passphrase': passphrase,
          },
          revealableSeed: mnemonic,
          primaryAddress: keys.primaryAddress,
        );

      case SeedFormat.bip39_24:
        final mnemonic = bip39.generateMnemonic(strength: 256);
        final keys = deriveMoneroKeys(mnemonic, passphrase: passphrase);
        return NewWalletMaterial(
          seedMaterial: {
            'mnemonic': mnemonic,
            'passphrase': passphrase,
          },
          revealableSeed: mnemonic,
          primaryAddress: keys.primaryAddress,
        );

      case SeedFormat.monero25:
        return _generateNativeMonero(
          walletId: walletId,
          walletFilePassword: walletFilePassword,
        );

      case SeedFormat.moneroPolyseed:
        return _generatePolyseed(
          walletId: walletId,
          walletFilePassword: walletFilePassword,
        );

      case SeedFormat.keysOnly:
        throw const CoinModuleError(
            'Cannot CREATE a keys-only wallet — keys-only is for restoring an existing wallet from its keys.');
    }
  }

  @override
  Future<RestoredWalletMaterial> restoreFrom({
    required String walletId,
    required SeedFormat format,
    required Map<String, String> input,
    required String walletFilePassword,
    int? restoreHeight,
  }) async {
    switch (format) {
      case SeedFormat.bip39_12:
      case SeedFormat.bip39_24:
        final mnemonic = (input['mnemonic'] ?? '').trim().toLowerCase();
        final passphrase = input['passphrase'] ?? '';
        final words =
            mnemonic.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
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
        final keys = deriveMoneroKeys(normalised, passphrase: passphrase);
        return RestoredWalletMaterial(
          seedMaterial: {
            'mnemonic': normalised,
            'passphrase': passphrase,
          },
          primaryAddress: keys.primaryAddress,
          restoreHeight: restoreHeight,
        );

      case SeedFormat.monero25:
        return _restoreNativeMonero(
          walletId: walletId,
          seed: input['seed'] ?? '',
          seedOffset: input['seedOffset'] ?? '',
          walletFilePassword: walletFilePassword,
          restoreHeight: restoreHeight ?? 0,
        );

      case SeedFormat.moneroPolyseed:
        return _restorePolyseed(
          walletId: walletId,
          seed: input['seed'] ?? '',
          seedOffset: input['seedOffset'] ?? '',
          walletFilePassword: walletFilePassword,
        );

      case SeedFormat.keysOnly:
        return _restoreFromKeys(
          walletId: walletId,
          address: input['address'] ?? '',
          spendKey: input['spendKey'] ?? '',
          viewKey: input['viewKey'] ?? '',
          restoreHeight: restoreHeight ?? 0,
          walletFilePassword: walletFilePassword,
        );
    }
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
    final walletPath = await _walletPathFor(walletId);

    // BIP39 wallets keep using the existing MoneroWallet.open() —
    // its address-mismatch recovery is invaluable for migrating
    // legacy users from vault-wallet. The path it computes from
    // the BIP39-derived address won't collide with the walletId-
    // based path used by non-BIP39 wallets, so they coexist.
    switch (format) {
      case SeedFormat.bip39_12:
      case SeedFormat.bip39_24:
        return MoneroWallet.open(
          mnemonic: seedMaterial['mnemonic'] as String,
          passphrase: (seedMaterial['passphrase'] as String?) ?? '',
          restoreHeight: restoreHeight,
          daemonUri: daemonUri,
          walletPassword: walletFilePassword,
          onStage: onStage,
        );

      case SeedFormat.monero25:
      case SeedFormat.moneroPolyseed:
      case SeedFormat.keysOnly:
        // The on-disk wallet was already created during
        // generateNew / restoreFrom — try to just open it.
        try {
          return await MoneroWallet.openFromPath(
            walletPath: walletPath,
            walletPassword: walletFilePassword,
            daemonUri: daemonUri,
            restoreHeight: restoreHeight,
            onStage: onStage,
          );
        } catch (e) {
          // Recovery path: pre-fix builds wrote the wallet file with
          // a different password than WalletStore.open() now hands
          // us. If we have the seed material we can blow the file
          // away and re-create it with the right password — same
          // self-healing the BIP39 path has had.
          final msg = e.toString().toLowerCase();
          final isPwdMismatch =
              msg.contains('invalid password') || msg.contains('failed to open');
          if (!isPwdMismatch) rethrow;
          onStage?.call('wallet file password mismatch — re-creating from seed');
          await _wipeWalletDir(walletPath);
          await _recreateFromSeedMaterial(
            walletId: walletId,
            format: format,
            seedMaterial: seedMaterial,
            walletFilePassword: walletFilePassword,
            restoreHeight: restoreHeight,
          );
          return MoneroWallet.openFromPath(
            walletPath: walletPath,
            walletPassword: walletFilePassword,
            daemonUri: daemonUri,
            restoreHeight: restoreHeight,
            onStage: onStage,
          );
        }
    }
  }

  /// Wipe the wallet files at [walletPath] so we can recreate them
  /// fresh with the right password. We delete the specific files
  /// monero_c writes (`<path>`, `<path>.keys`, and `<path>.address.txt`)
  /// rather than rmdir-ing the parent, because rmdir can race with
  /// the WalletManager's still-flushing sync thread on some Android
  /// builds and leave the directory in a half-deleted state where
  /// WalletManager_walletExists() incorrectly returns true.
  ///
  /// We then VERIFY via WalletManager_walletExists() that monero_c
  /// agrees the wallet is gone. If anything's still there we delete
  /// the parent dir as a fallback and re-create it empty.
  Future<void> _wipeWalletDir(String walletPath) async {
    final dir = Directory(walletPath).parent;
    if (!dir.existsSync()) return;

    // Targeted delete of monero_c's known artifacts. .keys is the
    // important one for walletExists() detection; the cache file and
    // address.txt are clean-up.
    for (final suffix in ['', '.keys', '.address.txt']) {
      final f = File('$walletPath$suffix');
      try {
        if (f.existsSync()) f.deleteSync();
      } catch (_) {/* best effort, falls through to the parent-dir wipe */}
    }

    // Verify monero_c agrees the wallet is gone. If walletExists()
    // still returns true, fall back to nuking the parent dir.
    final wm = monero.WalletManagerFactory_getWalletManager();
    final stillThere = monero.WalletManager_walletExists(wm, walletPath);
    if (stillThere) {
      try {
        // Quarantine first (rename is atomic + monero_c can't hold
        // file handles on a renamed path), then async-delete.
        final quarantine = Directory(
            '${dir.path}.broken-${DateTime.now().microsecondsSinceEpoch}');
        dir.renameSync(quarantine.path);
        unawaited(Future(() {
          try {
            quarantine.deleteSync(recursive: true);
          } catch (_) {/* leak the dir; next boot can clean it up */}
        }));
      } catch (_) {
        try {
          dir.deleteSync(recursive: true);
        } catch (_) {/* best effort */}
      }
      // Recreate the parent so _walletPathFor's existsSync() check
      // doesn't trigger a second createSync.
      if (!dir.existsSync()) dir.createSync(recursive: true);
    }
  }

  /// Run the appropriate restore-from-seed monero_c call to
  /// re-materialize a wallet file at the canonical path with the
  /// CURRENT walletFilePassword.
  Future<void> _recreateFromSeedMaterial({
    required String walletId,
    required SeedFormat format,
    required Map<String, dynamic> seedMaterial,
    required String walletFilePassword,
    required int restoreHeight,
  }) async {
    switch (format) {
      case SeedFormat.monero25:
        await _restoreNativeMonero(
          walletId: walletId,
          seed: seedMaterial['seed'] as String? ?? '',
          seedOffset: (seedMaterial['seedOffset'] as String?) ?? '',
          walletFilePassword: walletFilePassword,
          restoreHeight: restoreHeight,
        );
        return;
      case SeedFormat.moneroPolyseed:
        await _restorePolyseed(
          walletId: walletId,
          seed: seedMaterial['seed'] as String? ?? '',
          seedOffset: (seedMaterial['seedOffset'] as String?) ?? '',
          walletFilePassword: walletFilePassword,
        );
        return;
      case SeedFormat.keysOnly:
        await _restoreFromKeys(
          walletId: walletId,
          address: seedMaterial['address'] as String? ?? '',
          spendKey: seedMaterial['spendKey'] as String? ?? '',
          viewKey: seedMaterial['viewKey'] as String? ?? '',
          restoreHeight: restoreHeight,
          walletFilePassword: walletFilePassword,
        );
        return;
      default:
        throw CoinModuleError(
            'Cannot self-heal $format wallets — recovery requires the original seed');
    }
  }

  // ── Native 25-word seed (monero_c WalletManager_createWallet) ─────

  /// Resolve the on-disk wallet path for [walletId]. Used by every
  /// generate/restore variant so wallet files land at a stable
  /// location known to MoneroWallet.openFromPath at runtime.
  Future<String> _walletPathFor(String walletId) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/peek_xmr/$walletId');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return '${dir.path}/wallet';
  }

  Future<NewWalletMaterial> _generateNativeMonero({
    required String walletId,
    required String walletFilePassword,
  }) async {
    final walletPath = await _walletPathFor(walletId);

    final wm = monero.WalletManagerFactory_getWalletManager();
    // Same belt-and-suspenders as the restore paths: if a stale
    // wallet from a previous failed attempt is at this path,
    // createWallet will error with "Wallet already exists" — wipe
    // first so we always get a clean creation.
    if (monero.WalletManager_walletExists(wm, walletPath)) {
      await _wipeWalletDir(walletPath);
    }
    final w = monero.WalletManager_createWallet(
      wm,
      path: walletPath,
      password: walletFilePassword,
      language: 'English',
      networkType: 0,
    );
    final status = monero.Wallet_status(w);
    if (status != 0) {
      final err = monero.Wallet_errorString(w);
      try {
        monero.WalletManager_closeWallet(wm, w, false);
      } catch (_) {/* best effort */}
      throw CoinModuleError(
          'monero_c could not mint a 25-word wallet: ${err.isEmpty ? "status $status" : err}');
    }
    final seedPhrase = monero.Wallet_seed(w, seedOffset: '');
    final address = monero.Wallet_address(w, accountIndex: 0, addressIndex: 0);
    // Use a conservative restore-height anchor — the daemon-tip clamp
    // in MoneroWallet.open kicks in on first sync.
    final restoreHeight = monero.Wallet_getRefreshFromBlockHeight(w);
    try {
      monero.WalletManager_closeWallet(wm, w, true);
    } catch (_) {/* best effort */}

    return NewWalletMaterial(
      seedMaterial: {
        'seed': seedPhrase,
        'seedOffset': '',
        'mintedAt': DateTime.now().toIso8601String(),
      },
      revealableSeed: seedPhrase,
      primaryAddress: address,
      restoreHeight: restoreHeight,
    );
  }

  Future<RestoredWalletMaterial> _restoreNativeMonero({
    required String walletId,
    required String seed,
    required String seedOffset,
    required String walletFilePassword,
    required int restoreHeight,
  }) async {
    final words = seed.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length != 25) {
      throw CoinModuleError(
          'Monero seed is 25 words; got ${words.length}. (For 14-word polyseed, use that option.)');
    }
    final walletPath = await _walletPathFor(walletId);

    // Belt-and-suspenders: if a stale wallet file from a previous
    // failed attempt is sitting at this exact path, WalletManager_-
    // recoveryWallet will try to OPEN it with our password and
    // report "invalid password" when (inevitably) it doesn't match.
    // Wipe any artifacts at the path BEFORE we ask monero_c to
    // create the wallet so it always takes the "create fresh"
    // branch internally.
    final wm = monero.WalletManagerFactory_getWalletManager();
    if (monero.WalletManager_walletExists(wm, walletPath)) {
      await _wipeWalletDir(walletPath);
    }

    final w = monero.WalletManager_recoveryWallet(
      wm,
      path: walletPath,
      password: walletFilePassword,
      mnemonic: words.join(' '),
      networkType: 0,
      restoreHeight: restoreHeight,
      kdfRounds: 1,
      seedOffset: seedOffset,
    );
    final status = monero.Wallet_status(w);
    if (status != 0) {
      final err = monero.Wallet_errorString(w);
      try {
        monero.WalletManager_closeWallet(wm, w, false);
      } catch (_) {/* best effort */}
      throw CoinModuleError(
          'Monero seed restore failed: ${err.isEmpty ? "status $status" : err}');
    }
    final address = monero.Wallet_address(w, accountIndex: 0, addressIndex: 0);
    try {
      monero.WalletManager_closeWallet(wm, w, true);
    } catch (_) {/* best effort */}

    return RestoredWalletMaterial(
      seedMaterial: {
        'seed': words.join(' '),
        'seedOffset': seedOffset,
      },
      primaryAddress: address,
      restoreHeight: restoreHeight,
    );
  }

  // ── Polyseed (14 words, encodes restoreHeight) ─────────────────

  Future<NewWalletMaterial> _generatePolyseed({
    required String walletId,
    required String walletFilePassword,
  }) async {
    // monero_c doesn't expose a direct "generate polyseed" — we have
    // to use WalletManager_createWallet then convert via Wallet_-
    // getPolyseed, which reads back the equivalent 14-word polyseed
    // representation of the freshly-minted wallet.
    final walletPath = await _walletPathFor(walletId);

    final wm = monero.WalletManagerFactory_getWalletManager();
    if (monero.WalletManager_walletExists(wm, walletPath)) {
      await _wipeWalletDir(walletPath);
    }
    final w = monero.WalletManager_createWallet(
      wm,
      path: walletPath,
      password: walletFilePassword,
      language: 'English',
      networkType: 0,
    );
    final status = monero.Wallet_status(w);
    if (status != 0) {
      final err = monero.Wallet_errorString(w);
      try {
        monero.WalletManager_closeWallet(wm, w, false);
      } catch (_) {/* best effort */}
      throw CoinModuleError(
          'monero_c could not mint a Polyseed wallet: ${err.isEmpty ? "status $status" : err}');
    }
    final polyseed = monero.Wallet_getPolyseed(w, passphrase: '');
    final address = monero.Wallet_address(w, accountIndex: 0, addressIndex: 0);
    final restoreHeight = monero.Wallet_getRefreshFromBlockHeight(w);
    try {
      monero.WalletManager_closeWallet(wm, w, true);
    } catch (_) {/* best effort */}

    if (polyseed.isEmpty) {
      throw const CoinModuleError(
          'Wallet was minted but Polyseed export returned empty — falling back to 25-word seed.');
    }

    return NewWalletMaterial(
      seedMaterial: {
        'seed': polyseed,
        'seedOffset': '',
      },
      revealableSeed: polyseed,
      primaryAddress: address,
      restoreHeight: restoreHeight,
    );
  }

  Future<RestoredWalletMaterial> _restorePolyseed({
    required String walletId,
    required String seed,
    required String seedOffset,
    required String walletFilePassword,
  }) async {
    final words = seed.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length != 14 && words.length != 16) {
      throw CoinModuleError(
          'Polyseed is 14 (or 16, with encryption) words; got ${words.length}.');
    }
    final walletPath = await _walletPathFor(walletId);

    final wm = monero.WalletManagerFactory_getWalletManager();
    if (monero.WalletManager_walletExists(wm, walletPath)) {
      await _wipeWalletDir(walletPath);
    }
    final w = monero.WalletManager_createWalletFromPolyseed(
      wm,
      path: walletPath,
      password: walletFilePassword,
      networkType: 0,
      mnemonic: words.join(' '),
      seedOffset: seedOffset,
      newWallet: false,
      restoreHeight: 0,
      kdfRounds: 1,
    );
    final status = monero.Wallet_status(w);
    if (status != 0) {
      final err = monero.Wallet_errorString(w);
      try {
        monero.WalletManager_closeWallet(wm, w, false);
      } catch (_) {/* best effort */}
      throw CoinModuleError(
          'Polyseed restore failed: ${err.isEmpty ? "status $status" : err}');
    }
    final address = monero.Wallet_address(w, accountIndex: 0, addressIndex: 0);
    final restoreHeight = monero.Wallet_getRefreshFromBlockHeight(w);
    try {
      monero.WalletManager_closeWallet(wm, w, true);
    } catch (_) {/* best effort */}

    return RestoredWalletMaterial(
      seedMaterial: {
        'seed': words.join(' '),
        'seedOffset': seedOffset,
      },
      primaryAddress: address,
      restoreHeight: restoreHeight,
    );
  }

  // ── Keys-only restore ──────────────────────────────────────────

  Future<RestoredWalletMaterial> _restoreFromKeys({
    required String walletId,
    required String address,
    required String spendKey,
    required String viewKey,
    required int restoreHeight,
    required String walletFilePassword,
  }) async {
    if (address.isEmpty || spendKey.isEmpty || viewKey.isEmpty) {
      throw const CoinModuleError(
          'Need address + spend key + view key for keys-only restore.');
    }
    if (!address.startsWith('4') || address.length != 95) {
      throw const CoinModuleError(
          'Primary Monero address must be 95 chars starting with 4.');
    }
    if (spendKey.length != 64) {
      throw const CoinModuleError('Private spend key must be 64 hex chars.');
    }
    if (viewKey.length != 64) {
      throw const CoinModuleError('Private view key must be 64 hex chars.');
    }

    final walletPath = await _walletPathFor(walletId);

    final wm = monero.WalletManagerFactory_getWalletManager();
    if (monero.WalletManager_walletExists(wm, walletPath)) {
      await _wipeWalletDir(walletPath);
    }
    final w = monero.WalletManager_createWalletFromKeys(
      wm,
      path: walletPath,
      password: walletFilePassword,
      nettype: 0,
      restoreHeight: restoreHeight,
      addressString: address,
      viewKeyString: viewKey,
      spendKeyString: spendKey,
      kdf_rounds: 1,
    );
    final status = monero.Wallet_status(w);
    if (status != 0) {
      final err = monero.Wallet_errorString(w);
      try {
        monero.WalletManager_closeWallet(wm, w, false);
      } catch (_) {/* best effort */}
      throw CoinModuleError(
          'Keys restore failed: ${err.isEmpty ? "status $status" : err}');
    }
    try {
      monero.WalletManager_closeWallet(wm, w, true);
    } catch (_) {/* best effort */}

    return RestoredWalletMaterial(
      seedMaterial: {
        'address': address,
        'spendKey': spendKey,
        'viewKey': viewKey,
      },
      primaryAddress: address,
      restoreHeight: restoreHeight,
    );
  }
}
