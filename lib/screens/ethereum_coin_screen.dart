import 'dart:async';

import 'package:flutter/material.dart';
import '../coins/ethereum/custom_token_store.dart';
import '../coins/ethereum/erc20_tokens.dart';
import '../coins/ethereum/ethereum_module.dart';
import '../coins/ethereum/ethereum_wallet.dart';
import '../coins/ethereum/etherscan_client.dart';
import '../prices/price_feed.dart';
import '../theme.dart';
import '../vault/vault_state.dart';
import '../wallets/wallet_meta.dart';
import '../wallets/wallet_store.dart';
import '../util/coin_avatar.dart';
import '../wallets/balance_cache.dart';
import '../widgets/coin_screen_widgets.dart';
import '../widgets/receive_sheet.dart';
import '../widgets/tx_detail_sheet.dart';
import 'send_ethereum_screen.dart';

/// Ethereum coin page. Lighter than the Bitcoin one because we don't
/// yet have send (RLP + EIP-1559 land in a follow-up), so this is
/// receive + balance + history only.
class EthereumCoinScreen extends StatefulWidget {
  const EthereumCoinScreen({super.key, required this.walletMeta});
  final WalletMeta walletMeta;

  @override
  State<EthereumCoinScreen> createState() => _EthereumCoinScreenState();
}

