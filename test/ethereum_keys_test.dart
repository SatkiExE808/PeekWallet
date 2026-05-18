// Ethereum address derivation tests against well-known BIP39 + BIP44
// vectors that every Ethereum wallet (MetaMask, Trezor, Ledger Live)
// reproduces from the abandon-about test mnemonic.
//
// Pinning these vectors here means a regression in BIP44 derivation,
// Keccak-256 hashing, or EIP-55 checksumming surfaces in CI rather
// than at the user's wallet "Why doesn't my address match MetaMask?"

import 'package:flutter_test/flutter_test.dart';
import 'package:peek_wallet/coins/ethereum/ethereum_keys.dart';

void main() {
  group('Ethereum address derivation', () {
    const abandonAbout =
        'abandon abandon abandon abandon abandon abandon abandon abandon '
        'abandon abandon abandon about';

    test('index 0 matches MetaMask/Trezor canonical derivation', () {
      final addr = deriveEthereumAddress(
          mnemonic: abandonAbout, addressIndex: 0);
      // This address is what MetaMask shows for the abandon-about
      // mnemonic at the default m/44'/60'/0'/0/0 path. Verified
      // against MetaMask, Trezor Suite, Ledger Live, and various
      // online BIP39 derivation tools.
      expect(addr.addressLower, '0x9858effd232b4033e47d90003d41ec34ecaeda94');
      expect(addr.path, "m/44'/60'/0'/0/0");
    });

    test('index 1 differs from index 0', () {
      final a0 = deriveEthereumAddress(
          mnemonic: abandonAbout, addressIndex: 0);
      final a1 = deriveEthereumAddress(
          mnemonic: abandonAbout, addressIndex: 1);
      expect(a0.address, isNot(equals(a1.address)));
      expect(a1.path, "m/44'/60'/0'/0/1");
    });

    test('passphrase changes the derived address', () {
      final base = deriveEthereumAddress(
          mnemonic: abandonAbout, addressIndex: 0);
      final withPass = deriveEthereumAddress(
        mnemonic: abandonAbout,
        addressIndex: 0,
        passphrase: 'TREZOR',
      );
      expect(base.address, isNot(equals(withPass.address)));
    });

    test('EIP-55 checksum encoding: well-known case for index 0', () {
      final addr = deriveEthereumAddress(
          mnemonic: abandonAbout, addressIndex: 0);
      // EIP-55 mixed-case form for 0x9858effd232b4033e47d90003d41ec34ecaeda94
      // (verified against multiple EIP-55 implementations).
      expect(addr.address, '0x9858EfFD232B4033E47d90003D41EC34EcaEda94');
    });

    test('deterministic: same input yields same address', () {
      final a = deriveEthereumAddress(
          mnemonic: abandonAbout, addressIndex: 0);
      final b = deriveEthereumAddress(
          mnemonic: abandonAbout, addressIndex: 0);
      expect(a.address, b.address);
      expect(a.addressLower, b.addressLower);
    });
  });
}
