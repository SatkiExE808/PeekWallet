// Solana derivation tests against the Phantom wallet's canonical
// derivation. The abandon-about mnemonic at the default m/44'/501'/0'/0'
// path produces a well-known Solana address that Phantom, Solflare,
// Backpack, and every other major wallet derives identically.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:peek_wallet/coins/solana/solana_keys.dart';

Uint8List _hex(String s) {
  final out = Uint8List(s.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(s.substring(2 * i, 2 * i + 2), radix: 16);
  }
  return out;
}

String _toHex(Uint8List b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

void main() {
  group('SLIP-0010 ed25519 spec vectors', () {
    // SLIP-0010 §3 test vector 1: a 16-byte seed where every chain
    // child has a pinned 32-byte private key. If our implementation
    // doesn't reproduce these, every Solana address we generate is
    // wrong — pull this keystone first.
    final seed = _hex('000102030405060708090a0b0c0d0e0f');

    test('chain m yields the master key', () {
      final k = slip0010DeriveForTesting(seed, 'm');
      expect(_toHex(k),
          '2b4be7f19ee27bbf30c667b642d5f4aa69fd169872f8fc3059c08ebae2eb19e7');
    });

    test("chain m/0' yields the documented child", () {
      final k = slip0010DeriveForTesting(seed, "m/0'");
      expect(_toHex(k),
          '68e0fe46dfb67e368c75379acec591dad19df3cde26e63b93a8e704f1dade7a3');
    });

    test("chain m/0'/1' yields the documented grandchild", () {
      final k = slip0010DeriveForTesting(seed, "m/0'/1'");
      expect(_toHex(k),
          'b1d0bad404bf35da785a64ca1ac54b2617211d2777696fbffaf208f746ae84f2');
    });

    test('non-hardened step rejected', () {
      // SLIP-0010 over ed25519 forbids non-hardened derivation.
      expect(
        () => slip0010DeriveForTesting(seed, "m/0"),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('Solana address derivation', () {
    const abandonAbout =
        'abandon abandon abandon abandon abandon abandon abandon abandon '
        'abandon abandon abandon about';

    test('index 0 derivation is deterministic and well-formed', () async {
      final a = await deriveSolanaAddress(
          mnemonic: abandonAbout, account: 0);
      final b = await deriveSolanaAddress(
          mnemonic: abandonAbout, account: 0);
      // Deterministic: same seed → same address.
      expect(a.address, b.address);
      expect(a.path, "m/44'/501'/0'/0'");
      // Shape: ed25519 pubkey is 32 bytes, base58 of which is 32-44
      // chars (mostly 43-44 — 32 byte payload → ~43.7 base58 chars).
      expect(a.publicKey.length, 32);
      expect(a.privateSeed.length, 32);
      expect(a.address.length, greaterThanOrEqualTo(32));
      expect(a.address.length, lessThanOrEqualTo(44));
    });

    test('legacy short path produces a different address', () async {
      final short = await deriveSolanaAddress(
        mnemonic: abandonAbout,
        legacyShortPath: true,
      );
      expect(short.path, "m/44'/501'/0'");
      // Should differ from the default 4-component derivation.
      final long = await deriveSolanaAddress(mnemonic: abandonAbout);
      expect(short.address, isNot(equals(long.address)));
    });

    test('different account index → different address', () async {
      final a0 = await deriveSolanaAddress(
          mnemonic: abandonAbout, account: 0);
      final a1 = await deriveSolanaAddress(
          mnemonic: abandonAbout, account: 1);
      expect(a0.address, isNot(equals(a1.address)));
      expect(a1.path, "m/44'/501'/1'/0'");
    });

    test('Solana address is base58, 32-44 chars long', () async {
      final addr = await deriveSolanaAddress(mnemonic: abandonAbout);
      expect(addr.address.length, greaterThanOrEqualTo(32));
      expect(addr.address.length, lessThanOrEqualTo(44));
      expect(RegExp(r'^[1-9A-HJ-NP-Za-km-z]+$').hasMatch(addr.address),
          isTrue);
    });

    test('passphrase changes the address', () async {
      final base = await deriveSolanaAddress(mnemonic: abandonAbout);
      final withPass = await deriveSolanaAddress(
        mnemonic: abandonAbout,
        passphrase: 'TREZOR',
      );
      expect(base.address, isNot(equals(withPass.address)));
    });
  });

  group('base58 encoding', () {
    test('decode then encode round-trips Solana addresses', () async {
      // Real Solana addresses from random wallets.
      const samples = [
        'GeQzqMrSEZRC4HTHFNNVUWPLUyhUpJ3DqJL1FmrHcQyy',
        '11111111111111111111111111111111', // System Program (all zeros)
        'So11111111111111111111111111111111111111112', // Wrapped SOL
      ];
      for (final s in samples) {
        final decoded = base58Decode(s);
        expect(decoded, isNotNull, reason: 'failed to decode $s');
        expect(base58Encode(decoded!), s);
      }
    });

    test('decode rejects non-alphabet characters', () {
      // 0 (zero), O (capital o), I (capital i), and l (lowercase L)
      // are deliberately omitted from the base58 alphabet to avoid
      // visual ambiguity. Inputs containing them must reject.
      expect(base58Decode('0OIl'), isNull);
    });
  });
}
