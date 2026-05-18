import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../coins/ethereum/erc20_tokens.dart';
import '../coins/ethereum/ethereum_module.dart';
import '../coins/ethereum/ethereum_wallet.dart';
import '../coins/ethereum/etherscan_client.dart';
import '../prices/price_feed.dart';
import '../theme.dart';
import '../vault/vault_state.dart';
import '../wallets/wallet_meta.dart';
import '../wallets/wallet_store.dart';
import '../util/explorer_links.dart';
import '../wallets/balance_cache.dart';
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
  List<EthereumTx> _txes = const [];
  /// Token balances keyed by contract address. Populated on each
  /// _refresh() so the UI can show USDT/USDC/DAI rows under the
  /// native ETH/MATIC row.
  Map<String, BigInt> _tokenBalances = const {};
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
        case 'MATIC':
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
      // Fetch token balances in parallel — cheap eth_call's that
      // skip if the wallet is closed mid-fetch. We don't fail the
      // whole refresh on individual token errors; the wallet's
      // tokenBalanceRaw swallows them and returns zero.
      final tokens = w.defaultTokens;
      final tokenResults = <String, BigInt>{};
      if (tokens.isNotEmpty) {
        final balances = await Future.wait(
            tokens.map((t) => w.tokenBalanceRaw(t)));
        for (var i = 0; i < tokens.length; i++) {
          if (balances[i] > BigInt.zero) {
            tokenResults[tokens[i].contract] = balances[i];
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _balanceWei = wei;
        _txes = txes;
        _tokenBalances = tokenResults;
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  String get _symbol => _wallet?.network.symbol ?? widget.walletMeta.coinId;
  String get _coinName => _wallet?.network.name ?? 'Ethereum';

  String _balanceText() {
    if (_wallet == null) return '… $_symbol';
    final eth = EthereumTx.weiToEth(_balanceWei);
    return '${eth.toStringAsFixed(6)} $_symbol';
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
                'Receive $_symbol',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
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
                'BIP44 m/44\'/60\'/0\'/0/0. Same address every BIP39-'
                'compatible wallet (MetaMask, Trezor, Ledger Live, '
                'Rabby) derives from this seed.',
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _symbol == 'MATIC'
                          ? const Color(0xFF8247E5)
                          : const Color(0xFF627EEA),
                      radius: 18,
                      child: Icon(
                        _symbol == 'MATIC'
                            ? Icons.hexagon
                            : Icons.diamond,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$_symbol balance',
                      style: const TextStyle(
                          color: PeekColors.text2, fontSize: 13),
                    ),
                    const Spacer(),
                    if (_refreshing)
                      const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: PeekColors.accent),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _balanceText(),
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.w700),
                ),
                AnimatedBuilder(
                  animation: PriceFeed.I,
                  builder: (_, _) {
                    if (_balanceWei == BigInt.zero) {
                      return const SizedBox.shrink();
                    }
                    final fiat = PriceFeed.I.formatFiat(
                        _symbol, EthereumTx.weiToEth(_balanceWei));
                    if (fiat.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('≈ $fiat',
                          style: const TextStyle(
                              color: PeekColors.text2, fontSize: 13)),
                    );
                  },
                ),
                if (_err != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_err!,
                        style: const TextStyle(
                            color: PeekColors.red, fontSize: 11)),
                  ),
                const SizedBox(height: 20),
                if (w != null)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showReceiveSheet,
                          icon: const Icon(Icons.qr_code, size: 18),
                          label: const Text('Receive'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _balanceWei == BigInt.zero
                              ? null
                              : () => _openSendScreen(w),
                          icon: const Icon(Icons.arrow_upward, size: 18),
                          label: const Text('Send'),
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
                if (w != null && _tokenBalances.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('Tokens',
                      style: TextStyle(
                          color: PeekColors.text2, fontSize: 12)),
                  const SizedBox(height: 6),
                  for (final token in w.defaultTokens)
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
                              '$_symbol appears here.',
                      style: const TextStyle(
                          color: PeekColors.text3, fontSize: 12),
                    ),
                  )
                else
                  for (final tx in _txes) _EthTxRow(tx: tx, symbol: _symbol),
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

  void _showDetails(BuildContext context, EthereumTx tx) {
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
              _kv('Net amount', '${tx.netEth.toStringAsFixed(6)} $symbol'),
              _kv('Gas fee', '${tx.gasFeeEth.toStringAsFixed(6)} $symbol'),
              _kv('Status', tx.confirmed ? 'Confirmed' : 'Pending'),
              _kv('Block height',
                  tx.blockHeight == 0 ? '—' : tx.blockHeight.toString()),
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
                            coinId: symbol, txid: tx.hash);
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
