import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../coins/solana/solana_rpc_client.dart';
import '../coins/solana/solana_wallet.dart';
import '../prices/price_feed.dart';
import '../theme.dart';
import '../util/screenshot_guard.dart';
import '../util/sensitive_clipboard.dart';
import 'qr_scan_screen.dart';

/// Solana send screen. Same two-step flow as the other coins —
/// form → preview → type SEND to confirm. Marked experimental:
/// transaction encoding is unit-tested but the end-to-end flow
/// hasn't been audited.
class SendSolanaScreen extends StatefulWidget {
  const SendSolanaScreen({super.key, required this.wallet});
  final SolanaWallet wallet;

  @override
  State<SendSolanaScreen> createState() => _SendSolanaScreenState();
}

class _SendSolanaScreenState extends State<SendSolanaScreen> {
  final _addrCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  int _balanceLamports = 0;
  bool _loading = true;
  String? _balanceError;

  bool _previewing = false;
  bool _broadcasting = false;
  String? _error;

  /// Fixed Solana base fee — see SolanaRpcClient.defaultTransferFeeLamports
  /// for the rationale. We use the constant directly so the user sees
  /// the expected fee in the preview without an extra RPC round-trip.
  static const _feeLamports = SolanaRpcClient.defaultTransferFeeLamports;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  @override
  void dispose() {
    _addrCtrl.dispose();
    _amountCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    try {
      final v = await widget.wallet.balanceLamports();
      if (mounted) {
        setState(() {
          _balanceLamports = v;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _balanceError = '$e';
          _loading = false;
        });
      }
    }
  }

  int? _parseAmountLamports() {
    final raw = _amountCtrl.text.trim();
    if (raw.isEmpty) return null;
    if (raw.contains('.')) {
      // SOL form. 1 SOL = 10^9 lamports. Convert by string arithmetic
      // so we don't lose precision past ~6 decimals.
      final parts = raw.split('.');
      final whole = parts[0];
      final frac = parts.length > 1 ? parts[1] : '';
      if (frac.length > 9) return null; // SOL has 9 decimals
      final padded = frac.padRight(9, '0');
      final combined = (whole.isEmpty ? '0' : whole) + padded;
      final trimmed = combined.replaceFirst(RegExp(r'^0+'), '');
      return int.tryParse(trimmed.isEmpty ? '0' : trimmed);
    }
    return int.tryParse(raw);
  }

