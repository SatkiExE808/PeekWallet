import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peek_wallet/wallets/seed_format.dart';
import 'package:peek_wallet/wallets/wallet_store.dart';

/// Same FlutterSecureStorage mock pattern as vault_storage_test.
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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakeSecureStorage fake;

  setUp(() async {
    fake = _FakeSecureStorage()..install();
    await WalletStore.I.wipe();
  });

  tearDown(() => fake.uninstall());

  group('create / list', () {
    test('starts empty', () async {
      expect(await WalletStore.I.hasAny(), isFalse);
      expect(await WalletStore.I.list(), isEmpty);
    });

    test('create + list', () async {
      final meta = await WalletStore.I.create(
        name: 'My Monero',
        coinId: 'XMR',
        format: SeedFormat.bip39_12,
        seedMaterial: {'mnemonic': 'abandon abandon …', 'passphrase': ''},
        password: 'pw12345678',
        primaryAddress: '4abc',
      );
      expect(meta.id.startsWith('w_'), isTrue);
      expect(meta.name, 'My Monero');
      expect(meta.coinId, 'XMR');
      expect(meta.format, SeedFormat.bip39_12);
      expect(meta.primaryAddress, '4abc');

      final list = await WalletStore.I.list();
      expect(list.length, 1);
      expect(list.first.id, meta.id);
      expect(await WalletStore.I.hasAny(), isTrue);
    });

    test('multiple wallets', () async {
      await WalletStore.I.create(
        name: 'A',
        coinId: 'XMR',
        format: SeedFormat.bip39_12,
        seedMaterial: {'mnemonic': 'm1', 'passphrase': ''},
        password: 'pw12345678',
      );
      await WalletStore.I.create(
        name: 'B',
        coinId: 'XMR',
        format: SeedFormat.monero25,
        seedMaterial: {'seed': 'twenty-five word phrase here'},
        password: 'pw12345678',
      );

      final list = await WalletStore.I.list();
      expect(list.length, 2);
      // Order preserves insertion (A then B).
      expect(list[0].name, 'A');
      expect(list[1].name, 'B');
      expect(list[0].order, 0);
      expect(list[1].order, 1);
    });
  });

  group('open', () {
    test('round-trip seedMaterial', () async {
      final meta = await WalletStore.I.create(
        name: 'X',
        coinId: 'XMR',
        format: SeedFormat.bip39_12,
        seedMaterial: {'mnemonic': 'one two three', 'passphrase': '25th'},
        password: 'correct-password',
      );
      final decrypted = await WalletStore.I.open(
        walletId: meta.id,
        password: 'correct-password',
      );
      expect(decrypted.meta.id, meta.id);
      expect(decrypted.seedMaterial['mnemonic'], 'one two three');
      expect(decrypted.seedMaterial['passphrase'], '25th');
      expect(decrypted.walletFilePassword, isNotEmpty);
    });

    test('walletFilePassword: add-wallet-flow → coin-screen round trip', () async {
      // Reproduces the exact sequence the XMR 25-word restore takes:
      //   1. add_wallet_flow generates an id + derives the wallet-file
      //      password via deriveWalletFilePassword(masterPwd, id) and
      //      hands that to monero_c at restore time.
      //   2. WalletStore.create(withId: id, ...) stores the wallet.
      //   3. coin_screen later calls WalletStore.open(walletId: id)
      //      and uses the walletFilePassword field for monero_c open.
      //
      // For the open to succeed, the value from (1) MUST equal the
      // value returned by (3). This test pins that invariant.
      const masterPwd = 'correct-horse-battery-staple';
      final id = WalletStore.I.generateId();
      final filePwdAtRestore =
          await WalletStore.I.deriveWalletFilePassword(masterPwd, id);

      await WalletStore.I.create(
        withId: id,
        name: 'XMR 25-word',
        coinId: 'XMR',
        format: SeedFormat.monero25,
        seedMaterial: {'seed': 'word1 word2 word3', 'seedOffset': ''},
        password: masterPwd,
      );

      final decrypted = await WalletStore.I.open(
        walletId: id,
        password: masterPwd,
      );
      expect(decrypted.walletFilePassword, filePwdAtRestore,
          reason:
              'Wallet-file password must be reproducible by the open path. '
              'If this fails, the add-wallet-flow → monero_c file is encrypted '
              'with one password and coin-screen tries the other.');
    });

    test('walletFilePassword is deterministic across opens', () async {
      final meta = await WalletStore.I.create(
        name: 'X',
        coinId: 'XMR',
        format: SeedFormat.bip39_12,
        seedMaterial: {'mnemonic': 'm'},
        password: 'pw12345678',
      );
      final a = await WalletStore.I.open(walletId: meta.id, password: 'pw12345678');
      final b = await WalletStore.I.open(walletId: meta.id, password: 'pw12345678');
      expect(a.walletFilePassword, b.walletFilePassword);
    });

    test('different wallets get different walletFilePasswords', () async {
      final a = await WalletStore.I.create(
        name: 'A',
        coinId: 'XMR',
        format: SeedFormat.bip39_12,
        seedMaterial: {'mnemonic': 'a'},
        password: 'pw12345678',
      );
      final b = await WalletStore.I.create(
        name: 'B',
        coinId: 'XMR',
        format: SeedFormat.bip39_12,
        seedMaterial: {'mnemonic': 'b'},
        password: 'pw12345678',
      );
      final da = await WalletStore.I.open(walletId: a.id, password: 'pw12345678');
      final db = await WalletStore.I.open(walletId: b.id, password: 'pw12345678');
      // Different per-wallet salts → different derived passwords.
      expect(da.walletFilePassword, isNot(db.walletFilePassword));
    });

    test('wrong password throws', () async {
      final meta = await WalletStore.I.create(
        name: 'X',
        coinId: 'XMR',
        format: SeedFormat.bip39_12,
        seedMaterial: {'mnemonic': 'm'},
        password: 'correct',
      );
      expect(
        () => WalletStore.I.open(walletId: meta.id, password: 'wrong'),
        throwsA(isA<WalletStoreError>().having(
            (e) => e.message, 'message', 'Wrong password')),
      );
    });

    test('unknown walletId throws', () async {
      expect(
        () => WalletStore.I.open(walletId: 'w_does_not_exist', password: 'x'),
        throwsA(isA<WalletStoreError>()),
      );
    });
  });

  group('verifyPassword', () {
    test('passes for correct password', () async {
      await WalletStore.I.create(
        name: 'X',
        coinId: 'XMR',
        format: SeedFormat.bip39_12,
        seedMaterial: {'m': 'y'},
        password: 'pw12345678',
      );
      // Must not throw.
      await WalletStore.I.verifyPassword('pw12345678');
    });

    test('throws when no wallets exist', () async {
      expect(
        () => WalletStore.I.verifyPassword('pw'),
        throwsA(isA<WalletStoreError>()),
      );
    });
  });

  group('mutations', () {
    late String walletId;

    setUp(() async {
      final meta = await WalletStore.I.create(
        name: 'Original',
        coinId: 'XMR',
        format: SeedFormat.bip39_12,
        seedMaterial: {'m': 'y'},
        password: 'pw12345678',
      );
      walletId = meta.id;
    });

    test('rename', () async {
      await WalletStore.I.rename(walletId: walletId, newName: 'Renamed');
      final list = await WalletStore.I.list();
      expect(list.first.name, 'Renamed');
    });

    test('setRestoreHeight', () async {
      await WalletStore.I.setRestoreHeight(walletId: walletId, height: 3700000);
      final list = await WalletStore.I.list();
      expect(list.first.restoreHeight, 3700000);
    });

    test('delete removes wallet', () async {
      await WalletStore.I.delete(walletId);
      expect(await WalletStore.I.list(), isEmpty);
    });

    test('reorder', () async {
      // Add a second wallet so there's something to reorder.
      final second = await WalletStore.I.create(
        name: 'Second',
        coinId: 'XMR',
        format: SeedFormat.bip39_12,
        seedMaterial: {'m': 'y2'},
        password: 'pw12345678',
      );
      await WalletStore.I.reorder([second.id, walletId]);
      final list = await WalletStore.I.list();
      expect(list[0].id, second.id);
      expect(list[1].id, walletId);
    });
  });

  group('wipe', () {
    test('clears everything', () async {
      await WalletStore.I.create(
        name: 'X',
        coinId: 'XMR',
        format: SeedFormat.bip39_12,
        seedMaterial: {'m': 'y'},
        password: 'pw12345678',
      );
      await WalletStore.I.wipe();
      expect(await WalletStore.I.list(), isEmpty);
      expect(await WalletStore.I.hasAny(), isFalse);
    });
  });
}
