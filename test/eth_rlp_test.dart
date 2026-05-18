// RLP encoding tests against canonical vectors from the Ethereum
// Yellow Paper appendix B and BIP-style spec docs. A wrong RLP
// encoding means every transaction we produce has the wrong hash,
// which means signatures don't verify and the network rejects the
// tx — so this test pulls the keystone.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:peek_wallet/coins/ethereum/rlp.dart';

String _toHex(Uint8List b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

void main() {
  group('RLP encoding canonical vectors', () {
    test('empty string encodes to 0x80', () {
      expect(_toHex(rlpEncode(Uint8List(0))), '80');
    });

    test('single byte 0x00 encodes to itself', () {
      expect(_toHex(rlpEncode(Uint8List.fromList([0x00]))), '00');
    });

    test('single byte 0x7f encodes to itself', () {
      expect(_toHex(rlpEncode(Uint8List.fromList([0x7f]))), '7f');
    });

    test('single byte 0x80 encodes to 0x8180 (becomes length-prefixed)', () {
      expect(_toHex(rlpEncode(Uint8List.fromList([0x80]))), '8180');
    });

    test('string "dog" encodes to 83646f67', () {
      // Yellow paper example
      expect(_toHex(rlpEncode('dog')), '83646f67');
    });

    test('empty list encodes to 0xc0', () {
      expect(_toHex(rlpEncode(<dynamic>[])), 'c0');
    });

    test('list ["cat", "dog"] encodes to c88363617483646f67', () {
      // Yellow paper example
      expect(_toHex(rlpEncode(<dynamic>['cat', 'dog'])),
          'c88363617483646f67');
    });

    test('integer 0 encodes to 0x80 (empty)', () {
      expect(_toHex(rlpEncode(0)), '80');
      expect(_toHex(rlpEncode(BigInt.zero)), '80');
    });

    test('integer 15 encodes to 0x0f', () {
      // Single byte < 0x80: encoded as itself.
      expect(_toHex(rlpEncode(15)), '0f');
    });

    test('integer 1024 encodes to 0x820400', () {
      // Multi-byte: length-prefixed.
      expect(_toHex(rlpEncode(1024)), '820400');
    });

    test('long string (length 56) takes the >55 path', () {
      final fiftySixZeros = Uint8List(56);
      final encoded = _toHex(rlpEncode(fiftySixZeros));
      // 0xb8 = 0xb7 + 1 (one length byte) followed by 0x38 (56) then 56 zeroes
      expect(encoded.startsWith('b838'), isTrue);
      expect(encoded.length, 2 + 2 + 56 * 2);
    });

    test('canonical integer encoding: no leading zeros', () {
      // BigInt 256 must encode as 8201 00 (2-byte payload "0100"),
      // not 8200 01 00 (which would be wrong — leading zero forbidden).
      expect(_toHex(rlpEncode(256)), '820100');
    });

    test('negative integer rejected', () {
      expect(() => rlpEncode(-1), throwsArgumentError);
    });

    test('nested lists', () {
      // [[], [[]], [ [], [[]] ]] from the yellow paper. Total 7 bytes:
      //   c7  c0  c1c0  c3c0c1c0
      final v = <dynamic>[
        <dynamic>[],
        <dynamic>[<dynamic>[]],
        <dynamic>[<dynamic>[], <dynamic>[<dynamic>[]]],
      ];
      expect(_toHex(rlpEncode(v)), 'c7c0c1c0c3c0c1c0');
    });
  });
}
