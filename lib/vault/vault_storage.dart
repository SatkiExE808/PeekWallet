import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the wallet seed encrypted with a password-derived key.
///
/// On-disk layout (base64): salt(16) || nonce(12) || ciphertext || tag(16).
/// PBKDF2-HMAC-SHA256 with 200k iterations derives a 256-bit AES key,
/// AES-GCM provides confidentiality + integrity.
///
/// The OS-level secure storage (Keychain / Keystore) gives us a second
/// layer: even if the device is unlocked, the password is still needed
/// to decrypt. Same model as vault-wallet.
class VaultStorage {
  VaultStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  static const _blobKey = 'vault.encrypted_seed.v2';
  static const _biometricPasswordKey = 'vault.biometric_password.v1';
  static const _iterations = 200000;
  static const _saltLen = 16;
  static const _nonceLen = 12;
  static const _keyLen = 32;

  final FlutterSecureStorage _storage;
  final _algo = AesGcm.with256bits();

  /// True once a seed has been saved (regardless of whether the
  /// current session has unlocked it).
  Future<bool> hasWallet() async => await _storage.containsKey(key: _blobKey);

  /// Encrypts `mnemonic` (+ optional BIP39 passphrase / "25th word")
  /// with `password`, replaces any existing stored seed. Both values
  /// land in the same AES-GCM ciphertext so the passphrase never sits
  /// on disk in cleartext.
  Future<DecryptedSeed> save(String mnemonic, String password,
      {String passphrase = ''}) async {
    final salt = _randomBytes(_saltLen);
    final nonce = _randomBytes(_nonceLen);
    final key = await _deriveKey(password, salt);

    final plaintext = utf8.encode(
      jsonEncode({'mnemonic': mnemonic, 'passphrase': passphrase}),
    );
    final box = await _algo.encrypt(
      plaintext,
      secretKey: key,
      nonce: nonce,
    );

    final blob = Uint8List(_saltLen + _nonceLen + box.cipherText.length + box.mac.bytes.length)
      ..setRange(0, _saltLen, salt)
      ..setRange(_saltLen, _saltLen + _nonceLen, nonce)
      ..setRange(_saltLen + _nonceLen, _saltLen + _nonceLen + box.cipherText.length, box.cipherText)
      ..setRange(_saltLen + _nonceLen + box.cipherText.length, _saltLen + _nonceLen + box.cipherText.length + box.mac.bytes.length, box.mac.bytes);

    await _storage.write(key: _blobKey, value: base64Encode(blob));
    final walletFilePwd = await _deriveWalletFilePassword(password, salt);
    return DecryptedSeed(
      mnemonic: mnemonic,
      passphrase: passphrase,
      walletFilePassword: walletFilePwd,
    );
  }

  /// Decrypts the stored seed with `password`. Throws on wrong
  /// password (AES-GCM auth-tag mismatch) or missing blob.
  Future<DecryptedSeed> unlock(String password) async {
    final encoded = await _storage.read(key: _blobKey);
    if (encoded == null) throw const VaultError('No wallet on this device');

    final blob = base64Decode(encoded);
    if (blob.length < _saltLen + _nonceLen + 16) {
      throw const VaultError('Stored seed is corrupt');
    }

    final salt = blob.sublist(0, _saltLen);
    final nonce = blob.sublist(_saltLen, _saltLen + _nonceLen);
    final macStart = blob.length - 16;
    final cipherText = blob.sublist(_saltLen + _nonceLen, macStart);
    final mac = Mac(blob.sublist(macStart));

    final key = await _deriveKey(password, salt);
    try {
      final plain = await _algo.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: mac),
        secretKey: key,
      );
      final json = jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
      final walletFilePwd = await _deriveWalletFilePassword(password, salt);
      return DecryptedSeed(
        mnemonic: json['mnemonic'] as String,
        passphrase: (json['passphrase'] as String?) ?? '',
        walletFilePassword: walletFilePwd,
      );
    } on SecretBoxAuthenticationError {
      throw const VaultError('Wrong password');
    }
  }

  /// Permanently removes the encrypted seed AND any biometric stash.
  Future<void> wipe() async {
    await _storage.delete(key: _blobKey);
    await _storage.delete(key: _biometricPasswordKey);
  }

  /// Stash the master password in OS-backed secure storage so a
  /// biometric prompt can later release it. The password isn't
  /// secret to the OS — it's already needed to write the seed blob —
  /// but living in Keystore/Keychain means it survives reboots
  /// without ever being on disk in cleartext outside that boundary.
  Future<void> saveBiometricPassword(String password) =>
      _storage.write(key: _biometricPasswordKey, value: password);

  /// Read the biometric-stashed password. Returns null if biometric
  /// unlock is disabled (key never written or explicitly cleared).
  Future<String?> readBiometricPassword() =>
      _storage.read(key: _biometricPasswordKey);

  /// Disable biometric unlock by removing the stashed password.
  /// The encrypted seed is untouched — the user can still unlock
  /// with their password.
  Future<void> clearBiometricPassword() =>
      _storage.delete(key: _biometricPasswordKey);

  /// Convenience: does this device have biometric unlock enabled?
  Future<bool> biometricEnabled() async =>
      await _storage.containsKey(key: _biometricPasswordKey);

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

  /// Derive the password used to encrypt per-coin wallet files (e.g.
  /// the Monero `.wallet` blob on disk). Distinct from the seed key
  /// because (a) the underlying PRF input is suffixed with a context
  /// string so the two derivations can never collide, and (b) the
  /// iteration count is lower — this is a defense-in-depth password
  /// behind the seed encryption, not the primary boundary. Without
  /// this, the on-disk wallet file would be encrypted with a hardcoded
  /// constant — anyone with the file could open it and read the spend
  /// key out of it without knowing the user's master password.
  Future<String> _deriveWalletFilePassword(
      String password, List<int> salt) async {
    const ctxLabel = '|peek.wallet-file.v1';
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 10000,
      bits: 32 * 8,
    );
    final key = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password + ctxLabel)),
      nonce: salt,
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

class VaultError implements Exception {
  const VaultError(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Result of a successful unlock: the BIP39 phrase, the optional
/// 25th-word passphrase, and a per-vault password used to encrypt
/// per-coin on-disk wallet files (e.g. the Monero `.wallet` file).
class DecryptedSeed {
  const DecryptedSeed({
    required this.mnemonic,
    required this.passphrase,
    required this.walletFilePassword,
  });
  final String mnemonic;
  final String passphrase;
  final String walletFilePassword;
}
