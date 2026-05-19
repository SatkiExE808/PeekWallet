import 'dart:async';

import 'package:flutter/material.dart';
import '../coins/bitcoin_cash/bch_module.dart';
import '../coins/bitcoin_cash/bch_wallet.dart';
import '../coins/bitcoin_cash/blockchair_client.dart';
import '../prices/price_feed.dart';
import '../theme.dart';
import '../util/coin_avatar.dart';
import '../util/explorer_links.dart';
import '../wallets/balance_cache.dart';
import '../widgets/coin_screen_widgets.dart';
import '../widgets/receive_sheet.dart';
import 'send_bch_screen.dart';
import '../vault/vault_state.dart';
import '../wallets/wallet_meta.dart';
import '../wallets/wallet_store.dart';

/// Bitcoin Cash coin page. Receive + balance + (txid-only) history.
/// Full per-tx detail (net balance, fee) lands when we wire the
/// /dashboards/transaction/{hash} second-call path. Send is a
/// follow-up — BCH uses legacy P2PKH signing with SIGHASH_FORKID,
/// distinct from BIP143.
class BitcoinCashCoinScreen extends StatefulWidget {
  const BitcoinCashCoinScreen({super.key, required this.walletMeta});
  final WalletMeta walletMeta;

  @override
  State<BitcoinCashCoinScreen> createState() => _BitcoinCashCoinScreenState();
}

class _BitcoinCashCoinScreenState extends State<BitcoinCashCoinScreen> {
  BitcoinCashWallet? _wallet;
  String? _err;
  int _balanceSat = 0;
  List<BchTx> _txes = const [];
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
    // Pre-fill from BalanceCache so the user sees a real balance
    // before the live fetch returns (or fails — Blockchair can
    // take 30+ s under load).
    final cached = await BalanceCache.I.get(widget.walletMeta.id);
    if (cached != null && mounted) {
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
      final mod = const BitcoinCashModule();
      final w = await mod.open(
        walletId: widget.walletMeta.id,
        format: widget.walletMeta.format,
        seedMaterial: decrypted.seedMaterial,
        walletFilePassword: decrypted.walletFilePassword,
        daemonUri: '',
        restoreHeight: 0,
      ) as BitcoinCashWallet;
      if (!mounted) return;
      setState(() => _wallet = w);
      unawaited(_refresh());
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
      final bch = sat / 100000000.0;
      final price = PriceFeed.I.prices['BCH'];
      unawaited(BalanceCache.I.put(CachedBalance(
        walletId: widget.walletMeta.id,
        symbol: 'BCH',
        displayAmount: '${bch.toStringAsFixed(8)} BCH',
        fiatValue: price == null ? 0 : bch * price,
        fiatCurrency: PriceFeed.I.currency,
        updatedAt: DateTime.now(),
      )));
      if (mounted) setState(() => _balanceFromCacheAt = null);
    } catch (e) {
      if (!mounted) return;
      // Keep the cached balance displayed; just note the live fetch
      // failed. Common with Blockchair on the free tier.
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  String _relTime(DateTime then) {
    final d = DateTime.now().difference(then);
    if (d.inSeconds < 60) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  String _balanceText() {
    if (_wallet == null) return '… BCH';
    final bch = _balanceSat / 100000000.0;
    return '${bch.toStringAsFixed(8)} BCH';
  }

  Future<void> _openSendScreen(BitcoinCashWallet w) async {
    final didSend = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SendBchScreen(wallet: w),
      ),
    );
    if (didSend == true) {
      unawaited(_refresh());
    }
  }

  void _showReceiveSheet() {
    final w = _wallet;
    if (w == null) return;
    showReceiveSheet(
      context,
      coinId: 'BCH',
      coinName: 'Bitcoin Cash',
      address: w.primaryAddress,
      derivationHint:
          "BIP44 m/44'/145'/0'/0/0 in CashAddr form. Same address Electron "
          "Cash, BlueWallet, Edge, and Ledger Live derive from this seed.",
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = _wallet;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bitcoin Cash'),
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
                          coinAvatar('BCH', radius: 22),
                          const SizedBox(width: PeekDesign.sp3),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bitcoin Cash',
                                  style: TextStyle(
                                    color: PeekColors.text,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                                Text(
                                  'BCH balance',
                                  style: TextStyle(
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
                                    decoration: const BoxDecoration(
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
                      Text(
                        _balanceText(),
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
                          if (_balanceSat == 0) return const SizedBox(height: 4);
                          final fiat = PriceFeed.I.formatFiat(
                              'BCH', _balanceSat / 100000000.0);
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
                if (w != null) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Send is experimental — legacy P2PKH with '
                    'SIGHASH_FORKID. Test with small amounts first.',
                    style: TextStyle(color: PeekColors.text3, fontSize: 11),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Transactions',
                        style:
                            TextStyle(color: PeekColors.text2, fontSize: 12),
                      ),
                    ),
                    if (_txes.isNotEmpty)
                      Text(
                        '${_txes.length} total',
                        style: const TextStyle(
                            color: PeekColors.text3, fontSize: 11),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                if (_txes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      _wallet == null
                          ? 'Loading…'
                          : 'No transactions yet — give your receive '
                              'address to a sender, refresh, and incoming '
                              'BCH appears here.',
                      style: const TextStyle(
                          color: PeekColors.text3, fontSize: 12),
                    ),
                  )
                else
                  for (final tx in _txes) _BchTxRow(tx: tx),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BchTxRow extends StatelessWidget {
  const _BchTxRow({required this.tx});
  final BchTx tx;

  @override
  Widget build(BuildContext context) {
    // First-commit txes only carry the hash. Show that plus an
    // "Explorer" tap-out so the user can see details on Blockchair.
    final shortHash = tx.hash.length >= 14
        ? '${tx.hash.substring(0, 8)}…${tx.hash.substring(tx.hash.length - 6)}'
        : tx.hash;
    return InkWell(
      onTap: () async {
        final url = explorerTxUrl(coinId: 'BCH', txid: tx.hash);
        if (url == null) return;
        await openExplorerUrl(url);
      },
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
              child: const Icon(Icons.swap_horiz_rounded,
                  color: PeekColors.text2, size: 18),
            ),
            const SizedBox(width: PeekDesign.sp3),
            Expanded(
              child: Text(shortHash,
                  style: const TextStyle(
                      color: PeekColors.text,
                      fontSize: 13,
                      fontFamily: 'monospace')),
            ),
            const Icon(Icons.open_in_new_rounded,
                color: PeekColors.text3, size: 16),
          ],
        ),
      ),
    );
  }
}
