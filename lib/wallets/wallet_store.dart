import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'seed_format.dart';
import 'wallet_meta.dart';

/// Result of unlocking a wallet — caller gets the decrypted seed
/// material packaged with its metadata. Stays in memory only while
/// the caller holds the reference; never re-persisted.
@immutable
class DecryptedWallet {
  const DecryptedWallet({
    required this.meta,
    required this.seedMaterial,
    required this.walletFilePassword,
  });

  final WalletMeta meta;

  /// Wallet-format-specific JSON payload. Schema depends on
  /// [meta.format]:
  ///   bip39_*:           {mnemonic, passphrase}
  ///   monero_25:         {seed}
  ///   monero_polyseed:   {seed}
  ///   keys_only:         {primaryAddress, spendKeyHex, viewKeyHex}
  final Map<String, dynamic> seedMaterial;

  /// Per-wallet password used to encrypt on-disk wallet files (Monero
  /// keys file, future BTC seed cache). Derived from the master
  /// password + wallet's salt.
  final String walletFilePassword;
}

/// Multi-wallet persistent store. Replaces the single-seed VaultStorage
/// model. Each wallet has its own AES-GCM blob; the master password
/// unlocks all of them via PBKDF2 + per-wallet salt.
///
/// On-disk layout (single secure-storage entry, key 'wallets.v1'):
/// ```json
/// {
///   "wallets": [
///     {
///       "meta": { ... WalletMeta.toJson() ... },
///       "blob": { "b": "<base64 salt||nonce||ct||tag>" }
///     },
///     ...
///   ]
/// }
/// ```
class WalletStore extends ChangeNotifier {
  WalletStore._({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  static final WalletStore I = WalletStore._();

  static const _key = 'wallets.v1';
  static const _iterations = 200000;
  static const _saltLen = 16;
  static const _nonceLen = 12;
  static const _keyLen = 32;

  final FlutterSecureStorage _storage;
  final _algo = AesGcm.with256bits();

  List<_StoredWallet>? _cache;
  bool _loaded = false;

  /// Wallet metadata in display order. Loads on first call. Safe to
  /// read without the master password — only the encrypted blobs need
  /// it.
  Future<List<WalletMeta>> list() async {
    if (!_loaded) await _load();
    final entries = List<_StoredWallet>.from(_cache ?? []);
    entries.sort((a, b) => a.meta.order.compareTo(b.meta.order));
    return entries.map((e) => e.meta).toList();
  }

  /// True iff at least one wallet has been added.
  Future<bool> hasAny() async {
    if (!_loaded) await _load();
    return (_cache ?? []).isNotEmpty;
  }

  /// Generate a fresh wallet id without committing it. The caller
  /// can pre-assign this to a coin-module's create flow so on-disk
  /// wallet files land at the final path immediately (no rename step
  /// after WalletStore.create). When the caller passes the id back
  /// to [create] via [withId], it's used instead of a fresh one.
  String generateId() => 'w_${DateTime.now().microsecondsSinceEpoch}';

  /// Add a new wallet. Encrypts [seedMaterial] with the master
  /// [password] and persists. Returns the new meta.
  Future<WalletMeta> create({
    required String name,
    required String coinId,
    required SeedFormat format,
    required Map<String, dynamic> seedMaterial,
    required String password,
    String? primaryAddress,
    int? restoreHeight,
    String? withId,
  }) async {
    if (!_loaded) await _load();

    final id = withId ?? generateId();
    final salt = _randomBytes(_saltLen);
    final nonce = _randomBytes(_nonceLen);
    final key = await _deriveKey(password, salt);

    final plaintext = utf8.encode(jsonEncode(seedMaterial));
    final box = await _algo.encrypt(plaintext, secretKey: key, nonce: nonce);
    final blob = _packBlob(salt, nonce, box);

    final meta = WalletMeta(
      id: id,
      name: name,
      coinId: coinId,
      format: format,
      createdAt: DateTime.now(),
      primaryAddress: primaryAddress,
      restoreHeight: restoreHeight,
      order: (_cache?.length ?? 0),
    );

    _cache!.add(_StoredWallet(meta: meta, blob: EncryptedWalletBlob(blob)));
    await _save();
    notifyListeners();
    return meta;
  }

  /// Decrypt the seed material for a specific wallet. Throws on wrong
  /// password (AES-GCM auth-tag mismatch) or missing wallet id.
  Future<DecryptedWallet> open({
    required String walletId,
    required String password,
  }) async {
    if (!_loaded) await _load();
    final entry = _cache!.firstWhere(
      (e) => e.meta.id == walletId,
      orElse: () => throw const WalletStoreError('Wallet not found'),
    );

    final raw = base64Decode(entry.blob.base64);
    if (raw.length < _saltLen + _nonceLen + 16) {
      throw const WalletStoreError('Stored wallet blob is corrupt');
    }
    final salt = raw.sublist(0, _saltLen);
    final nonce = raw.sublist(_saltLen, _saltLen + _nonceLen);
    final macStart = raw.length - 16;
    final cipherText = raw.sublist(_saltLen + _nonceLen, macStart);
    final mac = Mac(raw.sublist(macStart));

    final key = await _deriveKey(password, salt);
    try {
      final plain = await _algo.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: mac),
        secretKey: key,
      );
      final material = jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
      final walletFilePwd =
          await deriveWalletFilePassword(password, entry.meta.id);
      return DecryptedWallet(
        meta: entry.meta,
        seedMaterial: material,
        walletFilePassword: walletFilePwd,
      );
    } on SecretBoxAuthenticationError {
      throw const WalletStoreError('Wrong password');
    }
  }

