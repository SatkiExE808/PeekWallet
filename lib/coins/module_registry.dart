import 'bitcoin/bitcoin_module.dart';
import 'coin_module.dart';
import 'monero/monero_module.dart';

/// Single source of truth for which coins PeekWallet supports. The
/// Wallets-create flow lists these as options; future coin
/// implementations register here.
///
/// Order = display order in the coin picker.
const List<CoinModule> kCoinModules = <CoinModule>[
  MoneroModule(),
  BitcoinModule(),
  // Ethereum             — pending Sprint 4
  // Litecoin             — pending Sprint 4
  // Solana / Tron / BCH  — pending Sprint 4
];

CoinModule? coinModuleFor(String coinId) {
  for (final m in kCoinModules) {
    if (m.id == coinId) return m;
  }
  return null;
}
