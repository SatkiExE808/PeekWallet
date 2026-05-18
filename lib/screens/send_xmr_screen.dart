import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../coins/monero/monero_wallet.dart';
import '../theme.dart';

/// Two-step Send flow:
///   1. Form — destination, amount, fee priority
///   2. Confirm — show parsed total + fee + txCount, then commit
///
/// Pending tx is built on step-1 -> step-2 transition (we need the
/// fee from monero_c, which only knows it after createTransaction
/// has built the actual TX object). Cancel from confirm discards the
/// pending tx; it never hits the daemon.
class SendXmrScreen extends StatefulWidget {
  const SendXmrScreen({super.key, required this.wallet});
  final MoneroWallet wallet;

  @override
  State<SendXmrScreen> createState() => _SendXmrScreenState();
}

class _SendXmrScreenState extends State<SendXmrScreen> {
  final _addr = TextEditingController();
  final _amount = TextEditingController();
  int _priority = 2; // 1=slow, 2=normal, 4=fast
  bool _busy = false;
  String? _err;
  PendingMoneroTx? _pending;
  String? _broadcastTxid;

  @override
  void dispose() {
    _addr.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _build() async {
    setState(() {
      _err = null;
      _busy = true;
    });
    final addr = _addr.text.trim();
    final amountText = _amount.text.trim();
    if (!_isLikelyXmrAddress(addr)) {
      setState(() {
        _err = 'That doesn\'t look like a Monero address (95 chars, starts with 4 or 8).';
        _busy = false;
      });
      return;
    }

    // Exact decimal-to-piconero parsing — never via `* 1e12` doubles,
    // which silently loses precision once amounts exceed ~9007 XMR.
    BigInt piconero;
    try {
      piconero = xmrDecimalToPiconero(amountText);
    } on FormatException catch (e) {
      setState(() {
        _err = e.message;
        _busy = false;
      });
      return;
    }
    if (piconero <= BigInt.zero) {
      setState(() {
        _err = 'Enter an amount greater than 0.';
        _busy = false;
      });
      return;
    }
    if (piconero > BigInt.from(widget.wallet.balancePiconero)) {
      setState(() {
        _err = 'Insufficient balance.';
        _busy = false;
      });
      return;
    }

    try {
      // Run off the UI thread? Wallet_createTransaction is sync FFI;
      // wrapping in Future.microtask doesn't move it off the main
      // isolate but at least yields the event loop. Real off-thread
      // would require Isolate.run, which is a bigger change.
      final pt = widget.wallet.buildTransaction(
        destAddress: addr,
        amountPiconero: piconero,
        priority: _priority,
      );
      setState(() {
        _pending = pt;
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _err = _humanizeError(e);
        _busy = false;
      });
    }
  }

  Future<void> _confirm() async {
    setState(() {
      _err = null;
      _busy = true;
    });
    try {
      final txid = _pending!.commit();
      setState(() {
        _broadcastTxid = txid;
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _err = _humanizeError(e);
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send XMR')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _broadcastTxid != null
              ? _resultView()
              : _pending != null
                  ? _confirmView()
                  : _formView(),
        ),
      ),
    );
  }

  // --- Step 1: form ------------------------------------------------------

  Widget _formView() {
    final balance = widget.wallet.balanceXmr;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Available: ${balance.toStringAsFixed(9)} XMR',
          style: const TextStyle(color: PeekColors.text2, fontSize: 13),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _addr,
          autocorrect: false,
          textCapitalization: TextCapitalization.none,
          decoration: InputDecoration(
            labelText: 'Recipient address',
            hintText: '4… or 8…',
            suffixIcon: IconButton(
              icon: const Icon(Icons.content_paste, size: 18),
              tooltip: 'Paste',
              onPressed: () async {
                final data = await Clipboard.getData('text/plain');
                if (data?.text != null) {
                  _addr.text = data!.text!.trim();
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          ],
          decoration: const InputDecoration(
            labelText: 'Amount (XMR)',
            hintText: '0.0',
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Fee priority',
          style: TextStyle(color: PeekColors.text2, fontSize: 12),
        ),
        const SizedBox(height: 6),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 1, label: Text('Slow')),
            ButtonSegment(value: 2, label: Text('Normal')),
            ButtonSegment(value: 4, label: Text('Fast')),
          ],
          selected: {_priority},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() => _priority = s.first),
        ),
        if (_err != null) ...[
          const SizedBox(height: 10),
          Text(_err!, style: const TextStyle(color: PeekColors.red, fontSize: 13)),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _busy ? null : _build,
          child: _busy
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Review send'),
        ),
      ],
    );
  }

  // --- Step 2: confirm ---------------------------------------------------

  Widget _confirmView() {
    final pt = _pending!;
    final total = pt.amountXmr + pt.feeXmr;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ConfirmRow(label: 'To', value: _addr.text.trim(), mono: true),
        _ConfirmRow(label: 'Amount', value: '${pt.amountXmr.toStringAsFixed(9)} XMR'),
        _ConfirmRow(label: 'Network fee', value: '${pt.feeXmr.toStringAsFixed(9)} XMR'),
        const Divider(color: PeekColors.border),
        _ConfirmRow(
          label: 'Total',
          value: '${total.toStringAsFixed(9)} XMR',
          emphasize: true,
        ),
        if (pt.txCount > 1)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'This send will be relayed as ${pt.txCount} sub-transactions.',
              style: const TextStyle(color: PeekColors.text3, fontSize: 11),
            ),
          ),
        if (_err != null) ...[
          const SizedBox(height: 10),
          Text(_err!, style: const TextStyle(color: PeekColors.red, fontSize: 13)),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : () => setState(() => _pending = null),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _busy ? null : _confirm,
                child: _busy
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Send'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Step 3: result ----------------------------------------------------

  Widget _resultView() {
    // Capture the messenger so the post-await SnackBar isn't tied to
    // a (possibly disposed) BuildContext.
    final messenger = ScaffoldMessenger.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle, color: PeekColors.green, size: 56),
        const SizedBox(height: 12),
        const Text(
          'Transaction broadcast',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        const Text(
          'It will appear in your transaction history once the network confirms it.',
          textAlign: TextAlign.center,
          style: TextStyle(color: PeekColors.text2, fontSize: 13),
        ),
        const SizedBox(height: 24),
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
            _broadcastTxid!,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: _broadcastTxid!));
            messenger.showSnackBar(
              const SnackBar(content: Text('TX ID copied')),
            );
          },
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Copy TX ID'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({
    required this.label,
    required this.value,
    this.mono = false,
    this.emphasize = false,
  });
  final String label;
  final String value;
  final bool mono;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(color: PeekColors.text2, fontSize: 12),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                color: PeekColors.text,
                fontSize: emphasize ? 14 : 13,
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

bool _isLikelyXmrAddress(String s) {
  if (s.length != 95 && s.length != 106) return false;
  // 95: standard / subaddress (start 4 or 8)
  // 106: integrated address (start 4)
  final first = s.codeUnitAt(0);
  if (first != 0x34 /* '4' */ && first != 0x38 /* '8' */) return false;
  return RegExp(r'^[1-9A-HJ-NP-Za-km-z]+$').hasMatch(s);
}

String _humanizeError(Object e) {
  final s = e.toString();
  // Strip the leading "Exception: " that Dart adds.
  return s.startsWith('Exception: ') ? s.substring(11) : s;
}
