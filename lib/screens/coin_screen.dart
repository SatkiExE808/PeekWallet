import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../coins/coin.dart';
import '../coins/monero/monero_engine.dart';
import '../coins/monero/monero_wallet.dart';
import '../prefs/prefs.dart';
import '../theme.dart';
import '../vault/vault_state.dart';
import 'send_xmr_screen.dart';

/// Coin detail page. For Monero, shows the live native-engine balance
/// + sync progress; other coins still show placeholder text until
/// their own backends land.
class CoinScreen extends StatefulWidget {
  const CoinScreen({super.key, required this.coin});
  final Coin coin;

  @override
  State<CoinScreen> createState() => _CoinScreenState();
}

class _CoinScreenState extends State<CoinScreen> {
  String? _address;
  String? _error;

  /// 1s poll of MoneroSession for balance + sync %. Cheap enough — the
  /// FFI calls are non-blocking reads of cached native state.
  Timer? _poll;
  int? _syncPct;
  double? _balanceXmr;
  int _currentHeight = 0;
  int _tipHeight = 0;
  bool _daemonConnected = false;
  bool _isSynced = false;
  String? _daemonError;
  String? _engineError;
  List<MoneroTx> _transactions = const [];
  MoneroWallet? _moneroWallet;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final mn = VaultState.I.mnemonic;
    if (mn == null) {
      setState(() => _error = 'Wallet is locked');
      return;
    }
    try {
      final a = await widget.coin.deriveAddress(mn);
      setState(() => _address = a);
    } catch (e) {
      setState(() => _error = 'Address derivation failed: $e');
    }

    if (widget.coin.id == 'XMR' && moneroNativeAvailable()) {
      final engine = MoneroEngine.I.status();
      if (!engine.loaded) {
        setState(() => _engineError = engine.error);
        return;
      }
      await _bootMonero(mn);
    }
  }

  Future<void> _bootMonero(String mnemonic) async {
    // Fallback restoreHeight only used if the daemon doesn't respond
    // to /get_height within ~15s during wallet creation. In the normal
    // path MoneroWallet.open queries the daemon for real tip and calls
    // Wallet_setRefreshFromBlockHeight with (tip - 5000). This value
    // is intentionally conservative — a couple weeks before the real
    // May-2026 tip — so even on a degraded boot the wallet won't skip
    // recent receives. Bump on each release as a safety net.
    const restoreHeight = 3650000;
    // Repaint while open() is still streaming stage updates so the
    // user sees progress instead of just a blank '…XMR'.
    final stageTicker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      setState(() {});
    });
    final walletPwd = VaultState.I.walletFilePassword;
    if (walletPwd == null) {
      setState(() => _engineError = 'Vault locked — wallet password unavailable');
      return;
    }
    final daemonUri =
        await Prefs.I.moneroDaemonUri() ?? kDefaultMoneroDaemon;
    final w = await MoneroSession.I.start(
      mnemonic: mnemonic,
      passphrase: VaultState.I.passphrase,
      restoreHeight: restoreHeight,
      daemonUri: daemonUri,
      walletPassword: walletPwd,
    );
    stageTicker.cancel();
    if (w == null) {
      setState(() => _engineError = MoneroSession.I.lastError ?? 'unknown');
      return;
    }
    _moneroWallet = w;
    var lastHistoryPoll = DateTime.now();
    _poll = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      // Refresh the cached tx list every 5s — it's a native call
      // that iterates the wallet's in-memory history vector, cheap
      // but not free, no reason to do it once per second.
      List<MoneroTx>? newTx;
      final now = DateTime.now();
      if (now.difference(lastHistoryPoll).inSeconds >= 5) {
        lastHistoryPoll = now;
        try {
          newTx = w.transactions();
        } catch (_) {/* leave old list in place */}
      }
      setState(() {
        _syncPct = w.syncProgressPct;
        _balanceXmr = w.balanceXmr;
        _currentHeight = w.currentHeight;
        _tipHeight = w.daemonTipHeight;
        _daemonConnected = w.isDaemonConnected;
        _isSynced = w.isSynced;
        _daemonError = w.daemonError;
        if (newTx != null) _transactions = newTx;
      });
    });
  }

  void _showReceiveSheet() {
    if (_address == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: PeekColors.bg2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
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
              'Receive XMR',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: QrImageView(
                  data: _address!,
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
                _address!,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _address!));
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Address copied')),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy address'),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtHeight(int h) {
    if (h == 0) return '—';
    // Thousand-separators so 3,795,210 is readable at a glance.
    final s = h.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _balanceText() {
    if (widget.coin.id != 'XMR') return '… ${widget.coin.symbol}';
    if (_engineError != null) return '… ${widget.coin.symbol}';
    if (_balanceXmr == null) {
      final s = MoneroSession.I.stage;
      return s == null ? '… ${widget.coin.symbol}' : 'Boot: $s';
    }
    if (!_daemonConnected) return 'Connecting to daemon…';
    // monero_c's Wallet_synchronized is the authoritative "done" flag.
    // We can't rely on syncProgressPct alone — the daemon's tip keeps
    // advancing while we scan, so the ratio asymptotes at 99-something
    // forever. isSynced flips once the wallet decides it's caught up.
    if (!_isSynced) return 'Syncing ${_syncPct ?? 0}%';
    return '${_balanceXmr!.toStringAsFixed(9)} ${widget.coin.symbol}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.coin.name)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: widget.coin.color,
                    radius: 18,
                    child: Icon(widget.coin.icon, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${widget.coin.symbol} balance',
                    style: const TextStyle(color: PeekColors.text2, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _balanceText(),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
              ),
              if (widget.coin.id == 'XMR') const _EngineStatusBanner(),
              if (widget.coin.id == 'XMR' && _tipHeight > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Height ${_fmtHeight(_currentHeight)} / ${_fmtHeight(_tipHeight)} '
                    '(${_tipHeight - _currentHeight} behind)',
                    style: const TextStyle(color: PeekColors.text3, fontSize: 11),
                  ),
                ),
              if (_engineError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Engine: $_engineError',
                    style: const TextStyle(color: PeekColors.red, fontSize: 11),
                  ),
                ),
              if (widget.coin.id == 'XMR' &&
                  _engineError == null &&
                  _daemonError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Daemon: $_daemonError',
                    style: const TextStyle(color: PeekColors.red, fontSize: 11),
                  ),
                ),
              const SizedBox(height: 20),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x33EF4444),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!, style: const TextStyle(color: PeekColors.text)),
                )
              else if (_address == null)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: PeekColors.accent),
                  ),
                )
              else ...[
                if (widget.coin.id == 'XMR') _ActionRow(
                  canSend: _moneroWallet != null &&
                      _isSynced &&
                      (_balanceXmr ?? 0) > 0,
                  onSend: () {
                    if (_moneroWallet == null) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            SendXmrScreen(wallet: _moneroWallet!),
                      ),
                    );
                  },
                  onReceive: () => _showReceiveSheet(),
                ),
                if (widget.coin.id == 'XMR') ...[
                  const SizedBox(height: 20),
                  const Text('Transactions',
                      style: TextStyle(color: PeekColors.text2, fontSize: 12)),
                  const SizedBox(height: 6),
                  if (_transactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        _isSynced
                            ? 'No transactions yet.'
                            : 'Transactions will appear after sync completes.',
                        style: const TextStyle(
                          color: PeekColors.text3,
                          fontSize: 12,
                        ),
                      ),
                    )
                  else
                    for (final tx in _transactions.take(20))
                      _TxRow(tx: tx),
                ] else ...[
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.white,
                      child: QrImageView(
                        data: _address!,
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
                      _address!,
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: _address!));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Address copied')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy address'),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.canSend,
    required this.onSend,
    required this.onReceive,
  });
  final bool canSend;
  final VoidCallback onSend;
  final VoidCallback onReceive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onReceive,
            icon: const Icon(Icons.qr_code, size: 18),
            label: const Text('Receive'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: canSend ? onSend : null,
            icon: const Icon(Icons.arrow_upward, size: 18),
            label: const Text('Send'),
          ),
        ),
      ],
    );
  }
}

