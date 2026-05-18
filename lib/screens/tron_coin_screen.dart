import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../coins/tron/tron_module.dart';
import '../coins/tron/tron_wallet.dart';
import '../coins/tron/trongrid_client.dart';
import '../prices/price_feed.dart';
import '../theme.dart';
import '../util/explorer_links.dart';
import '../wallets/balance_cache.dart';
import '../vault/vault_state.dart';
import '../wallets/wallet_meta.dart';
import '../wallets/wallet_store.dart';

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
  List<TronTx> _txes = const [];
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
      if (!mounted) return;
      setState(() {
        _balanceSun = sun;
        _txes = txes;
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
    } catch (e) {
      if (!mounted) return;
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFEB0029),
                      radius: 18,
                      child: Icon(Icons.flash_on,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'TRX balance',
                      style:
                          TextStyle(color: PeekColors.text2, fontSize: 13),
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
                    if (_balanceSun == 0) return const SizedBox.shrink();
                    final fiat = PriceFeed.I.formatFiat(
                        'TRX', _balanceSun / 1000000.0);
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
                          onPressed: null,
                          icon: const Icon(Icons.arrow_upward, size: 18),
                          label: const Text('Send'),
                        ),
                      ),
                    ],
                  ),
                if (w != null) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Send isn\'t enabled yet — protobuf-encoded '
                    'TransferContract + secp256k1 sign + broadcast '
                    'land in a follow-up.',
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
                          : 'No native-TRX transactions yet. TRC-20 token '
                              'transfers (USDT etc.) aren\'t shown here '
                              'yet — they need separate per-token decoding.',
                      style: const TextStyle(
                          color: PeekColors.text3, fontSize: 12),
                    ),
                  )
                else
                  for (final tx in _txes) _TrxTxRow(tx: tx),
              ],
            ),
          ),
        ),
      ),
    );
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
