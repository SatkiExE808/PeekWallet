import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../coins/tron/trc20.dart';
import '../coins/tron/tron_module.dart';
import '../coins/tron/tron_wallet.dart';
import '../coins/tron/trongrid_client.dart';
import 'send_tron_screen.dart';
import '../prices/price_feed.dart';
import '../theme.dart';
import '../util/coin_avatar.dart';
import '../util/explorer_links.dart';
import '../wallets/balance_cache.dart';
import '../vault/vault_state.dart';
import '../wallets/wallet_meta.dart';
import '../wallets/wallet_store.dart';
import '../widgets/coin_screen_widgets.dart';

/// Tron coin page. Receive + balance + history. Send is a follow-up
/// — TRX transactions are protobuf-encoded (TransferContract +
/// raw_data + block reference) which is non-trivial. For now this is
/// a watch-only wallet that lets you receive TRX (and as a bonus, the
/// address can later receive USDT-TRC20 once we add TRC-20 support).
class TronCoinScreen extends StatefulWidget {
  const TronCoinScreen({super.key, required this.walletMeta});
  final WalletMeta walletMeta;

  @override
  State<TronCoinScreen> createState() => _TronCoinScreenState();
}

class _TronCoinScreenState extends State<TronCoinScreen> {
  TronWallet? _wallet;
  String? _err;
  int _balanceSun = 0;
  DateTime? _balanceFromCacheAt;
  List<TronTx> _txes = const [];
  /// TRC-20 balances keyed by base58 contract address. Populated
  /// in _refresh() alongside the native TRX balance.
  Map<String, BigInt> _tokenBalances = const {};
  /// TRC-20 transfer history, filtered to tokens we recognize.
  List<Trc20Transfer> _tokenTxes = const [];
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
    // Pre-fill from BalanceCache so the user sees a number before
    // the TronGrid balance call completes (or fails — public TronGrid
    // is rate-limited and 429s under contention).
    final cached = await BalanceCache.I.get(widget.walletMeta.id);
    if (cached != null && mounted) {
      final m =
          RegExp(r'([0-9]+\.[0-9]+)').firstMatch(cached.displayAmount);
      if (m != null) {
        final trx = double.tryParse(m.group(1)!) ?? 0;
        setState(() {
          _balanceSun = (trx * 1000000).round();
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
      final mod = const TronModule();
      final w = await mod.open(
        walletId: widget.walletMeta.id,
        format: widget.walletMeta.format,
        seedMaterial: decrypted.seedMaterial,
        walletFilePassword: decrypted.walletFilePassword,
        daemonUri: '',
        restoreHeight: 0,
      ) as TronWallet;
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
      final sun = await w.balanceSun();
      final txes = await w.transactions();
      // Fan out TRC-20 balance fetches in parallel; individual
      // failures stay quiet (the wallet's tokenBalanceRaw catches
      // them and returns zero rather than rethrow).
      //
      // Always record every default token in tokenResults, even when
      // the live balance is zero. Otherwise a temporary TronGrid
      // rate-limit (which makes tokenBalanceRaw return 0) would hide
      // USDT/USDC entirely — users expect to always see "USDT 0.00"
      // so they know the wallet is tracking it. Matches Cake's UX.
      final tokens = w.defaultTokens;
      final tokenResults = <String, BigInt>{};
      if (tokens.isNotEmpty) {
        final balances = await Future.wait(
            tokens.map((t) => w.tokenBalanceRaw(t)));
        for (var i = 0; i < tokens.length; i++) {
          tokenResults[tokens[i].contract] = balances[i];
        }
      }
      // TRC-20 transfer history, filtered to tokens we recognize.
      List<Trc20Transfer> tokenTransfers = const [];
      try {
        final all = await w.trc20Transfers();
        final knownContracts = tokens.map((t) => t.contract).toSet();
        tokenTransfers =
            all.where((t) => knownContracts.contains(t.contract)).toList();
      } catch (_) {/* keep empty */}

      if (!mounted) return;
      setState(() {
        _balanceSun = sun;
        _txes = txes;
        _tokenBalances = tokenResults;
        _tokenTxes = tokenTransfers;
        _err = null;
      });
      final trx = sun / 1000000.0;
      final price = PriceFeed.I.prices['TRX'];
      unawaited(BalanceCache.I.put(CachedBalance(
        walletId: widget.walletMeta.id,
        symbol: 'TRX',
        displayAmount: '${trx.toStringAsFixed(6)} TRX',
        fiatValue: price == null ? 0 : trx * price,
        fiatCurrency: PriceFeed.I.currency,
        updatedAt: DateTime.now(),
      )));
      if (mounted) setState(() => _balanceFromCacheAt = null);
    } catch (e) {
      if (!mounted) return;
      // Keep the cached balance visible — TronGrid is rate-limited
      // and transient failures are common. Surface the error but
      // don't wipe _balanceSun.
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  String _balanceText() {
    if (_wallet == null) return '… TRX';
    final trx = _balanceSun / 1000000.0;
    return '${trx.toStringAsFixed(6)} TRX';
  }

  static String _relTime(DateTime then) {
    final d = DateTime.now().difference(then);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    if (d.inHours < 24) return '${d.inHours} hr';
    return '${d.inDays} d';
  }

  /// Native TRX + TRC-20 transfer history merged into a single
  /// newest-first list.
  List<Object> _mergedTrxHistory() {
    final merged = <Object>[
      ..._txes,
      ..._tokenTxes,
    ];
    merged.sort((a, b) {
      final ta = a is TronTx
          ? a.timestampSec
          : (a as Trc20Transfer).timestampSec;
      final tb = b is TronTx
          ? b.timestampSec
          : (b as Trc20Transfer).timestampSec;
      return tb.compareTo(ta);
    });
    return merged;
  }

  Future<void> _openSendScreen(TronWallet w, Trc20Token? token) async {
    final didSend = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SendTronScreen(wallet: w, token: token),
      ),
    );
    if (didSend == true) {
      unawaited(_refresh());
    }
  }

  void _showReceiveSheet() {
    final w = _wallet;
    if (w == null) return;
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
              const Text(
                'Receive TRX',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: QrImageView(
                    data: w.primaryAddress,
                    version: QrVersions.auto,
                    size: 240,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PeekColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: PeekColors.border),
                ),
                child: SelectableText(
                  w.primaryAddress,
                  style: const TextStyle(
                      fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                      ClipboardData(text: w.primaryAddress));
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Address copied')),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy address'),
              ),
              const SizedBox(height: 8),
              const Text(
                'BIP44 m/44\'/195\'/0\'/0/0. Same address TronLink, '
                'Trust Wallet, and Ledger Live derive from this seed.',
                style: TextStyle(color: PeekColors.text3, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = _wallet;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tron'),
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
                          coinAvatar('TRX', radius: 22),
                          const SizedBox(width: PeekDesign.sp3),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tron',
                                  style: TextStyle(
                                    color: PeekColors.text,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                                Text(
                                  'TRX balance',
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
                          if (_balanceSun == 0) return const SizedBox(height: 4);
                          final fiat = PriceFeed.I.formatFiat(
                              'TRX', _balanceSun / 1000000.0);
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
                          onTap: _balanceSun == 0
                              ? null
                              : () => _openSendScreen(w, null),
                        ),
                      ),
                    ],
                  ),
                if (w != null) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Send is experimental — Tron tx is built by the '
                    'RPC and signed locally with a txid-hash check. '
                    'Test with small amounts. TRC-20 sends need a '
                    'small TRX balance for bandwidth/energy.',
                    style: TextStyle(color: PeekColors.text3, fontSize: 11),
                  ),
                ],
                if (w != null && _tokenBalances.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('Tokens (TRC-20)',
                      style: TextStyle(
                          color: PeekColors.text2, fontSize: 12)),
                  const SizedBox(height: 6),
                  for (final token in w.defaultTokens)
                    if (_tokenBalances[token.contract] != null)
                      _Trc20Row(
                        token: token,
                        rawBalance: _tokenBalances[token.contract]!,
                        wallet: w,
                        onTap: () => _openSendScreen(w, token),
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
                    if (_txes.isNotEmpty || _tokenTxes.isNotEmpty)
                      Text(
                        '${_txes.length + _tokenTxes.length} total',
                        style: const TextStyle(
                            color: PeekColors.text3, fontSize: 11),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                if (_txes.isEmpty && _tokenTxes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      _wallet == null
                          ? 'Loading…'
                          : 'No transactions yet — receive TRX or '
                              'USDT/USDC to this address and they\'ll '
                              'appear here.',
                      style: const TextStyle(
                          color: PeekColors.text3, fontSize: 12),
                    ),
                  )
                else
                  for (final row in _mergedTrxHistory())
                    if (row is TronTx)
                      _TrxTxRow(tx: row)
                    else
                      _Trc20TxRow(tx: row as Trc20Transfer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Display row for one TRC-20 token. Read-only for now — tapping
/// does nothing. Send-token is a follow-up: Tron transactions are
/// protobuf-encoded with a recent-block reference, distinct from
/// the ETH RLP+EIP-1559 path that ERC-20 send rides on.
class _Trc20Row extends StatelessWidget {
  const _Trc20Row({
    required this.token,
    required this.rawBalance,
    required this.wallet,
    required this.onTap,
  });
  final Trc20Token token;
  final BigInt rawBalance;
  final TronWallet wallet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final display = wallet.tokenBalanceDisplay(rawBalance, token);
    return InkWell(
      onTap: onTap,
      child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AnimatedBuilder(
        animation: PriceFeed.I,
        builder: (_, _) {
          // Stablecoin prices are pulled per-symbol; for USDT and
          // USDC this stays near $1 unless the chain has depegged.
          final fiat = PriceFeed.I.formatFiat(token.symbol, display);
          return Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: PeekColors.surface2,
                child: Text(
                  token.symbol.substring(0, 1),
                  style: const TextStyle(
                      color: PeekColors.text, fontSize: 11),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(token.symbol,
                        style: const TextStyle(
                            color: PeekColors.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    Text(token.name,
                        style: const TextStyle(
                            color: PeekColors.text3, fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _fmt(display, token.decimals == 6 ? 2 : 4),
                    style: const TextStyle(
                        color: PeekColors.text, fontSize: 13),
                  ),
                  if (fiat.isNotEmpty)
                    Text('≈ $fiat',
                        style: const TextStyle(
                            color: PeekColors.text3, fontSize: 11)),
                ],
              ),
            ],
          );
        },
      ),
      ),
    );
  }

  static String _fmt(double v, int digits) {
    if (v == 0) return '0';
    if (v < 0.0001) return v.toStringAsExponential(2);
    return v.toStringAsFixed(digits);
  }
}

/// One row for a TRC-20 transfer. Visually distinguished from
/// native TRX rows by a token-symbol chip rather than the directional
/// arrow icon — same convention as the ETH screen's _TokenTxRow.
class _Trc20TxRow extends StatelessWidget {
  const _Trc20TxRow({required this.tx});
  final Trc20Transfer tx;

  @override
  Widget build(BuildContext context) {
    final color = tx.isIncoming ? PeekColors.green : PeekColors.text;
    final sign = tx.isIncoming ? '+' : '−';
    final digits = tx.tokenDecimals == 6 ? 2 : 4;
    final amount =
        '$sign${tx.displayAmount.toStringAsFixed(digits)} ${tx.tokenSymbol}';
    final subtitle = '${_fmtDate(tx.timestamp.toLocal())} · Confirmed';
    return InkWell(
      onTap: () async {
        final url = explorerTxUrl(coinId: 'TRX', txid: tx.hash);
        if (url == null) return;
        await openExplorerUrl(url);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: PeekColors.surface2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  tx.tokenSymbol.length >= 4
                      ? tx.tokenSymbol.substring(0, 4)
                      : tx.tokenSymbol,
                  style: const TextStyle(
                      color: PeekColors.text2, fontSize: 9),
                ),
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
            const Icon(Icons.open_in_new,
                color: PeekColors.text3, size: 16),
          ],
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} '
        '${two(d.hour)}:${two(d.minute)}';
  }
}

class _TrxTxRow extends StatelessWidget {
  const _TrxTxRow({required this.tx});
  final TronTx tx;

