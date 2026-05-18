// Self-consistency tests for the EIP-1559 transaction builder.
//
// The EIP itself doesn't pin RFC-6979 deterministic-k vectors, so a
// byte-for-byte canonical comparison isn't possible. Instead we
// verify that:
//   1. Round-trip: sign → ecRecover gives back our pubkey.
//   2. Structure: typed-tx envelope starts with 0x02 and is well-formed.
//   3. Same inputs produce identical raw bytes (deterministic k).
//   4. Nonce changes alter the tx hash.
//   5. Address validation rejects garbage early.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:peek_wallet/coins/ethereum/eth_tx_builder.dart';
import 'package:pointycastle/ecc/curves/secp256k1.dart';

Uint8List _hex(String s) {
  final clean = s.startsWith('0x') ? s.substring(2) : s;
  final out = Uint8List(clean.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(clean.substring(2 * i, 2 * i + 2), radix: 16);
  }
  return out;
}

/// Compute the compressed secp256k1 public key for a given private
/// key, matching what bip32 produces internally for derivation.
Uint8List _computePubkey(Uint8List privKey) {
  final curve = ECCurve_secp256k1();
  final priv = BigInt.parse(
      privKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      radix: 16);
  final point = (curve.G * priv)!;
  final x = point.x!.toBigInteger()!;
  final y = point.y!.toBigInteger()!;
  final prefix = y.isEven ? 0x02 : 0x03;
  final out = Uint8List(33);
  out[0] = prefix;
  final xHex = x.toRadixString(16).padLeft(64, '0');
  for (var i = 0; i < 32; i++) {
    out[i + 1] = int.parse(xHex.substring(2 * i, 2 * i + 2), radix: 16);
  }
  return out;
}

void main() {
  // Test private key from the EIP-155 worked example. Reusing it
  // here puts our test values in familiar territory.
  final privKey = _hex(
      '4646464646464646464646464646464646464646464646464646464646464646');
  final pubKey = _computePubkey(privKey);

  group('EIP-1559 signed transaction', () {
    test('rawHex starts with 0x02 (EIP-2718 typed-tx envelope)', () {
      final built = buildAndSignEip1559(
        chainId: 1,
        nonce: BigInt.from(0),
        maxPriorityFeePerGasWei: BigInt.from(1500000000),
        maxFeePerGasWei: BigInt.from(30000000000),
        gasLimit: BigInt.from(21000),
        toAddress: '0xd8da6bf26964af9d7eed9e03e53415d37aa96045',
        valueWei: BigInt.from(1000000000000000),
        privateKey: privKey,
        expectedPublicKey: pubKey,
      );
      expect(built.rawHex.startsWith('0x02'), isTrue);
      expect(built.rawHex.length, greaterThan(20));
      expect(built.gasLimit, BigInt.from(21000));
      expect(built.maxFeeWei, BigInt.from(30000000000));
      expect(built.maxPriorityFeeWei, BigInt.from(1500000000));
      expect(built.txHash.length, 66); // 0x + 32 bytes
    });

    test('deterministic: identical inputs yield identical raw bytes', () {
      // Deterministic k (RFC 6979) means signing is bit-identical
      // across calls for the same (privkey, hash). That property is
      // critical for resilience — a user who retries from the same
      // state must end up with the same nonce-locked tx, not a new one.
      Object sign() => buildAndSignEip1559(
            chainId: 1,
            nonce: BigInt.from(7),
            maxPriorityFeePerGasWei: BigInt.from(1500000000),
            maxFeePerGasWei: BigInt.from(30000000000),
            gasLimit: BigInt.from(21000),
            toAddress: '0xd8da6bf26964af9d7eed9e03e53415d37aa96045',
            valueWei: BigInt.from(500000000000000),
            privateKey: privKey,
            expectedPublicKey: pubKey,
          );
      final a = sign() as BuiltEthereumTransaction;
      final b = sign() as BuiltEthereumTransaction;
      expect(a.rawHex, b.rawHex);
      expect(a.txHash, b.txHash);
    });

    test('different nonce → different tx hash', () {
      BuiltEthereumTransaction at(int nonce) => buildAndSignEip1559(
            chainId: 1,
            nonce: BigInt.from(nonce),
            maxPriorityFeePerGasWei: BigInt.from(1500000000),
            maxFeePerGasWei: BigInt.from(30000000000),
            gasLimit: BigInt.from(21000),
            toAddress: '0xd8da6bf26964af9d7eed9e03e53415d37aa96045',
            valueWei: BigInt.from(1000000000000000),
            privateKey: privKey,
            expectedPublicKey: pubKey,
          );
      expect(at(0).txHash, isNot(equals(at(1).txHash)));
    });

    test('different chainId → different tx hash', () {
      // EIP-155 replay protection: chainId is baked into the signing
      // hash so a tx signed for mainnet can't be replayed on Sepolia.
      BuiltEthereumTransaction at(int chainId) => buildAndSignEip1559(
            chainId: chainId,
            nonce: BigInt.from(0),
            maxPriorityFeePerGasWei: BigInt.from(1500000000),
            maxFeePerGasWei: BigInt.from(30000000000),
            gasLimit: BigInt.from(21000),
            toAddress: '0xd8da6bf26964af9d7eed9e03e53415d37aa96045',
            valueWei: BigInt.from(1000000000000000),
            privateKey: privKey,
            expectedPublicKey: pubKey,
          );
      expect(at(1).txHash, isNot(equals(at(11155111).txHash)));
    });

    test('rejects malformed to address', () {
      expect(
        () => buildAndSignEip1559(
          chainId: 1,
          nonce: BigInt.from(0),
          maxPriorityFeePerGasWei: BigInt.from(1500000000),
          maxFeePerGasWei: BigInt.from(30000000000),
          gasLimit: BigInt.from(21000),
          toAddress: '0xnot_a_real_address',
          valueWei: BigInt.from(1),
          privateKey: privKey,
          expectedPublicKey: pubKey,
        ),
        throwsA(isA<InvalidEthereumAddressException>()),
      );
    });

    test('accepts unprefixed address', () {
      final built = buildAndSignEip1559(
        chainId: 1,
        nonce: BigInt.from(0),
        maxPriorityFeePerGasWei: BigInt.from(1500000000),
        maxFeePerGasWei: BigInt.from(30000000000),
        gasLimit: BigInt.from(21000),
        toAddress: 'd8da6bf26964af9d7eed9e03e53415d37aa96045',
        valueWei: BigInt.from(1),
        privateKey: privKey,
        expectedPublicKey: pubKey,
      );
      expect(built.rawHex.startsWith('0x02'), isTrue);
    });

    test('throws if expectedPublicKey does not match privateKey', () {
      // Mismatched expectedPublicKey means the signer can never find
      // a recovery_id that recovers the "expected" key, because the
      // signature is for a DIFFERENT key. We should throw, not return
      // a corrupted tx.
      final wrongPubKey = _computePubkey(_hex(
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'));
      expect(
        () => buildAndSignEip1559(
          chainId: 1,
          nonce: BigInt.from(0),
          maxPriorityFeePerGasWei: BigInt.from(1500000000),
          maxFeePerGasWei: BigInt.from(30000000000),
          gasLimit: BigInt.from(21000),
          toAddress: '0xd8da6bf26964af9d7eed9e03e53415d37aa96045',
          valueWei: BigInt.from(1),
          privateKey: privKey,
          expectedPublicKey: wrongPubKey,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
