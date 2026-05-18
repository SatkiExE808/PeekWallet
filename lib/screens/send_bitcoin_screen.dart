import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../coins/bitcoin/bitcoin_wallet.dart';
import '../coins/bitcoin/mempool_client.dart';
import '../prices/price_feed.dart';
import '../theme.dart';
import '../util/screenshot_guard.dart';
import '../util/sensitive_clipboard.dart';

/// Bitcoin send screen — destination + amount + fee tier, then a
/// confirm step that requires typing "SEND" before broadcast.
///
/// Marked experimental in the UI. The transaction builder is
/// BIP-0143 spec-vector tested but real-world adversarial conditions
/// (RBF replacement, fee bumping, mempool eviction, hardware wallet
/// integration) are intentionally NOT yet handled — those are
/// follow-up sprints.
class SendBitcoinScreen extends StatefulWidget {
  const SendBitcoinScreen({super.key, required this.wallet});
  final BitcoinWallet wallet;

  @override
  State<SendBitcoinScreen> createState() => _SendBitcoinScreenState();
}

class _SendBitcoinScreenState extends State<SendBitcoinScreen> {
  final _addrCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  FeeRates? _fees;
  String? _feesError;
  _FeeTier _tier = _FeeTier.halfHour;
  final int _customRate = 5;

  int _availableSat = 0;
  bool _utxosLoading = true;
  String? _utxosError;

