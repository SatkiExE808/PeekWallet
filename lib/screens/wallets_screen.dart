import 'package:flutter/material.dart';

import '../coins/bitcoin/bitcoin_wallet.dart';
import '../coins/bitcoin_cash/bch_wallet.dart';
import '../coins/coin.dart';
import '../coins/ethereum/custom_token_store.dart';
import '../coins/ethereum/ethereum_wallet.dart';
import '../coins/module_registry.dart';
import '../coins/solana/solana_wallet.dart';
import '../coins/tron/tron_wallet.dart';
import '../prices/price_feed.dart';
import '../theme.dart';
import '../util/coin_avatar.dart';
import '../vault/vault_state.dart';
import '../wallets/balance_cache.dart';
import '../wallets/wallet_meta.dart';
import '../wallets/wallet_store.dart';
import 'add_wallet/add_wallet_flow.dart';
import 'bch_coin_screen.dart';
import 'bitcoin_coin_screen.dart';
import 'coin_screen.dart';
import 'ethereum_coin_screen.dart';
import 'solana_coin_screen.dart';
import 'tron_coin_screen.dart';

/// Lists every wallet in the WalletStore. Tap a row to open its coin
/// page; tap "+" to add a new wallet via the multi-step flow.
///
/// This replaces the previous "one row per coin" view — the new
/// architecture supports multiple wallets per coin, so the list is
/// per-wallet.
class WalletsScreen extends StatefulWidget {
  const WalletsScreen({super.key});

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen> {
  late Future<List<WalletMeta>> _entries;
  bool _autoLoading = false;

  @override
  void initState() {
    super.initState();
    _entries = WalletStore.I.list();
    WalletStore.I.addListener(_refresh);
    // Rebuild when any wallet pushes a new balance snapshot so the
    // subtitles + portfolio total update live.
    BalanceCache.I.addListener(_refresh);
    // Eagerly fetch balances for any wallet that doesn't have a
    // cached value yet, so the home screen shows real numbers on
    // first launch instead of "—".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeAutoLoadBalances();
    });
  }

  @override
  void dispose() {
    WalletStore.I.removeListener(_refresh);
    BalanceCache.I.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _entries = WalletStore.I.list();
    });
  }

  Future<void> _add() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddWalletFlow()),
    );
    _refresh();
  }

  /// Fetch balances for every wallet that doesn't have a cached
  /// value yet. Each non-XMR coin is one or two HTTP calls; XMR is
  /// skipped (boot is heavy and the user has to open the coin
  /// screen for sync state anyway).
  ///
  /// Triggered automatically on the first frame so users see real
  /// numbers without having to tap each wallet. Also exposed as a
  /// manual "refresh" via the AppBar so the user can force-pull.
  Future<void> _maybeAutoLoadBalances({bool force = false}) async {
    if (_autoLoading) return;
    final entries = await WalletStore.I.list();
    if (entries.isEmpty) return;
    final cache = await BalanceCache.I.all();

    // Pick wallets whose cache entry is stale (or missing) AND that
    // we know how to balance-probe without booting monero_c.
    final targets = entries.where((m) {
      if (m.coinId == 'XMR') return false; // skip — too expensive
      if (!force && cache.containsKey(m.id)) return false;
      return true;
    }).toList();
    if (targets.isEmpty) return;

    final password = VaultState.I.cachedPassword;
    if (password == null) return; // locked — can't decrypt seeds

    setState(() => _autoLoading = true);
    try {
      // Fan out — most chains are independent HTTP. We don't try
      // to limit concurrency because the user has at most a few
      // wallets per chain and the public endpoints handle it fine.
      await Future.wait(targets.map((m) =>
          _probeBalance(m, password).catchError((_) {/* skip */})));
    } finally {
      if (mounted) setState(() => _autoLoading = false);
    }
  }

  /// Open a wallet, fetch its native balance, push to BalanceCache,
  /// then close. The result of [BalanceCache.put] notifies listeners
  /// so the portfolio header + per-row subtitle update live.
  Future<void> _probeBalance(WalletMeta meta, String password) async {
    final decrypted = await WalletStore.I.open(
      walletId: meta.id, password: password);
    final coinMod = coinModuleFor(meta.coinId);
    if (coinMod == null) return;
    final w = await coinMod.open(
      walletId: meta.id,
      format: meta.format,
      seedMaterial: decrypted.seedMaterial,
      walletFilePassword: decrypted.walletFilePassword,
      daemonUri: '', // unused for non-XMR
      restoreHeight: 0,
    );

    String symbol;
    String displayAmount;
    double fiatTokens;
    try {
      switch (meta.coinId) {
        case 'BTC':
        case 'LTC':
          final btc = w as BitcoinWallet;
          final sat = await btc.balanceSat();
          symbol = btc.params.symbol;
          final amount = sat / 100000000.0;
          displayAmount = '${amount.toStringAsFixed(8)} $symbol';
          fiatTokens = amount;
          break;
        case 'ETH':
        case 'MATIC':
          final eth = w as EthereumWallet;
          final wei = await eth.balanceWei();
          symbol = eth.network.symbol;
          final amount = wei.toDouble() / 1e18;
          displayAmount = '${amount.toStringAsFixed(6)} $symbol';
          fiatTokens = amount;
          break;
        case 'SOL':
          final sol = w as SolanaWallet;
          final lamports = await sol.balanceLamports();
          symbol = 'SOL';
          final amount = lamports / 1000000000.0;
          displayAmount = '${amount.toStringAsFixed(6)} SOL';
          fiatTokens = amount;
          break;
        case 'TRX':
          final trx = w as TronWallet;
          final sun = await trx.balanceSun();
          symbol = 'TRX';
          final amount = sun / 1000000.0;
          displayAmount = '${amount.toStringAsFixed(6)} TRX';
          fiatTokens = amount;
          break;
        case 'BCH':
          final bch = w as BitcoinCashWallet;
          final sat = await bch.balanceSat();
          symbol = 'BCH';
          final amount = sat / 100000000.0;
          displayAmount = '${amount.toStringAsFixed(8)} BCH';
          fiatTokens = amount;
          break;
        default:
          return;
      }
      final price = PriceFeed.I.prices[symbol];
      await BalanceCache.I.put(CachedBalance(
        walletId: meta.id,
        symbol: symbol,
        displayAmount: displayAmount,
        fiatValue: price == null ? 0 : fiatTokens * price,
        fiatCurrency: PriceFeed.I.currency,
        updatedAt: DateTime.now(),
      ));
    } finally {
      // Each wallet impl has its own .close() — call dynamically.
      try {
        (w as dynamic).close();
      } catch (_) {/* not all wallets have close */}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallets'),
        actions: [
          IconButton(
            icon: _autoLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: PeekColors.accent),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh balances',
            onPressed: _autoLoading
                ? null
                : () => _maybeAutoLoadBalances(force: true),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add wallet',
            onPressed: _add,
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<WalletMeta>>(
          future: _entries,
          builder: (ctx, snap) {
            if (!snap.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: PeekColors.accent),
              );
            }
            final entries = snap.data!;
            if (entries.isEmpty) {
              return _EmptyState(onAdd: _add);
            }
            return FutureBuilder<Map<String, CachedBalance>>(
              future: BalanceCache.I.all(),
              builder: (ctx, cacheSnap) {
                final cache = cacheSnap.data ?? const {};
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: entries.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return _PortfolioHeader(
                          entries: entries, cache: cache);
                    }
                    final meta = entries[i - 1];
                    final coin = coinModuleFor(meta.coinId);
                    final cached = cache[meta.id];
                    return Card(
                  child: ListTile(
                    leading: coinAvatar(meta.coinId),
                    title: Text(meta.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: cached != null
                        ? Text(
                            '${cached.displayAmount}'
                            '${cached.fiatValue > 0 ? ' · ${_fmtFiat(cached.fiatValue, cached.fiatCurrency)}' : ''}',
                            style: const TextStyle(
                                color: PeekColors.text2, fontSize: 12),
                          )
                        : Text(
                            '${coin?.symbol ?? meta.coinId} · ${meta.format.displayName}',
                            style: const TextStyle(
                                color: PeekColors.text2, fontSize: 12),
                          ),
                    trailing: const Icon(Icons.chevron_right,
                        color: PeekColors.text3),
                    onTap: coin == null
                        ? null
                        : () {
                            late final Widget page;
                            switch (meta.coinId) {
                              case 'BTC':
                              case 'LTC':
                                page = BitcoinCoinScreen(walletMeta: meta);
                                break;
                              case 'ETH':
                              case 'MATIC':
                                page = EthereumCoinScreen(walletMeta: meta);
                                break;
                              case 'SOL':
                                page = SolanaCoinScreen(walletMeta: meta);
                                break;
                              case 'TRX':
                                page = TronCoinScreen(walletMeta: meta);
                                break;
                              case 'BCH':
                                page = BitcoinCashCoinScreen(walletMeta: meta);
                                break;
                              default:
                                page = CoinScreen(
                                  coin: _LegacyCoinAdapter(coin),
                                  walletMeta: meta,
                                );
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => page),
                            );
                          },
                    onLongPress: () => _showWalletMenu(meta),
                  ),
                );
              },
            );
              },
            );
          },
        ),
      ),
    );
  }

  /// Format a fiat value with a leading symbol matching the cached
  /// currency. Most wallets show "$" for USD; we use that-or-the-code
  /// (e.g. "EUR 12.34") for other currencies.
  static String _fmtFiat(double value, String currency) {
    final c = currency.toLowerCase();
    final symbol = switch (c) {
      'usd' => '\$',
      'eur' => '€',
      'gbp' => '£',
      'jpy' => '¥',
      'cny' => '¥',
      'hkd' => 'HK\$',
      _ => '${currency.toUpperCase()} ',
    };
    final digits = (c == 'jpy' || c == 'cny') ? 0 : 2;
    return '≈ $symbol${value.toStringAsFixed(digits)}';
  }

  Future<void> _showWalletMenu(WalletMeta meta) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: PeekColors.bg2,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: PeekColors.text2),
              title: const Text('Rename'),
              onTap: () => Navigator.of(ctx).pop('rename'),
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: PeekColors.red),
              title: const Text('Delete'),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
            ListTile(
              leading: const Icon(Icons.close, color: PeekColors.text3),
              title: const Text('Cancel'),
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
    if (action == 'rename') await _rename(meta);
    if (action == 'delete') await _delete(meta);
  }

  Future<void> _rename(WalletMeta meta) async {
    final controller = TextEditingController(text: meta.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename wallet'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName != null && newName.trim().isNotEmpty) {
      await WalletStore.I.rename(walletId: meta.id, newName: newName);
    }
  }

  Future<void> _delete(WalletMeta meta) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${meta.name}?'),
        content: const Text(
          'The on-chain wallet is not affected — anyone with the seed '
          'can still restore it later. Only this device\'s record is '
          'removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes == true) {
      await WalletStore.I.delete(meta.id);
      // Also drop the cached balance + any custom-token entries so
      // neither dangles after the wallet is gone.
      await BalanceCache.I.forget(meta.id);
      await CustomTokenStore.I.forget(meta.id);
    }
  }
}

