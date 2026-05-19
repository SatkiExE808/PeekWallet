import 'dart:async';

import 'package:flutter/material.dart';
import '../coins/solana/solana_module.dart';
import '../coins/solana/solana_rpc_client.dart';
import '../coins/solana/solana_wallet.dart';
import '../coins/solana/spl_tokens.dart';
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
import '../widgets/tx_detail_sheet.dart';
import 'send_solana_screen.dart';

/// Solana coin page. Receive + balance + history; send is a follow-up
/// (we need SystemProgram.transfer build + ed25519 signing + base64
/// serialization + sendTransaction RPC).
class SolanaCoinScreen extends StatefulWidget {
  const SolanaCoinScreen({super.key, required this.walletMeta});
  final WalletMeta walletMeta;

  @override
  State<SolanaCoinScreen> createState() => _SolanaCoinScreenState();
}

class _SolanaCoinScreenState extends State<SolanaCoinScreen> {
  SolanaWallet? _wallet;
  String? _err;
  int _balanceLamports = 0;
  DateTime? _balanceFromCacheAt;
  List<SolanaTxDetail> _txes = const [];
  /// SPL token balances keyed by mint address. Populated alongside
  /// the native SOL balance during each refresh.
  Map<String, BigInt> _tokenBalances = const {};
  /// SPL token transfer history. Each entry is a parsed Token
  /// Program transfer — direction (incoming/outgoing) is inferred
  /// from whether our wallet owner address is the authority on
  /// the source ATA.
  List<SolanaTokenTx> _tokenTxes = const [];
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
    // mainnet-beta's RPC finishes (or fails, the public node is
    // commonly rate-limited).
    final cached = await BalanceCache.I.get(widget.walletMeta.id);
    if (cached != null && mounted) {
      final m =
          RegExp(r'([0-9]+\.[0-9]+)').firstMatch(cached.displayAmount);
      if (m != null) {
        final sol = double.tryParse(m.group(1)!) ?? 0;
        final age = DateTime.now().difference(cached.updatedAt);
        setState(() {
          _balanceLamports = (sol * 1000000000).round();
          _balanceFromCacheAt =
              age > const Duration(seconds: 60) ? cached.updatedAt : null;
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
      final mod = const SolanaModule();
      final w = await mod.open(
        walletId: widget.walletMeta.id,
        format: widget.walletMeta.format,
        seedMaterial: decrypted.seedMaterial,
        walletFilePassword: decrypted.walletFilePassword,
        daemonUri: '',
        restoreHeight: 0,
      ) as SolanaWallet;
      if (!mounted) return;
      setState(() => _wallet = w);
      unawaited(_refresh());
      // Solana confirms every ~400ms but the public RPC rate-limits
      // hard — 30s poll is the same cadence we use elsewhere.
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
      final balance = await w.balanceLamports();
      final txes = await w.transactions();
      // Fan out SPL token balance fetches in parallel. Same pattern
      // as the ERC-20 / TRC-20 paths — record every default token
      // even with zero balance so a transient mainnet-beta failure
      // doesn't hide the user's USDC/USDT row.
      final tokens = w.defaultTokens;
      final tokenResults = <String, BigInt>{};
      if (tokens.isNotEmpty) {
        final balances = await Future.wait(
            tokens.map((t) => w.tokenBalanceRaw(t)));
        for (var i = 0; i < tokens.length; i++) {
          tokenResults[tokens[i].mint] = balances[i];
        }
      }
      // SPL token transfer history — fetched in parallel with the
      // native side. Errors are swallowed (the wallet's splTransfers
      // catches per-token failures and continues), so the worst
      // case is an empty token-tx list this cycle.
      List<SolanaTokenTx> splTxes = const [];
      try {
        splTxes = await w.splTransfers();
      } catch (_) {/* keep empty */}

      if (!mounted) return;
      setState(() {
        _balanceLamports = balance;
        _txes = txes;
        _tokenBalances = tokenResults;
        _tokenTxes = splTxes;
        _err = null;
      });
      final sol = balance / 1000000000.0;
      final price = PriceFeed.I.prices['SOL'];
      unawaited(BalanceCache.I.put(CachedBalance(
        walletId: widget.walletMeta.id,
        symbol: 'SOL',
        displayAmount: '${sol.toStringAsFixed(6)} SOL',
        fiatValue: price == null ? 0 : sol * price,
        fiatCurrency: PriceFeed.I.currency,
        updatedAt: DateTime.now(),
      )));
      if (mounted) setState(() => _balanceFromCacheAt = null);
    } catch (e) {
      if (!mounted) return;
      // Keep the cached balance visible — mainnet-beta's public RPC
      // is rate-limited and transient failures are common. Surface
      // the error but don't wipe _balanceLamports.
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  String _balanceText() {
    if (_wallet == null) return '… SOL';
    final sol = _balanceLamports / 1000000000.0;
    return '${sol.toStringAsFixed(6)} SOL';
  }

  static String _relTime(DateTime then) {
    final d = DateTime.now().difference(then);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    if (d.inHours < 24) return '${d.inHours} hr';
    return '${d.inDays} d';
  }

  Future<void> _openSendScreen(SolanaWallet w) async {
    final didSend = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SendSolanaScreen(wallet: w),
      ),
    );
    if (didSend == true) {
      unawaited(_refresh());
    }
  }

  /// Native SOL + SPL transfers merged into one newest-first list.
  /// Token entries pass through unchanged; the row branching at the
  /// callsite picks the right widget per type.
  List<Object> _mergedSolHistory() {
    final merged = <Object>[
      ..._txes,
      ..._tokenTxes,
    ];
    merged.sort((a, b) {
      final ta = a is SolanaTxDetail
          ? a.timestampSec
          : (a as SolanaTokenTx).timestampSec;
      final tb = b is SolanaTxDetail
          ? b.timestampSec
          : (b as SolanaTokenTx).timestampSec;
      return tb.compareTo(ta);
    });
    return merged;
  }

  Future<void> _openSplSendScreen(SolanaWallet w, SplToken token) async {
    final didSend = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SendSolanaScreen(wallet: w, token: token),
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
      coinId: 'SOL',
      coinName: 'Solana',
      address: w.primaryAddress,
      derivationHint:
          "SLIP-0010 ed25519, path m/44'/501'/0'/0'. Same address Phantom, "
          "Solflare, Backpack and other major wallets derive from this seed.",
    );
  }


  @override
  Widget build(BuildContext context) {
    final w = _wallet;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solana'),
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
                          coinAvatar('SOL', radius: 22),
                          const SizedBox(width: PeekDesign.sp3),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Solana',
                                  style: TextStyle(
                                    color: PeekColors.text,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                                Text(
                                  'SOL balance',
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
                          if (_balanceLamports == 0) {
                            return const SizedBox(height: 4);
                          }
                          final fiat = PriceFeed.I.formatFiat(
                              'SOL', _balanceLamports / 1000000000.0);
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
                          onTap: _balanceLamports == 0
                              ? null
                              : () => _openSendScreen(w),
                        ),
                      ),
                    ],
                  ),
                if (w != null) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Send is experimental — the SystemProgram.transfer '
                    'encoder is unit-tested but the end-to-end flow '
                    'has not been audited. Test with small amounts.',
                    style:
                        TextStyle(color: PeekColors.text3, fontSize: 11),
                  ),
                ],
                if (w != null && _tokenBalances.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('Tokens (SPL)',
                      style: TextStyle(
                          color: PeekColors.text2, fontSize: 12)),
                  const SizedBox(height: 6),
                  for (final token in w.defaultTokens)
                    if (_tokenBalances[token.mint] != null)
                      _SplRow(
                        token: token,
                        rawBalance: _tokenBalances[token.mint]!,
                        wallet: w,
                        onTap: () => _openSplSendScreen(w, token),
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
                          : 'No transactions yet — give your receive '
                              'address to a sender, refresh, and incoming '
                              'SOL or tokens appear here.',
                      style: const TextStyle(
                          color: PeekColors.text3, fontSize: 12),
                    ),
                  )
                else
                  for (final row in _mergedSolHistory())
                    if (row is SolanaTxDetail)
                      _SolTxRow(tx: row)
                    else
                      _SolTokenTxRow(tx: row as SolanaTokenTx),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Display row for one SPL token. Read-only for now — send is a
