// BCH transaction builder sanity tests. Doesn't try to reproduce
// the canonical BIP-143 sighash directly (BCH adds the SIGHASH_FORKID
// flag on top, and there's no BIP-grade worked-example vector). Tests
// structure + deterministic round-trip + canonical reject paths.
//
// The underlying BIP-143 sighash math is shared with the BTC SegWit
// signer, which IS pinned against the canonical vector in
// test/bitcoin_tx_builder_test.dart — so a regression there fails
// loudly and we don't need to duplicate it.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:peek_wallet/coins/bitcoin_cash/bch_keys.dart';
import 'package:peek_wallet/coins/bitcoin_cash/bch_tx_builder.dart';
import 'package:peek_wallet/coins/bitcoin_cash/cashaddr.dart';

Uint8List _hex(String s) {
  final out = Uint8List(s.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(s.substring(2 * i, 2 * i + 2), radix: 16);
  }
  return out;
}

void main() {
  const mnemonic =
      'abandon abandon abandon abandon abandon abandon abandon abandon '
      'abandon abandon abandon about';

  group('BCH P2PKH transaction', () {
    test('produces a deterministic, well-formed legacy tx', () {
      final spending = deriveBitcoinCashSpendingKey(mnemonic: mnemonic);

      final utxo = BchUtxo(
        txid:
            'a1075db55d416d3ca199f55b6084e2115b9345e16c5cf302fc80e9d5fbf5d48d',
        vout: 0,
        valueSat: 100000,
        address: spending.address,
      );

      // Decode our OWN address to use as the (synthetic) recipient.
      final destDecoded = cashaddrDecode(spending.address)!;
      final built = buildAndSignP2PKH(
        inputs: [utxo],
        signers: {spending.address: spending},
        destPkh: destDecoded.hash,
        amountSat: 50000,
        changePkh: spending.publicKeyHash,
        feeRateSatPerByte: 2,
      );

      // Shape: well-formed hex, version 2, no SegWit marker.
      expect(built.rawHex.length % 2, 0);
      expect(built.rawHex.length, greaterThan(200));
      final bytes = _hex(built.rawHex);
      // Bytes 0-3: version (LE) = 02 00 00 00.
      expect(bytes[0], 0x02);
      expect(bytes[1], 0x00);
      // Byte 4 must be the input count varint (legacy — no 0x00 SegWit marker).
      expect(bytes[4], isNot(0x00),
          reason: 'BCH is legacy — no SegWit marker/flag bytes');

      // Fee math: out + fee + change == in. With ~225 bytes * 2 sat/B
      // ≈ 450 sat fee for a 1-in/2-out tx.
      expect(
          built.recipientSat + built.feeSat + built.changeSat, 100000);
      expect(built.feeSat, greaterThan(0));
      expect(built.feeSat, lessThan(1500));

      // txid is 32 bytes (64 hex), all-lowercase.
      expect(built.txid.length, 64);
      expect(RegExp(r'^[0-9a-f]+$').hasMatch(built.txid), isTrue);
    });

    test('appends SIGHASH_FORKID (0x41) to every signature', () {
      // We can verify this by inspecting the scriptSig: the last
      // byte of the signature push should be 0x41.
      final spending = deriveBitcoinCashSpendingKey(mnemonic: mnemonic);
      final utxo = BchUtxo(
        txid:
            'a1075db55d416d3ca199f55b6084e2115b9345e16c5cf302fc80e9d5fbf5d48d',
        vout: 0,
        valueSat: 100000,
        address: spending.address,
      );
      final destDecoded = cashaddrDecode(spending.address)!;
      final built = buildAndSignP2PKH(
        inputs: [utxo],
        signers: {spending.address: spending},
        destPkh: destDecoded.hash,
        amountSat: 50000,
        changePkh: spending.publicKeyHash,
        feeRateSatPerByte: 2,
      );

      // Walk the tx to find the scriptSig: version (4) + 1-byte in_count
      // + prevout (36) + varint(scriptSigLen) + scriptSig.
      final bytes = _hex(built.rawHex);
      // Skip version + in_count (1 byte for 1 input) + prevout = 4 + 1 + 36 = 41.
      final scriptSigLenIdx = 41;
      final scriptSigLen = bytes[scriptSigLenIdx];
      final sigPushLen = bytes[scriptSigLenIdx + 1];
      // First byte of the script is the sig push length. The sig
      // itself ends with 0x41 (SIGHASH_ALL | SIGHASH_FORKID), so
      // byte at (scriptSigLenIdx + 1 + sigPushLen) is the SIGHASH byte.
      final sighashByteIdx = scriptSigLenIdx + 1 + sigPushLen;
      expect(bytes[sighashByteIdx], 0x41,
          reason: 'BCH scriptSig signature must end with 0x41 sighash type');
      expect(scriptSigLen, greaterThan(0));
    });

    test('rolls dust change into fee', () {
      final spending = deriveBitcoinCashSpendingKey(mnemonic: mnemonic);
      // ~228 bytes * 2 sat/B = ~456 sat fee, so a 50,800-sat UTXO
      // sending 50,000 sat leaves ~344 sat — below the 546 dust line.
      final utxo = BchUtxo(
        txid:
            'a1075db55d416d3ca199f55b6084e2115b9345e16c5cf302fc80e9d5fbf5d48d',
        vout: 0,
        valueSat: 50500,
        address: spending.address,
      );
      final destDecoded = cashaddrDecode(spending.address)!;
      final built = buildAndSignP2PKH(
        inputs: [utxo],
        signers: {spending.address: spending},
        destPkh: destDecoded.hash,
        amountSat: 50000,
        changePkh: spending.publicKeyHash,
        feeRateSatPerByte: 1,
      );
      expect(built.changeSat, 0);
      expect(built.feeSat, 500); // 50500 in - 50000 out = 500 sat fee
    });

    test('rejects when funds insufficient', () {
      final spending = deriveBitcoinCashSpendingKey(mnemonic: mnemonic);
      final utxo = BchUtxo(
        txid:
            'a1075db55d416d3ca199f55b6084e2115b9345e16c5cf302fc80e9d5fbf5d48d',
        vout: 0,
        valueSat: 1000, // way too small
        address: spending.address,
      );
      final destDecoded = cashaddrDecode(spending.address)!;
      expect(
        () => buildAndSignP2PKH(
          inputs: [utxo],
          signers: {spending.address: spending},
          destPkh: destDecoded.hash,
          amountSat: 50000,
          changePkh: spending.publicKeyHash,
          feeRateSatPerByte: 5,
        ),
        throwsA(isA<InsufficientBchFundsException>()),
      );
    });
  });

  group('UTXO selection', () {
    test('picks largest-first', () {
      final addr = deriveBitcoinCashAddress(mnemonic: mnemonic).address;
      BchUtxo u(int sat) => BchUtxo(
            txid:
                'a1075db55d416d3ca199f55b6084e2115b9345e16c5cf302fc80e9d5fbf5d48d',
            vout: 0,
            valueSat: sat,
            address: addr,
          );
      final picked = selectBchUtxosGreedy(
        available: [u(5000), u(20000), u(10000)],
        amountSat: 15000,
        feeRateSatPerByte: 2,
      );
      expect(picked, isNotNull);
      expect(picked!.first.valueSat, 20000);
    });

    test('returns null when insufficient', () {
      final addr = deriveBitcoinCashAddress(mnemonic: mnemonic).address;
      final picked = selectBchUtxosGreedy(
        available: [
          BchUtxo(
            txid:
                'a1075db55d416d3ca199f55b6084e2115b9345e16c5cf302fc80e9d5fbf5d48d',
            vout: 0,
            valueSat: 500,
            address: addr,
          ),
        ],
        amountSat: 100000,
        feeRateSatPerByte: 2,
      );
      expect(picked, isNull);
    });
  });
}
