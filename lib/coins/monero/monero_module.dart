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
        return _generateNativeMonero(walletFilePassword: walletFilePassword);

      case SeedFormat.moneroPolyseed:
        return _generatePolyseed(walletFilePassword: walletFilePassword);

      case SeedFormat.keysOnly:
        throw const CoinModuleError(
            'Cannot CREATE a keys-only wallet — keys-only is for restoring an existing wallet from its keys.');
    }
  }

  @override
  Future<RestoredWalletMaterial> restoreFrom({
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
          seed: input['seed'] ?? '',
          seedOffset: input['seedOffset'] ?? '',
          walletFilePassword: walletFilePassword,
          restoreHeight: restoreHeight ?? 0,
        );

      case SeedFormat.moneroPolyseed:
        return _restorePolyseed(
          seed: input['seed'] ?? '',
          seedOffset: input['seedOffset'] ?? '',
          walletFilePassword: walletFilePassword,
        );

      case SeedFormat.keysOnly:
        return _restoreFromKeys(
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
    // Map each format back to its on-disk wallet file path. The path
    // is derived from the wallet id (stable per-wallet directory)
    // rather than the address — same id always opens the same file
    // even if we rotate keys / migrate someday.
    final docs = await getApplicationDocumentsDirectory();
    final walletDir = Directory('${docs.path}/peek_xmr/$walletId');
    if (!walletDir.existsSync()) walletDir.createSync(recursive: true);
    // walletPath is `${walletDir.path}/wallet` — set per-format below
    // when the open path is wired up in P2-D.

    // We delegate to MoneroWallet.open for the bip39 + keysOnly path
    // (both ultimately use WalletManager_createWalletFromKeys). For
    // monero25 / polyseed, we need to construct from the native seed
    // first because the on-disk wallet file IS the source of truth.
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
        // These wallets have an on-disk monero_c wallet file already
        // (created during restoreFrom / generateNew). The simplest
        // path: open that file directly via Wallet_openWallet. The
        // current MoneroWallet.open() doesn't support that flow — it
        // always tries createWalletFromKeys first — so we'd need a
        // small refactor there OR a parallel open path here.
        //
        // For this commit we wire only the data + restore-time
        // creation. Runtime open path lands in P2-D when the UI
        // actually navigates to a non-bip39 wallet.
        throw const CoinModuleError(
            'Opening non-BIP39 wallets via the new path lands in the next commit; '
            'use the legacy bip39-only flow for now.');
    }
  }

  // ── Native 25-word seed (monero_c WalletManager_createWallet) ─────

  Future<NewWalletMaterial> _generateNativeMonero({
    required String walletFilePassword,
  }) async {
    final docs = await getApplicationDocumentsDirectory();
    // Temporary location to mint the wallet; the WalletStore.create
    // call gives us the real wallet id, at which point we'll rename
    // the dir. Use a microsecond-timestamped name to avoid collision
    // with a concurrent mint.
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final tmpDir = Directory('${docs.path}/peek_xmr/_minting_$stamp');
    if (!tmpDir.existsSync()) tmpDir.createSync(recursive: true);
    final walletPath = '${tmpDir.path}/wallet';

    final wm = monero.WalletManagerFactory_getWalletManager();
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
        'mintedAt': stamp,
      },
      revealableSeed: seedPhrase,
      primaryAddress: address,
      restoreHeight: restoreHeight,
    );
  }

  Future<RestoredWalletMaterial> _restoreNativeMonero({
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
    final docs = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final tmpDir = Directory('${docs.path}/peek_xmr/_restoring_$stamp');
    if (!tmpDir.existsSync()) tmpDir.createSync(recursive: true);
    final walletPath = '${tmpDir.path}/wallet';

    final wm = monero.WalletManagerFactory_getWalletManager();
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
    required String walletFilePassword,
  }) async {
    // monero_c doesn't expose a direct "generate polyseed" — we have
    // to use WalletManager_createWallet then convert via Wallet_-
    // getPolyseed, which reads back the equivalent 14-word polyseed
    // representation of the freshly-minted wallet.
    final docs = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final tmpDir = Directory('${docs.path}/peek_xmr/_minting_$stamp');
    if (!tmpDir.existsSync()) tmpDir.createSync(recursive: true);
    final walletPath = '${tmpDir.path}/wallet';

    final wm = monero.WalletManagerFactory_getWalletManager();
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
    required String seed,
    required String seedOffset,
    required String walletFilePassword,
  }) async {
    final words = seed.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length != 14 && words.length != 16) {
      throw CoinModuleError(
          'Polyseed is 14 (or 16, with encryption) words; got ${words.length}.');
    }
    final docs = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final tmpDir = Directory('${docs.path}/peek_xmr/_restoring_$stamp');
    if (!tmpDir.existsSync()) tmpDir.createSync(recursive: true);
    final walletPath = '${tmpDir.path}/wallet';

    final wm = monero.WalletManagerFactory_getWalletManager();
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

    final docs = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final tmpDir = Directory('${docs.path}/peek_xmr/_restoring_$stamp');
    if (!tmpDir.existsSync()) tmpDir.createSync(recursive: true);
    final walletPath = '${tmpDir.path}/wallet';

    final wm = monero.WalletManagerFactory_getWalletManager();
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
