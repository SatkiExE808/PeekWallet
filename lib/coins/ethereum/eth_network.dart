/// EVM-compatible network parameters. Ethereum mainnet, Polygon,
/// Arbitrum, Optimism, BSC — all use the same EIP-1559 transaction
/// format, the same BIP44 derivation path family (just different
/// chain IDs in the tx envelope), and the same secp256k1 + Keccak-256
/// crypto. The only things that differ per-network:
///
///   - chainId (1 for ETH, 137 for Polygon, etc.) — baked into the
///     EIP-1559 signing hash for replay protection
///   - bech32 / display ticker (ETH vs MATIC vs BNB)
///   - block explorer endpoint (etherscan, polygonscan, …) — we use
///     the Blockscout instance when available
///   - default RPC endpoint
///   - SLIP-0044 coin_type used in the BIP44 path (60 for ETH, 966
///     for Polygon, etc.) — BUT in practice most wallets use
///     coinType=60 for every EVM chain because the account-based
///     model means a single key can hold balances on every EVM chain
///     simultaneously. We follow the MetaMask convention here.
class EthereumNetwork {
  const EthereumNetwork({
    required this.id,
    required this.symbol,
    required this.name,
    required this.chainId,
    required this.blockscoutBaseUrl,
    required this.rpcUrl,
    this.fallbackRpcUrls = const [],
    this.fallbackBlockscoutUrls = const [],
    this.coinType = 60,
  });

  final String id;
  final String symbol;
  final String name;
  /// EIP-155 chain id. Mainnet ETH = 1, Polygon = 137, etc.
  final int chainId;
  /// Blockscout-compatible REST base URL for balance + tx history.
  final String blockscoutBaseUrl;
  /// JSON-RPC endpoint for send-path operations (nonce, gas, broadcast).
  final String rpcUrl;
  /// Additional no-auth JSON-RPC endpoints tried in order when [rpcUrl]
  /// or earlier fallbacks return 5xx, time out, or are unreachable.
  /// Same JSON-RPC API; just a different provider.
  final List<String> fallbackRpcUrls;
  /// Additional Blockscout-compatible base URLs tried on transient
  /// failure of [blockscoutBaseUrl]. Some Blockscout instances cache
  /// differently or are temporarily down — list a couple of well-
  /// known mirrors so balance/history stays live.
  final List<String> fallbackBlockscoutUrls;
  /// SLIP-0044 coin_type. 60 for almost every EVM chain by convention.
  final int coinType;

  /// Primary + fallback RPCs as a single ordered list.
  List<String> get allRpcUrls => [rpcUrl, ...fallbackRpcUrls];

  /// Primary + fallback explorers as a single ordered list.
  List<String> get allBlockscoutUrls =>
      [blockscoutBaseUrl, ...fallbackBlockscoutUrls];
}

const kEthMainnet = EthereumNetwork(
  id: 'ETH',
  symbol: 'ETH',
  name: 'Ethereum',
  chainId: 1,
  blockscoutBaseUrl: 'https://eth.blockscout.com/api',
  rpcUrl: 'https://eth.llamarpc.com',
  fallbackRpcUrls: [
    'https://cloudflare-eth.com',
    'https://ethereum-rpc.publicnode.com',
    'https://rpc.ankr.com/eth',
  ],
  fallbackBlockscoutUrls: [
    'https://api.etherscan.io/api',
  ],
);

const kPolygonMainnet = EthereumNetwork(
  id: 'MATIC',
  symbol: 'MATIC',
  name: 'Polygon',
  chainId: 137,
  blockscoutBaseUrl: 'https://polygon.blockscout.com/api',
  rpcUrl: 'https://polygon-rpc.com',
  fallbackRpcUrls: [
    'https://polygon-bor-rpc.publicnode.com',
    'https://rpc.ankr.com/polygon',
    'https://polygon.llamarpc.com',
  ],
  fallbackBlockscoutUrls: [
    'https://api.polygonscan.com/api',
  ],
);
