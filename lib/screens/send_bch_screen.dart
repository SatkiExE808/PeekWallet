import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../address_book/address_book.dart';
import '../coins/bitcoin_cash/bch_wallet.dart';
import '../prices/price_feed.dart';
import '../theme.dart';
import '../util/remember_recipient.dart';
import '../util/screenshot_guard.dart';
import '../util/sensitive_clipboard.dart';
import '../widgets/coin_screen_widgets.dart';
import '../widgets/send_widgets.dart';
import 'address_book_screen.dart';
import 'qr_scan_screen.dart';

/// Bitcoin Cash send screen. Same two-step pattern as the BTC one,
/// adapted for BCH's quirks: no fee tiers (the network is cheap
/// enough that a single ~2 sat/byte rate works for anything you'd
/// reasonably want to send), no SegWit, addresses are CashAddr.
class SendBchScreen extends StatefulWidget {
  const SendBchScreen({super.key, required this.wallet});
  final BitcoinCashWallet wallet;

  @override
  State<SendBchScreen> createState() => _SendBchScreenState();
}

class _SendBchScreenState extends State<SendBchScreen> {
  final _addrCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  int _availableSat = 0;
  bool _utxosLoading = true;
  String? _utxosError;

  int _feeRate = 2; // sat/byte default; refined from wallet on load
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
    _feeRate = widget.wallet.suggestedFeeRateSatPerByte();
    try {
      final utxos = await widget.wallet.utxos();
      final sum = utxos.fold<int>(0, (a, u) => a + u.valueSat);
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

  int? _parseAmountSat() {
    final raw = _amountCtrl.text.trim();
    if (raw.isEmpty) return null;
    // Integer-string math so 0.1 BCH doesn't round to 9999999 sat.
    if (raw.contains('.')) {
      final parts = raw.split('.');
      if (parts.length != 2) return null;
      final whole = parts[0].isEmpty ? '0' : parts[0];
      final frac = parts[1];
      if (frac.length > 8) return null;
      final padded = frac.padRight(8, '0');
      final sats = int.tryParse(whole) ?? -1;
      final fracSats = int.tryParse(padded) ?? -1;
      if (sats < 0 || fracSats < 0) return null;
      final total = sats * 100000000 + fracSats;
      return total > 0 ? total : null;
    }
    return int.tryParse(raw);
  }

  Future<void> _pickFromBook() async {
    final picked = await Navigator.of(context).push<AddressBookEntry>(
      MaterialPageRoute(
        builder: (_) => const AddressBookScreen(pickForCoin: 'BCH'),
      ),
    );
    if (picked != null) {
      _addrCtrl.text = picked.address;
      unawaited(AddressBook.I.recordUse(picked.id));
      setState(() => _error = null);
    }
  }

  Future<void> _scanQr() async {
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) =>
            const QrScanScreen(title: 'Scan Bitcoin Cash address'),
      ),
    );
    if (scanned != null && scanned.isNotEmpty) {
      var s = scanned.trim();
      // Strip a bitcoincash: URI prefix if present.
      if (s.toLowerCase().startsWith('bitcoincash:')) {
        // keep the prefix — CashAddr decode expects it
        final qIx = s.indexOf('?');
        if (qIx >= 0) s = s.substring(0, qIx);
      }
      _addrCtrl.text = s;
    }
  }

  void _onMax() {
    if (_availableSat <= 0) return;
    setState(() {
      _amountCtrl.text = _availableSat.toString();
    });
  }

  Future<void> _onContinue() async {
    setState(() => _error = null);
    final amount = _parseAmountSat();
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }
    final addr = _addrCtrl.text.trim();
    // CashAddr P2KH starts with `q`, P2SH starts with `p` (either
    // bare or prefixed `bitcoincash:`). Accept both up front so the
    // form doesn't reject valid P2SH addresses; the underlying signer
    // still only supports P2KH for the moment and will surface a
    // clearer error if the user pastes a P2SH recipient.
    final cashAddrPart =
        addr.contains(':') ? addr.split(':').last : addr;
    final addrChar = cashAddrPart.isEmpty
        ? ''
        : cashAddrPart.substring(0, 1).toLowerCase();
    if (addrChar != 'q' && addrChar != 'p') {
      setState(() => _error =
          'Recipient must be a CashAddr (bitcoincash:q…/p… or just q…/p…)');
      return;
    }
    if (addrChar == 'p') {
      setState(() => _error =
          'P2SH BCH addresses (p…) aren\'t supported yet — '
          'only P2KH (q…) is in this build.');
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
      // CashAddr decode is lenient — accepts bare q… or full
      // bitcoincash:q… by adding the default prefix if missing.
      var addr = _addrCtrl.text.trim();
      if (!addr.contains(':')) {
        addr = 'bitcoincash:$addr';
      }
      final built = await widget.wallet.sendBch(
        destAddress: addr,
        amountSat: amount,
        feeRateSatPerByte: _feeRate,
      );
      unawaited(rememberRecipient(coinId: 'BCH', address: addr));
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: PeekColors.green,
          content: Text('Broadcast! tx: ${built.txid.substring(0, 14)}…'),
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
        appBar: AppBar(title: const Text('Send Bitcoin Cash')),
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
    final amount = _parseAmountSat();
    final fiat = amount == null
        ? ''
        : PriceFeed.I.formatFiat('BCH', amount / 100000000.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ExperimentalBanner(
            body:
                'legacy P2PKH with SIGHASH_FORKID. The BIP143 sighash is spec-vector tested via BTC SegWit; the BCH-specific 0x41 sighash byte + legacy tx envelope are unit-tested but unaudited.'),
        const SizedBox(height: 16),
        _balanceCard(),
        const SizedBox(height: 20),
        const Text('Recipient address (CashAddr)',
            style: TextStyle(color: PeekColors.text2, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: _addrCtrl,
          decoration: InputDecoration(
            hintText: 'bitcoincash:q…',
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.bookmark_border, size: 18),
                  tooltip: 'From address book',
                  onPressed: _pickFromBook,
                ),
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
              child: Text('Amount (BCH or sat)',
                  style: TextStyle(color: PeekColors.text2, fontSize: 12)),
            ),
            TextButton(
              onPressed: _availableSat == 0 ? null : _onMax,
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
              (_utxosLoading || _availableSat == 0) ? null : _onContinue,
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    final amount = _parseAmountSat()!;
    final addr = _addrCtrl.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ExperimentalBanner(
            body:
                'legacy P2PKH with SIGHASH_FORKID. The BIP143 sighash is spec-vector tested via BTC SegWit; the BCH-specific 0x41 sighash byte + legacy tx envelope are unit-tested but unaudited.'),
        const SizedBox(height: PeekDesign.sp4),
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
                '${(amount / 100000000.0).toStringAsFixed(8)} BCH',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'will be sent to',
                style: TextStyle(color: PeekColors.text3, fontSize: 12),
              ),
              const SizedBox(height: PeekDesign.sp4),
              _kvRow('To',
                  '${addr.substring(0, 18)}…${addr.substring(addr.length - 8)}'),
              const Divider(height: 18, color: PeekColors.hairline),
              _kvRow('Fee rate', '$_feeRate sat/byte'),
              const Divider(height: 18, color: PeekColors.hairline),
              _kvRow('Available', '$_availableSat sat'),
            ],
          ),
        ),
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
            children: const [
              Icon(Icons.info_outline_rounded,
                  size: 14, color: PeekColors.text3),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'BCH legacy P2PKH with SIGHASH_FORKID. Once submitted '
                  'this CANNOT be reversed (BCH does not honor RBF).',
                  style: TextStyle(
                      color: PeekColors.text3, fontSize: 11, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PeekDesign.sp5),
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
        const SizedBox(height: PeekDesign.sp5),
        Row(
          children: [
            Expanded(
              child: ActionButton(
                icon: Icons.arrow_back_rounded,
                label: 'Back',
                primary: false,
                onTap: _broadcasting
                    ? null
                    : () => setState(() {
                          _previewing = false;
                          _confirmCtrl.clear();
                        }),
              ),
            ),
            const SizedBox(width: PeekDesign.sp3),
            Expanded(
              child: ActionButton(
                icon: Icons.send_rounded,
                label: _broadcasting ? 'Sending…' : 'Send',
                primary: true,
                onTap: _broadcasting ? null : _onConfirm,
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
              child: _utxosLoading
                  ? const Text('Loading UTXOs…',
                      style: TextStyle(
                          color: PeekColors.text2, fontSize: 13))
                  : _utxosError != null
                      ? Text('UTXO error: $_utxosError',
                          style: const TextStyle(
                              color: PeekColors.red, fontSize: 12))
                      : Text(
                          '${(_availableSat / 100000000.0).toStringAsFixed(8)} BCH available',
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
          children: [
            const Text('Network fee',
                style: TextStyle(
                    color: PeekColors.text2, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              '$_feeRate sat/byte — typical 1-input tx ≈ ${(192 * _feeRate).toString()} sat. BCH fees are extremely low.',
              style: const TextStyle(
                  color: PeekColors.text, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorBox(String msg) => SendErrorTile(message: msg);

  Widget _kvRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
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

// _ExperimentalBanner moved to widgets/send_widgets.dart.
