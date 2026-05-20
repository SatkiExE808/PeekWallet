import 'dart:async';

import 'package:flutter/material.dart';

import '../coins/bitcoin/bitcoin_wallet.dart';
import '../l10n/gen/app_localizations.dart';
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
import '../util/peek_logger.dart';
import '../vault/vault_state.dart';
import '../wallets/balance_cache.dart';
import '../wallets/wallet_meta.dart';
import '../wallets/wallet_store.dart';
import '../widgets/skeleton.dart';
import 'add_wallet/add_wallet_flow.dart';
import 'bch_coin_screen.dart';
import 'bitcoin_coin_screen.dart';
import 'coin_screen.dart';
import 'ethereum_coin_screen.dart';
import 'show_wallet_seed_screen.dart';
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
  /// Cached, stable BalanceCache snapshot. Re-fetched only when the
  /// cache actually notifies us — naively calling `BalanceCache.I
  /// .all()` inside FutureBuilder rebuilt the future on every parent
  /// rebuild, which flickered the wallet list back to spinner state
  /// every time a wallet refresh landed.
  late Future<Map<String, CachedBalance>> _cacheSnapshot;
  bool _autoLoading = false;
  /// Periodic refresh — keeps balances fresh while the user is in
  /// the app even if they don't open any coin screen. Fires every
  /// `_autoRefreshInterval` and force-probes every non-XMR wallet.
  /// IndexedStack keeps this screen alive across tab switches, so
  /// the timer effectively follows the lifetime of the unlocked
  /// session; cancelled in dispose() when the vault re-locks.
  Timer? _autoRefreshTimer;
  static const _autoRefreshInterval = Duration(minutes: 2);

  @override
  void initState() {
    super.initState();
    _entries = WalletStore.I.list();
    _cacheSnapshot = BalanceCache.I.all();
    WalletStore.I.addListener(_refresh);
    // Rebuild when any wallet pushes a new balance snapshot so the
    // subtitles + portfolio total update live.
    BalanceCache.I.addListener(_refreshCache);
    // Eagerly fetch balances for any wallet that doesn't have a
    // cached value yet, so the home screen shows real numbers on
    // first launch instead of "—".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeAutoLoadBalances();
    });
    _autoRefreshTimer =
        Timer.periodic(_autoRefreshInterval, (_) {
      _maybeAutoLoadBalances(force: true);
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    WalletStore.I.removeListener(_refresh);
    BalanceCache.I.removeListener(_refreshCache);
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _entries = WalletStore.I.list();
    });
  }

  void _refreshCache() {
    if (!mounted) return;
    setState(() {
      _cacheSnapshot = BalanceCache.I.all();
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

    // Pick wallets whose cache entry is genuinely stale (or missing)
    // AND that we know how to balance-probe without booting monero_c.
    //
    // The previous check was containsKey(m.id) — a presence-only
    // gate that treated any cache entry, even 8 hours old, as fresh.
    // Now we require the cached entry to be <5 minutes old to skip;
    // older entries get re-probed on the next cold open or post-tab-
    // switch frame.
    final now = DateTime.now();
    final targets = entries.where((m) {
      if (m.coinId == 'XMR') return false; // skip — too expensive
      if (force) return true;
      final c = cache[m.id];
      if (c == null) return true;
      return now.difference(c.updatedAt) > const Duration(minutes: 5);
    }).toList();
    if (targets.isEmpty) return;

    final password = VaultState.I.cachedPassword;
    if (password == null) return; // locked — can't decrypt seeds

    if (!mounted) return;
    setState(() => _autoLoading = true);
    try {
      // Fan out — most chains are independent HTTP. We don't try
      // to limit concurrency because the user has at most a few
      // wallets per chain and the public endpoints handle it fine.
      //
      // Hard 8-second timeout per probe so one slow / dead RPC (e.g.
      // a user-pinned override that's down) can't freeze the whole
      // wallets list. On timeout the row keeps showing its cached
      // value and the next auto-refresh tries again.
      await Future.wait(targets.map((m) => _probeBalance(m, password)
          .timeout(const Duration(seconds: 8))
          .catchError((Object e) {
        PeekLogger.I.log(m.coinId.toLowerCase(),
            'balance probe (${m.id}) failed: $e');
      })));
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
        case 'POL':
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
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.walletsTitle),
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
            tooltip: l.walletsRefreshTooltip,
            onPressed: _autoLoading
                ? null
                : () => _maybeAutoLoadBalances(force: true),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l.walletsAddTooltip,
            onPressed: _add,
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<WalletMeta>>(
          future: _entries,
          builder: (ctx, snap) {
            if (!snap.hasData) {
              // Shimmer 3 placeholder rows instead of a centered
              // spinner — same layout the live list will use, so the
              // page doesn't jump when wallets land.
              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                    horizontal: PeekDesign.sp4,
                    vertical: PeekDesign.sp3),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: PeekDesign.sp2),
                itemBuilder: (_, _) => const WalletRowSkeleton(),
              );
            }
            final entries = snap.data!;
            if (entries.isEmpty) {
              return _EmptyState(onAdd: _add);
            }
            return FutureBuilder<Map<String, CachedBalance>>(
              future: _cacheSnapshot,
              builder: (ctx, cacheSnap) {
                final cache = cacheSnap.data ?? const {};
                return RefreshIndicator(
                  color: PeekColors.accent,
                  onRefresh: () => _maybeAutoLoadBalances(force: true),
                  child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: PeekDesign.sp4,
                      vertical: PeekDesign.sp3),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: entries.length + 1,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: PeekDesign.sp2),
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return _PortfolioHeader(
                          entries: entries, cache: cache);
                    }
                    final meta = entries[i - 1];
                    final coin = coinModuleFor(meta.coinId);
                    final cached = cache[meta.id];
                    return _WalletRow(
                      meta: meta,
                      coinSymbol: coin?.symbol ?? meta.coinId,
                      formatName: meta.format.displayName,
                      cached: cached,
                      onLongPress: () => _showWalletMenu(meta),
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
                              case 'POL':
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
                    );
                  },
                ),
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
      'sgd' => 'S\$',
      'twd' => 'NT\$',
      'myr' => 'RM',
      'thb' => '฿',
      'idr' => 'Rp',
      'php' => '₱',
      'vnd' => '₫',
      _ => '${currency.toUpperCase()} ',
    };
    // Currencies where the smallest unit isn't a hundredth (JPY,
    // CNY, IDR, VND, KRW) display whole-number-only by convention.
    final wholeOnly = const {'jpy', 'cny', 'idr', 'vnd', 'krw'}.contains(c);
    final digits = wholeOnly ? 0 : 2;
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
              leading: const Icon(Icons.vpn_key_outlined,
                  color: PeekColors.accent),
              title: const Text('Show recovery phrase'),
              subtitle: const Text(
                'Back this up separately from the vault seed.',
                style:
                    TextStyle(color: PeekColors.text3, fontSize: 11),
              ),
              onTap: () => Navigator.of(ctx).pop('reveal'),
            ),
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
    if (!mounted) return;
    if (action == 'reveal') {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ShowWalletSeedScreen(walletMeta: meta),
      ));
    }
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
    final l = AppLocalizations.of(context);
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
          if (c.fiatCurrency == currency && c.fiatValue > 0) {
            total += c.fiatValue;
          }
        }
        return Container(
          margin: const EdgeInsets.fromLTRB(
              0, PeekDesign.sp2, 0, PeekDesign.sp4),
          padding: const EdgeInsets.fromLTRB(
              20, 22, 20, 20),
          decoration: BoxDecoration(
            borderRadius: PeekDesign.brHero,
            gradient: PeekDesign.surfaceGradient,
            border: Border.all(
              color: PeekColors.border,
              width: 1,
            ),
            boxShadow: PeekDesign.cardShadow,
          ),
          // Stack the soft accent glow behind the content so the
          // hero feels like a "living" surface rather than a flat
          // card. Same depth-via-color trick Tangem + Exodus use on
          // their portfolio cards.
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      PeekColors.accent.withAlpha(36),
                      PeekColors.accent.withAlpha(0),
                    ]),
                  ),
                ),
              ),
              Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    l.homeTotalBalance,
                    style: const TextStyle(
                        color: PeekColors.text2,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: PeekColors.surface2,
                      borderRadius: PeekDesign.brPill,
                      border: Border.all(color: PeekColors.border),
                    ),
                    child: Text(
                      l.homeSyncedCount(counted, entries.length),
                      style: const TextStyle(
                          color: PeekColors.text2,
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: PeekDesign.tMed,
                curve: PeekDesign.easeOut,
                builder: (_, t, _) => Opacity(
                  opacity: t,
                  child: Text(
                    total > 0
                        ? _WalletsScreenState._fmtFiat(total, currency)
                            .replaceFirst('≈ ', '')
                        : '—',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l.homeAcrossWallets(entries.length),
                style: const TextStyle(
                    color: PeekColors.text3,
                    fontSize: 12),
              ),
            ],
          ),
            ],
          ),
        );
      },
    );
  }
}

