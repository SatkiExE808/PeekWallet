// TRC-20 ABI + token catalog for Tron.
//
// TRC-20 is functionally the same as ERC-20 — same Solidity ABI
// shape, same function selectors. The differences are at the RPC
// envelope layer:
//   - addresses on Tron are hex with a 0x41 prefix, not 0x
//   - reads go through TronGrid's wallet/triggerconstantcontract,
//     not eth_call
//   - writes need a protobuf-encoded Transaction with a recent
//     block reference — substantially more complex than EIP-1559,
//     out of scope for the receive-only first commit.
//
// For sends in a follow-up, the cleanest path is going via the
// hosted /wallet/triggersmartcontract endpoint to BUILD the tx
// (returns the wire bytes), then sign the resulting raw_data_hex
// locally and broadcast. That avoids the protobuf encoder dep
// while still keeping signing on-device.

/// One TRC-20 token's static identity. Mirrors Erc20Token closely
/// — the only reason these aren't the same class is the address
/// format differs (base58 T-addresses vs 0x hex), so unifying would
/// add per-field "which kind of address" branching that's not
/// worth the deduplication.
class Trc20Token {
  const Trc20Token({
    required this.symbol,
    required this.name,
    required this.contract,
    required this.decimals,
  });

  final String symbol;
  final String name;
  /// Base58 T-prefixed contract address (the form block explorers
  /// and other wallets display).
  final String contract;
  final int decimals;
}

/// Canonical TRC-20 tokens we surface by default. USDT is by far
/// the most-used asset on Tron (greater volume than native TRX),
/// especially in Asian retail flow. USDC also has growing share.
/// Users can add more by contract address in a future Settings flow.
const List<Trc20Token> kDefaultTrc20Tokens = <Trc20Token>[
  Trc20Token(
    symbol: 'USDT',
    name: 'Tether USD (TRC-20)',
    contract: 'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t',
    decimals: 6,
  ),
  Trc20Token(
    symbol: 'USDC',
    name: 'USD Coin (TRC-20)',
    contract: 'TEkxiTehnzSmSe2XqrBj4w32RUN966rdz8',
    decimals: 6,
  ),
];

/// Encode a balanceOf(address) call's `parameter` for TronGrid's
/// triggerconstantcontract. The function selector itself isn't
/// included here — TronGrid takes it as a separate JSON field
/// ("function_selector").
///
/// The Solidity ABI for `balanceOf(address)`:
///   address arg: 32 bytes, left-padded with 12 zero bytes.
///
/// We accept either base58 (T...) or hex (41...) input forms. The
/// hex form gets the leading "41" byte STRIPPED — TronGrid expects
/// the raw 20-byte hash, no network prefix.
String encodeTrc20BalanceOfParameter(String ownerHexOrBase58) {
  final hex = _normalizeAddress(ownerHexOrBase58);
  // Skip the 41 prefix byte (2 hex chars), pad the 20-byte hash to
  // 32 bytes left.
  final addr20 = hex.substring(2);
  return '${'0' * 24}$addr20';
}

/// Normalize whatever form the caller has to the standard "41…" hex.
/// Base58 is decoded via the existing base58 decoder; hex is just
/// validated to start with 41.
String _normalizeAddress(String input) {
  if (input.startsWith('T')) {
    final decoded = _base58Decode(input);
    if (decoded == null || decoded.length < 21) {
      throw FormatException('Invalid Tron base58 address: $input');
    }
    // strip the 4-byte checksum
    final payload = decoded.sublist(0, decoded.length - 4);
    return payload.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
  final clean = input.toLowerCase();
  if (!clean.startsWith('41') || clean.length != 42) {
    throw FormatException('Invalid Tron hex address: $input');
  }
  return clean;
}

/// Local base58 decode (Bitcoin alphabet) — copied here so this
/// module is self-contained for the Tron RPC layer.
List<int>? _base58Decode(String s) {
  if (s.isEmpty) return [];
  const alphabet =
      '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  var n = BigInt.zero;
  final big58 = BigInt.from(58);
  for (final ch in s.runes) {
    final idx = alphabet.indexOf(String.fromCharCode(ch));
    if (idx < 0) return null;
    n = n * big58 + BigInt.from(idx);
  }
  final tmp = <int>[];
  while (n > BigInt.zero) {
    tmp.add((n % BigInt.from(256)).toInt());
    n = n ~/ BigInt.from(256);
  }
  var leadingOnes = 0;
  for (var i = 0; i < s.length && s[i] == '1'; i++) {
    leadingOnes++;
  }
  final out = List<int>.filled(leadingOnes + tmp.length, 0);
  for (var i = 0; i < tmp.length; i++) {
    out[leadingOnes + i] = tmp[tmp.length - 1 - i];
  }
  return out;
}

/// Decode a TronGrid triggerconstantcontract result. The endpoint
/// returns `constant_result: [hexUint256, …]` — we take the first
/// entry and parse it as a 256-bit unsigned. Returns 0 on empty
/// (which happens for fresh-funded contracts before the index has
/// caught up).
BigInt decodeTrc20Uint256(String hexResult) {
  final clean =
      hexResult.startsWith('0x') ? hexResult.substring(2) : hexResult;
  if (clean.isEmpty || RegExp(r'^0+$').hasMatch(clean)) {
    return BigInt.zero;
  }
  return BigInt.parse(clean, radix: 16);
}
