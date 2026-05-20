import 'dart:async';

import 'package:flutter/material.dart';
import '../coins/bitcoin/bitcoin_module.dart';
import '../coins/bitcoin/bitcoin_wallet.dart';
import '../coins/bitcoin/mempool_client.dart';
import '../l10n/gen/app_localizations.dart';
import '../prices/price_feed.dart';
import '../theme.dart';
import '../util/lifecycle_poller.dart';
import '../widgets/animated_balance.dart';
import '../vault/vault_state.dart';
import '../wallets/wallet_meta.dart';
import '../wallets/wallet_store.dart';
import '../util/coin_avatar.dart';
import '../wallets/balance_cache.dart';
import '../widgets/coin_screen_widgets.dart';
import '../widgets/receive_sheet.dart';
import '../widgets/tx_detail_sheet.dart';
import 'send_bitcoin_screen.dart';

/// Bitcoin coin page. Separate from CoinScreen (which is Monero-
/// specific in its boot path) because the BTC runtime is fundamentally
/// different — no native engine, no sync %, no subaddresses, no
/// daemon. Just BIP84 derive + mempool.space polling for balance and
/// history.
class BitcoinCoinScreen extends StatefulWidget {
  const BitcoinCoinScreen({super.key, required this.walletMeta});
  final WalletMeta walletMeta;

  @override
  State<BitcoinCoinScreen> createState() => _BitcoinCoinScreenState();
}

enum _SetupErrKind { none, vaultLocked, openFailed }

