/// Parameters that distinguish UTXO-based, BIP143-signing chains.
///
/// Bitcoin and Litecoin share the entire transaction format (BIP141
/// SegWit, BIP143 sighash, P2WPKH script template). They differ only
/// in three places — the bech32 HRP, the SLIP-0044 coin_type used in
/// the BIP84 derivation path, and the block-explorer endpoint we hit
/// for UTXOs and history.
///
/// Capturing those three things here lets every layer above
/// (derivation, address parsing, mempool client, wallet open) take a
/// single [BitcoinChainParams] argument instead of growing parallel
/// LTC-specific copies of every function.
///
/// New BIP143-style chains (Bitcoin Cash hypothetical, Dogecoin if
/// we ever care) would be one more constant here.
class BitcoinChainParams {
  const BitcoinChainParams({
    required this.id,
    required this.symbol,
    required this.name,
    required this.bech32Hrp,
    required this.coinType,
    required this.mempoolBaseUrl,
  });

  /// Stable identifier used in the wallet store and CoinModule registry
  /// (e.g. "BTC", "LTC"). Same as the public symbol for simplicity.
  final String id;
  final String symbol;
  final String name;
  /// HRP for native SegWit addresses: "bc" for mainnet Bitcoin, "ltc"
  /// for mainnet Litecoin. Determines what addresses look like
  /// (bc1q… vs ltc1q…) and validates incoming sends.
  final String bech32Hrp;
  /// SLIP-0044 coin_type, used as the second hardened component of
  /// the BIP84 derivation path m/84'/{coinType}'/0'/{0,1}/{index}.
  /// 0 for Bitcoin, 2 for Litecoin.
  final int coinType;
  /// REST base URL of the chain's mempool-space-compatible explorer.
  /// mempool.space serves Bitcoin; litecoinspace.org runs the same
  /// software for Litecoin so the API surface is identical.
  final String mempoolBaseUrl;
}

const kBtcMainnet = BitcoinChainParams(
  id: 'BTC',
  symbol: 'BTC',
  name: 'Bitcoin',
  bech32Hrp: 'bc',
  coinType: 0,
  mempoolBaseUrl: 'https://mempool.space/api',
);

const kLtcMainnet = BitcoinChainParams(
  id: 'LTC',
  symbol: 'LTC',
  name: 'Litecoin',
  bech32Hrp: 'ltc',
  coinType: 2,
  mempoolBaseUrl: 'https://litecoinspace.org/api',
);
