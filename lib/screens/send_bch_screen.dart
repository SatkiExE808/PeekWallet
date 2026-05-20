import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../address_book/address_book.dart';
import '../coins/bitcoin_cash/bch_wallet.dart';
import '../l10n/gen/app_localizations.dart';
import '../prices/price_feed.dart';
import '../theme.dart';
import '../widgets/send_success_snackbar.dart';
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
    final l = AppLocalizations.of(context);
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => QrScanScreen(title: l.sendScanTitle('BCH')),
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
    final l = AppLocalizations.of(context);
    setState(() => _error = null);
    final amount = _parseAmountSat();
    if (amount == null || amount <= 0) {
      setState(() => _error = l.sendFormErrorInvalidAmount);
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
      setState(() => _error = l.sendBchErrorMustBeCashAddr);
      return;
    }
    if (addrChar == 'p') {
      setState(() => _error = l.sendBchErrorP2shNotSupported);
      return;
    }
    if (amount > _availableSat) {
      setState(() => _error = l.sendBtcExceedsBalance(_availableSat));
      return;
    }
    setState(() => _previewing = true);
  }

  Future<void> _onConfirm() async {
    final l = AppLocalizations.of(context);
    if (_confirmCtrl.text.trim().toUpperCase() != 'SEND') {
      setState(() => _error = l.sendFormConfirmHint);
      return;
    }
    final amount = _parseAmountSat();
    if (amount == null) return;
    setState(() {
      _broadcasting = true;
      _error = null;
    });
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
      showSendSuccess(context, txid: built.txid);
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
    final l = AppLocalizations.of(context);
    return ScreenshotGuard(
      child: Scaffold(
        appBar: AppBar(
            title: Text(l.sendScreenTitle('Bitcoin Cash'))),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: AnimatedSwitcher(
              duration: PeekDesign.tMed,
              switchInCurve: PeekDesign.easeOut,
              switchOutCurve: PeekDesign.easeOut,
              transitionBuilder: (child, animation) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.08, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: KeyedSubtree(
                key: ValueKey<bool>(_previewing),
                child: _previewing ? _buildPreview() : _buildForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final l = AppLocalizations.of(context);
    final amount = _parseAmountSat();
    final fiat = amount == null
        ? ''
        : PriceFeed.I.formatFiat('BCH', amount / 100000000.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExperimentalBanner(body: l.sendBchExperimentalBody),
        const SizedBox(height: 16),
        _balanceCard(),
        const SizedBox(height: 20),
        Text(l.sendBchRecipientLabel,
            style: const TextStyle(color: PeekColors.text2, fontSize: 12)),
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
                  tooltip: l.sendFormBookTooltip,
                  onPressed: _pickFromBook,
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner, size: 18),
                  tooltip: l.sendFormScanTooltip,
                  onPressed: _scanQr,
                ),
                IconButton(
                  icon: const Icon(Icons.paste, size: 18),
                  tooltip: l.sendFormPasteTooltip,
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
            Expanded(
              child: Text(l.sendBchAmountLabel,
                  style: const TextStyle(
                      color: PeekColors.text2, fontSize: 12)),
            ),
            TextButton(
              onPressed: _availableSat == 0 ? null : _onMax,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 0),
                minimumSize: const Size(0, 24),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(l.sendFormMaxButton,
                  style: const TextStyle(fontSize: 12)),
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
          child: Text(l.actionContinue),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    final l = AppLocalizations.of(context);
    final amount = _parseAmountSat()!;
    final addr = _addrCtrl.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExperimentalBanner(body: l.sendBchExperimentalBody),
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
              Text(
                l.sendFormWillBeSentTo,
                style: const TextStyle(
                    color: PeekColors.text3, fontSize: 12),
              ),
              const SizedBox(height: PeekDesign.sp4),
              _kvRow(l.sendFormToLabel,
                  '${addr.substring(0, 18)}…${addr.substring(addr.length - 8)}'),
              const Divider(height: 18, color: PeekColors.hairline),
              _kvRow(l.sendBtcFeeRateLabel, '$_feeRate sat/byte'),
              const Divider(height: 18, color: PeekColors.hairline),
              _kvRow(l.sendFormAvailableLabel, '$_availableSat sat'),
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
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 14, color: PeekColors.text3),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.sendBchFinalFeeHint,
                  style: const TextStyle(
                      color: PeekColors.text3, fontSize: 11, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PeekDesign.sp5),
        Text(l.sendFormConfirmHint,
            style: const TextStyle(color: PeekColors.text2, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: _confirmCtrl,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          decoration:
              InputDecoration(hintText: l.sendFormConfirmPlaceholder),
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
                label: l.actionBack,
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
                label: _broadcasting ? l.actionSending : l.actionSend,
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
    final l = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: PeekDesign.sp4, vertical: PeekDesign.sp3),
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
              child: const Icon(Icons.account_balance_wallet_rounded,
                  color: PeekColors.text2, size: 18),
            ),
            const SizedBox(width: PeekDesign.sp3),
            Expanded(
              child: _utxosLoading
                  ? Text(l.sendBtcLoadingUtxos,
                      style: const TextStyle(
                          color: PeekColors.text2, fontSize: 13))
                  : _utxosError != null
                      ? Text(l.sendBtcUtxoError(_utxosError!),
                          style: const TextStyle(
                              color: PeekColors.red, fontSize: 12))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(_availableSat / 100000000.0).toStringAsFixed(8)} BCH',
                              style: const TextStyle(
                                color: PeekColors.text,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.1,
                              ),
                            ),
                            Text(l.sendBchAvailableShort,
                                style: const TextStyle(
                                    color: PeekColors.text3,
                                    fontSize: 11)),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feeCard() {
    final l = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.sendBchNetworkFeeLabel,
                style: const TextStyle(
                    color: PeekColors.text2, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              l.sendBchFeeRateDescription(_feeRate, 192 * _feeRate),
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