  bool _previewing = false;
  bool _broadcasting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _addrCtrl.dispose();
    _amountCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    try {
      final fees = await widget.wallet.feeRates();
      if (mounted) setState(() => _fees = fees);
    } catch (e) {
      if (mounted) setState(() => _feesError = '$e');
    }
    try {
      final utxos = await widget.wallet.utxos();
      final sum = utxos
          .where((u) => u.confirmed)
          .fold<int>(0, (a, u) => a + u.valueSat);
      if (mounted) {
        setState(() {
          _availableSat = sum;
          _utxosLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _utxosError = '$e';
          _utxosLoading = false;
        });
      }
    }
  }

  int get _selectedFeeRate {
    final fees = _fees;
    if (fees == null) return _customRate;
    switch (_tier) {
      case _FeeTier.fastest:
        return fees.fastestSatPerVByte;
      case _FeeTier.halfHour:
        return fees.halfHourSatPerVByte;
      case _FeeTier.hour:
        return fees.hourSatPerVByte;
      case _FeeTier.economy:
        return fees.economySatPerVByte;
      case _FeeTier.custom:
        return _customRate;
    }
  }

  int? _parseAmountSat() {
    final raw = _amountCtrl.text.trim();
    if (raw.isEmpty) return null;
    // Accept both 0.00012 (BTC) and 12000 (sat). If it contains a
    // decimal point, treat as BTC.
    if (raw.contains('.')) {
      final v = double.tryParse(raw);
      if (v == null || v <= 0) return null;
      return (v * 100000000).round();
    }
    return int.tryParse(raw);
  }

  Future<void> _onContinue() async {
    setState(() => _error = null);
    final amount = _parseAmountSat();
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }
    final addr = _addrCtrl.text.trim();
    if (!addr.startsWith('bc1q')) {
      setState(() => _error = 'Only bech32 P2WPKH (bc1q…) addresses are supported');
      return;
    }
    if (amount > _availableSat) {
      setState(() =>
          _error = 'Amount exceeds confirmed balance ($_availableSat sat)');
      return;
    }
    setState(() => _previewing = true);
  }

  Future<void> _onConfirm() async {
    if (_confirmCtrl.text.trim().toUpperCase() != 'SEND') {
      setState(() => _error = 'Type SEND to confirm');
      return;
    }
    final amount = _parseAmountSat();
    if (amount == null) return;
    setState(() {
      _broadcasting = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      final built = await widget.wallet.sendBitcoin(
        destAddress: _addrCtrl.text.trim(),
        amountSat: amount,
        feeRateSatPerVByte: _selectedFeeRate,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: PeekColors.green,
          content: Text('Broadcast! txid: ${built.txid.substring(0, 12)}…'),
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
        appBar: AppBar(
          title: const Text('Send Bitcoin'),
        ),
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
    final amountSat = _parseAmountSat();
    final fiatStr = amountSat == null
        ? ''
        : PriceFeed.I.formatFiat('BTC', amountSat / 100000000.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ExperimentalBanner(),
        const SizedBox(height: 16),
        _balanceRow(),
        const SizedBox(height: 20),
        const Text('Recipient address',
            style: TextStyle(color: PeekColors.text2, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: _addrCtrl,
          decoration: InputDecoration(
            hintText: 'bc1q…',
            suffixIcon: IconButton(
              icon: const Icon(Icons.paste, size: 18),
              tooltip: 'Paste from clipboard',
              onPressed: () async {
                final data = await Clipboard.getData('text/plain');
                if (data?.text != null) {
                  _addrCtrl.text = data!.text!.trim();
                }
              },
            ),
          ),
          autocorrect: false,
          enableSuggestions: false,
        ),
        const SizedBox(height: 16),
        const Text('Amount (BTC or sat)',
            style: TextStyle(color: PeekColors.text2, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: _amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: '0.001',
            helperText: fiatStr.isEmpty ? null : '≈ $fiatStr',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        _feeSelector(),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: PeekColors.red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_error!,
                style: const TextStyle(color: PeekColors.red, fontSize: 12)),
          ),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed:
              (_utxosLoading || _availableSat == 0) ? null : _onContinue,
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    final amount = _parseAmountSat()!;
    final feeRate = _selectedFeeRate;
    final addr = _addrCtrl.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ExperimentalBanner(),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kvRow('To',
                    '${addr.substring(0, 12)}…${addr.substring(addr.length - 8)}'),
                _kvRow('Amount', '${(amount / 100000000).toStringAsFixed(8)} BTC'),
                _kvRow('Fee rate', '$feeRate sat/vB'),
                _kvRow('Available', '$_availableSat sat'),
                const SizedBox(height: 8),
                const Text(
                  'Final fee + change will be shown after the transaction '
                  'is constructed and broadcast. Once submitted to the '
                  'network it CANNOT be reversed.',
                  style: TextStyle(color: PeekColors.text3, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Type SEND to confirm',
          style: TextStyle(color: PeekColors.text2, fontSize: 12),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _confirmCtrl,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          decoration: const InputDecoration(hintText: 'SEND'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: PeekColors.red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_error!,
                style: const TextStyle(color: PeekColors.red, fontSize: 12)),
          ),
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

  Widget _balanceRow() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet,
                color: PeekColors.text3, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: _utxosLoading
                  ? const Text('Loading UTXOs…',
                      style: TextStyle(
                          color: PeekColors.text2, fontSize: 13))
                  : _utxosError != null
                      ? Text('UTXO error: $_utxosError',
                          style: const TextStyle(
                              color: PeekColors.red, fontSize: 12))
                      : Text(
                          '${(_availableSat / 100000000).toStringAsFixed(8)} BTC '
                          'available (confirmed UTXOs only)',
                          style: const TextStyle(
                              color: PeekColors.text, fontSize: 13),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feeSelector() {
    final fees = _fees;
    if (_feesError != null) {
      return Text('Fee rates unavailable: $_feesError',
          style: const TextStyle(color: PeekColors.red, fontSize: 12));
    }
    if (fees == null) {
      return const Text('Loading fee rates…',
          style: TextStyle(color: PeekColors.text3, fontSize: 12));
    }
    Widget tile(_FeeTier t, String label, int rate, String hint) {
      final selected = _tier == t;
      return InkWell(
        onTap: () => setState(() => _tier = t),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? PeekColors.green.withValues(alpha: 0.12)
                : PeekColors.surface2,
            border: Border.all(
              color: selected ? PeekColors.green : PeekColors.border,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            color: PeekColors.text, fontSize: 13)),
                    Text(hint,
                        style: const TextStyle(
                            color: PeekColors.text3, fontSize: 11)),
                  ],
                ),
              ),
              Text('$rate sat/vB',
                  style: const TextStyle(
                      color: PeekColors.text2, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Fee priority',
            style: TextStyle(color: PeekColors.text2, fontSize: 12)),
        const SizedBox(height: 6),
        tile(_FeeTier.fastest, 'Fastest', fees.fastestSatPerVByte, '~10 min'),
        const SizedBox(height: 6),
        tile(_FeeTier.halfHour, 'Half hour', fees.halfHourSatPerVByte,
            '~30 min'),
        const SizedBox(height: 6),
        tile(_FeeTier.hour, 'Hour', fees.hourSatPerVByte, '~1 hour'),
        const SizedBox(height: 6),
        tile(_FeeTier.economy, 'Economy', fees.economySatPerVByte,
            'When the mempool allows'),
      ],
    );
  }

  Widget _kvRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(k,
                style: const TextStyle(
                    color: PeekColors.text2, fontSize: 12)),
          ),
          Expanded(
            child: GestureDetector(
              onLongPress: () =>
                  SensitiveClipboard.copy(v, label: k),
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

enum _FeeTier { fastest, halfHour, hour, economy, custom }

class _ExperimentalBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PeekColors.red.withValues(alpha: 0.12),
        border: Border.all(color: PeekColors.red),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: PeekColors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Experimental — Bitcoin send is BIP-0143 spec-vector '
              'tested but has not been audited end-to-end. Test with '
              'small amounts first.',
              style: const TextStyle(color: PeekColors.text, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
