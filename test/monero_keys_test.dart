import 'package:flutter_test/flutter_test.dart';
import 'package:peek_wallet/coins/monero/monero_keys.dart';

void main() {
  // Fixed BIP39 phrase from the BIP39 spec ('abandon ... about') so the
  // test is deterministic and doesn't leak any real wallet.
  const phrase = 'abandon abandon abandon abandon abandon abandon '
      'abandon abandon abandon abandon abandon about';

  test('derive primary address from a known BIP39 phrase', () {
    final keys = deriveMoneroKeys(phrase);

    // Mainnet primary addresses start with '4' and are 95 chars long.
    expect(keys.primaryAddress.length, 95);
    expect(keys.primaryAddress.startsWith('4'), isTrue);

    // Spend / view keys are 32 bytes (64 hex chars).
    expect(keys.privateSpendHex.length, 64);
    expect(keys.privateViewHex.length, 64);
    expect(keys.privateSpendKey.length, 32);
    expect(keys.privateViewKey.length, 32);
  });

  test('derive deterministic primary address across calls', () {
    final a = deriveMoneroKeys(phrase).primaryAddress;
    final b = deriveMoneroKeys(phrase).primaryAddress;
    expect(a, b);
  });

  test('subaddress(0, 0) equals primary', () {
    final primary = deriveMoneroKeys(phrase).primaryAddress;
    final sub00 = deriveMoneroSubaddress(phrase, 0, 0);
    expect(sub00, primary);
  });

  test('subaddress(0, 1) is a real subaddress (8-prefix)', () {
    final sub = deriveMoneroSubaddress(phrase, 0, 1);
    // Mainnet subaddresses begin with '8' and are 95 chars long.
    expect(sub.length, 95);
    expect(sub.startsWith('8'), isTrue);
  });
}
