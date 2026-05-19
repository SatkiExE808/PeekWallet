import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../coins/bitcoin/bitcoin_module.dart';
import '../coins/bitcoin/bitcoin_wallet.dart';
import '../coins/bitcoin/mempool_client.dart';
import '../prices/price_feed.dart';
import '../theme.dart';
import '../vault/vault_state.dart';
import '../wallets/wallet_meta.dart';
import '../wallets/wallet_store.dart';
import '../util/coin_avatar.dart';
import '../util/explorer_links.dart';
import '../wallets/balance_cache.dart';
import '../widgets/coin_screen_widgets.dart';
import '../widgets/receive_sheet.dart';
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

class _BitcoinCoinScreenState extends State<BitcoinCoinScreen> {
  BitcoinWallet? _wallet;
  String? _err;
  int _balanceSat = 0;
  List<BitcoinTx> _txes = const [];
  /// When the live fetch fails (litecoinspace 521, network down,
  /// etc.) we fall back to whatever was last in BalanceCache so the
  /// user keeps seeing a balance instead of "0". null = no cached
  /// snapshot was ever taken; render zeroes.
  DateTime? _balanceFromCacheAt;
  Timer? _poll;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _wallet?.close();
    super.dispose();
  }

  Future<void> _open() async {
    setState(() => _err = null);
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
        setState(() {
          _balanceSat = (coins * 100000000).round();
          _balanceFromCacheAt = cached.updatedAt;
        });
      }
    }
    final password = VaultState.I.cachedPassword;
    if (password == null) {
      setState(() => _err = 'Vault is locked.');
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
      unawaited(_refresh());
      // Poll every 30 s while the screen is alive. Mempool.space
      // doesn't appreciate sub-10s pollers; 30 s is the sweet spot
      // between "users see new tx within a block-time" and "we
      // don't get rate-limited".
      _poll = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
    } catch (e) {
      setState(() => _err = 'Could not open wallet: $e');
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

  /// Human-readable "5 min ago" / "3 hours ago" / "yesterday" for
  /// the cached-balance staleness badge.
  String _relTime(DateTime then) {
    final d = DateTime.now().difference(then);
    if (d.inSeconds < 60) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  String get _symbol => _wallet?.params.symbol ?? widget.walletMeta.coinId;
  String get _coinName => _wallet?.params.name ?? 'Bitcoin';

  String _balanceText() {
    if (_wallet == null) return '… $_symbol';
    final btc = _balanceSat / 100000000.0;
    return '${btc.toStringAsFixed(8)} $_symbol';
  }

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
    showReceiveSheet(
      context,
      coinId: _symbol,
      coinName: _coinName,
      address: w.primaryAddress,
      derivationHint:
          'BIP84 native SegWit. Same address every BIP39-compatible wallet '
          '(Sparrow, Electrum, BlueWallet) derives from this seed.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = _wallet;
    return Scaffold(
      appBar: AppBar(
        title: Text(_coinName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
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
                // Hero balance card — gradient surface + soft accent
                // glow + big balance with fiat. Replaces the
                // previously-flat avatar + label + number stack.
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                  decoration: BoxDecoration(
                    borderRadius: PeekDesign.brHero,
                    gradient: PeekDesign.surfaceGradient,
                    border: Border.all(color: PeekColors.border, width: 1),
                    boxShadow: PeekDesign.cardShadow,
                  ),
                  child: Column(
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
                                  '$_symbol balance',
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
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.95, end: 1.0),
                        duration: PeekDesign.tMed,
                        curve: PeekDesign.easeOut,
                        builder: (_, t, child) => Opacity(
                          opacity: t,
                          child: child,
                        ),
                        child: Text(
                          _balanceText(),
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.7,
                            height: 1.1,
                          ),
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
                      if (_balanceFromCacheAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: PeekDesign.sp3),
                          child: StatusPill(
                            text:
                                'Cached · ${_relTime(_balanceFromCacheAt!)}',
                            color: PeekColors.accent,
                            icon: Icons.cloud_off_rounded,
                          ),
                        ),
                      if (_err != null)
                        Padding(
                          padding: const EdgeInsets.only(top: PeekDesign.sp3),
                          child: StatusPill(
                            text: _err!,
                            color: PeekColors.red,
                            icon: Icons.error_outline_rounded,
                          ),
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
                          label: 'Receive',
                          primary: false,
                          onTap: _showReceiveSheet,
                        ),
                      ),
                      const SizedBox(width: PeekDesign.sp3),
                      Expanded(
                        child: ActionButton(
                          icon: Icons.arrow_upward_rounded,
                          label: 'Send',
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
                    const Text(
                      'Activity',
                      style: TextStyle(
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: PeekColors.surface.withAlpha(120),
                      borderRadius: PeekDesign.brCard,
                      border: Border.all(color: PeekColors.hairline),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _wallet == null
                              ? Icons.hourglass_top_rounded
                              : Icons.inbox_rounded,
                          size: 28,
                          color: PeekColors.text3,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _wallet == null
                              ? 'Loading…'
                              : 'No transactions yet',
                          style: const TextStyle(
                              color: PeekColors.text2,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                        if (_wallet != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Share your address to receive $_symbol',
                            style: const TextStyle(
                                color: PeekColors.text3, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
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
                            'Send is experimental — test with small amounts '
                            'before moving meaningful $_symbol.',
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
    final color = tx.isIncoming ? PeekColors.green : PeekColors.text;
    final sign = tx.isIncoming ? '+' : '−';
    final amount = '$sign${tx.netBtc.abs().toStringAsFixed(8)} $symbol';
    final subtitle = tx.confirmed
        ? '${_fmtDate(tx.timestamp.toLocal())} · Confirmed'
        : 'In mempool';
    return InkWell(
      onTap: () => _showDetails(context, tx),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: PeekColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                tx.isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
                color: color,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
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
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: PeekColors.bg2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: PeekColors.border2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                tx.isIncoming ? 'Incoming' : 'Outgoing',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _kv('Net amount',
                  '${tx.netBtc.toStringAsFixed(8)} $symbol'),
              _kv('Fee', '${tx.feeBtc.toStringAsFixed(8)} $symbol'),
              _kv('Status', tx.confirmed ? 'Confirmed' : 'In mempool'),
              _kv('Block height',
                  tx.blockHeight == 0 ? '—' : tx.blockHeight.toString()),
              _kv('Date', _fmtDate(tx.timestamp.toLocal())),
              const SizedBox(height: 6),
              const Text('TX ID',
                  style:
                      TextStyle(color: PeekColors.text2, fontSize: 12)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: PeekColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: PeekColors.border),
                ),
                child: SelectableText(
                  tx.txid,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                            ClipboardData(text: tx.txid));
                        messenger.showSnackBar(
                          const SnackBar(content: Text('TX ID copied')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final url = explorerTxUrl(
                            coinId: symbol, txid: tx.txid);
                        if (url == null) return;
                        final ok = await openExplorerUrl(url);
                        if (!ok && ctx.mounted) {
                          messenger.showSnackBar(const SnackBar(
                              content: Text(
                                  'Could not open browser')));
                        }
                      },
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Explorer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(k,
                style: const TextStyle(color: PeekColors.text2, fontSize: 12)),
          ),
          Expanded(
            child: SelectableText(v,
                style: const TextStyle(color: PeekColors.text, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
