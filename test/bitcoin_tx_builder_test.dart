// BIP-0143 spec-vector test for the Bitcoin transaction builder.
//
// The Native P2WPKH example from the BIP itself fixes a specific
// sighash value (`c37af31116d1b27caf68aae9e3ac82f1477929014d5b917657d0eb49478cb670`)
// for a known transaction. Reproducing it here verifies that our
// sighash construction matches consensus — a wrong sighash means
// signatures fail to verify, transactions get rejected by the network,
// and we'd produce unrelay-able transactions.
//
// We also test the higher-level [buildAndSignP2WPKH] for shape
// (structure round-trips, fee/change math is correct), but the
// signature-validity check against real consensus is what the BIP143
// vector covers.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:peek_wallet/coins/bitcoin/bitcoin_keys.dart';
import 'package:peek_wallet/coins/bitcoin/bitcoin_tx_builder.dart';
import 'package:peek_wallet/coins/bitcoin/mempool_client.dart';

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
  group('BIP-0143 sighash spec vector', () {
    test('Native P2WPKH worked example reproduces canonical sighash', () {
      // Setup from BIP-143 "Native P2WPKH":
      //   Two inputs, two outputs, version 1, locktime 0x11.
      //   Input 0: P2PK (irrelevant for our test — we just need its
      //            outpoint + sequence to feed into hashPrevouts /
      //            hashSequence so the multi-input commitment matches).
      //   Input 1: P2WPKH owned by the test private key. THIS is what
      //            we sign.
      //
      // The txid bytes in BIP143 are shown in INTERNAL (little-endian)
      // byte order — i.e. the reverse of how block explorers display
      // them. Our builder takes display-form (mempool.space form), so
      // we reverse the BIP's bytes to match.
      String reverseTxid(String h) {
        final bytes = _hex(h);
        final rev = Uint8List.fromList(bytes.reversed.toList());
        return _toHex(rev);
      }
      final inputs = [
        (
          txid: reverseTxid(
              'fff7f7881a8099afa6940d42d1e7f6362bec38171ea3edf433541db4e4ad969f'),
          vout: 0,
          value: 625000000, // 6.25 BTC (irrelevant for the P2PK input)
          pubKeyHash: Uint8List(20), // not used; this input isn't signed here
          sequence: 0xffffffee,
        ),
        (
          txid: reverseTxid(
              'ef51e1b804cc89d182d279655c3aa89e815b1b309fe287d9b2b55d57b90ec68a'),
          vout: 1,
          value: 600000000, // 6.0 BTC
          pubKeyHash: _hex('1d0f172a0ecb48aee1be1f2687d2963ae33f71a1'),
          sequence: 0xffffffff,
        ),
      ];
      // Outputs from the BIP example, exactly.
      final outputs = [
        (
          value: 112340000,
          scriptPubKey: _hex(
              '76a9148280b37df378db99f66f85c95a783a76ac7a6d5988ac'),
        ),
        (
          value: 223450000,
          scriptPubKey: _hex(
              '76a9143bde42dbee7e4dbe6a21b2d50ce2f0167faa815988ac'),
        ),
      ];
      final sigHash = computeBip143SighashForTesting(
        version: 1,
        inputs: inputs,
        outputs: outputs,
        signingInputIndex: 1,
        locktime: 17, // 0x11
      );
      // Canonical sigHash from BIP-0143 "Native P2WPKH" example.
      expect(_toHex(sigHash),
          'c37af31116d1b27caf68aae9e3ac82f1477929014d5b917657d0eb49478cb670');
    });
  });

  group('buildAndSignP2WPKH', () {
    // Reference test mnemonic from the BIP-0084 spec — used to derive
    // a real BIP84 address that we then construct a synthetic UTXO
    // against. The signed transaction won't be valid on-chain (the
    // UTXO doesn't exist) but signature validity + structure can be
    // verified locally.
    const mnemonic =
        'abandon abandon abandon abandon abandon abandon abandon abandon '
        'abandon abandon abandon about';

    test('produces a structurally-valid signed transaction', () {
      final spending = deriveBitcoinSpendingKey(
        mnemonic: mnemonic,
        addressIndex: 0,
      );
      final changeKey = deriveBitcoinSpendingKey(
        mnemonic: mnemonic,
        addressIndex: 1,
      );

      // Synthetic UTXO at index 0's address worth 0.001 BTC.
      final utxo = Utxo(
        txid:
            'a1075db55d416d3ca199f55b6084e2115b9345e16c5cf302fc80e9d5fbf5d48d',
        vout: 0,
        valueSat: 100000,
        address: spending.address,
        confirmed: true,
        blockHeight: 700000,
      );

      // Send to a known-bech32 address (BIP84 spec example wallet,
      // index 0). Amount 0.0005 BTC; rest minus fee goes to change.
      const destAddress = 'bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu';
      final built = buildAndSignP2WPKH(
        inputs: [utxo],
        signers: {spending.address: spending},
        destAddress: destAddress,
        amountSat: 50000,
        changeAddress: changeKey.address,
        feeRateSatPerVByte: 5,
      );

      // Basic invariants.
      expect(built.recipientSat, 50000);
      expect(built.feeSat, greaterThan(0));
      expect(built.changeSat, greaterThanOrEqualTo(0));
      expect(built.recipientSat + built.feeSat + built.changeSat, 100000);
      expect(built.virtualSize, greaterThan(100)); // 1-in/2-out ~ 140 vbytes
      expect(built.virtualSize, lessThan(200));

      // Hex must be even-length and decode to bytes.
      expect(built.rawHex.length % 2, 0);
      final txBytes = _hex(built.rawHex);

      // First 4 bytes are the version (LE). We hardcode version=2 in
      // the builder, matching modern wallets.
      expect(txBytes[0], 0x02);
      expect(txBytes[1], 0x00);
      expect(txBytes[2], 0x00);
      expect(txBytes[3], 0x00);

      // Bytes 4-5 are the SegWit marker (0x00) + flag (0x01).
      expect(txBytes[4], 0x00);
      expect(txBytes[5], 0x01);

      // Txid is a 32-byte hex string (64 chars).
      expect(built.txid.length, 64);
      expect(RegExp(r'^[0-9a-f]+$').hasMatch(built.txid), isTrue);
    });

    test('throws InsufficientFunds when UTXOs do not cover amount + fee', () {
      final spending = deriveBitcoinSpendingKey(
        mnemonic: mnemonic,
        addressIndex: 0,
      );
      final utxo = Utxo(
        txid:
            'a1075db55d416d3ca199f55b6084e2115b9345e16c5cf302fc80e9d5fbf5d48d',
        vout: 0,
        valueSat: 1000, // way too small
        address: spending.address,
        confirmed: true,
      );
      expect(
        () => buildAndSignP2WPKH(
          inputs: [utxo],
          signers: {spending.address: spending},
          destAddress: 'bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu',
          amountSat: 50000,
          changeAddress: spending.address,
          feeRateSatPerVByte: 10,
        ),
        throwsA(isA<InsufficientFundsException>()),
      );
    });

    test('rejects non-bech32 destination addresses', () {
      final spending = deriveBitcoinSpendingKey(
        mnemonic: mnemonic,
        addressIndex: 0,
      );
      final utxo = Utxo(
        txid:
            'a1075db55d416d3ca199f55b6084e2115b9345e16c5cf302fc80e9d5fbf5d48d',
        vout: 0,
        valueSat: 100000,
        address: spending.address,
        confirmed: true,
      );
      // Legacy P2PKH addresses, P2SH, malformed bech32 etc. should all
      // throw before any signing happens. We only assert "some kind of
      // exception" — the exact type depends on whether segwit.decode
      // bails out (FormatException / MixedCase / InvalidHrp) or our
      // own validator catches it (InvalidBitcoinAddressException).
      expect(
        () => buildAndSignP2WPKH(
          inputs: [utxo],
          signers: {spending.address: spending},
          destAddress: '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa',
          amountSat: 50000,
          changeAddress: spending.address,
          feeRateSatPerVByte: 5,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('rolls dust change into fee', () {
      final spending = deriveBitcoinSpendingKey(
        mnemonic: mnemonic,
        addressIndex: 0,
      );
      // UTXO sized so that after sending most of it, change would be
      // ~400 sat (below the 546-sat dust threshold). At 1 sat/vB, a
      // 1-in/2-out tx is ~141 vB so a 50500-sat UTXO sending 50000
      // would leave 359 sat change pre-dust check — exactly the case
      // we want the builder to fold into fee.
      final utxo = Utxo(
        txid:
            'a1075db55d416d3ca199f55b6084e2115b9345e16c5cf302fc80e9d5fbf5d48d',
        vout: 0,
        valueSat: 50500,
        address: spending.address,
        confirmed: true,
      );
      final built = buildAndSignP2WPKH(
        inputs: [utxo],
        signers: {spending.address: spending},
        destAddress: 'bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu',
        amountSat: 50000,
        changeAddress: spending.address,
        feeRateSatPerVByte: 1,
      );
      expect(built.changeSat, 0);
      expect(built.feeSat, 500); // 50500 in - 50000 out = 500 sat fee
    });
  });

  group('selectUtxosGreedy', () {
    final addr = 'bc1qaddr';
    Utxo u(int sat) => Utxo(
          txid:
              'a1075db55d416d3ca199f55b6084e2115b9345e16c5cf302fc80e9d5fbf5d48d',
          vout: 0,
          valueSat: sat,
          address: addr,
          confirmed: true,
        );

    test('picks largest first until covered', () {
      final picked = selectUtxosGreedy(
        available: [u(5000), u(20000), u(10000)],
        amountSat: 15000,
        feeRateSatPerVByte: 5,
      );
      expect(picked, isNotNull);
      // Should pick the 20000 first.
      expect(picked!.first.valueSat, 20000);
    });

    test('returns null when insufficient', () {
      final picked = selectUtxosGreedy(
        available: [u(500), u(200)],
        amountSat: 15000,
        feeRateSatPerVByte: 5,
      );
      expect(picked, isNull);
    });

    test('ignores unconfirmed UTXOs', () {
      final unconf = Utxo(
        txid:
            'a1075db55d416d3ca199f55b6084e2115b9345e16c5cf302fc80e9d5fbf5d48d',
        vout: 0,
        valueSat: 100000,
        address: addr,
        confirmed: false,
      );
      final picked = selectUtxosGreedy(
        available: [unconf],
        amountSat: 50000,
        feeRateSatPerVByte: 5,
      );
      expect(picked, isNull);
    });
  });
}