class _TxRow extends StatelessWidget {
  const _TxRow({required this.tx});
  final MoneroTx tx;

  @override
  Widget build(BuildContext context) {
    final color = tx.isFailed
        ? PeekColors.red
        : (tx.isIncoming ? PeekColors.green : PeekColors.text);
    final sign = tx.isIncoming ? '+' : '−';
    final amount = '$sign${tx.amountXmr.toStringAsFixed(6)} XMR';
    final dt = tx.timestamp.toLocal();
    final dateLabel = _fmtDate(dt);
    final subtitle = tx.isFailed
        ? 'Failed'
        : tx.isPending
            ? 'Pending'
            : tx.confirmations < 10
                ? '${tx.confirmations} conf'
                : 'Confirmed';

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
                  Text(
                    amount,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$dateLabel · $subtitle',
                    style: const TextStyle(color: PeekColors.text3, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: PeekColors.text3, size: 18),
          ],
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  void _showDetails(BuildContext context, MoneroTx tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: PeekColors.bg2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _kv('Amount', '${tx.amountXmr.toStringAsFixed(9)} XMR'),
            if (!tx.isIncoming)
              _kv('Fee', '${tx.feeXmr.toStringAsFixed(9)} XMR'),
            _kv('Date', _fmtDate(tx.timestamp.toLocal())),
            _kv('Block height', tx.blockHeight == 0 ? '—' : tx.blockHeight.toString()),
            _kv('Confirmations', tx.confirmations.toString()),
            _kv('Status', tx.isFailed ? 'Failed' : (tx.isPending ? 'Pending' : 'Confirmed')),
            if (tx.paymentId.isNotEmpty)
              _kv('Payment ID', tx.paymentId),
            const SizedBox(height: 6),
            const Text('TX ID', style: TextStyle(color: PeekColors.text2, fontSize: 12)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: PeekColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: PeekColors.border),
              ),
              child: SelectableText(
                tx.hash,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: tx.hash));
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('TX ID copied')),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy TX ID'),
            ),
          ],
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
            child: Text(k, style: const TextStyle(color: PeekColors.text2, fontSize: 12)),
          ),
          Expanded(
            child: SelectableText(
              v,
              style: const TextStyle(color: PeekColors.text, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sanity check: shows whether libmonero_wallet2_api_c.so loaded on
/// this device.
class _EngineStatusBanner extends StatelessWidget {
  const _EngineStatusBanner();

  @override
  Widget build(BuildContext context) {
    final s = MoneroEngine.I.status();
    final color = s.loaded ? PeekColors.green : PeekColors.red;
    final label = s.loaded
        ? '✓ Native monero_c engine loaded'
        : '✗ Engine not loaded: ${s.error}';
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11),
      ),
    );
  }
}