class _BitcoinCoinScreenState extends State<BitcoinCoinScreen>
    with LifecyclePoller {
  BitcoinWallet? _wallet;
  /// Live RPC error from _refresh — already an upstream exception
  /// string, shown as-is.
  String? _err;
  /// Setup-path error kind (vault locked, open failed). Resolved
  /// to a localized string in [build].
  _SetupErrKind _setupErrKind = _SetupErrKind.none;
  String? _setupErrDetail;
  int _balanceSat = 0;
  List<BitcoinTx> _txes = const [];
  /// When the live fetch fails (litecoinspace 521, network down,
  /// etc.) we fall back to whatever was last in BalanceCache so the
  /// user keeps seeing a balance instead of "0". null = no cached
  /// snapshot was ever taken; render zeroes.
  DateTime? _balanceFromCacheAt;
  bool _refreshing = false;

  /// Mempool.space doesn't appreciate sub-10s pollers; 30 s is the
  /// sweet spot between "users see new tx within a block-time" and
  /// "we don't get rate-limited". Pauses automatically when the app
  /// is backgrounded (see [LifecyclePoller]).
  @override
  Duration get pollInterval => const Duration(seconds: 30);

  @override
  Future<void> onPollTick() => _refresh();

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void dispose() {
    _wallet?.close();
    super.dispose();
  }

  Future<void> _open() async {
    setState(() {
      _err = null;
      _setupErrKind = _SetupErrKind.none;
      _setupErrDetail = null;
    });
    // Bring up the cached balance immediately so the user sees a
    // number even before the live fetch returns (or fails). The
    // refresh below will overwrite if it succeeds; if it 521s we
    // keep this value rather than reverting to 0.
    final cached = await BalanceCache.I.get(widget.walletMeta.id);
    if (cached != null && mounted) {
      // Parse the cached display amount back to satoshis — it's
      // always "X.XXXXXXXX BTC" / "X.XXXXXXXX LTC" so a regex pulls
      // the number out without coupling to the formatter.
      final m =
          RegExp(r'([0-9]+\.[0-9]+)').firstMatch(cached.displayAmount);
      if (m != null) {
        final coins = double.tryParse(m.group(1)!) ?? 0;
        final age = DateTime.now().difference(cached.updatedAt);
        setState(() {
          _balanceSat = (coins * 100000000).round();
          // Only flag as "cached" when the value is actually stale.
          // The wallets-list auto-refresh writes a fresh snapshot
          // every minute or so, so almost every wallet open hits a
          // <60s cache — showing a "Cached 1 min ago" pill on those
          // is noise, not signal.
          _balanceFromCacheAt =
              age > const Duration(minutes: 5) ? cached.updatedAt : null;
        });
      }
    }
    final password = VaultState.I.cachedPassword;
    if (password == null) {
      setState(() => _setupErrKind = _SetupErrKind.vaultLocked);
      return;
    }
    try {
      final decrypted = await WalletStore.I.open(
        walletId: widget.walletMeta.id,
        password: password,
      );
      // Same screen serves BTC and LTC — pick the right module from
      // the wallet's coinId so we get the right derivation params.
      final mod = widget.walletMeta.coinId == 'LTC'
          ? const LitecoinModule()
          : const BitcoinModule();
      final w = await mod.open(
        walletId: widget.walletMeta.id,
        format: widget.walletMeta.format,
        seedMaterial: decrypted.seedMaterial,
        walletFilePassword: decrypted.walletFilePassword,
        daemonUri: '', // unused for UTXO chains
        restoreHeight: 0,
      ) as BitcoinWallet;
      if (!mounted) return;
      setState(() => _wallet = w);
      // startPolling fires onPollTick (== _refresh) immediately and
      // then every pollInterval until the app backgrounds. The
      // first tick replaces the old `unawaited(_refresh())` call.
      startPolling();
    } catch (e) {
      setState(() {
        _setupErrKind = _SetupErrKind.openFailed;
        _setupErrDetail = e.toString();
      });
    }
  }

  Future<void> _refresh() async {
    final w = _wallet;
    if (w == null || _refreshing) return;
    setState(() => _refreshing = true);
    try {
      final sat = await w.balanceSat();
      final txes = await w.transactions();
      if (!mounted) return;
      setState(() {
        _balanceSat = sat;
        _txes = txes;
        _err = null;
      });
      // Push to cache so the wallets-list subtitle + portfolio total
      // can display this balance without re-fetching, AND so we
      // have something to fall back to next time the explorer is
      // down (litecoinspace.org 521s every few hours).
      final btc = sat / 100000000.0;
      final price = PriceFeed.I.prices[_symbol];
      unawaited(BalanceCache.I.put(CachedBalance(
        walletId: widget.walletMeta.id,
        symbol: _symbol,
        displayAmount: '${btc.toStringAsFixed(8)} $_symbol',
        fiatValue: price == null ? 0 : btc * price,
        fiatCurrency: PriceFeed.I.currency,
        updatedAt: DateTime.now(),
      )));
      // Live fetch succeeded — clear the "stale cache" stamp.
      if (mounted) {
        setState(() => _balanceFromCacheAt = null);
      }
    } catch (e) {
      if (!mounted) return;
      // Keep whatever balance we already had on screen (either from
      // cache or from the previous successful fetch). Only surface
      // the error so the user knows the live number might be stale.
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  /// Human-readable "5 min" / "3 hours" / "2 days" for the
  /// cached-balance staleness badge. Localized via [AppLocalizations]
  /// so it follows the device locale.
  String _relTime(AppLocalizations l, DateTime then) {
    final d = DateTime.now().difference(then);
    if (d.inSeconds < 60) return l.ageJustNow;
    if (d.inMinutes < 60) return l.ageMinutes(d.inMinutes);
    if (d.inHours < 24) return l.ageHours(d.inHours);
    return l.ageDays(d.inDays);
  }

  String get _symbol => _wallet?.params.symbol ?? widget.walletMeta.coinId;
  String get _coinName => _wallet?.params.name ?? 'Bitcoin';

  Future<void> _openSendScreen(BitcoinWallet w) async {
    final didSend = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SendBitcoinScreen(wallet: w),
      ),
    );
    if (didSend == true) {
      // Refresh balance + history so the new outgoing tx appears.
      unawaited(_refresh());
    }
  }

  void _showReceiveSheet() {
    final w = _wallet;
    if (w == null) return;
    // Rotate to the next unused address in the gap-limit window so
    // each receive flow shows a fresh address (privacy: prevents
    // a tip-jar or pasted-once address from clustering all incoming
    // payments under one on-chain identity). Falls back to the
    // primary address on first open before the wallet's done its
    // first balance refresh.
    showReceiveSheet(
      context,
      coinId: _symbol,
      coinName: _coinName,
      address: w.nextReceiveAddress,
      derivationHint:
          'BIP84 native SegWit. The same seed produces the same address '
          'window in Sparrow / Electrum / BlueWallet. The address shown '
          "rotates after each use; previously-shown addresses still receive.",
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final w = _wallet;
    final String? setupErrText;
    switch (_setupErrKind) {
      case _SetupErrKind.vaultLocked:
        setupErrText = l.balanceVaultLocked;
        break;
      case _SetupErrKind.openFailed:
        setupErrText = l.balanceCouldNotOpen(_setupErrDetail ?? '');
        break;
      case _SetupErrKind.none:
        setupErrText = null;
        break;
    }
    final displayErr = setupErrText ?? _err;
    return Scaffold(
      appBar: AppBar(
        title: Text(_coinName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l.coinScreenRefreshTooltip,
            onPressed: _refresh,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: PeekColors.accent,
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(PeekDesign.sp4, PeekDesign.sp3,
                PeekDesign.sp4, PeekDesign.sp4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero balance card — coin-tinted gradient + bloom
                // glow + big balance with fiat. The coin accent
                // washes the surface so the user can tell BTC vs ETH
                // vs SOL at a glance without reading the title.
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                  decoration: BoxDecoration(
                    borderRadius: PeekDesign.brHero,
                    gradient: PeekDesign.coinHeroGradient(
                        PeekColors.coinAccent(_symbol)),
                    border: Border.all(color: PeekColors.border, width: 1),
                    boxShadow: PeekDesign.cardShadow,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      // Soft top-right brand bloom — premium "lit from
                      // the side" depth, same trick the portfolio hero
                      // uses on the wallets list.
                      Positioned(
                        right: -50,
                        top: -50,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: PeekDesign.heroAccentBloom(
                              PeekColors.coinAccent(_symbol)),
                        ),
                      ),
                      Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          coinAvatar(_symbol, radius: 22),
                          const SizedBox(width: PeekDesign.sp3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _coinName,
                                  style: const TextStyle(
                                    color: PeekColors.text,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                                Text(
                                  l.coinScreenBalanceLabel(_symbol),
                                  style: const TextStyle(
                                      color: PeekColors.text3,
                                      fontSize: 11,
                                      letterSpacing: 0.3),
                                ),
                              ],
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: PeekDesign.tFast,
                            child: _refreshing
                                ? Container(
                                    key: const ValueKey('spin'),
                                    width: 28,
                                    height: 28,
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: PeekColors.surface2,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: PeekColors.accent),
                                  )
                                : const SizedBox(
                                    key: ValueKey('none'), width: 28),
                          ),
                        ],
                      ),
                      const SizedBox(height: PeekDesign.sp5),
                      AnimatedBalance(
                        amount: _wallet == null
                            ? 0
                            : _balanceSat / 100000000.0,
                        formatter: (v) => _wallet == null
                            ? '… $_symbol'
                            : '${v.toStringAsFixed(8)} $_symbol',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.7,
                          height: 1.1,
                        ),
                      ),
                      AnimatedBuilder(
                        animation: PriceFeed.I,
                        builder: (_, _) {
                          if (_balanceSat == 0) {
                            return const SizedBox(height: 4);
                          }
                          final fiat = PriceFeed.I.formatFiat(
                              _symbol, _balanceSat / 100000000.0);
                          if (fiat.isEmpty) return const SizedBox(height: 4);
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              fiat,
                              style: const TextStyle(
                                  color: PeekColors.text2,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500),
                            ),
                          );
                        },
                      ),
                      if (_balanceFromCacheAt != null && !_refreshing)
                        Padding(
                          padding: const EdgeInsets.only(top: PeekDesign.sp3),
                          child: StatusPill(
                            text: l.balanceCached(
                                _relTime(l, _balanceFromCacheAt!)),
                            color: PeekColors.accent,
                            icon: Icons.cloud_off_rounded,
                          ),
                        ),
                      if (displayErr != null)
                        Padding(
                          padding: const EdgeInsets.only(top: PeekDesign.sp3),
                          child: StatusPill(
                            text: displayErr,
                            color: PeekColors.red,
                            icon: Icons.error_outline_rounded,
                          ),
                        ),
                    ],
                  ),
                    ],
                  ),
                ),
                const SizedBox(height: PeekDesign.sp4),
                if (w != null)
                  Row(
                    children: [
                      Expanded(
                        child: ActionButton(
                          icon: Icons.qr_code_rounded,
                          label: l.actionReceive,
                          primary: false,
                          onTap: _showReceiveSheet,
                        ),
                      ),
                      const SizedBox(width: PeekDesign.sp3),
                      Expanded(
                        child: ActionButton(
                          icon: Icons.arrow_upward_rounded,
                          label: l.actionSend,
                          primary: true,
                          onTap: _balanceSat == 0
                              ? null
                              : () => _openSendScreen(w),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: PeekDesign.sp6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      l.coinScreenActivityTitle,
                      style: const TextStyle(
                          color: PeekColors.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1),
                    ),
                    const SizedBox(width: PeekDesign.sp2),
                    if (_txes.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: PeekColors.surface2,
                          borderRadius: PeekDesign.brPill,
                        ),
                        child: Text(
                          '${_txes.length}',
                          style: const TextStyle(
                              color: PeekColors.text2,
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: PeekDesign.sp3),
                if (_txes.isEmpty)
                  EmptyActivity(
                    loading: _wallet == null,
                    coinLabel: _symbol,
                  )
                else
                  for (final tx in _txes) _BtcTxRow(tx: tx, symbol: _symbol),
                if (w != null) ...[
                  const SizedBox(height: PeekDesign.sp5),
                  Container(
                    padding: const EdgeInsets.all(PeekDesign.sp3),
                    decoration: BoxDecoration(
                      color: PeekColors.surface2,
                      borderRadius: PeekDesign.brSmall,
                      border: Border.all(color: PeekColors.hairline),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined,
                            size: 14, color: PeekColors.text3),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l.experimentalSendWarning(_symbol),
                            style: const TextStyle(
                                color: PeekColors.text3,
                                fontSize: 11,
                                height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _BtcTxRow extends StatelessWidget {
  const _BtcTxRow({required this.tx, required this.symbol});
  final BitcoinTx tx;
  /// Coin symbol — "BTC" or "LTC". Used for the amount label so the
  /// same row layout renders for either chain.
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = tx.isIncoming ? PeekColors.green : PeekColors.text;
    final sign = tx.isIncoming ? '+' : '−';
    final amount = '$sign${tx.netBtc.abs().toStringAsFixed(8)} $symbol';
    final subtitle = tx.confirmed
        ? '${_fmtDate(tx.timestamp.toLocal())} · ${l.txStatusConfirmed}'
        : l.txStatusInMempool;
    return InkWell(
      onTap: () => _showDetails(context, tx),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: PeekDesign.sp2),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: PeekColors.surface2,
                borderRadius: PeekDesign.brSmall,
              ),
              child: Icon(
                tx.isIncoming
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: PeekDesign.sp3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(amount,
                      style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: PeekColors.text3, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: PeekColors.text3, size: 18),
          ],
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  void _showDetails(BuildContext context, BitcoinTx tx) {
    final l = AppLocalizations.of(context);
    final amountColor = tx.isIncoming ? PeekColors.green : PeekColors.text;
    final sign = tx.isIncoming ? '+' : '−';
    showTxDetailSheet(
      context,
      coinId: symbol,
      isIncoming: tx.isIncoming,
      amountText: '$sign${tx.netBtc.abs().toStringAsFixed(8)} $symbol',
      amountColor: amountColor,
      rows: [
        TxDetailRow(
            l.txFeeLabel, '${tx.feeBtc.toStringAsFixed(8)} $symbol'),
        TxDetailRow(l.txBlockHeightLabel,
            tx.blockHeight == 0 ? '—' : tx.blockHeight.toString()),
        TxDetailRow(l.txDateLabel, fmtTxDate(tx.timestamp.toLocal())),
      ],
      hashLabel: l.txIdLabel,
      hashValue: tx.txid,
      statusText:
          tx.confirmed ? l.txStatusConfirmed : l.txStatusInMempool,
      statusColor:
          tx.confirmed ? PeekColors.green : PeekColors.accent,
      statusIcon: tx.confirmed
          ? Icons.check_circle_rounded
          : Icons.hourglass_top_rounded,
    );
  }
}