  /// Verify the master password is correct without committing to a
  /// full open. Picks any wallet and tries to decrypt — returns
  /// without exception on success.
  Future<void> verifyPassword(String password) async {
    if (!_loaded) await _load();
    if (_cache!.isEmpty) {
      throw const WalletStoreError('No wallets to verify against');
    }
    // Use the first wallet as the probe; same encryption boundary
    // protects all of them so a single check is enough.
    await open(walletId: _cache!.first.meta.id, password: password);
  }

  /// Rename a wallet.
  Future<void> rename({required String walletId, required String newName}) async {
    if (!_loaded) await _load();
    final ix = _cache!.indexWhere((e) => e.meta.id == walletId);
    if (ix < 0) throw const WalletStoreError('Wallet not found');
    _cache![ix] = _StoredWallet(
      meta: _cache![ix].meta.copyWith(name: newName.trim()),
      blob: _cache![ix].blob,
    );
    await _save();
    notifyListeners();
  }

  /// Update the cached restore height (Monero only). No-op when null.
  Future<void> setRestoreHeight({
    required String walletId,
    required int height,
  }) async {
    if (!_loaded) await _load();
    final ix = _cache!.indexWhere((e) => e.meta.id == walletId);
    if (ix < 0) return;
    _cache![ix] = _StoredWallet(
      meta: _cache![ix].meta.copyWith(restoreHeight: height),
      blob: _cache![ix].blob,
    );
    await _save();
    notifyListeners();
  }

  /// Delete a wallet (just the store entry — the on-disk monero_c
  /// wallet directory is cleaned up by the caller).
  Future<void> delete(String walletId) async {
    if (!_loaded) await _load();
    _cache!.removeWhere((e) => e.meta.id == walletId);
    await _save();
    notifyListeners();
  }

  /// Reorder. Pass walletIds in the new desired order. Wallets not
  /// in the list keep their existing order (sorted to the end).
  Future<void> reorder(List<String> walletIds) async {
    if (!_loaded) await _load();
    final reordered = <_StoredWallet>[];
    for (final id in walletIds) {
      final entry = _cache!.firstWhere(
        (e) => e.meta.id == id,
        orElse: () => throw StateError('Unknown wallet id $id'),
      );
      reordered.add(_StoredWallet(
        meta: entry.meta.copyWith(order: reordered.length),
        blob: entry.blob,
      ));
    }
    // Append any wallets not mentioned.
    var nextOrder = reordered.length;
    for (final e in _cache!) {
      if (walletIds.contains(e.meta.id)) continue;
      reordered.add(_StoredWallet(
        meta: e.meta.copyWith(order: nextOrder++),
        blob: e.blob,
      ));
    }
    _cache = reordered;
    await _save();
    notifyListeners();
  }

