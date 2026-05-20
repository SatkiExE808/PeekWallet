import 'dart:async';

import 'package:flutter/material.dart';
import '../coins/tron/trc20.dart';
import '../coins/tron/tron_module.dart';
import '../coins/tron/tron_wallet.dart';
import '../coins/tron/trongrid_client.dart';
import 'send_tron_screen.dart';
import '../l10n/gen/app_localizations.dart';
import '../prices/price_feed.dart';
import '../theme.dart';
import '../util/coin_avatar.dart';
import '../util/explorer_links.dart';
import '../util/lifecycle_poller.dart';
import '../wallets/balance_cache.dart';
import '../widgets/animated_balance.dart';
import '../vault/vault_state.dart';
import '../wallets/wallet_meta.dart';
import '../wallets/wallet_store.dart';
import '../widgets/coin_screen_widgets.dart';
import '../widgets/receive_sheet.dart';
import '../widgets/tx_detail_sheet.dart';

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

enum _SetupErrKind { none, vaultLocked, openFailed }

class _TronCoinScreenState extends State<TronCoinScreen>
    with LifecyclePoller {
  TronWallet? _wallet;
  String? _err;
  _SetupErrKind _setupErrKind = _SetupErrKind.none;
  String? _setupErrDetail;
  int _balanceSun = 0;
  DateTime? _balanceFromCacheAt;
  List<TronTx> _txes = const [];
  /// TRC-20 balances keyed by base58 contract address. Populated
  /// in _refresh() alongside the native TRX balance.
  Map<String, BigInt> _tokenBalances = const {};
  /// TRC-20 transfer history, filtered to tokens we recognize.
  List<Trc20Transfer> _tokenTxes = const [];
  bool _refreshing = false;

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
    // Pre-fill from BalanceCache so the user sees a number before
    // the TronGrid balance call completes (or fails — public TronGrid
    // is rate-limited and 429s under contention).
    final cached = await BalanceCache.I.get(widget.walletMeta.id);
    if (cached != null && mounted) {
      final m =
          RegExp(r'([0-9]+\.[0-9]+)').firstMatch(cached.displayAmount);
      if (m != null) {
        final trx = double.tryParse(m.group(1)!) ?? 0;
        final age = DateTime.now().difference(cached.updatedAt);
        setState(() {
          _balanceSun = (trx * 1000000).round();
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


  static String _relTime(AppLocalizations l, DateTime then) {
    final d = DateTime.now().difference(then);
    if (d.inMinutes < 1) return l.ageJustNow;
    if (d.inMinutes < 60) return l.ageMinutes(d.inMinutes);
    if (d.inHours < 24) return l.ageHours(d.inHours);
    return l.ageDays(d.inDays);
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
    showReceiveSheet(
      context,
      coinId: 'TRX',
      coinName: 'Tron',
      address: w.primaryAddress,
      derivationHint:
          "BIP44 m/44'/195'/0'/0/0. Same address TronLink, Trust Wallet, "
          "and Ledger Live derive from this seed.",
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
        title: const Text('Tron'),
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
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                  decoration: BoxDecoration(
                    borderRadius: PeekDesign.brHero,
                    gradient: PeekDesign.coinHeroGradient(
                        PeekColors.coinAccent('TRX')),
                    border: Border.all(color: PeekColors.border, width: 1),
                    boxShadow: PeekDesign.cardShadow,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned(
                        right: -50,
                        top: -50,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: PeekDesign.heroAccentBloom(
                              PeekColors.coinAccent('TRX')),
                        ),
                      ),
                      Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          coinAvatar('TRX', radius: 22),
                          const SizedBox(width: PeekDesign.sp3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tron',
                                  style: TextStyle(
                                    color: PeekColors.text,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                                Text(
                                  l.coinScreenBalanceLabel('TRX'),
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
                      AnimatedBalance(
                        amount: _wallet == null
                            ? 0
                            : _balanceSun / 1000000.0,
                        formatter: (v) => _wallet == null
                            ? '… TRX'
                            : '${v.toStringAsFixed(6)} TRX',
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
                          onTap: _balanceSun == 0
                              ? null
                              : () => _openSendScreen(w, null),
                        ),
                      ),
                    ],
                  ),
                if (w != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    l.experimentalSendWarning('TRX'),
                    style: const TextStyle(
                        color: PeekColors.text3, fontSize: 11),
                  ),
                ],
                if (w != null && _tokenBalances.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(l.tronTokensTitle,
                      style: const TextStyle(
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
                SectionHeader(
                  title: l.coinScreenActivityTitle,
                  countChip: (_txes.isEmpty && _tokenTxes.isEmpty)
                      ? null
                      : (_txes.length + _tokenTxes.length).toString(),
                ),
                const SizedBox(height: 6),
                if (_txes.isEmpty && _tokenTxes.isEmpty)
                  EmptyActivity(loading: _wallet == null, coinLabel: 'TRX')
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
              coinAvatar(token.symbol, radius: 14),
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
    final l = AppLocalizations.of(context);
    final color = tx.isIncoming ? PeekColors.green : PeekColors.text;
    final sign = tx.isIncoming ? '+' : '−';
    final digits = tx.tokenDecimals == 6 ? 2 : 4;
    final amount =
        '$sign${tx.displayAmount.toStringAsFixed(digits)} ${tx.tokenSymbol}';
    final subtitle =
        '${_fmtDate(tx.timestamp.toLocal())} · ${l.txStatusConfirmed}';
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
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: PeekColors.surface2,
                borderRadius: PeekDesign.brSmall,
              ),
              child: Text(
                tx.tokenSymbol.length >= 4
                    ? tx.tokenSymbol.substring(0, 4)
                    : tx.tokenSymbol,
                style: const TextStyle(
                    color: PeekColors.text2,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3),
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
    final l = AppLocalizations.of(context);
    final color = tx.isIncoming ? PeekColors.green : PeekColors.text;
    final sign = tx.isIncoming ? '+' : '−';
    final amount = '$sign${tx.netTrx.abs().toStringAsFixed(6)} TRX';
    final subtitle = tx.confirmed
        ? '${_fmtDate(tx.timestamp.toLocal())} · ${l.txStatusConfirmed}'
        : l.txStatusFailed;
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
    return '${d.year}-${two(d.month)}-${two(d.day)} '
        '${two(d.hour)}:${two(d.minute)}';
  }

  void _showDetails(BuildContext context, TronTx tx) {
    final l = AppLocalizations.of(context);
    final sign = tx.isIncoming ? '+' : '−';
    showTxDetailSheet(
      context,
      coinId: 'TRX',
      isIncoming: tx.isIncoming,
      amountText: '$sign${tx.netTrx.abs().toStringAsFixed(6)} TRX',
      amountColor: tx.isIncoming ? PeekColors.green : PeekColors.text,
      rows: [
        TxDetailRow(l.txFeeLabel, '${tx.feeTrx.toStringAsFixed(6)} TRX'),
        TxDetailRow(l.txDateLabel, fmtTxDate(tx.timestamp.toLocal())),
      ],
      hashLabel: l.txHashLabel,
      hashValue: tx.hash,
      statusText: tx.confirmed ? l.txStatusConfirmed : l.txStatusFailed,
      statusColor:
          tx.confirmed ? PeekColors.green : PeekColors.red,
      statusIcon: tx.confirmed
          ? Icons.check_circle_rounded
          : Icons.error_outline_rounded,
    );
  }
}
