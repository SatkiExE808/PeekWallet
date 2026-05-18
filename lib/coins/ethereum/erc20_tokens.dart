/// One ERC-20 token's static identity. We pre-populate the well-
/// known tokens (USDT, USDC, DAI) on each supported chain so users
/// don't have to paste contract addresses.
///
/// Decimals matters: USDT and USDC have 6 decimals, DAI has 18.
/// Display logic divides the raw balance by 10^decimals.
class Erc20Token {
  const Erc20Token({
    required this.symbol,
    required this.name,
    required this.contract,
    required this.decimals,
    required this.chainId,
  });

  final String symbol;
  final String name;
  /// 0x-prefixed contract address. LOWERCASE — eth_call accepts
  /// either case, but lowercase prevents accidental EIP-55 mismatch
  /// when comparing to addresses we derive ourselves.
  final String contract;
  final int decimals;
  /// EIP-155 chain id this token lives on (1 for ETH mainnet,
  /// 137 for Polygon).
  final int chainId;
}

/// Default token list, one entry per (token, chain) tuple. Users
/// could in the future add custom tokens by contract address; this
/// hard-coded list covers the 95% case.
const List<Erc20Token> kDefaultTokens = <Erc20Token>[
  // ── Ethereum mainnet ──────────────────────────────────────────
  Erc20Token(
    symbol: 'USDT',
    name: 'Tether USD',
    contract: '0xdac17f958d2ee523a2206206994597c13d831ec7',
    decimals: 6,
    chainId: 1,
  ),
  Erc20Token(
    symbol: 'USDC',
    name: 'USD Coin',
    contract: '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48',
    decimals: 6,
    chainId: 1,
  ),
  Erc20Token(
    symbol: 'DAI',
    name: 'Dai Stablecoin',
    contract: '0x6b175474e89094c44da98b954eedeac495271d0f',
    decimals: 18,
    chainId: 1,
  ),
  // ── Polygon ───────────────────────────────────────────────────
  Erc20Token(
    symbol: 'USDT',
    name: 'Tether USD (PoS)',
    contract: '0xc2132d05d31c914a87c6611c10748aeb04b58e8f',
    decimals: 6,
    chainId: 137,
  ),
  Erc20Token(
    symbol: 'USDC',
    name: 'USD Coin (PoS)',
    contract: '0x3c499c542cef5e3811e1192ce70d8cc03d5c3359',
    decimals: 6,
    chainId: 137,
  ),
  Erc20Token(
    symbol: 'DAI',
    name: 'Dai (PoS)',
    contract: '0x8f3cf7ad23cd3cadbd9735aff958023239c6a063',
    decimals: 18,
    chainId: 137,
  ),
];

/// Default tokens for one chain.
List<Erc20Token> defaultTokensFor(int chainId) =>
    kDefaultTokens.where((t) => t.chainId == chainId).toList();