  /// Drop every stored wallet. Called from VaultState.wipe.
  Future<void> wipe() async {
    await _storage.delete(key: _key);
    _cache = [];
    _loaded = true;
    notifyListeners();
  }

  Future<void> _load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) {
      _cache = [];
      _loaded = true;
      return;
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final list = (json['wallets'] as List?) ?? [];
      _cache = list
          .map((m) => _StoredWallet.fromJson(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Corrupt JSON shouldn't lock the user out of their existing
      // wallets — but we can't recover encrypted material without the
      // index, so the safest fallback is empty + force a fresh
      // create/restore. Logged elsewhere for diagnostics.
      _cache = [];
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final json = jsonEncode({
      'wallets': _cache!.map((e) => e.toJson()).toList(),
    });
    await _storage.write(key: _key, value: json);
  }

  String _packBlob(Uint8List salt, Uint8List nonce, SecretBox box) {
    final out = Uint8List(
        _saltLen + _nonceLen + box.cipherText.length + box.mac.bytes.length);
    out.setRange(0, _saltLen, salt);
    out.setRange(_saltLen, _saltLen + _nonceLen, nonce);
    out.setRange(_saltLen + _nonceLen,
        _saltLen + _nonceLen + box.cipherText.length, box.cipherText);
    out.setRange(_saltLen + _nonceLen + box.cipherText.length,
        out.length, box.mac.bytes);
    return base64Encode(out);
  }

  Future<SecretKey> _deriveKey(String password, List<int> salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _iterations,
      bits: _keyLen * 8,
    );
    return pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
  }

  /// Deterministic wallet-file password from (master password, walletId).
  ///
  /// Used in two places that MUST agree:
  ///   1. add_wallet_flow at create/restore time — picks the password
  ///      that monero_c will use to encrypt the wallet file.
  ///   2. WalletStore.open() at runtime — recomputes the same value
  ///      so we hand monero_c the right password to decrypt later.
  ///
  /// Keyed on walletId (stable across the wallet's lifetime) rather
  /// than the per-wallet random salt so callers can compute it BEFORE
  /// the wallet is committed to the store. Prior versions used the
  /// salt and that worked for re-opens but couldn't be reproduced
  /// at create-time, leading to a permanent password mismatch on
  /// any non-BIP39 wallet (no address-mismatch recovery path).
  Future<String> deriveWalletFilePassword(
      String masterPassword, String walletId) async {
    const ctxLabel = '|peek.wallet-file.v2';
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 10000,
      bits: 32 * 8,
    );
    final key = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(masterPassword + ctxLabel)),
      nonce: utf8.encode(walletId),
    );
    final bytes = await key.extractBytes();
    return base64Encode(bytes);
  }

  Uint8List _randomBytes(int n) {
    final rng = Random.secure();
    final out = Uint8List(n);
    for (var i = 0; i < n; i++) {
      out[i] = rng.nextInt(256);
    }
    return out;
  }
}

class WalletStoreError implements Exception {
  const WalletStoreError(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Internal: meta + blob pair as stored on disk.
class _StoredWallet {
  const _StoredWallet({required this.meta, required this.blob});
  final WalletMeta meta;
  final EncryptedWalletBlob blob;

  Map<String, dynamic> toJson() => {
        'meta': meta.toJson(),
        'blob': blob.toJson(),
      };

  factory _StoredWallet.fromJson(Map<String, dynamic> json) => _StoredWallet(
        meta: WalletMeta.fromJson(json['meta'] as Map<String, dynamic>),
        blob: EncryptedWalletBlob.fromJson(json['blob'] as Map<String, dynamic>),
      );
}
