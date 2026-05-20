import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../address_book/address_book.dart';
import '../coins/bitcoin/bitcoin_wallet.dart';
import '../coins/bitcoin/mempool_client.dart';
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
  /// Fallback sat/vB used when mempool.space's fee oracle is
  /// unreachable. Picked to clear within ~1h on a typical day; well
  /// above the network's minimum-relay floor.
  static const int _feeFallback = 5;

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
    // Fire both calls in parallel so the send screen lands in
    // ~max(feeRates, utxos) instead of feeRates + utxos. Each call
    // has its own try/catch so a feerate failure doesn't poison the
    // UTXO result (and vice versa) — mempool.space sometimes serves
    // /fees/recommended while /address/.../utxo is rate-limited, and
    // we want the form to be usable in that case.
    final feesFut = widget.wallet.feeRates().then((fees) {
      if (mounted) setState(() => _fees = fees);
    }).catchError((Object e) {
      if (mounted) setState(() => _feesError = '$e');
    });
    final utxosFut = widget.wallet.utxos().then((utxos) {
      final sum = utxos
          .where((u) => u.confirmed)
          .fold<int>(0, (a, u) => a + u.valueSat);
      if (mounted) {
        setState(() {
          _availableSat = sum;
          _utxosLoading = false;
        });
      }
    }).catchError((Object e) {
      if (mounted) {
        setState(() {
          _utxosError = '$e';
          _utxosLoading = false;
        });
      }
    });
    await Future.wait([feesFut, utxosFut]);
  }

  int get _selectedFeeRate {
    final fees = _fees;
    if (fees == null) return _feeFallback;
    switch (_tier) {
      case _FeeTier.fastest:
        return fees.fastestSatPerVByte;
      case _FeeTier.halfHour:
        return fees.halfHourSatPerVByte;
      case _FeeTier.hour:
        return fees.hourSatPerVByte;
      case _FeeTier.economy:
        return fees.economySatPerVByte;
    }
  }

  int? _parseAmountSat() {
    final raw = _amountCtrl.text.trim();
    if (raw.isEmpty) return null;
    // Accept both 0.00012 (BTC) and 12000 (sat). If it contains a
    // decimal point, treat as BTC. Parse as integer-string math so
    // we don't lose precision through double × 1e8 — `0.1` BTC
    // could otherwise round to 9999999 or 10000001 sat depending on
    // the platform's FP rounding mode.
    if (raw.contains('.')) {
      final parts = raw.split('.');
      if (parts.length != 2) return null;
      final whole = parts[0].isEmpty ? '0' : parts[0];
      final frac = parts[1];
      if (frac.length > 8) return null; // more decimals than sat granularity
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
        builder: (_) => AddressBookScreen(
            pickForCoin: widget.wallet.params.id),
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
        builder: (_) => QrScanScreen(
          title: l.sendScanTitle(widget.wallet.params.symbol),
        ),
      ),
    );
    if (scanned != null && scanned.isNotEmpty) {
      _addrCtrl.text = scanned;
    }
  }

  void _onMax() {
    // "Send all" — fill the amount field with the available balance.
    // The send path will recompute the fee and subtract it (rolling
    // dust change into fee already handles the small leftover).
    // We populate sat-form so there's no float rounding.
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
    final hrpPrefix = '${widget.wallet.params.bech32Hrp}1q';
    if (!addr.startsWith(hrpPrefix)) {
      setState(() => _error = l.sendBtcOnlyBech32(hrpPrefix));
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
      final destAddress = _addrCtrl.text.trim();
      final built = await widget.wallet.sendBitcoin(
        destAddress: destAddress,
        amountSat: amount,
        feeRateSatPerVByte: _selectedFeeRate,
      );
      unawaited(rememberRecipient(
        coinId: widget.wallet.params.id,
        address: destAddress,
      ));
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
    final coinName = widget.wallet.params.name;
    return ScreenshotGuard(
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.sendScreenTitle(coinName)),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            // Sliding form → preview transition. The new step slides
            // in from the right (a tap-into-confirm feel) and the
            // old one slides out to the left. Matches the wallet
            // navigation gesture so the user reads it as "moved
            // forward" rather than a content swap.
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
    final amountSat = _parseAmountSat();
    final fiatStr = amountSat == null
        ? ''
        : PriceFeed.I.formatFiat(
            widget.wallet.params.symbol, amountSat / 100000000.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExperimentalBanner(body: l.sendBtcExperimentalBody),
        const SizedBox(height: 16),
        _balanceRow(),
        const SizedBox(height: 20),
        Text(l.sendFormRecipientLabel,
            style: const TextStyle(color: PeekColors.text2, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: _addrCtrl,
          decoration: InputDecoration(
            hintText: '${widget.wallet.params.bech32Hrp}1q…',
            // Two trailing icons: paste + QR scan. The QR path drops
            // any bitcoin:/litecoin:/monero: scheme automatically so
            // we get a bare address into the field.
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
              child: Text(
                l.sendBtcAmountLabel(widget.wallet.params.symbol),
                style: const TextStyle(
                    color: PeekColors.text2, fontSize: 12),
              ),
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
            hintText: '0.001',
            helperText: fiatStr.isEmpty ? null : '≈ $fiatStr',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        _feeSelector(),
        if (_error != null) ...[
          const SizedBox(height: 12),
          SendErrorTile(message: _error!),
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
    final feeRate = _selectedFeeRate;
    final addr = _addrCtrl.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExperimentalBanner(body: l.sendBtcExperimentalBody),
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
                '${(amount / 100000000).toStringAsFixed(8)} ${widget.wallet.params.symbol}',
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
                  '${addr.substring(0, 12)}…${addr.substring(addr.length - 8)}'),
              const Divider(height: 18, color: PeekColors.hairline),
              _kvRow(l.sendBtcFeeRateLabel, '$feeRate sat/vB'),
              const Divider(height: 18, color: PeekColors.hairline),
              // Available was previously the pre-send balance, which
              // misled the user into thinking the send had no impact.
              // Show pre-send + a derived "Remaining (approx)" line —
              // exact change can only be known after coin selection
              // runs in sendBitcoin() but a "amount + 1×fee-rate band"
              // estimate is good enough for a sanity check.
              _kvRow(l.sendFormAvailableLabel, '$_availableSat sat'),
              const Divider(height: 18, color: PeekColors.hairline),
              _kvRow(
                  'Remaining ≈',
                  '${(_availableSat - amount - feeRate * 200).clamp(0, _availableSat)} sat'),
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
                  l.sendBtcFinalFeeHint,
                  style: const TextStyle(
                      color: PeekColors.text3, fontSize: 11, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PeekDesign.sp5),
        Text(
          l.sendFormConfirmHint,
          style: const TextStyle(color: PeekColors.text2, fontSize: 12),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _confirmCtrl,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          decoration: InputDecoration(hintText: l.sendFormConfirmPlaceholder),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          SendErrorTile(message: _error!),
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

  Widget _balanceRow() {
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
                              '${(_availableSat / 100000000).toStringAsFixed(8)} '
                              '${widget.wallet.params.symbol}',
                              style: const TextStyle(
                                color: PeekColors.text,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.1,
                              ),
                            ),
                            Text(
                              l.sendBtcAvailableHint,
                              style: const TextStyle(
                                  color: PeekColors.text3, fontSize: 11),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feeSelector() {
    final l = AppLocalizations.of(context);
    final fees = _fees;
    if (_feesError != null) {
      return Text(l.sendBtcFeeRatesError(_feesError!),
          style: const TextStyle(color: PeekColors.red, fontSize: 12));
    }
    if (fees == null) {
      return Text(l.sendBtcLoadingFeeRates,
          style: const TextStyle(color: PeekColors.text3, fontSize: 12));
    }
    Widget tile(_FeeTier t, String label, int rate, String hint) {
      final selected = _tier == t;
      return Material(
        color: selected ? PeekColors.accentMuted : PeekColors.surface,
        borderRadius: PeekDesign.brSmall,
        child: InkWell(
          onTap: () => setState(() => _tier = t),
          borderRadius: PeekDesign.brSmall,
          splashColor: PeekColors.accentMuted,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: PeekDesign.sp3, vertical: PeekDesign.sp3),
            decoration: BoxDecoration(
              borderRadius: PeekDesign.brSmall,
              border: Border.all(
                color: selected
                    ? PeekColors.accent
                    : PeekColors.hairline,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: PeekDesign.tFast,
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? PeekColors.accent
                        : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? PeekColors.accent
                          : PeekColors.border2,
                      width: 1.5,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded,
                          size: 12, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: PeekDesign.sp3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              color: PeekColors.text,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.1)),
                      Text(hint,
                          style: const TextStyle(
                              color: PeekColors.text3, fontSize: 11)),
                    ],
                  ),
                ),
                Text('$rate sat/vB',
                    style: const TextStyle(
                        color: PeekColors.text2,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.sendFormFeePriorityLabel,
          style: const TextStyle(
              color: PeekColors.text3,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2),
        ),
        const SizedBox(height: PeekDesign.sp2),
        tile(_FeeTier.fastest, l.sendBtcFeeTierFastest,
            fees.fastestSatPerVByte, l.sendBtcFeeEtaFastest),
        const SizedBox(height: PeekDesign.sp2),
        tile(_FeeTier.halfHour, l.sendBtcFeeTierHalfHour,
            fees.halfHourSatPerVByte, l.sendBtcFeeEtaHalfHour),
        const SizedBox(height: PeekDesign.sp2),
        tile(_FeeTier.hour, l.sendBtcFeeTierHour, fees.hourSatPerVByte,
            l.sendBtcFeeEtaHour),
        const SizedBox(height: PeekDesign.sp2),
        tile(_FeeTier.economy, l.sendBtcFeeTierEconomy,
            fees.economySatPerVByte, l.sendBtcFeeEtaEconomy),
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

enum _FeeTier { fastest, halfHour, hour, economy }

// _ExperimentalBanner / error tile are now in widgets/send_widgets.dart.
