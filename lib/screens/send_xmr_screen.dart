import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../address_book/address_book.dart';
import '../coins/monero/monero_wallet.dart';
import '../theme.dart';
import '../util/screenshot_guard.dart';
import '../widgets/coin_screen_widgets.dart';
import 'address_book_screen.dart';
import 'qr_scan_screen.dart';

/// Two-step Send flow:
///   1. Form — recipients (1..N), fee priority, optional "Send all"
///   2. Confirm — show parsed totals + fee + txCount, then commit
///
/// Multi-recipient mode (S2-4): the form holds a list of recipient
/// rows, each with its own address + amount controllers. "Add
/// recipient" appends a row; per-row × removes it. Send-all is
/// mutually exclusive with multi-recipient (a sweep is by definition
/// a single-destination of everything).
class SendXmrScreen extends StatefulWidget {
  const SendXmrScreen({super.key, required this.wallet});
  final MoneroWallet wallet;

  @override
  State<SendXmrScreen> createState() => _SendXmrScreenState();
}

class _SendXmrScreenState extends State<SendXmrScreen> {
  final List<_RecipientRow> _recipients = [_RecipientRow()];
  int _priority = 2; // 1=slow, 2=normal, 4=fast
  bool _busy = false;
  bool _sweepAll = false;
  String? _err;
  PendingMoneroTx? _pending;
  String? _broadcastTxid;

  @override
  void dispose() {
    for (final r in _recipients) {
      r.dispose();
    }
    super.dispose();
  }

  void _addRecipient() {
    if (_sweepAll) return;
    setState(() => _recipients.add(_RecipientRow()));
  }

  void _removeRecipient(int i) {
    if (_recipients.length <= 1) return;
    setState(() => _recipients.removeAt(i).dispose());
  }

