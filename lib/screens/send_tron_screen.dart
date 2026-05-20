import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../address_book/address_book.dart';
import '../coins/tron/trc20.dart';
import '../coins/tron/tron_wallet.dart';
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

/// Send screen for native TRX + TRC-20 tokens. Same two-step flow
/// as the BTC/ETH/SOL ones (form → preview → type SEND to confirm),
/// adapted for Tron's two quirks:
///   - Sends always cost some bandwidth/energy; the network either
///     charges a TRX fee or burns the user's daily free quota.
///     Hard to predict ahead of time, so we don't show a per-tx
///     fee preview — just a banner about the ~1 TRX worst-case.
///   - Token sends use the same TRX gas (bandwidth/energy), so a
///     user with 0 TRX can't send tokens even if they have a USDT
///     balance.
class SendTronScreen extends StatefulWidget {
  const SendTronScreen({
    super.key,
    required this.wallet,
    this.token,
  });
  final TronWallet wallet;
  /// Non-null = TRC-20 transfer to this token's contract.
  /// Null = native TRX transfer.
  final Trc20Token? token;

  String get assetSymbol => token?.symbol ?? 'TRX';

  @override
  State<SendTronScreen> createState() => _SendTronScreenState();
}

class _SendTronScreenState extends State<SendTronScreen> {
  final _addrCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  int _balanceSun = 0;
  BigInt _tokenBalanceRaw = BigInt.zero;
  bool _loading = true;
  String? _balanceError;