class _EthereumCoinScreenState extends State<EthereumCoinScreen> {
  EthereumWallet? _wallet;
  String? _err;
  BigInt _balanceWei = BigInt.zero;
  DateTime? _balanceFromCacheAt;
  List<EthereumTx> _txes = const [];
  /// Token balances keyed by contract address. Populated on each
  /// _refresh() so the UI can show USDT/USDC/DAI rows under the
  /// native ETH/MATIC row.
  Map<String, BigInt> _tokenBalances = const {};
  /// All tokens we display (defaults + user-added). Re-fetched on
  /// each refresh so newly-added custom tokens appear immediately.
  List<Erc20Token> _tokens = const [];
  /// ERC-20 token transfer history, filtered to tokens we recognize
  /// (defaults + custom). Sorted newest-first.
  List<TokenTransfer> _tokenTxes = const [];
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
    // Pre-fill from BalanceCache so users see a balance instantly
    // even if the RPC takes a moment.
    final cached = await BalanceCache.I.get(widget.walletMeta.id);
    if (cached != null && mounted) {
      // Parse "x.yyy ETH" → wei via string math so we don't lose
      // precision through double * 1e18 (ETH has 18 decimals, doubles
      // give ~15 significant digits — the round-trip loses up to
      // 1e3 wei and is wildly off for whole-ETH balances).
      final m =
          RegExp(r'([0-9]+)\.([0-9]+)').firstMatch(cached.displayAmount);
      if (m != null) {
        final whole = m.group(1)!;
        final frac = m.group(2)!;
        // Pad/truncate frac to 18 digits, then concat whole+frac as
        // a single integer string; that's the wei value exactly.
        final padded = frac.length >= 18
            ? frac.substring(0, 18)
            : frac + '0' * (18 - frac.length);
        final weiStr = (whole == '0' ? '' : whole) + padded;
        final wei =
            BigInt.tryParse(weiStr.replaceFirst(RegExp(r'^0+'), '')) ??
                BigInt.zero;
        setState(() {
          _balanceWei = wei;
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
      // Same screen serves ETH and any other EVM chain (Polygon
      // for now) — pick the module from coinId.
      final EvmCoinModule mod;
      switch (widget.walletMeta.coinId) {
        case 'POL':
          mod = const PolygonModule();
          break;
        case 'ETH':
        default:
          mod = const EthereumModule();
      }
      final w = await mod.open(
        walletId: widget.walletMeta.id,
        format: widget.walletMeta.format,
        seedMaterial: decrypted.seedMaterial,
        walletFilePassword: decrypted.walletFilePassword,
        daemonUri: '',
        restoreHeight: 0,
      ) as EthereumWallet;
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
      final wei = await w.balanceWei();
      final txes = await w.transactions();
      // Fetch token balances in parallel for the merged default +
      // custom token list. Individual failures stay quiet (the
      // wallet's tokenBalanceRaw catches them and returns zero).
      //
      // Record every token even with zero balance so a transient RPC
      // failure doesn't hide USDT/USDC etc. — users expect to always
      // see their stablecoin rows; the alternative ("hide on zero")
      // looks broken when the public RPC throttles us.
      final tokens = await w.tokensFor(widget.walletMeta.id);
      final tokenResults = <String, BigInt>{};
      if (tokens.isNotEmpty) {
        final balances = await Future.wait(
            tokens.map((t) => w.tokenBalanceRaw(t)));
        for (var i = 0; i < tokens.length; i++) {
          tokenResults[tokens[i].contract] = balances[i];
        }
      }

      // Fetch token transfer history in parallel with everything
      // else; filter to tokens we recognize so unrelated airdrops
      // don't clutter the list.
      List<TokenTransfer> tokenTransfers = const [];
      try {
        final all = await w.tokenTransfers();
        final knownContracts =
            tokens.map((t) => t.contract.toLowerCase()).toSet();
        tokenTransfers = all
            .where((t) => knownContracts.contains(t.contract.toLowerCase()))
            .toList();
      } catch (_) {/* keep empty */}

      if (!mounted) return;
      setState(() {
        _balanceWei = wei;
        _txes = txes;
        _tokenBalances = tokenResults;
        _tokens = tokens;
        _tokenTxes = tokenTransfers;
        _err = null;
      });
      final eth = EthereumTx.weiToEth(wei);
      final price = PriceFeed.I.prices[_symbol];
      unawaited(BalanceCache.I.put(CachedBalance(
        walletId: widget.walletMeta.id,
        symbol: _symbol,
        displayAmount: '${eth.toStringAsFixed(6)} $_symbol',
        fiatValue: price == null ? 0 : eth * price,
        fiatCurrency: PriceFeed.I.currency,
        updatedAt: DateTime.now(),
      )));
      if (mounted) setState(() => _balanceFromCacheAt = null);
    } catch (e) {
      if (!mounted) return;
      // Keep cached balance on screen; flag the live-fetch error.
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  String get _symbol => _wallet?.network.symbol ?? widget.walletMeta.coinId;
  String get _coinName => _wallet?.network.name ?? 'Ethereum';

  String _relTime(DateTime then) {
    final d = DateTime.now().difference(then);
    if (d.inSeconds < 60) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  String _balanceText() {
    if (_wallet == null) return '… $_symbol';
    final eth = EthereumTx.weiToEth(_balanceWei);
    return '${eth.toStringAsFixed(6)} $_symbol';
  }

  /// Dialog flow for adding a custom ERC-20 token by contract
  /// address. We probe the chain for the token's symbol + decimals
  /// so the user doesn't have to type them manually.
  Future<void> _addCustomToken(EthereumWallet w) async {
    final controller = TextEditingController();
    final contract = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add custom ERC-20 token'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Paste the token\'s contract address. We\'ll fetch its '
              'symbol and decimals from the chain.',
              style: TextStyle(color: PeekColors.text2, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Contract address',
                hintText: '0x…',
              ),
              autocorrect: false,
              enableSuggestions: false,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Probe'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (contract == null || contract.isEmpty || !mounted) return;
    if (!contract.startsWith('0x') || contract.length != 42) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Contract must be 0x + 40 hex chars'),
      ));
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(
      content: Row(
        children: [
          const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 12),
          Text('Probing ${contract.substring(0, 10)}…'),
        ],
      ),
      duration: const Duration(seconds: 10),
    ));

    final info = await w.probeToken(contract);
    if (!mounted) return;
    messenger.hideCurrentSnackBar();
    if (info == null || info.symbol == '?') {
      messenger.showSnackBar(const SnackBar(
        content: Text(
            'Could not read token metadata — wrong chain or not an ERC-20?'),
      ));
      return;
    }

    await CustomTokenStore.I.add(
      widget.walletMeta.id,
      Erc20Token(
        symbol: info.symbol,
        name: '${info.symbol} (custom)',
        contract: contract.toLowerCase(),
        decimals: info.decimals,
        chainId: w.network.chainId,
      ),
    );
    messenger.showSnackBar(SnackBar(
      content: Text(
          'Added ${info.symbol} (${info.decimals} decimals)'),
    ));
    // Trigger a refresh so the new token's balance loads.
    unawaited(_refresh());
  }

  /// Native ETH txes + ERC-20 token transfers merged into a single
  /// list, sorted newest-first by timestamp. We accept the mixed
  /// type because rendering branches on it anyway; saves an
  /// intermediate wrapper class.
  List<Object> _mergedTxList() {
    final merged = <Object>[
      ..._txes,
      ..._tokenTxes,
    ];
    merged.sort((a, b) {
      final ta = a is EthereumTx
          ? a.timestampSec
          : (a as TokenTransfer).timestampSec;
      final tb = b is EthereumTx
          ? b.timestampSec
          : (b as TokenTransfer).timestampSec;
      return tb.compareTo(ta);
    });
    return merged;
  }

  Future<void> _openSendScreen(EthereumWallet w) async {
    final didSend = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SendEthereumScreen(wallet: w),
      ),
    );
    if (didSend == true) {
      unawaited(_refresh());
    }
  }

  Future<void> _openTokenSendScreen(
      EthereumWallet w, Erc20Token token) async {
    final didSend = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SendEthereumScreen(wallet: w, token: token),
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
      coinId: _symbol,
      coinName: _coinName,
      address: w.primaryAddress,
      derivationHint:
          "BIP44 m/44'/60'/0'/0/0. Same address every BIP39-compatible "
          "wallet (MetaMask, Trezor, Ledger Live, Rabby) derives from "
          "this seed.",
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
                          if (_balanceWei == BigInt.zero) {
                            return const SizedBox(height: 4);
                          }
                          final fiat = PriceFeed.I.formatFiat(
                              _symbol, EthereumTx.weiToEth(_balanceWei));
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
                          onTap: _balanceWei == BigInt.zero
                              ? null
                              : () => _openSendScreen(w),
                        ),
                      ),
                    ],
                  ),
                if (w != null) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Send is experimental — RLP + EIP-1559 sighash + '
                    'ECDSA-recovery are unit-tested but the end-to-end '
                    'flow has not been audited. Test with small amounts.',
                    style:
                        TextStyle(color: PeekColors.text3, fontSize: 11),
                  ),
                ],
                if (w != null) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Tokens',
                            style: TextStyle(
                                color: PeekColors.text2, fontSize: 12)),
                      ),
                      TextButton.icon(
                        onPressed: () => _addCustomToken(w),
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('Add token',
                            style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 0),
                          minimumSize: const Size(0, 24),
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (_tokenBalances.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No tokens yet — receive USDT/USDC/DAI to this '
                        'address or tap "Add token" to track another '
                        'ERC-20 by contract address.',
                        style: TextStyle(
                            color: PeekColors.text3, fontSize: 11),
                      ),
                    )
                  else
                    for (final token in _tokens)
                      if (_tokenBalances[token.contract] != null)
                        _TokenRow(
                          token: token,
                          rawBalance: _tokenBalances[token.contract]!,
                          wallet: w,
                          onTap: () => _openTokenSendScreen(w, token),
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
                              '$_symbol or tokens appear here.',
                      style: const TextStyle(
                          color: PeekColors.text3, fontSize: 12),
                    ),
                  )
                else
                  for (final row in _mergedTxList())
                    if (row is EthereumTx)
                      _EthTxRow(tx: row, symbol: _symbol)
                    else
                      _TokenTxRow(
                        tx: row as TokenTransfer,
                        chainSymbol: _symbol,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Display row for one ERC-20 token. Shows the user's balance in
/// display units (USDT/USDC have 6 decimals; DAI has 18) and the
/// fiat conversion if the price feed has a quote for that symbol.
/// Read-only for now — tapping does nothing. Send-token is a
/// follow-up that needs a token-aware send screen.
class _TokenRow extends StatelessWidget {
  const _TokenRow({
    required this.token,
    required this.rawBalance,
    required this.wallet,
    required this.onTap,
  });
  final Erc20Token token;
  final BigInt rawBalance;
  final EthereumWallet wallet;
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

/// One row in the merged history list for an ERC-20 token transfer.
/// Visually distinguished from native txes by a token-symbol chip
/// in the leading icon — so the user can immediately tell "USDT in"
/// from "ETH in".
class _TokenTxRow extends StatelessWidget {
  const _TokenTxRow({required this.tx, required this.chainSymbol});
  final TokenTransfer tx;
  /// The native coin's symbol (ETH / MATIC). Drives which block
  /// explorer the "Explorer" button opens — etherscan.io vs
  /// polygonscan.com. Without this the row always opened ETH's
  /// explorer even on Polygon.
  final String chainSymbol;

  @override
  Widget build(BuildContext context) {
    final color = tx.isIncoming ? PeekColors.green : PeekColors.text;
    final sign = tx.isIncoming ? '+' : '−';
    final display = tx.displayAmount;
    // Stablecoins (6-dec USDT/USDC) want 2 display digits; long-tail
    // tokens with 18 decimals get 4 to avoid losing the user's eye
    // in a sea of zeros.
    final digits = tx.tokenDecimals == 6 ? 2 : 4;
    final amount = '$sign${display.toStringAsFixed(digits)} ${tx.tokenSymbol}';
    final subtitle = tx.confirmed
        ? '${_fmtDate(tx.timestamp.toLocal())} · Confirmed'
        : 'Pending';
    return InkWell(
      onTap: () => _showDetails(context),
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

  void _showDetails(BuildContext context) {
    final digits = tx.tokenDecimals == 6 ? 2 : 4;
    final sign = tx.isIncoming ? '+' : '−';
    showTxDetailSheet(
      context,
      coinId: chainSymbol,
      isIncoming: tx.isIncoming,
      amountText:
          '$sign${tx.displayAmount.toStringAsFixed(digits)} ${tx.tokenSymbol}',
      amountColor: tx.isIncoming ? PeekColors.green : PeekColors.text,
      rows: [
        TxDetailRow('Token', tx.tokenSymbol),
        TxDetailRow('Counterparty',
            '${(tx.isIncoming ? tx.from : tx.to).substring(0, 10)}…'),
        TxDetailRow('Date', fmtTxDate(tx.timestamp.toLocal())),
      ],
      hashLabel: 'Hash',
      hashValue: tx.hash,
    );
  }
}

class _EthTxRow extends StatelessWidget {
  const _EthTxRow({required this.tx, required this.symbol});
  final EthereumTx tx;
  /// Coin symbol — "ETH" or "MATIC". Drives the amount label so the
  /// same row layout renders for either chain.
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final color = tx.isIncoming ? PeekColors.green : PeekColors.text;
    final sign = tx.isIncoming ? '+' : '−';
    final amount =
        '$sign${tx.netEth.abs().toStringAsFixed(6)} $symbol';
    final subtitle = tx.confirmed
        ? '${_fmtDate(tx.timestamp.toLocal())} · Confirmed'
        : 'Pending';
    return InkWell(
      onTap: () => _showDetails(context, tx),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
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

  void _showDetails(BuildContext context, EthereumTx tx) {
    final sign = tx.isIncoming ? '+' : '−';
    showTxDetailSheet(
      context,
      coinId: symbol,
      isIncoming: tx.isIncoming,
      amountText:
          '$sign${tx.netEth.abs().toStringAsFixed(6)} $symbol',
      amountColor: tx.isIncoming ? PeekColors.green : PeekColors.text,
      rows: [
        TxDetailRow('Gas fee', '${tx.gasFeeEth.toStringAsFixed(6)} $symbol'),
        TxDetailRow('Block height',
            tx.blockHeight == 0 ? '—' : tx.blockHeight.toString()),
        TxDetailRow('Date', fmtTxDate(tx.timestamp.toLocal())),
      ],
      hashLabel: 'Hash',
      hashValue: tx.hash,
      statusText: tx.confirmed ? 'Confirmed' : 'Pending',
      statusColor: tx.confirmed ? PeekColors.green : PeekColors.accent,
      statusIcon: tx.confirmed
          ? Icons.check_circle_rounded
          : Icons.hourglass_top_rounded,
    );
  }
}
