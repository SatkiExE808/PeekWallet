import 'coin.dart';
import 'monero/monero_coin.dart';

/// Single source of truth for which coins the wallet supports.
/// New coins go here; the Wallets screen iterates this list.
const List<Coin> kCoins = [
  MoneroCoin(),
  // BTC, ETH, LTC, SOL, TRX, BCH, MATIC etc. land here as they're
  // implemented. Order = display order on the Wallets tab.
];
