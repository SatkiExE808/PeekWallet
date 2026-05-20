import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../address_book/address_book.dart';
import '../coins/solana/solana_rpc_client.dart';
import '../coins/solana/solana_wallet.dart';
import '../coins/solana/spl_tokens.dart';
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

/// Solana send screen. Same two-step flow as the other coins —
/// form → preview → type SEND to confirm. Marked experimental:
/// transaction encoding is unit-tested but the end-to-end flow
/// hasn't been audited.
class SendSolanaScreen extends StatefulWidget {
  const SendSolanaScreen({
    super.key,
    required this.wallet,
    this.token,
  });
  final SolanaWallet wallet;
  /// Non-null = send THIS SPL token via the Token Program transfer
  /// instruction. Null = send native SOL via SystemProgram.transfer.
  final SplToken? token;

  String get assetSymbol => token?.symbol ?? 'SOL';

  @override
  State<SendSolanaScreen> createState() => _SendSolanaScreenState();
}

class _SendSolanaScreenState extends State<SendSolanaScreen> {
  final _addrCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  int _balanceLamports = 0;
  BigInt _tokenBalanceRaw = BigInt.zero;
  bool _loading = true;
  String? _balanceError;

  bool _previewing = false;
  bool _broadcasting = false;
  bool _probingAta = false;
  String? _error;

