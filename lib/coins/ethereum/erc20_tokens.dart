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
  // Stablecoins first — most-used on Polygon.
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
  // Major non-stable tokens commonly bridged to Polygon. Users can
  // always remove them — surfacing zero-balance entries is filtered
  // out by the coin screen anyway, so these only show up after the
  // user has actually received some.
  Erc20Token(
    symbol: 'WMATIC',
    name: 'Wrapped MATIC',
    contract: '0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270',
    decimals: 18,
    chainId: 137,
  ),
  Erc20Token(
    symbol: 'WETH',
    name: 'Wrapped Ether (PoS)',
    contract: '0x7ceb23fd6bc0add59e62ac25578270cff1b9f619',
    decimals: 18,
    chainId: 137,
  ),
  Erc20Token(
    symbol: 'LINK',
    name: 'Chainlink (PoS)',
    contract: '0x53e0bca35ec356bd5dddfebbd1fc0fd03fabad39',
    decimals: 18,
    chainId: 137,
  ),
  Erc20Token(
    symbol: 'AAVE',
    name: 'Aave (PoS)',
    contract: '0xd6df932a45c0f255f85145f286ea0b292b21c90b',
    decimals: 18,
    chainId: 137,
  ),
];

/// Default tokens for one chain.
List<Erc20Token> defaultTokensFor(int chainId) =>
    kDefaultTokens.where((t) => t.chainId == chainId).toList();
