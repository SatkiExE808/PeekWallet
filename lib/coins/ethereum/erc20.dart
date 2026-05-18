// Minimal ABI encoding for the two ERC-20 functions we care about:
// balanceOf(address) and transfer(address, uint256).
//
// Function selectors are the first 4 bytes of keccak256(signature),
// pre-computed here so we don't depend on Keccak at every call.
//
// Argument layout (per the Solidity ABI spec):
//   - address: 32 bytes, left-padded with 12 zero bytes
//   - uint256: 32 bytes, big-endian unsigned
//
// To call a contract function, the eth_call / tx data is:
//   selector(4) || arg_0(32) || arg_1(32) || ...
//
// Tested implicitly through the round-trip on integrationy paths;
// the function selector constants are verified by hand against
// keccak256 outputs.

import 'dart:typed_data';

/// keccak256("balanceOf(address)")[0:4] = 70a08231
const String selectorBalanceOf = '70a08231';

/// keccak256("transfer(address,uint256)")[0:4] = a9059cbb
const String selectorTransfer = 'a9059cbb';

/// keccak256("decimals()")[0:4] = 313ce567
const String selectorDecimals = '313ce567';

/// keccak256("symbol()")[0:4] = 95d89b41
const String selectorSymbol = '95d89b41';

/// Build the `data` payload for an ERC-20 balanceOf call.
/// Returns a 0x-prefixed hex string ready for eth_call.
String encodeBalanceOfCall(String owner0xAddress) {
  final addrBytes = _parseAddress(owner0xAddress);
  return '0x$selectorBalanceOf${_padAddress(addrBytes)}';
}

/// Build the `data` payload for an ERC-20 transfer call.
String encodeTransferCall({
  required String to0xAddress,
  required BigInt amountBaseUnits,
}) {
  final addrBytes = _parseAddress(to0xAddress);
  return '0x$selectorTransfer${_padAddress(addrBytes)}${_padUint256(amountBaseUnits)}';
}

/// Decode the result of a balanceOf eth_call (a hex-encoded uint256).
/// Returns BigInt.zero for an empty/zero result.
BigInt decodeUint256(String hexResult) {
  var clean = hexResult.startsWith('0x') ? hexResult.substring(2) : hexResult;
  if (clean.isEmpty || RegExp(r'^0+$').hasMatch(clean)) {
    return BigInt.zero;
  }
  return BigInt.parse(clean, radix: 16);
}

/// Decode the raw bytes of an eth_call result. Used by [decodeUint256]
/// and could be extended for string returns (which use a different
/// dynamic-type layout).
Uint8List decodeBytes(String hexResult) {
  final clean = hexResult.startsWith('0x') ? hexResult.substring(2) : hexResult;
  if (clean.length.isOdd) {
    throw FormatException('Odd-length hex string: $hexResult');
  }
  final out = Uint8List(clean.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(clean.substring(2 * i, 2 * i + 2), radix: 16);
  }
  return out;
}

Uint8List _parseAddress(String s) {
  var trimmed = s.startsWith('0x') || s.startsWith('0X')
      ? s.substring(2)
      : s;
  if (trimmed.length != 40) {
    throw FormatException(
        'Ethereum address must be 40 hex chars, got ${trimmed.length}');
  }
  final out = Uint8List(20);
  for (var i = 0; i < 20; i++) {
    out[i] = int.parse(trimmed.substring(2 * i, 2 * i + 2), radix: 16);
  }
  return out;
}

/// Left-pad a 20-byte address with 12 zero bytes to make a 32-byte
/// ABI-encoded address.
String _padAddress(Uint8List addr20) {
  final sb = StringBuffer();
  // 12 leading zero bytes = 24 hex zeros.
  for (var i = 0; i < 24; i++) {
    sb.write('0');
  }
  for (final b in addr20) {
    sb.write(b.toRadixString(16).padLeft(2, '0'));
  }
  return sb.toString();
}

/// Encode an unsigned integer as a 32-byte big-endian ABI uint256.
String _padUint256(BigInt n) {
  if (n < BigInt.zero) {
    throw ArgumentError('uint256 cannot be negative');
  }
  final hex = n.toRadixString(16);
  return hex.padLeft(64, '0');
}
