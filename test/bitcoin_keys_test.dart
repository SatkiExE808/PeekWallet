import 'package:flutter_test/flutter_test.dart';
import 'package:peek_wallet/coins/bitcoin/bitcoin_keys.dart';

/// BIP84 test vector from the BIP-0084 specification:
///   https://github.com/bitcoin/bips/blob/master/bip-0084.mediawiki
/// Seed: "abandon abandon abandon abandon abandon abandon
///        abandon abandon abandon abandon abandon about"
///   Account 0, external index 0  →  bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu
///   Account 0, external index 1  →  bc1qnjg0jd8228aq7egyzacy8cys3knf9xvrerkf9g
///   Account 0, change index 0    →  bc1q8c6fshw2dlwun7ekn9qwf37cu2rn755upcp6el
///
/// Same BIP39 phrase, same algorithm — if our derivation produces
/// these addresses, our derivation matches every other BIP84 wallet
/// in existence.
void main() {
  const phrase = 'abandon abandon abandon abandon abandon abandon '
      'abandon abandon abandon abandon abandon about';

  group('BIP-0084 spec vectors', () {
    test('account 0, receive 0', () {
      final d = deriveBitcoinAddress(mnemonic: phrase);
      expect(d.address, 'bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu');
      expect(d.path, "m/84'/0'/0'/0/0");
      expect(d.publicKey.length, 33);
    });

    test('account 0, receive 1', () {
      final d = deriveBitcoinAddress(mnemonic: phrase, addressIndex: 1);
      expect(d.address, 'bc1qnjg0jd8228aq7egyzacy8cys3knf9xvrerkf9g');
    });

    test('account 0, change 0', () {
      final d = deriveBitcoinAddress(mnemonic: phrase, change: true);
      expect(d.address, 'bc1q8c6fshw2dlwun7ekn9qwf37cu2rn755upcp6el');
    });
  });

  group('shape', () {
    test('addresses are bech32 with bc1q prefix', () {
      final d = deriveBitcoinAddress(mnemonic: phrase);
      expect(d.address.startsWith('bc1q'), isTrue);
      expect(d.address.length, lessThanOrEqualTo(62));
    });

    test('different indices yield different addresses', () {
      final a = deriveBitcoinAddress(mnemonic: phrase, addressIndex: 0);
      final b = deriveBitcoinAddress(mnemonic: phrase, addressIndex: 1);
      final c = deriveBitcoinAddress(mnemonic: phrase, addressIndex: 2);
      expect({a.address, b.address, c.address}.length, 3);
    });

    test('passphrase changes the derived address', () {
      final none = deriveBitcoinAddress(mnemonic: phrase);
      final withPp = deriveBitcoinAddress(mnemonic: phrase, passphrase: 'x');
      expect(withPp.address, isNot(none.address));
    });

    test('deterministic across calls', () {
      final a = deriveBitcoinAddress(mnemonic: phrase);
      final b = deriveBitcoinAddress(mnemonic: phrase);
      expect(a.address, b.address);
      expect(a.publicKey, b.publicKey);
    });
  });
}
