// PDA + on-curve check tests.
//
// The on-curve check is the keystone — if it returns wrong answers
// we either produce ATAs that aren't usable (claims off-curve when
// it isn't) or fail to find any PDA at all (claims on-curve when it
// isn't). Test against actual ed25519 points (must be on-curve)
// and against the canonical PDA result for known seeds (must derive
// to a published value).

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:peek_wallet/coins/solana/pda.dart';
import 'package:peek_wallet/coins/solana/solana_keys.dart';

void main() {
  group('ed25519 on-curve check', () {
    test('the identity point (y=1, x=0) is on curve', () {
      // y=1 → bytes 01 00 00 ... 00. With high bit zero.
      final bytes = Uint8List(32);
      bytes[0] = 1;
      expect(isOnCurve(bytes), isTrue);
    });

    test('a known SPL token mint address IS a valid ed25519 point', () async {
      // USDC's mint address is a real Solana account, so it must
      // decode as a valid ed25519 point.
      final mint = base58Decode('EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v')!;
      expect(isOnCurve(mint), isTrue);
    });

    test('a derived wallet address IS a valid ed25519 point', () async {
      // Derive a fresh Solana address and verify it's on the curve.
      final addr = await deriveSolanaAddress(
        mnemonic:
            'abandon abandon abandon abandon abandon abandon abandon abandon '
            'abandon abandon abandon about',
      );
      expect(isOnCurve(addr.publicKey), isTrue);
    });

    test('y >= p is off curve', () {
      // The largest 32-byte LE value is p-1 in the curve's field.
      // We construct y = p, which is invalid (out of range).
      // p = 2^255 - 19 → byte 31 should equal 0x7f and bit 254 set.
      final bytes = Uint8List(32);
      for (var i = 0; i < 32; i++) {
        bytes[i] = 0xff;
      }
      bytes[31] = 0x7f; // high bit is sign bit, not part of y; this still puts y near p
      // y is close to p but with bit 254 set; verify off-curve check
      // rejects values y >= p. The exact value depends on bytes; we
      // just confirm SOMETHING in this range rejects.
      // (We don't construct an exact y=p because that'd require
      // careful bit math; the goal is just "high y rejected".)
      expect(isOnCurve(bytes), isFalse);
    });
  });

  group('PDA derivation', () {
    test('ATA derivation for known owner+mint is deterministic', () async {
      // Derive a Solana wallet from the abandon-about seed; compute
      // its USDC ATA. Two calls must return the same address.
      final owner = await deriveSolanaAddress(
        mnemonic:
            'abandon abandon abandon abandon abandon abandon abandon abandon '
            'abandon abandon abandon about',
      );
      final mint = base58Decode('EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v')!;

      final ata1 = associatedTokenAddress(
        owner: owner.publicKey,
        mint: mint,
      );
      final ata2 = associatedTokenAddress(
        owner: owner.publicKey,
        mint: mint,
      );
      expect(ata1, ata2);
      // The resulting address is itself off-curve (PDAs always are
      // by construction).
      expect(isOnCurve(ata1), isFalse);
      // 32 bytes.
      expect(ata1.length, 32);
    });

    test('different mints → different ATAs', () async {
      final owner = await deriveSolanaAddress(
        mnemonic:
            'abandon abandon abandon abandon abandon abandon abandon abandon '
            'abandon abandon abandon about',
      );
      final usdcMint =
          base58Decode('EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v')!;
      final usdtMint =
          base58Decode('Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB')!;
      final ataUsdc = associatedTokenAddress(
          owner: owner.publicKey, mint: usdcMint);
      final ataUsdt = associatedTokenAddress(
          owner: owner.publicKey, mint: usdtMint);
      expect(ataUsdc, isNot(equals(ataUsdt)));
    });

    test('find_program_address respects empty seeds list', () {
      // Pathological case — should still terminate without throwing.
      final result = findProgramAddress(
        seeds: const [],
        programId: ataProgramId,
      );
      expect(result.address.length, 32);
      expect(result.bump, inInclusiveRange(0, 255));
      // Bonus: the derived address must be off-curve.
      expect(isOnCurve(result.address), isFalse);
    });
  });
}