  Future<void> _scanQr() async {
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const QrScanScreen(title: 'Scan Solana address'),
      ),
    );
    if (scanned != null && scanned.isNotEmpty) {
      var s = scanned.trim();
      // Solana doesn't have a standard BIP21-equivalent URI scheme,
      // but Solana Pay uses `solana:address?amount=...&label=...`.
      // Strip if present.
      if (s.toLowerCase().startsWith('solana:')) {
        s = s.substring('solana:'.length);
        final qIx = s.indexOf('?');
        if (qIx >= 0) s = s.substring(0, qIx);
      }
      _addrCtrl.text = s;
    }
  }

  void _onMax() {
    // Subtract a one-tx fee reserve so the send can't fail for
    // insufficient funds after we've already signed.
    if (_balanceLamports <= _feeLamports) return;
    setState(() {
      _amountCtrl.text = (_balanceLamports - _feeLamports).toString();
    });
  }

  Future<void> _onContinue() async {
    setState(() => _error = null);
    final amount = _parseAmountLamports();
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }
    final addr = _addrCtrl.text.trim();
    // Solana addresses are 32-byte base58 → 32-44 chars; we don't
    // validate the base58 alphabet here, the builder does that.
    if (addr.length < 32 || addr.length > 44) {
      setState(() => _error = 'Address should be 32-44 base58 characters');
      return;
    }
    if (amount + _feeLamports > _balanceLamports) {
      setState(() => _error = 'Amount + fee exceeds balance');
      return;
    }
    setState(() => _previewing = true);
  }

  Future<void> _onConfirm() async {
    if (_confirmCtrl.text.trim().toUpperCase() != 'SEND') {
      setState(() => _error = 'Type SEND to confirm');
      return;
    }
    final amount = _parseAmountLamports();
    if (amount == null) return;
    setState(() {
      _broadcasting = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      final built = await widget.wallet.sendSol(
        destAddress: _addrCtrl.text.trim(),
        lamports: amount,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: PeekColors.green,
          content: Text(
              'Broadcast! sig: ${built.signature.substring(0, 16)}…'),
          duration: const Duration(seconds: 6),
        ),
      );
      nav.pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _broadcasting = false;
          _error = '$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenshotGuard(
      child: Scaffold(
        appBar: AppBar(title: const Text('Send Solana')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _previewing ? _buildPreview() : _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final amount = _parseAmountLamports();
    final fiat = amount == null
        ? ''
        : PriceFeed.I.formatFiat('SOL', amount / 1000000000.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ExperimentalBanner(),
        const SizedBox(height: 16),
        _balanceCard(),
        const SizedBox(height: 20),
        const Text('Recipient address',
            style: TextStyle(color: PeekColors.text2, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: _addrCtrl,
          decoration: InputDecoration(
            hintText: 'Solana address',
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner, size: 18),
                  tooltip: 'Scan QR',
                  onPressed: _scanQr,
                ),
                IconButton(
                  icon: const Icon(Icons.paste, size: 18),
                  tooltip: 'Paste from clipboard',
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null) {
                      _addrCtrl.text = data!.text!.trim();
                    }
                  },
                ),
              ],
            ),
          ),
          autocorrect: false,
          enableSuggestions: false,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(
              child: Text('Amount (SOL or lamports)',
                  style: TextStyle(color: PeekColors.text2, fontSize: 12)),
            ),
            TextButton(
              onPressed:
                  _balanceLamports <= _feeLamports ? null : _onMax,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 0),
                minimumSize: const Size(0, 24),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Max', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: '0.01',
            helperText: fiat.isEmpty ? null : '≈ $fiat',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        _feeCard(),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _errorBox(_error!),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed:
              (_loading || _balanceLamports == 0) ? null : _onContinue,
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    final amount = _parseAmountLamports()!;
    final addr = _addrCtrl.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ExperimentalBanner(),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kvRow('To',
                    '${addr.substring(0, 12)}…${addr.substring(addr.length - 8)}'),
                _kvRow('Amount',
                    '${(amount / 1000000000.0).toStringAsFixed(9)} SOL'),
                _kvRow('Network fee',
                    '${(_feeLamports / 1000000000.0).toStringAsFixed(9)} SOL'),
                const SizedBox(height: 8),
                const Text(
                  'Solana fees are fixed at 5000 lamports per signature. '
                  'Once submitted this CANNOT be reversed.',
                  style: TextStyle(color: PeekColors.text3, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Type SEND to confirm',
            style: TextStyle(color: PeekColors.text2, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: _confirmCtrl,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          decoration: const InputDecoration(hintText: 'SEND'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _errorBox(_error!),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _broadcasting
                    ? null
                    : () => setState(() {
                          _previewing = false;
                          _confirmCtrl.clear();
                        }),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _broadcasting ? null : _onConfirm,
                child: _broadcasting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Send'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _balanceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet,
                color: PeekColors.text3, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: _loading
                  ? const Text('Loading balance…',
                      style: TextStyle(
                          color: PeekColors.text2, fontSize: 13))
                  : _balanceError != null
                      ? Text('Balance error: $_balanceError',
                          style: const TextStyle(
                              color: PeekColors.red, fontSize: 12))
                      : Text(
                          '${(_balanceLamports / 1000000000.0).toStringAsFixed(9)} SOL available',
                          style: const TextStyle(
                              color: PeekColors.text, fontSize: 13),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Network fee',
                style: TextStyle(color: PeekColors.text2, fontSize: 12)),
            SizedBox(height: 4),
            Text(
              '5000 lamports (~0.000005 SOL) per signature — fixed.',
              style: TextStyle(color: PeekColors.text, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorBox(String msg) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: PeekColors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child:
          Text(msg, style: const TextStyle(color: PeekColors.red, fontSize: 12)),
    );
  }

  Widget _kvRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(k,
                style: const TextStyle(
                    color: PeekColors.text2, fontSize: 12)),
          ),
          Expanded(
            child: GestureDetector(
              onLongPress: () => SensitiveClipboard.copy(v, label: k),
              child: Text(v,
                  style: const TextStyle(
                      color: PeekColors.text, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExperimentalBanner extends StatelessWidget {
  const _ExperimentalBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PeekColors.red.withValues(alpha: 0.12),
        border: Border.all(color: PeekColors.red),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber, color: PeekColors.red, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Experimental — Solana transaction encoding is unit-'
              'tested but the end-to-end send path has not been '
              'audited. Test with small amounts first.',
              style: TextStyle(color: PeekColors.text, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
