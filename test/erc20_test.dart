// ERC-20 ABI encoding tests. The Solidity ABI is well-specified —
// these tests pin the per-function output against the documented
// layout so a regression in the encoder surfaces in CI.

import 'package:flutter_test/flutter_test.dart';
import 'package:peek_wallet/coins/ethereum/erc20.dart';

void main() {
  group('ERC-20 ABI encoding', () {
    test('balanceOf produces 4-byte selector + 32-byte padded address',
        () {
      // Vitalik's well-known address. balanceOf(vitalik) on USDT
      // would use this data payload in eth_call.
      final data = encodeBalanceOfCall(
          '0xd8da6bf26964af9d7eed9e03e53415d37aa96045');
      // 0x + 8 hex selector + 64 hex address = 74 chars
      expect(data.length, 74);
      expect(data.startsWith('0x70a08231'), isTrue,
          reason: 'must start with balanceOf selector');
      // 12 zero bytes (24 hex zeros) of address padding
      expect(data.substring(10, 34),
          '000000000000000000000000');
      // Then the 20-byte address (lowercased).
      expect(data.substring(34),
          'd8da6bf26964af9d7eed9e03e53415d37aa96045');
    });

    test('transfer encodes selector + to + uint256 amount', () {
      // Send 1 USDT (= 1_000_000 base units; USDT has 6 decimals).
      final data = encodeTransferCall(
        to0xAddress: '0xd8da6bf26964af9d7eed9e03e53415d37aa96045',
        amountBaseUnits: BigInt.from(1000000),
      );
      // 0x + 8 selector + 64 address + 64 amount = 138 chars
      expect(data.length, 138);
      expect(data.startsWith('0xa9059cbb'), isTrue,
          reason: 'must start with transfer selector');
      // Amount is 0xf4240 = 1,000,000, left-padded to 32 bytes.
      expect(data.substring(74),
          '00000000000000000000000000000000000000000000000000000000000f4240');
    });

    test('accepts unprefixed address', () {
      final a = encodeBalanceOfCall(
          'd8da6bf26964af9d7eed9e03e53415d37aa96045');
      final b = encodeBalanceOfCall(
          '0xd8da6bf26964af9d7eed9e03e53415d37aa96045');
      expect(a, b);
    });

    test('rejects malformed address', () {
      expect(
        () => encodeBalanceOfCall('0xshort'),
        throwsA(isA<FormatException>()),
      );
    });

    test('decodeUint256 round-trips encoded balances', () {
      // A common USDT balance: 12,345 USDT = 12345 * 10^6 base units.
      // Encoded by an RPC node it'd be a 0x-prefixed 32-byte hex.
      const result =
          '0x0000000000000000000000000000000000000000000000000000000002cad9c0';
      // 0x02cad9c0 = 46,848,448 base units (the actual decimal value
      // of the encoded hex — my arithmetic, not USDT-specific).
      expect(decodeUint256(result), BigInt.from(46848448));
    });

    test('decodeUint256 handles short or zero results', () {
      expect(decodeUint256('0x0'), BigInt.zero);
      expect(decodeUint256('0x'), BigInt.zero);
      expect(decodeUint256(
              '0x0000000000000000000000000000000000000000000000000000000000000000'),
          BigInt.zero);
    });
  });
}
