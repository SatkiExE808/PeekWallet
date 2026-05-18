// CashAddr encoding tests against the canonical spec vectors from
// https://github.com/bitcoincashorg/bitcoincash.org/blob/master/spec/cashaddr.md
//
// A wrong CashAddr encoder means every BCH address we generate
// either fails to validate against a wallet doing the encoding
// correctly, or worse, validates as a different address — sending
// to whoever DID hash to that other value. Pull the spec-vector
// keystone first.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:peek_wallet/coins/bitcoin_cash/cashaddr.dart';

Uint8List _hex(String s) {
  final out = Uint8List(s.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(s.substring(2 * i, 2 * i + 2), radix: 16);
  }
  return out;
}

void main() {
  group('CashAddr spec vectors', () {
    // Canonical example:
    //   hash160 76a04053bda0a88bda5177b86a15c3b29f559873 (P2PKH)
    //   = legacy P2PKH address 1BpEi6DfDAUFd7GtittLSdBeYJvcoaVggu
    //   = cashaddr bitcoincash:qpm2qsznhks23z7629mms6s4cwef74vcwvy22gdx6a
    //
    // (After the colon: 42 base32 chars = 34 payload + 8 checksum,
    //  since a 21-byte payload converts to ceil(168/5) = 34 5-bit
    //  symbols with 2 trailing zero pad bits.)
    test('P2PKH vector for hash 76a04053…', () {
      final out = cashaddrEncode(
        hash160: _hex('76a04053bda0a88bda5177b86a15c3b29f559873'),
        type: CashAddrType.p2pkh,
      );
      expect(out, 'bitcoincash:qpm2qsznhks23z7629mms6s4cwef74vcwvy22gdx6a');
    });

    test('P2SH variant: same hash, different version → different address', () {
      final p2pkh = cashaddrEncode(
        hash160: _hex('76a04053bda0a88bda5177b86a15c3b29f559873'),
        type: CashAddrType.p2pkh,
      );
      final p2sh = cashaddrEncode(
        hash160: _hex('76a04053bda0a88bda5177b86a15c3b29f559873'),
        type: CashAddrType.p2sh,
      );
      expect(p2sh, isNot(equals(p2pkh)));
      // Round-trip to confirm we tagged the variants correctly.
      expect(cashaddrDecode(p2pkh)?.type, CashAddrType.p2pkh);
      expect(cashaddrDecode(p2sh)?.type, CashAddrType.p2sh);
    });

    test('rejects non-20-byte payload', () {
      expect(
        () => cashaddrEncode(hash160: Uint8List(19)),
        throwsArgumentError,
      );
      expect(
        () => cashaddrEncode(hash160: Uint8List(32)),
        throwsArgumentError,
      );
    });

    test('encode → decode round-trips', () {
      final orig = _hex('76a04053bda0a88bda5177b86a15c3b29f559873');
      final addr = cashaddrEncode(hash160: orig);
      final decoded = cashaddrDecode(addr);
      expect(decoded, isNotNull);
      expect(decoded!.type, CashAddrType.p2pkh);
      expect(decoded.hash, orig);
    });

    test('decoder rejects bad checksum', () {
      // Twiddle the last character of a valid address. The polymod
      // check should catch the corruption.
      const valid =
          'bitcoincash:qpm2qsznhks23z7629mms6s4cwef74vcwvy22gdx';
      final broken = '${valid.substring(0, valid.length - 1)}q';
      expect(cashaddrDecode(broken), isNull);
    });

    test('decoder rejects wrong prefix', () {
      const wrongPrefix =
          'bchtest:qpm2qsznhks23z7629mms6s4cwef74vcwvy22gdx';
      expect(cashaddrDecode(wrongPrefix), isNull);
    });

    test('decoder accepts uppercase (case-insensitive)', () {
      const upper =
          'BITCOINCASH:QPM2QSZNHKS23Z7629MMS6S4CWEF74VCWVY22GDX6A';
      final decoded = cashaddrDecode(upper);
      expect(decoded, isNotNull);
    });
  });
}