  /// True when the recipient doesn't yet have an ATA for the token
  /// being sent — set by [_onContinue] after a getTokenAccountsByOwner
  /// probe. Drives the "+ ATA rent reserve" line in the preview so
  /// the user sees the actual SOL deduction (~0.00204 SOL) instead
  /// of just the 5000-lamport base fee. Null = native send (no ATA
  /// concept) or probe didn't run.
  bool? _destinationNeedsAta;

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
      BigInt tokenRaw = BigInt.zero;
      if (widget.token != null) {
        tokenRaw = await widget.wallet.tokenBalanceRaw(widget.token!);
      }
      if (mounted) {
        setState(() {
          _balanceLamports = v;
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

  /// Parse the amount as either lamports (native SOL) or token base
  /// units (SPL). Native SOL uses 9 decimals; SPL tokens use their
  /// own decimals from the catalog.
  ({int? lamports, BigInt? tokenRaw}) _parseAmount() {
    final raw = _amountCtrl.text.trim();
    if (raw.isEmpty) return (lamports: null, tokenRaw: null);

    if (widget.token != null) {
      final decimals = widget.token!.decimals;
      if (raw.contains('.')) {
        final tokenRaw = _decimalToRaw(raw, decimals);
        return (lamports: null, tokenRaw: tokenRaw);
      }
      return (lamports: null, tokenRaw: BigInt.tryParse(raw));
    }

    if (raw.contains('.')) {
      final asBig = _decimalToRaw(raw, 9);
      if (asBig == null) return (lamports: null, tokenRaw: null);
      // Solana lamports fit in int64; reject anything bigger so we
      // can't silently truncate the user's input on the way through
      // BigInt.toInt() and broadcast a different amount.
      if (asBig > BigInt.from(0x7fffffffffffffff)) {
        return (lamports: null, tokenRaw: null);
      }
      return (lamports: asBig.toInt(), tokenRaw: null);
    }
    return (lamports: int.tryParse(raw), tokenRaw: null);
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
        builder: (_) => const AddressBookScreen(pickForCoin: 'SOL'),
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
        builder: (_) => QrScanScreen(title: l.sendScanTitle('SOL')),
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
    if (widget.token != null) {
      // Token send: max = full token balance. SOL fee comes out
      // of the separate native balance.
      if (_tokenBalanceRaw <= BigInt.zero) return;
      setState(() {
        _amountCtrl.text = _tokenBalanceRaw.toString();
      });
      return;
    }
    // Native: subtract a one-tx fee reserve so the send can't fail
    // for insufficient funds after we've already signed.
    if (_balanceLamports <= _feeLamports) return;
    setState(() {
      _amountCtrl.text = (_balanceLamports - _feeLamports).toString();
    });
  }

  Future<void> _onContinue() async {
    final l = AppLocalizations.of(context);
    setState(() => _error = null);
    final parsed = _parseAmount();
    final addr = _addrCtrl.text.trim();
    if (addr.length < 32 || addr.length > 44) {
      setState(() => _error = l.sendSolErrorBadAddress);
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
      if (_balanceLamports < _feeLamports) {
        setState(() => _error = l.sendSolErrorNoSol);
        return;
      }

      // Probe the recipient's ATA so the preview can surface the
      // ~0.00204 SOL rent reserve sendSpl() would otherwise charge
      // silently. Failure to probe → assume worst case (needs ATA)
      // so the user sees the larger fee and isn't blindsided.
      setState(() {
        _probingAta = true;
        _destinationNeedsAta = null;
      });
      bool hasAta;
      try {
        hasAta = await widget.wallet.recipientHasTokenAccount(
          token: widget.token!,
          destOwnerAddress: addr,
        );
      } catch (_) {
        hasAta = false; // probe failed — assume worst case
      }
      if (!mounted) return;
      // SOL balance check has to account for the ATA rent if needed:
      // sendSpl will pay ~0.00204 SOL out of native balance on top of
      // the 5000-lamport tx fee. Reject up front rather than letting
      // the broadcast fail post-confirm.
      final needsAta = !hasAta;
      final solRequired = _feeLamports +
          (needsAta ? SolanaWallet.ataRentLamports : 0);
      if (_balanceLamports < solRequired) {
        setState(() {
          _probingAta = false;
          _error = needsAta
              ? l.sendSolErrorNeedsAtaSol(widget.token!.symbol)
              : l.sendSolErrorNotEnoughSol;
        });
        return;
      }
      setState(() {
        _destinationNeedsAta = needsAta;
        _probingAta = false;
        _previewing = true;
      });
      return;
    }
    final amt = parsed.lamports;
    if (amt == null || amt <= 0) {
      setState(() => _error = l.sendFormErrorInvalidAmount);
      return;
    }
    if (amt + _feeLamports > _balanceLamports) {
      setState(() => _error = l.sendSolErrorAmountFeeExceeds);
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
    final parsed = _parseAmount();
    setState(() {
      _broadcasting = true;
      _error = null;
    });
    final nav = Navigator.of(context);
    try {
      final destAddress = _addrCtrl.text.trim();
      String sig;
      if (widget.token != null) {
        final built = await widget.wallet.sendSpl(
          token: widget.token!,
          destOwnerAddress: destAddress,
          amountRaw: parsed.tokenRaw!,
        );
        sig = built.signature;
      } else {
        final built = await widget.wallet.sendSol(
          destAddress: destAddress,
          lamports: parsed.lamports!,
        );
        sig = built.signature;
      }
      unawaited(rememberRecipient(
        coinId: 'SOL',
        address: destAddress,
      ));
      if (!mounted) return;
      showSendSuccess(context, txid: sig);
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
          title: Text(widget.token != null
              ? l.sendScreenTitle(widget.token!.symbol)
              : l.sendScreenTitle('Solana')),
        ),
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
    final parsed = _parseAmount();
    final displayValue = widget.token != null && parsed.tokenRaw != null
        ? widget.wallet
            .tokenBalanceDisplay(parsed.tokenRaw!, widget.token!)
        : (parsed.lamports != null
            ? parsed.lamports! / 1000000000.0
            : 0.0);
    final fiat = displayValue > 0
        ? PriceFeed.I.formatFiat(widget.assetSymbol, displayValue)
        : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExperimentalBanner(body: l.sendSolExperimentalBody),
        const SizedBox(height: 16),
        _balanceCard(),
        const SizedBox(height: 20),
        Text(l.sendFormRecipientLabel,
            style: const TextStyle(color: PeekColors.text2, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: _addrCtrl,
          decoration: InputDecoration(
            hintText: l.sendSolAddressHint,
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
                      ? l.sendSolAmountLabelToken(widget.token!.symbol)
                      : l.sendSolAmountLabelNative,
                  style: const TextStyle(
                      color: PeekColors.text2, fontSize: 12)),
            ),
            TextButton(
              onPressed: (widget.token != null
                      ? _tokenBalanceRaw == BigInt.zero
                      : _balanceLamports <= _feeLamports)
                  ? null
                  : _onMax,
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
          onPressed: (_loading || _balanceLamports == 0 || _probingAta)
              ? null
              : _onContinue,
          child: _probingAta
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(l.actionContinue),
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
        : '${(parsed.lamports! / 1000000000.0).toStringAsFixed(9)} SOL';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExperimentalBanner(body: l.sendSolExperimentalBody),
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
              _kvRow(l.sendSolNetworkFeeLabel,
                  '${(_feeLamports / 1000000000.0).toStringAsFixed(9)} SOL'),
              if (_destinationNeedsAta == true) ...[
                const Divider(height: 18, color: PeekColors.hairline),
                _kvRow(
                  l.sendSolAtaRentLabel,
                  '${(SolanaWallet.ataRentLamports / 1000000000.0).toStringAsFixed(9)} SOL',
                ),
                const Divider(height: 18, color: PeekColors.hairline),
                _kvRow(
                  l.sendSolTotalOutLabel,
                  '${((_feeLamports + SolanaWallet.ataRentLamports) / 1000000000.0).toStringAsFixed(9)} SOL',
                ),
              ],
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
                  _destinationNeedsAta == true
                      ? l.sendSolFinalFeeHintNewAta(widget.token!.symbol)
                      : l.sendSolFinalFeeHintNative,
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
                                  : '${(_balanceLamports / 1000000000.0).toStringAsFixed(9)} SOL',
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
                                      (_balanceLamports / 1000000000.0)
                                          .toStringAsFixed(6),
                                      'SOL')
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

  Widget _feeCard() {
    final l = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.sendSolNetworkFeeLabel,
                style: const TextStyle(
                    color: PeekColors.text2, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              l.sendSolFinalFeeHintNative,
              style:
                  const TextStyle(color: PeekColors.text, fontSize: 12),
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

// _ExperimentalBanner moved to widgets/send_widgets.dart.