/// follow-up that needs the Token Program transfer instruction +
/// associated-token-account creation logic.
class _SplRow extends StatelessWidget {
  const _SplRow({
    required this.token,
    required this.rawBalance,
    required this.wallet,
    required this.onTap,
  });
  final SplToken token;
  final BigInt rawBalance;
  final SolanaWallet wallet;
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

/// One row for an SPL token transfer. Visually distinguished from
/// native SOL rows by a token-symbol chip in the leading icon —
/// same convention as the ETH/MATIC and Tron screens.
class _SolTokenTxRow extends StatelessWidget {
  const _SolTokenTxRow({required this.tx});
  final SolanaTokenTx tx;

  @override
  Widget build(BuildContext context) {
    final color = tx.isIncoming ? PeekColors.green : PeekColors.text;
    final sign = tx.isIncoming ? '+' : '−';
    final digits = tx.tokenDecimals == 6 ? 2 : 4;
    final amount =
        '$sign${tx.displayAmount.toStringAsFixed(digits)} ${tx.tokenSymbol}';
    final subtitle =
        '${_fmtDate(tx.timestamp.toLocal())} · Confirmed';
    return InkWell(
      onTap: () async {
        final url = explorerTxUrl(coinId: 'SOL', txid: tx.signature);
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

class _SolTxRow extends StatelessWidget {
  const _SolTxRow({required this.tx});
  final SolanaTxDetail tx;

  @override
  Widget build(BuildContext context) {
    final color = tx.isIncoming ? PeekColors.green : PeekColors.text;
    final sign = tx.isIncoming ? '+' : '−';
    final amount = '$sign${tx.netSol.abs().toStringAsFixed(6)} SOL';
    final subtitle = tx.confirmed
        ? '${_fmtDate(tx.timestamp.toLocal())} · Confirmed'
        : 'Failed';
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

  void _showDetails(BuildContext context, SolanaTxDetail tx) {
    final sign = tx.isIncoming ? '+' : '−';
    showTxDetailSheet(
      context,
      coinId: 'SOL',
      isIncoming: tx.isIncoming,
      amountText: '$sign${tx.netSol.abs().toStringAsFixed(6)} SOL',
      amountColor: tx.isIncoming ? PeekColors.green : PeekColors.text,
      rows: [
        TxDetailRow('Network fee', '${tx.feeSol.toStringAsFixed(9)} SOL'),
        TxDetailRow('Slot', tx.slot.toString()),
        TxDetailRow('Date', fmtTxDate(tx.timestamp.toLocal())),
      ],
      hashLabel: 'Signature',
      hashValue: tx.signature,
      statusText: tx.confirmed ? 'Confirmed' : 'Failed',
      statusColor:
          tx.confirmed ? PeekColors.green : PeekColors.red,
      statusIcon: tx.confirmed
          ? Icons.check_circle_rounded
          : Icons.error_outline_rounded,
    );
  }
}
