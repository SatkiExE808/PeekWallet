// Litecoin derivation tests. LTC reuses Bitcoin's BIP84 mechanics —
// only the SLIP-0044 coin_type (2 vs 0) and the bech32 HRP (ltc vs
// bc) differ. These tests pin the derivation path + address shape so
// a regression in the ChainParams plumbing surfaces in CI.

import 'package:flutter_test/flutter_test.dart';
import 'package:peek_wallet/coins/bitcoin/bitcoin_keys.dart';
import 'package:peek_wallet/coins/bitcoin/bitcoin_tx_builder.dart';
import 'package:peek_wallet/coins/bitcoin/chain_params.dart';
import 'package:peek_wallet/coins/bitcoin/mempool_client.dart';

void main() {
  group('Litecoin BIP84 derivation', () {
    const abandonAbout =
        'abandon abandon abandon abandon abandon abandon abandon abandon '
        'abandon abandon abandon about';

    test('produces ltc1q-prefixed mainnet address', () {
      final addr = deriveBitcoinAddress(
        mnemonic: abandonAbout,
        params: kLtcMainnet,
      );
      expect(addr.address.startsWith('ltc1q'), isTrue,
          reason: 'Expected ltc1q… prefix, got ${addr.address}');
      // Witness v0 P2WPKH addresses are deterministic-length when
      // base32-encoded: 14 chars HRP + separator + 32 chars program +
      // 6 checksum = 42 for "bc" HRP, 43 for "ltc" HRP.
      expect(addr.address.length, 43);
    });

    test('uses coin_type=2 in derivation path', () {
      final addr = deriveBitcoinAddress(
        mnemonic: abandonAbout,
        addressIndex: 0,
        params: kLtcMainnet,
      );
      expect(addr.path, "m/84'/2'/0'/0/0");
    });

    test('different addresses at successive indices', () {
      final a0 = deriveBitcoinAddress(
          mnemonic: abandonAbout, addressIndex: 0, params: kLtcMainnet);
      final a1 = deriveBitcoinAddress(
          mnemonic: abandonAbout, addressIndex: 1, params: kLtcMainnet);
      expect(a0.address, isNot(equals(a1.address)));
      expect(a0.path, "m/84'/2'/0'/0/0");
      expect(a1.path, "m/84'/2'/0'/0/1");
    });

    test('does not collide with the same-index Bitcoin address', () {
      // The same seed must produce different addresses on BTC and
      // LTC — that's the whole point of the SLIP-0044 split. If they
      // collide we'd be putting LTC and BTC on the same private key,
      // which is a privacy + accounting disaster.
      final btc = deriveBitcoinAddress(
          mnemonic: abandonAbout, addressIndex: 0, params: kBtcMainnet);
      final ltc = deriveBitcoinAddress(
          mnemonic: abandonAbout, addressIndex: 0, params: kLtcMainnet);
      expect(btc.address, isNot(equals(ltc.address)));
      expect(btc.address.startsWith('bc1q'), isTrue);
      expect(ltc.address.startsWith('ltc1q'), isTrue);
    });

    test('decodeP2WPKHAddress rejects Bitcoin address against LTC params',
        () {
      final btc = deriveBitcoinAddress(
          mnemonic: abandonAbout, addressIndex: 0, params: kBtcMainnet);
      expect(
        () => decodeP2WPKHAddress(btc.address, params: kLtcMainnet),
        throwsA(isA<FormatException>()),
      );
    });

    test('signing path produces a valid-shape signed transaction', () {
      final spending = deriveBitcoinSpendingKey(
        mnemonic: abandonAbout,
        addressIndex: 0,
        params: kLtcMainnet,
      );
      final changeKey = deriveBitcoinSpendingKey(
        mnemonic: abandonAbout,
        addressIndex: 1,
        params: kLtcMainnet,
      );
      final utxo = Utxo(
        txid:
            'a1075db55d416d3ca199f55b6084e2115b9345e16c5cf302fc80e9d5fbf5d48d',
        vout: 0,
        valueSat: 100000,
        address: spending.address,
        confirmed: true,
      );
      // Send 0.0005 LTC to another ltc1q address. Reuse the change
      // address as a sanity destination — invalid use in real life
      // (sending to yourself) but the builder doesn't care.
      final built = buildAndSignP2WPKH(
        inputs: [utxo],
        signers: {spending.address: spending},
        destAddress: changeKey.address,
        amountSat: 50000,
        changeAddress: changeKey.address,
        feeRateSatPerVByte: 5,
        params: kLtcMainnet,
      );
      expect(built.recipientSat, 50000);
      expect(built.feeSat, greaterThan(0));
      expect(built.virtualSize, greaterThan(100));
      expect(built.rawHex.length % 2, 0);
    });
  });
}