/// Header card at the top of the wallets list showing the sum of all
/// cached fiat values. Updates live as the BalanceCache changes (each
/// coin screen pushes after refresh, so opening any wallet refreshes
/// the total).
class _PortfolioHeader extends StatelessWidget {
  const _PortfolioHeader({required this.entries, required this.cache});
  final List<WalletMeta> entries;
  final Map<String, CachedBalance> cache;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: PriceFeed.I,
      builder: (_, _) {
        double total = 0;
        String currency = PriceFeed.I.currency;
        int counted = 0;
        for (final meta in entries) {
          final c = cache[meta.id];
          if (c == null) continue;
          counted++;
          // If the cached entry is in a different fiat than the
          // user's current preference, skip rather than show a wrong
          // total. The number will populate after the next wallet
          // refresh in the new currency.
          if (c.fiatCurrency == currency && c.fiatValue > 0) {
            total += c.fiatValue;
          }
        }
        return Card(
          color: PeekColors.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total portfolio',
                        style: TextStyle(
                            color: PeekColors.text2, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        total > 0
                            ? _WalletsScreenState._fmtFiat(total, currency)
                                .replaceFirst('≈ ', '')
                            : '—',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$counted of ${entries.length}',
                      style: const TextStyle(
                          color: PeekColors.text3, fontSize: 11),
                    ),
                    const Text('wallets cached',
                        style: TextStyle(
                            color: PeekColors.text3, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_balance_wallet_outlined,
                size: 56, color: PeekColors.text3),
            const SizedBox(height: 16),
            const Text(
              'No wallets yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a fresh wallet or restore an existing one from a '
              'recovery phrase / keys.',
              textAlign: TextAlign.center,
              style: TextStyle(color: PeekColors.text2, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add wallet'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bridge from the new CoinModule (which has the full lifecycle) to
/// the legacy Coin interface that CoinScreen still expects. Keeps the
/// CoinScreen rewrite out of THIS commit — that lands when we cut
/// over to the new MoneroSession.startFor multi-wallet path.
class _LegacyCoinAdapter implements Coin {
  _LegacyCoinAdapter(this.module);
  final dynamic /* CoinModule */ module;

  @override
  String get id => module.id as String;
  @override
  String get name => module.name as String;
  @override
  String get symbol => module.symbol as String;
  @override
  Color get color => module.color as Color;
  @override
  IconData get icon => module.icon as IconData;
  @override
  Future<String> deriveAddress(String mnemonic) async {
    // Old Coin.deriveAddress is used by the legacy CoinScreen to
    // pre-populate the receive address; the equivalent in the new
    // model is the cached primaryAddress in WalletMeta. CoinScreen
    // falls back to "no address" if this returns empty — fine for
    // the transition.
    return '';
  }
}
