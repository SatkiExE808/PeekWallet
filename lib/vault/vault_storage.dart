import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart' show compute;
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
  static const _failedAttemptsKey = 'vault.failed_attempts.v1';
  static const _lockoutUntilKey = 'vault.lockout_until.v1';
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

  // ── Failed-attempt rate limiting ────────────────────────────

  /// Read the running failed-unlock counter. Returns 0 when no
  /// failures have been recorded.
  Future<int> failedAttempts() async {
    final raw = await _storage.read(key: _failedAttemptsKey);
    return int.tryParse(raw ?? '') ?? 0;
  }

  /// Bump the failed-attempt counter by one. Persists across app
  /// restarts so an attacker who force-closes the app can't reset
  /// the count.
  Future<int> bumpFailedAttempts() async {
    final current = await failedAttempts();
    final next = current + 1;
    await _storage.write(key: _failedAttemptsKey, value: '$next');
    return next;
  }

  /// Zero the failed-attempt counter. Called on every successful
  /// unlock.
  Future<void> resetFailedAttempts() async {
    await _storage.delete(key: _failedAttemptsKey);
    await _storage.delete(key: _lockoutUntilKey);
  }

  /// Persist a "no unlock attempts allowed until X" timestamp. The
  /// lock screen consults this on every render and disables the
  /// unlock button until the clock passes it.
  Future<void> setLockoutUntil(DateTime when) async {
    await _storage.write(
      key: _lockoutUntilKey,
      value: when.toUtc().toIso8601String(),
    );
  }

  /// Read the current lockout deadline, or null when no lockout is
  /// in effect (or the deadline has already passed).
  Future<DateTime?> lockoutUntil() async {
    final raw = await _storage.read(key: _lockoutUntilKey);
    if (raw == null || raw.isEmpty) return null;
    final dt = DateTime.tryParse(raw);
    if (dt == null) return null;
    if (DateTime.now().toUtc().isAfter(dt)) {
      // Already expired — clear it so future reads are fast.
      await _storage.delete(key: _lockoutUntilKey);
      return null;
    }
    return dt;
  }

  Future<SecretKey> _deriveKey(String password, List<int> salt) async {
    // PBKDF2 with 200k iterations takes ~1-3 seconds on a mid-range
    // Android device. Running it on the UI isolate freezes the unlock
    // button. compute() ships the work to a background isolate so
    // the UI keeps responding (the lock screen can show a spinner
    // and animate it smoothly while the key derives).
    final bytes = await compute(
      _pbkdf2InIsolate,
      _Pbkdf2Args(
        password: utf8.encode(password),
        salt: salt,
        iterations: _iterations,
        bits: _keyLen * 8,
      ),
    );
    return SecretKey(bytes);
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
    // Wallet-file PBKDF2 is a 10k-iter inner derivation. Lighter than
    // the master key but still ~150ms on Android; isolate it for
    // the same reason — avoid a second UI-thread stall on unlock.
    final bytes = await compute(
      _pbkdf2InIsolate,
      _Pbkdf2Args(
        password: utf8.encode('$password$ctxLabel'),
        salt: salt,
        iterations: 10000,
        bits: 32 * 8,
      ),
    );
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

/// Thrown when the unlock rate-limiter has locked the user out. The
/// lock screen catches this specifically to render a countdown
/// instead of the generic "wrong password" message.
class VaultLockoutError extends VaultError {
  VaultLockoutError(this.until)
      : super(
            'Too many failed attempts. Wait until ${until.toLocal()} to try again.');
  final DateTime until;
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

/// Args struct sent across the isolate boundary by [compute] in
/// [VaultStorage._deriveKey]. Plain int/bytes only so it serializes
/// cleanly via the default SendPort encoder.
class _Pbkdf2Args {
  const _Pbkdf2Args({
    required this.password,
    required this.salt,
    required this.iterations,
    required this.bits,
  });
  final List<int> password;
  final List<int> salt;
  final int iterations;
  final int bits;
}

/// Top-level entry point for [compute] — must not be a method, so it
/// can be shipped to a background isolate. Returns the raw derived
/// key bytes; caller wraps them in a [SecretKey] on the main side.
Future<List<int>> _pbkdf2InIsolate(_Pbkdf2Args args) async {
  final pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: args.iterations,
    bits: args.bits,
  );
  final key = await pbkdf2.deriveKey(
    secretKey: SecretKey(args.password),
    nonce: args.salt,
  );
  return key.extractBytes();
}
