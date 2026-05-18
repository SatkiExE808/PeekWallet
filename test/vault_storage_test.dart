import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peek_wallet/vault/vault_storage.dart';

/// Mocks flutter_secure_storage by intercepting its MethodChannel.
/// Each test gets a fresh in-memory store so they can't influence one
/// another. Mirrors enough of the real plugin's surface (read / write /
/// delete / containsKey / readAll / deleteAll) for VaultStorage to
/// operate normally.
class _FakeSecureStorage {
  final Map<String, String> _map = {};

  void install() {
    const channel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, _handle);
  }

  void uninstall() {
    const channel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  }

  Future<Object?> _handle(MethodCall call) async {
    final args = (call.arguments as Map?) ?? const {};
    final key = args['key'] as String?;
    switch (call.method) {
      case 'write':
        _map[key!] = args['value'] as String;
        return null;
      case 'read':
        return _map[key];
      case 'delete':
        _map.remove(key);
        return null;
      case 'containsKey':
        return _map.containsKey(key);
      case 'readAll':
        return Map<String, String>.from(_map);
      case 'deleteAll':
        _map.clear();
        return null;
      default:
        return null;
    }
  }

  /// Mutate the stored ciphertext blob — used to verify AES-GCM auth
  /// catches tampering.
  void tamper(String key, int flipByteIndex) {
    final raw = _map[key];
    if (raw == null) return;
    final bytes = base64Decode(raw);
    bytes[flipByteIndex] ^= 0x01;
    _map[key] = base64Encode(bytes);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeSecureStorage fake;
  late VaultStorage vault;

  setUp(() {
    fake = _FakeSecureStorage()..install();
    vault = VaultStorage();
  });

  tearDown(() => fake.uninstall());

  group('round-trip', () {
    test('save → unlock returns the same mnemonic + passphrase', () async {
      const mnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon about';
      const password = 'correctHorseBatteryStaple';
      const passphrase = 'twenty-fifth';

      final saved = await vault.save(mnemonic, password, passphrase: passphrase);
      expect(saved.mnemonic, mnemonic);
      expect(saved.passphrase, passphrase);
      expect(saved.walletFilePassword, isNotEmpty);

      final unlocked = await vault.unlock(password);
      expect(unlocked.mnemonic, mnemonic);
      expect(unlocked.passphrase, passphrase);
    });

    test('empty passphrase round-trips as empty', () async {
      const mnemonic = 'one two three';
      await vault.save(mnemonic, 'pw12345678');
      final unlocked = await vault.unlock('pw12345678');
      expect(unlocked.passphrase, '');
    });

    test('walletFilePassword is deterministic across unlocks', () async {
      const mnemonic = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon about';
      const password = 'pw12345678';
      final first = await vault.save(mnemonic, password);
      final second = await vault.unlock(password);
      expect(first.walletFilePassword, second.walletFilePassword);
      // And re-unlocking again still produces the same value.
      final third = await vault.unlock(password);
      expect(third.walletFilePassword, first.walletFilePassword);
    });

    test('different passwords produce different walletFilePasswords', () async {
      // Build two stores side by side so we can compare derived values.
      await vault.save('seed-a', 'password-a');
      final a = await vault.unlock('password-a');

      // Wipe and reuse the same VaultStorage with a different password
      // — same salt strategy, different input.
      await vault.wipe();
      await vault.save('seed-b', 'password-b');
      final b = await vault.unlock('password-b');

      expect(a.walletFilePassword, isNot(b.walletFilePassword));
    });
  });

  group('rejection', () {
    test('wrong password throws VaultError', () async {
      await vault.save('seed', 'correct-password');
      expect(
        () => vault.unlock('wrong-password'),
        throwsA(isA<VaultError>().having((e) => e.message, 'message',
            equals('Wrong password'))),
      );
    });

    test('no wallet on device throws VaultError', () async {
      expect(
        () => vault.unlock('anything'),
        throwsA(isA<VaultError>().having((e) => e.message, 'message',
            contains('No wallet'))),
      );
    });

    test('tampered ciphertext throws (not silent garbage)', () async {
      await vault.save('seed-x', 'correct-password');
      // Flip a byte deep in the ciphertext (past salt + nonce headers).
      // AES-GCM's MAC must catch this — wrong password and tampered
      // ciphertext share the same surface error to avoid leaking which
      // boundary failed.
      fake.tamper('vault.encrypted_seed.v2', 40);
      expect(
        () => vault.unlock('correct-password'),
        throwsA(isA<VaultError>()),
      );
    });

    test('tampered MAC byte throws', () async {
      await vault.save('seed-y', 'correct-password');
      // Last 16 bytes of the blob are the AES-GCM MAC; flipping the
      // last byte should fail auth.
      // Need to compute the right offset against the raw blob — read
      // it back, decode, find the length.
      // Easier: flip a known-late index. The blob is at least
      // 16+12+ciphertext+16 bytes; flipping index −1 is the MAC tail.
      // The fake's tamper() flips by absolute byte index after base64
      // decode, so we use a relative-to-end offset:
      final raw = fake._map['vault.encrypted_seed.v2']!;
      final bytes = base64Decode(raw);
      fake.tamper('vault.encrypted_seed.v2', bytes.length - 1);
      expect(
        () => vault.unlock('correct-password'),
        throwsA(isA<VaultError>()),
      );
    });
  });

  group('failed-attempt counter', () {
    test('starts at zero', () async {
      expect(await vault.failedAttempts(), 0);
    });

    test('bumps + persists', () async {
      expect(await vault.bumpFailedAttempts(), 1);
      expect(await vault.bumpFailedAttempts(), 2);
      expect(await vault.failedAttempts(), 2);
    });

    test('reset clears both attempts and lockout', () async {
      await vault.bumpFailedAttempts();
      await vault.bumpFailedAttempts();
      await vault.setLockoutUntil(
          DateTime.now().toUtc().add(const Duration(minutes: 5)));
      await vault.resetFailedAttempts();
      expect(await vault.failedAttempts(), 0);
      expect(await vault.lockoutUntil(), isNull);
    });

    test('lockoutUntil returns null when expired and clears the key',
        () async {
      // Set a deadline in the past — accessor should treat it as
      // already expired AND wipe the key.
      await vault.setLockoutUntil(
          DateTime.now().toUtc().subtract(const Duration(seconds: 1)));
      expect(await vault.lockoutUntil(), isNull);
      // Subsequent read finds no key.
      expect(await vault.lockoutUntil(), isNull);
    });

    test('lockoutUntil returns the future deadline unmodified', () async {
      final deadline = DateTime.now()
          .toUtc()
          .add(const Duration(minutes: 5))
          // Trim sub-second precision — round-trip through ISO 8601
          // is millisecond-accurate but DateTime can have microseconds.
          .copyWith(microsecond: 0);
      await vault.setLockoutUntil(deadline);
      final got = await vault.lockoutUntil();
      expect(got, isNotNull);
      expect(got!.toIso8601String(), deadline.toIso8601String());
    });
  });

  group('biometric stash', () {
    test('save/read/clear cycle', () async {
      await vault.save('seed', 'pw12345678');
      expect(await vault.biometricEnabled(), isFalse);

      await vault.saveBiometricPassword('pw12345678');
      expect(await vault.biometricEnabled(), isTrue);
      expect(await vault.readBiometricPassword(), 'pw12345678');

      await vault.clearBiometricPassword();
      expect(await vault.biometricEnabled(), isFalse);
      expect(await vault.readBiometricPassword(), isNull);
    });

    test('wipe() clears both the seed AND the biometric stash', () async {
      await vault.save('seed', 'pw12345678');
      await vault.saveBiometricPassword('pw12345678');
      expect(await vault.hasWallet(), isTrue);
      expect(await vault.biometricEnabled(), isTrue);

      await vault.wipe();

      expect(await vault.hasWallet(), isFalse);
      expect(await vault.biometricEnabled(), isFalse);
    });
  });
}