  Future<void> _scanAddressFor(int i) async {
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const QrScanScreen(title: 'Scan recipient address'),
      ),
    );
    if (scanned != null && scanned.isNotEmpty) {
      _recipients[i].addr.text = scanned;
      setState(() => _err = null);
    }
  }

  Future<void> _pickFromBookFor(int i) async {
    final picked = await Navigator.of(context).push<AddressBookEntry>(
      MaterialPageRoute(
        builder: (_) => const AddressBookScreen(pickForCoin: 'XMR'),
      ),
    );
    if (picked != null) {
      _recipients[i].addr.text = picked.address;
      unawaited(AddressBook.I.recordUse(picked.id));
      setState(() => _err = null);
    }
  }

  Future<void> _build() async {
    setState(() {
      _err = null;
      _busy = true;
    });

    // Validate every recipient row before going to FFI.
    final txRecipients = <TxRecipient>[];
    final totalBalance = BigInt.from(widget.wallet.balancePiconero);
    var runningTotal = BigInt.zero;
    for (var i = 0; i < _recipients.length; i++) {
      final row = _recipients[i];
      final addr = row.addr.text.trim();
      final amountText = row.amount.text.trim();
      final tag = _recipients.length == 1 ? '' : ' (row ${i + 1})';
      if (!_isLikelyXmrAddress(addr)) {
        setState(() {
          _err = 'Address doesn\'t look like Monero$tag.';
          _busy = false;
        });
        return;
      }
      if (_sweepAll) {
        // sweep ignores amounts; only one row makes sense.
        txRecipients.add(TxRecipient(address: addr, amount: BigInt.zero));
        break;
      }
      BigInt amt;
      try {
        amt = xmrDecimalToPiconero(amountText);
      } on FormatException catch (e) {
        setState(() {
          _err = '${e.message}$tag';
          _busy = false;
        });
        return;
      }
      if (amt <= BigInt.zero) {
        setState(() {
          _err = 'Amount must be greater than 0$tag.';
          _busy = false;
        });
        return;
      }
      runningTotal += amt;
      txRecipients.add(TxRecipient(address: addr, amount: amt));
    }
    if (!_sweepAll && runningTotal > totalBalance) {
      setState(() {
        _err = 'Total exceeds your balance.';
        _busy = false;
      });
      return;
    }

    try {
      final pt = widget.wallet.buildMultiTransaction(
        recipients: txRecipients,
        isSweepAll: _sweepAll,
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
    final scaffold = Scaffold(
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
    return _pending != null && _broadcastTxid == null
        ? ScreenshotGuard(child: scaffold)
        : scaffold;
  }

  // --- Step 1: form ---

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

        // Per-recipient rows.
        for (var i = 0; i < _recipients.length; i++) ...[
          _RecipientCard(
            index: i,
            total: _recipients.length,
            row: _recipients[i],
            sweepAll: _sweepAll,
            onRemove: _recipients.length > 1
                ? () => _removeRecipient(i)
                : null,
            onScan: () => _scanAddressFor(i),
            onPickBook: () => _pickFromBookFor(i),
          ),
          if (i < _recipients.length - 1) const SizedBox(height: 8),
        ],

        if (!_sweepAll) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addRecipient,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add recipient'),
            ),
          ),
        ],

        const SizedBox(height: 10),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _sweepAll,
          onChanged: (v) => setState(() {
            _sweepAll = v ?? false;
            _err = null;
            if (_sweepAll && _recipients.length > 1) {
              // Sweep only sends to ONE address. Trim extras so the
              // form's state matches what we'll actually build.
              for (final r in _recipients.skip(1)) {
                r.dispose();
              }
              _recipients.removeRange(1, _recipients.length);
            }
          }),
          title: const Text('Send all', style: TextStyle(fontSize: 14)),
          subtitle: const Text(
            'Sweep every spendable output to the first recipient — fee '
            'taken from the swept amount. Disables multi-recipient.',
            style: TextStyle(color: PeekColors.text3, fontSize: 11),
          ),
          dense: true,
        ),
        const SizedBox(height: 14),
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
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Review send'),
        ),
      ],
    );
  }

  // --- Step 2: confirm ---

  Widget _confirmView() {
    final pt = _pending!;
    final total = pt.amountXmr + pt.feeXmr;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            borderRadius: PeekDesign.brHero,
            gradient: PeekDesign.surfaceGradient,
            border: Border.all(color: PeekColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${total.toStringAsFixed(9)} XMR',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _sweepAll
                    ? 'sweep total (including fee)'
                    : 'total including network fee',
                style: const TextStyle(
                    color: PeekColors.text3, fontSize: 12),
              ),
              const SizedBox(height: PeekDesign.sp4),
              for (var i = 0; i < _recipients.length; i++) ...[
                _ConfirmRow(
                  label: _recipients.length == 1
                      ? 'To'
                      : 'To #${i + 1}',
                  value: _recipients[i].addr.text.trim(),
                  mono: true,
                ),
                if (!_sweepAll)
                  _ConfirmRow(
                    label: '',
                    value:
                        '${_parseXmr(_recipients[i].amount.text).toStringAsFixed(9)} XMR',
                  ),
                if (i < _recipients.length - 1)
                  const Divider(height: 18, color: PeekColors.hairline),
              ],
              const Divider(height: 18, color: PeekColors.hairline),
              _ConfirmRow(
                label: _sweepAll ? 'Sending (sweep)' : 'Subtotal',
                value: '${pt.amountXmr.toStringAsFixed(9)} XMR',
              ),
              const Divider(height: 18, color: PeekColors.hairline),
              _ConfirmRow(
                  label: 'Network fee',
                  value: '${pt.feeXmr.toStringAsFixed(9)} XMR'),
            ],
          ),
        ),
        if (pt.txCount > 1) ...[
          const SizedBox(height: PeekDesign.sp3),
          Container(
            padding: const EdgeInsets.all(PeekDesign.sp3),
            decoration: BoxDecoration(
              color: PeekColors.surface2,
              borderRadius: PeekDesign.brSmall,
              border: Border.all(color: PeekColors.hairline),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 14, color: PeekColors.text3),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This send will be relayed as ${pt.txCount} sub-transactions.',
                    style: const TextStyle(
                        color: PeekColors.text3,
                        fontSize: 11,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_err != null) ...[
          const SizedBox(height: PeekDesign.sp3),
          Container(
            padding: const EdgeInsets.all(PeekDesign.sp3),
            decoration: BoxDecoration(
              color: PeekColors.red.withAlpha(28),
              borderRadius: PeekDesign.brSmall,
              border: Border.all(color: PeekColors.red.withAlpha(96)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 14, color: PeekColors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _err!,
                    style: const TextStyle(
                        color: PeekColors.red,
                        fontSize: 12,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: PeekDesign.sp6),
        Row(
          children: [
            Expanded(
              child: ActionButton(
                icon: Icons.arrow_back_rounded,
                label: 'Back',
                primary: false,
                onTap: _busy ? null : () => setState(() => _pending = null),
              ),
            ),
            const SizedBox(width: PeekDesign.sp3),
            Expanded(
              child: ActionButton(
                icon: Icons.send_rounded,
                label: _busy ? 'Sending…' : 'Send',
                primary: true,
                onTap: _busy ? null : _confirm,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Step 3: result ---

  Widget _resultView() {
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
        const SizedBox(height: PeekDesign.sp6),
        const Text(
          'TX ID',
          style: TextStyle(
              color: PeekColors.text3,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(PeekDesign.sp3),
          decoration: BoxDecoration(
            color: PeekColors.surface,
            borderRadius: PeekDesign.brSmall,
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

  double _parseXmr(String s) {
    try {
      final pico = xmrDecimalToPiconero(s);
      return pico.toDouble() / 1e12;
    } catch (_) {
      return 0;
    }
  }
}

/// Holds the controllers + lifecycle for one recipient row.
class _RecipientRow {
  final TextEditingController addr = TextEditingController();
  final TextEditingController amount = TextEditingController();
  void dispose() {
    addr.dispose();
    amount.dispose();
  }
}

class _RecipientCard extends StatelessWidget {
  const _RecipientCard({
    required this.index,
    required this.total,
    required this.row,
    required this.sweepAll,
    required this.onRemove,
    required this.onScan,
    required this.onPickBook,
  });
  final int index;
  final int total;
  final _RecipientRow row;
  final bool sweepAll;
  final VoidCallback? onRemove;
  final VoidCallback onScan;
  final VoidCallback onPickBook;

  @override
  Widget build(BuildContext context) {
    final showHeader = total > 1;
    return Container(
      padding: const EdgeInsets.all(PeekDesign.sp4),
      decoration: BoxDecoration(
        color: PeekColors.surface,
        borderRadius: PeekDesign.brCard,
        border: Border.all(color: PeekColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: PeekColors.accentMuted,
                    borderRadius: PeekDesign.brPill,
                  ),
                  child: Text(
                    '#${index + 1}',
                    style: const TextStyle(
                      color: PeekColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Recipient',
                    style: TextStyle(
                      color: PeekColors.text2,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: PeekColors.text3,
                    onPressed: onRemove,
                    tooltip: 'Remove',
                  ),
              ],
            ),
          if (showHeader) const SizedBox(height: PeekDesign.sp2),
          TextField(
            controller: row.addr,
            autocorrect: false,
            textCapitalization: TextCapitalization.none,
            decoration: InputDecoration(
              labelText: 'Recipient address',
              hintText: '4… or 8…',
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.contact_page_outlined, size: 18),
                    tooltip: 'Address book',
                    onPressed: onPickBook,
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner, size: 18),
                    tooltip: 'Scan QR',
                    onPressed: onScan,
                  ),
                  IconButton(
                    icon: const Icon(Icons.content_paste, size: 18),
                    tooltip: 'Paste',
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data?.text != null) {
                        row.addr.text = data!.text!.trim();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: row.amount,
            enabled: !sweepAll || index > 0,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            decoration: InputDecoration(
              labelText: 'Amount (XMR)',
              hintText: sweepAll ? 'Sweep — amount set automatically' : '0.0',
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({
    required this.label,
    required this.value,
    this.mono = false,
  });
  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
                fontSize: 13,
                fontWeight: FontWeight.w500,
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
  if (s.isEmpty) return false;
  final first = s.codeUnitAt(0);
  final isFour = first == 0x34;
  final isEight = first == 0x38;
  switch (s.length) {
    case 95:
      if (!isFour && !isEight) return false;
      break;
    case 106:
      if (!isFour) return false;
      break;
    default:
      return false;
  }
  return RegExp(r'^[1-9A-HJ-NP-Za-km-z]+$').hasMatch(s);
}

String _humanizeError(Object e) {
  final s = e.toString();
  return s.startsWith('Exception: ') ? s.substring(11) : s;
}