  @override
  Widget build(BuildContext context) {
    final color = tx.isIncoming ? PeekColors.green : PeekColors.text;
    final sign = tx.isIncoming ? '+' : '−';
    final amount = '$sign${tx.netTrx.abs().toStringAsFixed(6)} TRX';
    final subtitle = tx.confirmed
        ? '${_fmtDate(tx.timestamp.toLocal())} · Confirmed'
        : 'Failed';
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
    return '${d.year}-${two(d.month)}-${two(d.day)} '
        '${two(d.hour)}:${two(d.minute)}';
  }

  void _showDetails(BuildContext context, TronTx tx) {
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
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _kv('Net amount', '${tx.netTrx.toStringAsFixed(6)} TRX'),
              _kv('Fee', '${tx.feeTrx.toStringAsFixed(6)} TRX'),
              _kv('Status', tx.confirmed ? 'Confirmed' : 'Failed'),
              _kv('Date', _fmtDate(tx.timestamp.toLocal())),
              const Divider(color: PeekColors.border, height: 24),
              const Text('Hash',
                  style: TextStyle(color: PeekColors.text2, fontSize: 12)),
              const SizedBox(height: 4),
              SelectableText(tx.hash,
                  style: const TextStyle(
                      fontSize: 11, fontFamily: 'monospace')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy'),
                      onPressed: () async {
                        await Clipboard.setData(
                            ClipboardData(text: tx.hash));
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Hash copied')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Explorer'),
                      onPressed: () async {
                        final url = explorerTxUrl(
                            coinId: 'TRX', txid: tx.hash);
                        if (url == null) return;
                        final ok = await openExplorerUrl(url);
                        if (!ok && ctx.mounted) {
                          messenger.showSnackBar(const SnackBar(
                              content: Text('Could not open browser')));
                        }
                      },
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

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(k,
                  style:
                      const TextStyle(color: PeekColors.text2, fontSize: 12)),
            ),
            Expanded(
              child: Text(v,
                  style:
                      const TextStyle(color: PeekColors.text, fontSize: 13)),
            ),
          ],
        ),
      );
}