/// Single wallet row in the home list. Premium spacing, larger
/// avatar, two-line subtitle separating the live balance from the
/// network/format hint.
class _WalletRow extends StatelessWidget {
  const _WalletRow({
    required this.meta,
    required this.coinSymbol,
    required this.formatName,
    required this.cached,
    required this.onTap,
    required this.onLongPress,
  });

  final WalletMeta meta;
  final String coinSymbol;
  final String formatName;
  final CachedBalance? cached;
  final VoidCallback? onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final hasBalance = cached != null;
    final accent = PeekColors.coinAccent(meta.coinId);
    return Material(
      color: PeekColors.surface,
      borderRadius: PeekDesign.brCard,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: PeekDesign.brCard,
        splashColor: accent.withAlpha(36),
        highlightColor: accent.withAlpha(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: PeekDesign.brCard,
            border: Border.all(color: PeekColors.hairline, width: 1),
            // Coin-aware accent stripe on the left edge — same idea as
            // Mac apps' colored sidebar dots and Exodus's gradient cards.
            // 3px wide so it reads from across the room without dominating
            // the card. Falls back to the generic accent for unknown coins.
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.0, 0.012, 0.012, 1.0],
              colors: [
                accent,
                accent,
                PeekColors.surface,
                PeekColors.surface,
              ],
            ),
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: PeekDesign.sp4, vertical: PeekDesign.sp3),
          child: Row(
            children: [
              // Coin avatar with a soft ring of the brand accent so
              // the symbol reads as "this is BTC" / "this is ETH"
              // even when the user has scrolled fast.
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withAlpha(96), width: 1.5),
                ),
                child: coinAvatar(meta.coinId, radius: 20),
              ),
              const SizedBox(width: PeekDesign.sp4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      meta.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PeekColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasBalance
                          ? cached!.displayAmount
                          : '$coinSymbol · $formatName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PeekColors.text2,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PeekDesign.sp3),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasBalance && cached!.fiatValue > 0)
                    Text(
                      _WalletsScreenState._fmtFiat(
                              cached!.fiatValue, cached!.fiatCurrency)
                          .replaceFirst('≈ ', ''),
                      style: const TextStyle(
                        color: PeekColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    const Text('—',
                        style: TextStyle(
                            color: PeekColors.text3, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    coinSymbol,
                    style: const TextStyle(
                      color: PeekColors.text3,
                      fontSize: 11,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: PeekDesign.sp2),
              const Icon(Icons.chevron_right,
                  color: PeekColors.text3, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  static const _previewCoins = ['BTC', 'ETH', 'SOL', 'TRX', 'XMR'];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Breathing wallet icon — same animation as the lock-
            // screen lock so the empty state reads as "waiting for
            // you" instead of "nothing here".
            const _EmptyStateIcon(),
            const SizedBox(height: PeekDesign.sp5),
            Text(
              l.homeEmptyTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: PeekDesign.sp2),
            Text(
              l.homeEmptyBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: PeekColors.text2, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: PeekDesign.sp5),
            // Inline coin-cluster preview — five overlapping ringed
            // avatars hint at the chains the user can add without
            // making it feel like a separate "feature list" screen.
            SizedBox(
              height: 36,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  for (var i = 0; i < _previewCoins.length; i++)
                    Positioned(
                      left: i * 22.0,
                      child: Container(
                        padding: const EdgeInsets.all(1.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: PeekColors.bg,
                          border: Border.all(
                              color: PeekColors.coinAccent(_previewCoins[i])
                                  .withAlpha(96),
                              width: 1.5),
                        ),
                        child: coinAvatar(_previewCoins[i], radius: 14),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: PeekDesign.sp5),
            SizedBox(
              width: 220,
              child: ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: Text(l.homeAddWallet),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty-state wallet icon with a slow breathing glow — visual
/// counterpart to the lock-screen lock. Without this, the wallets
/// list empty state reads as "nothing here" instead of "ready when
/// you are".
class _EmptyStateIcon extends StatefulWidget {
  const _EmptyStateIcon();

  @override
  State<_EmptyStateIcon> createState() => _EmptyStateIconState();
}

class _EmptyStateIconState extends State<_EmptyStateIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        final scale = 0.95 + (t * 0.10);
        final glowAlpha = (40 + (t * 36)).round();
        return SizedBox(
          width: 112,
          height: 112,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      PeekColors.accent.withAlpha(glowAlpha),
                      PeekColors.accent.withAlpha(0),
                    ]),
                  ),
                ),
              ),
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: PeekColors.surface2,
                  border: Border.all(color: PeekColors.border),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 32,
                  color: PeekColors.accent,
                ),
              ),
            ],
          ),
        );
      },
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
