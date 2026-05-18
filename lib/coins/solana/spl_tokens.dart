// SPL token catalog for Solana.
//
// SPL tokens on Solana are conceptually similar to ERC-20 / TRC-20
// but the on-chain mechanics differ enough that they need their
// own code path:
//   - Tokens are "minted" via a separate account (the "mint
//     account") identified by a base58 pubkey.
//   - A user holding a token has an "associated token account" (ATA)
//     derived deterministically from (owner, mint) via a PDA.
//   - To read balances we ask the RPC for token accounts owned by
//     this wallet that match the mint we care about.
//   - To send we'd build a Token Program transfer instruction that
//     debits the user's ATA and credits the recipient's — plus
//     possibly create the recipient's ATA if it doesn't exist yet.
//
// This first commit covers READ only. Send is a follow-up.

class SplToken {
  const SplToken({
    required this.symbol,
    required this.name,
    required this.mint,
    required this.decimals,
  });

  final String symbol;
  final String name;
  /// Base58 SPL mint address. The "contract address" of the token.
  final String mint;
  final int decimals;
}

/// Canonical SPL tokens we surface by default. USDC and USDT are
/// the dominant stablecoins on Solana — Circle's official USDC and
/// Tether's bridged USDT-SPL. Users could add more via a future
/// custom-token flow.
const List<SplToken> kDefaultSplTokens = <SplToken>[
  SplToken(
    symbol: 'USDC',
    name: 'USD Coin (SPL)',
    mint: 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v',
    decimals: 6,
  ),
  SplToken(
    symbol: 'USDT',
    name: 'Tether USD (SPL)',
    mint: 'Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB',
    decimals: 6,
  ),
];