  bool _previewing = false;
  bool _broadcasting = false;
  String? _error;

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
      final sun = await widget.wallet.balanceSun();
      BigInt tokenRaw = BigInt.zero;
      if (widget.token != null) {
        tokenRaw = await widget.wallet.tokenBalanceRaw(widget.token!);
      }
      if (mounted) {
        setState(() {
          _balanceSun = sun;
          _tokenBalanceRaw = tokenRaw;
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

  /// Parse the amount as either decimal (TRX/token) or base units.
  /// Native TRX uses 6 decimals (1 TRX = 10^6 sun); TRC-20 uses
  /// whatever the token's decimals field says (USDT/USDC = 6).
  ({int? sun, BigInt? tokenRaw}) _parseAmount() {
    final raw = _amountCtrl.text.trim();
    if (raw.isEmpty) return (sun: null, tokenRaw: null);

    if (widget.token != null) {
      final decimals = widget.token!.decimals;
      if (raw.contains('.')) {
        final tokenRaw = _decimalToRaw(raw, decimals);
        return (sun: null, tokenRaw: tokenRaw);
      }
      return (sun: null, tokenRaw: BigInt.tryParse(raw));
    }

    if (raw.contains('.')) {
      final v = double.tryParse(raw);
      if (v == null || v <= 0) return (sun: null, tokenRaw: null);
      final asBigInt = _decimalToRaw(raw, 6);
      return (sun: asBigInt?.toInt(), tokenRaw: null);
    }
    return (sun: int.tryParse(raw), tokenRaw: null);
  }

  BigInt? _decimalToRaw(String dec, int decimals) {
    try {
      final parts = dec.split('.');
      final whole = parts[0];
      final frac = parts.length > 1 ? parts[1] : '';
      if (frac.length > decimals) return null;
      final padded = frac.padRight(decimals, '0');
      final combined = (whole.isEmpty ? '0' : whole) + padded;
      final trimmed = combined.replaceFirst(RegExp(r'^0+'), '');
      return BigInt.parse(trimmed.isEmpty ? '0' : trimmed);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickFromBook() async {
    final picked = await Navigator.of(context).push<AddressBookEntry>(
      MaterialPageRoute(
        builder: (_) => const AddressBookScreen(pickForCoin: 'TRX'),
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
        builder: (_) => QrScanScreen(title: l.sendScanTitle('TRX')),
      ),
    );
    if (scanned != null && scanned.isNotEmpty) {
      var s = scanned.trim();
      // Tron QRs sometimes use a tron:address URI scheme; strip it.
      if (s.toLowerCase().startsWith('tron:')) {
        s = s.substring('tron:'.length);
        final qIx = s.indexOf('?');
        if (qIx >= 0) s = s.substring(0, qIx);
      }
      _addrCtrl.text = s;
    }
  }

  void _onMax() {
    if (widget.token != null) {
      if (_tokenBalanceRaw <= BigInt.zero) return;
      setState(() {
        _amountCtrl.text = _tokenBalanceRaw.toString();
      });
      return;
    }
    // Native: keep ~1 TRX reserve for bandwidth/energy on subsequent
    // sends. Send-all-and-empty-wallet leaves the user without gas.
    const reserveSun = 1000000;
    if (_balanceSun <= reserveSun) return;
    setState(() {
      _amountCtrl.text = (_balanceSun - reserveSun).toString();
    });
  }

  Future<void> _onContinue() async {
    final l = AppLocalizations.of(context);
    setState(() => _error = null);
    final parsed = _parseAmount();
    final addr = _addrCtrl.text.trim();
    if (!addr.startsWith('T') || addr.length != 34) {
      setState(() => _error = l.sendTrxErrorBadAddress);
      return;
    }

    if (widget.token != null) {
      final amt = parsed.tokenRaw;
      if (amt == null || amt <= BigInt.zero) {
        setState(() => _error = l.sendFormErrorInvalidAmount);
        return;
      }
      if (amt > _tokenBalanceRaw) {
        setState(() =>
            _error = l.sendEthErrorExceedsToken(widget.token!.symbol));
        return;
      }
      if (_balanceSun == 0) {
        setState(() => _error = l.sendTrxErrorNoTrx);
        return;
      }
    } else {
      final amt = parsed.sun;
      if (amt == null || amt <= 0) {
        setState(() => _error = l.sendFormErrorInvalidAmount);
        return;
      }
      if (amt > _balanceSun) {
        setState(() => _error = l.sendFormErrorAmountExceedsBalance);
        return;
      }
    }
    setState(() => _previewing = true);
  }

  Future<void> _onConfirm() async {
    final l = AppLocalizations.of(context);
    if (_confirmCtrl.text.trim().toUpperCase() != 'SEND') {
      setState(() => _error = l.sendFormConfirmHint);
      return;
    }
    setState(() {
      _broadcasting = true;
      _error = null;
    });
    final nav = Navigator.of(context);
    try {
      final destAddress = _addrCtrl.text.trim();
      final parsed = _parseAmount();
      String txid;
      if (widget.token != null) {
        txid = await widget.wallet.sendTrc20(
          token: widget.token!,
          destAddress: destAddress,
          amountRaw: parsed.tokenRaw!,
        );
      } else {
        txid = await widget.wallet.sendTrx(
          destAddress: destAddress,
          amountSun: parsed.sun!,
        );
      }
      unawaited(rememberRecipient(
        coinId: 'TRX',
        address: destAddress,
      ));
      if (!mounted) return;
      showSendSuccess(context, txid: txid);
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
        appBar:
            AppBar(title: Text(l.sendScreenTitle(widget.assetSymbol))),
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
    final parsed = _parseAmount();
    final symbol = widget.assetSymbol;
    final displayValue = widget.token != null && parsed.tokenRaw != null
        ? widget.wallet
            .tokenBalanceDisplay(parsed.tokenRaw!, widget.token!)
        : (parsed.sun != null ? parsed.sun! / 1000000.0 : 0);
    final fiat = displayValue > 0
        ? PriceFeed.I.formatFiat(symbol, displayValue.toDouble())
        : '';
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExperimentalBanner(body: l.sendTrxExperimentalBody),
        const SizedBox(height: 16),
        _balanceCard(),
        const SizedBox(height: 20),
        Text(l.sendTrxRecipientLabel,
            style: const TextStyle(color: PeekColors.text2, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: _addrCtrl,
          decoration: InputDecoration(
            hintText: 'T…',
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
                widget.token != null
                    ? l.sendTrxAmountLabelToken(symbol)
                    : l.sendTrxAmountLabelNative,
                style: const TextStyle(
                    color: PeekColors.text2, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: _onMax,
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
            hintText: widget.token != null ? '10.00' : '0.5',
            helperText: fiat.isEmpty ? null : '≈ $fiat',
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _errorBox(_error!),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _loading ? null : _onContinue,
          child: Text(l.actionContinue),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    final l = AppLocalizations.of(context);
    final parsed = _parseAmount();
    final addr = _addrCtrl.text.trim();
    final amountStr = widget.token != null
        ? '${widget.wallet.tokenBalanceDisplay(parsed.tokenRaw!, widget.token!).toStringAsFixed(widget.token!.decimals == 6 ? 2 : 4)} ${widget.token!.symbol}'
        : '${(parsed.sun! / 1000000.0).toStringAsFixed(6)} TRX';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExperimentalBanner(body: l.sendTrxExperimentalBody),
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
                amountStr,
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
              _kvRow(
                  l.sendTrxBandwidthLabel,
                  widget.token != null
                      ? l.sendTrxBandwidthToken
                      : l.sendTrxBandwidthNative),
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
                  l.sendTrxFinalFeeHint,
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
              child: _loading
                  ? Text(l.sendEthLoadingBalance,
                      style: const TextStyle(
                          color: PeekColors.text2, fontSize: 13))
                  : _balanceError != null
                      ? Text(l.sendEthBalanceError(_balanceError!),
                          style: const TextStyle(
                              color: PeekColors.red, fontSize: 12))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.token != null
                                  ? '${widget.wallet.tokenBalanceDisplay(_tokenBalanceRaw, widget.token!).toStringAsFixed(widget.token!.decimals == 6 ? 2 : 4)} ${widget.token!.symbol}'
                                  : '${(_balanceSun / 1000000.0).toStringAsFixed(6)} TRX',
                              style: const TextStyle(
                                color: PeekColors.text,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.1,
                              ),
                            ),
                            Text(
                              widget.token != null
                                  ? l.sendEthAvailableForGas(
                                      (_balanceSun / 1000000.0)
                                          .toStringAsFixed(6),
                                      'TRX')
                                  : l.sendBchAvailableShort,
                              style: const TextStyle(
                                  color: PeekColors.text3,
                                  fontSize: 11),
                            ),
                          ],
                        ),
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
            width: 130,
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
