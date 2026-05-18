import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../address_book/address_book.dart';
import '../coins/tron/trc20.dart';
import '../coins/tron/tron_wallet.dart';
import '../prices/price_feed.dart';
import '../theme.dart';
import '../util/remember_recipient.dart';
import '../util/screenshot_guard.dart';
import '../util/sensitive_clipboard.dart';
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
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const QrScanScreen(title: 'Scan Tron address'),
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
    setState(() => _error = null);
    final parsed = _parseAmount();
    final addr = _addrCtrl.text.trim();
    if (!addr.startsWith('T') || addr.length != 34) {
      setState(() => _error =
          'Recipient must be a base58 Tron address (starts with T, 34 chars)');
      return;
    }

    if (widget.token != null) {
      final amt = parsed.tokenRaw;
      if (amt == null || amt <= BigInt.zero) {
        setState(() => _error = 'Enter a valid amount');
        return;
      }
      if (amt > _tokenBalanceRaw) {
        setState(() => _error =
            'Amount exceeds ${widget.token!.symbol} balance');
        return;
      }
      if (_balanceSun == 0) {
        setState(() => _error =
            'No TRX for bandwidth/energy — fund this wallet with TRX first');
        return;
      }
    } else {
      final amt = parsed.sun;
      if (amt == null || amt <= 0) {
        setState(() => _error = 'Enter a valid amount');
        return;
      }
      if (amt > _balanceSun) {
        setState(() => _error = 'Amount exceeds balance');
        return;
      }
    }
    setState(() => _previewing = true);
  }

  Future<void> _onConfirm() async {
    if (_confirmCtrl.text.trim().toUpperCase() != 'SEND') {
      setState(() => _error = 'Type SEND to confirm');
      return;
    }
    setState(() {
      _broadcasting = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
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
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: PeekColors.green,
          content: Text('Broadcast! tx: ${txid.substring(0, 16)}…'),
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
        appBar: AppBar(title: Text('Send ${widget.assetSymbol}')),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ExperimentalBanner(),
        const SizedBox(height: 16),
        _balanceCard(),
        const SizedBox(height: 20),
        const Text('Recipient (Tron base58)',
            style: TextStyle(color: PeekColors.text2, fontSize: 12)),
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
            Expanded(
              child: Text(
                widget.token != null
                    ? 'Amount ($symbol or base units)'
                    : 'Amount (TRX or sun)',
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
              child: const Text('Max', style: TextStyle(fontSize: 12)),
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
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    final parsed = _parseAmount();
    final addr = _addrCtrl.text.trim();
    final amountStr = widget.token != null
        ? '${widget.wallet.tokenBalanceDisplay(parsed.tokenRaw!, widget.token!).toStringAsFixed(widget.token!.decimals == 6 ? 2 : 4)} ${widget.token!.symbol}'
        : '${(parsed.sun! / 1000000.0).toStringAsFixed(6)} TRX';
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
                _kvRow('Amount', amountStr),
                _kvRow(
                    'Bandwidth/energy',
                    widget.token != null
                        ? 'Up to ~30 TRX-equivalent (TRC-20 calls cost more)'
                        : 'Free (daily quota) or ~0.27 TRX'),
                const SizedBox(height: 8),
                const Text(
                  'Tron transactions are built by the RPC node; we '
                  're-verify the txid hash before signing. Once '
                  'submitted this CANNOT be reversed.',
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
                          widget.token != null
                              ? '${widget.wallet.tokenBalanceDisplay(_tokenBalanceRaw, widget.token!).toStringAsFixed(widget.token!.decimals == 6 ? 2 : 4)} ${widget.token!.symbol} available · '
                                  '${(_balanceSun / 1000000.0).toStringAsFixed(6)} TRX for fees'
                              : '${(_balanceSun / 1000000.0).toStringAsFixed(6)} TRX available',
                          style: const TextStyle(
                              color: PeekColors.text, fontSize: 13),
                        ),
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
              'Experimental — Tron tx is built by the RPC and signed '
              'locally. The txid hash is verified before signing, but '
              'we don\'t decode the protobuf body. Test with small '
              'amounts first.',
              style: TextStyle(color: PeekColors.text, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
