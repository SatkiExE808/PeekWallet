import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../address_book/address_book.dart';
import '../coins/ethereum/erc20_tokens.dart';
import '../coins/ethereum/ethereum_wallet.dart';
import '../coins/ethereum/etherscan_client.dart';
import '../prices/price_feed.dart';
import '../theme.dart';
import '../util/remember_recipient.dart';
import '../util/screenshot_guard.dart';
import '../util/sensitive_clipboard.dart';
import '../widgets/coin_screen_widgets.dart';
import '../widgets/send_widgets.dart';
import 'address_book_screen.dart';
import 'qr_scan_screen.dart';

/// Ethereum send screen. Same two-step flow as the Bitcoin one —
/// fill form → preview → type SEND to confirm. Marked experimental:
/// RLP + EIP-1559 sighash + ECDSA-recovery_id are unit-tested but
/// the full end-to-end "real money on chain" path has not been
/// adversarially audited.
class SendEthereumScreen extends StatefulWidget {
  const SendEthereumScreen({
    super.key,
    required this.wallet,
    this.token,
  });
  final EthereumWallet wallet;
  /// Non-null = send THIS token (ABI-encoded transfer to its
  /// contract). Null = send native ETH/MATIC. Gas is paid in native
  /// either way.
  final Erc20Token? token;

  /// Display symbol for whatever this screen is sending.
  String get assetSymbol => token?.symbol ?? wallet.network.symbol;

  @override
  State<SendEthereumScreen> createState() => _SendEthereumScreenState();
}

class _SendEthereumScreenState extends State<SendEthereumScreen> {
  final _addrCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  EthFeeSuggestion? _fee;
  String? _feeError;
  BigInt _balanceWei = BigInt.zero;
  /// Token balance in BASE UNITS (e.g. 1,000,000 = 1 USDT). Only
  /// meaningful when widget.token != null.
  BigInt _tokenBalanceRaw = BigInt.zero;
  bool _loading = true;
  String? _balanceError;

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
      final fee = await widget.wallet.feeSuggestion();
      if (mounted) setState(() => _fee = fee);
    } catch (e) {
      if (mounted) setState(() => _feeError = '$e');
    }
    try {
      final wei = await widget.wallet.balanceWei();
      // For token sends we also need the token's balance — but we
      // still grab the native balance so we can warn if the user
      // doesn't have enough gas to send the token.
      BigInt tokenRaw = BigInt.zero;
      if (widget.token != null) {
        tokenRaw = await widget.wallet.tokenBalanceRaw(widget.token!);
      }
      if (mounted) {
        setState(() {
          _balanceWei = wei;
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

  /// Parse the amount input. Accepts "0.001" (ETH) or a wei integer
  /// (≥ 10^9 to disambiguate from a tiny ETH-decimal entry — anything
  /// with a decimal point is unambiguously ETH).
  /// Parse the amount field as base units (wei for ETH, base units
  /// for tokens — e.g. 1 USDT = 1_000_000 because USDT has 6 decimals).
  /// If a decimal point appears, treat as the display unit;
  /// otherwise treat the integer as raw base units.
  BigInt? _parseAmountRaw() {
    final raw = _amountCtrl.text.trim();
    if (raw.isEmpty) return null;
    final decimals = widget.token?.decimals ?? 18;
    if (raw.contains('.')) {
      final v = double.tryParse(raw);
      if (v == null || v <= 0) return null;
      try {
        return _decimalToRaw(raw, decimals);
      } on FormatException {
        // Too-many-decimals or otherwise malformed — surface as null
        // so the form's validator can flag it instead of crashing.
        return null;
      }
    }
    return BigInt.tryParse(raw);
  }

  BigInt _decimalToRaw(String dec, int decimals) {
    final parts = dec.split('.');
    final whole = parts[0];
    final frac = parts.length > 1 ? parts[1] : '';
    if (frac.length > decimals) {
      throw FormatException('More than $decimals decimal places');
    }
    final padded = frac.padRight(decimals, '0');
    final combined = (whole.isEmpty ? '0' : whole) + padded;
    final trimmed = combined.replaceFirst(RegExp(r'^0+'), '');
    return BigInt.parse(trimmed.isEmpty ? '0' : trimmed);
  }

  Future<void> _pickFromBook() async {
    final picked = await Navigator.of(context).push<AddressBookEntry>(
      MaterialPageRoute(
        builder: (_) => AddressBookScreen(
            pickForCoin: widget.wallet.network.id),
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
        builder: (_) => QrScanScreen(
            title: 'Scan ${widget.wallet.network.symbol} address'),
      ),
    );
    if (scanned != null && scanned.isNotEmpty) {
      // EIP-681 URLs (ethereum:0x.../?value=…) are out of scope for
      // QR scan — strip the prefix the same way the BTC path does
      // when the upstream QrScanScreen recognises common scheme.
      // mobile_scanner gives us the raw payload; normalise here.
      var s = scanned.trim();
      if (s.toLowerCase().startsWith('ethereum:')) {
        s = s.substring('ethereum:'.length);
        final qIx = s.indexOf('?');
        if (qIx >= 0) s = s.substring(0, qIx);
      }
      _addrCtrl.text = s;
    }
  }

  void _onMax() {
    // For token sends, "Max" = entire token balance — gas comes
    // out of the native balance, which we don't touch here.
    if (widget.token != null) {
      if (_tokenBalanceRaw <= BigInt.zero) return;
      setState(() {
        _amountCtrl.text = _tokenBalanceRaw.toString();
      });
      return;
    }
    // For native send: subtract a conservative gas reserve so the
    // user doesn't try to send a value the chain can never accept.
    if (_balanceWei <= BigInt.zero) return;
    final fee = _fee;
    if (fee == null) return;
    final reserve = fee.maxFeeWei * BigInt.from(21000);
    final spendable =
        _balanceWei > reserve ? _balanceWei - reserve : BigInt.zero;
    setState(() {
      _amountCtrl.text = spendable.toString();
    });
  }

  Future<void> _onContinue() async {
    setState(() => _error = null);
    final amount = _parseAmountRaw();
    if (amount == null || amount <= BigInt.zero) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }
    final addr = _addrCtrl.text.trim();
    if (!addr.startsWith('0x') || addr.length != 42) {
      setState(() =>
          _error = 'Recipient must be a 0x-prefixed 40-hex-character address');
      return;
    }
    if (widget.token != null) {
      if (amount > _tokenBalanceRaw) {
        setState(() => _error = 'Amount exceeds ${widget.token!.symbol} balance');
        return;
      }
      // Token sends still need native gas — flag if the user has zero ETH/MATIC.
      if (_balanceWei == BigInt.zero) {
        setState(() => _error =
            'No ${widget.wallet.network.symbol} for gas — fund this wallet first');
        return;
      }
    } else {
      if (amount > _balanceWei) {
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
    final amount = _parseAmountRaw();
    final fee = _fee;
    if (amount == null || fee == null) return;
    setState(() {
      _broadcasting = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      final destAddress = _addrCtrl.text.trim();
      final built = await widget.wallet.sendEth(
        destAddress: destAddress,
        valueWei: widget.token == null ? amount : BigInt.zero,
        token: widget.token,
        tokenAmountRaw: widget.token == null ? null : amount,
        maxPriorityFeeWei: fee.maxPriorityFeeWei,
        maxFeeWei: fee.maxFeeWei,
      );
      unawaited(rememberRecipient(
        coinId: widget.wallet.network.id,
        address: destAddress,
      ));
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: PeekColors.green,
          content: Text('Broadcast! tx: ${built.txHash.substring(0, 14)}…'),
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
            title: Text('Send ${widget.token?.symbol ?? widget.wallet.network.name}')),
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
    final amountRaw = _parseAmountRaw();
    final symbol = widget.assetSymbol;
    // Fiat shown next to the amount: for tokens, use the token's
    // own symbol and price (USDT ≈ $1, USDC ≈ $1, DAI ≈ $1).
    final fiat = amountRaw == null
        ? ''
        : widget.token != null
            ? PriceFeed.I.formatFiat(
                symbol,
                widget.wallet.tokenBalanceDisplay(
                    amountRaw, widget.token!),
              )
            : PriceFeed.I.formatFiat(
                symbol, EthereumTx.weiToEth(amountRaw));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ExperimentalBanner(
            body:
                'RLP + EIP-1559 sighash + ECDSA-recovery are unit-tested but the end-to-end send path has not been audited.'),
        const SizedBox(height: 16),
        _balanceCard(),
        const SizedBox(height: 20),
        const Text('Recipient address',
            style: TextStyle(color: PeekColors.text2, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: _addrCtrl,
          decoration: InputDecoration(
            hintText: '0x…',
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
                    : 'Amount ($symbol or wei)',
                style: const TextStyle(
                    color: PeekColors.text2, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: (widget.token != null
                      ? _tokenBalanceRaw == BigInt.zero
                      : _balanceWei == BigInt.zero)
                  ? null
                  : _onMax,
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
          onPressed: (_loading ||
                  (widget.token != null
                      ? _tokenBalanceRaw == BigInt.zero
                      : _balanceWei == BigInt.zero))
              ? null
              : _onContinue,
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    final amount = _parseAmountRaw()!;
    final fee = _fee!;
    final addr = _addrCtrl.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ExperimentalBanner(
            body:
                'RLP + EIP-1559 sighash + ECDSA-recovery are unit-tested but the end-to-end send path has not been audited.'),
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
                widget.token != null
                    ? '${widget.wallet.tokenBalanceDisplay(amount, widget.token!).toStringAsFixed(widget.token!.decimals == 6 ? 2 : 4)} ${widget.token!.symbol}'
                    : '${EthereumTx.weiToEth(amount).toStringAsFixed(6)} ${widget.wallet.network.symbol}',
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
                  '${addr.substring(0, 12)}…${addr.substring(addr.length - 8)}'),
              const Divider(height: 18, color: PeekColors.hairline),
              _kvRow('Max fee per gas', '${_gwei(fee.maxFeeWei)} gwei'),
              const Divider(height: 18, color: PeekColors.hairline),
              _kvRow('Priority fee', '${_gwei(fee.maxPriorityFeeWei)} gwei'),
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
                  'Final fee depends on the network base fee at inclusion '
                  "time. Anything below max is refunded — overpaying "
                  "doesn't actually cost. Once submitted this CANNOT be "
                  'reversed.',
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
                  ? const Text('Loading balance…',
                      style: TextStyle(
                          color: PeekColors.text2, fontSize: 13))
                  : _balanceError != null
                      ? Text('Balance error: $_balanceError',
                          style: const TextStyle(
                              color: PeekColors.red, fontSize: 12))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.token != null
                                  ? '${widget.wallet.tokenBalanceDisplay(_tokenBalanceRaw, widget.token!).toStringAsFixed(widget.token!.decimals == 6 ? 2 : 4)} ${widget.token!.symbol}'
                                  : '${EthereumTx.weiToEth(_balanceWei).toStringAsFixed(6)} ${widget.wallet.network.symbol}',
                              style: const TextStyle(
                                color: PeekColors.text,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.1,
                              ),
                            ),
                            Text(
                              widget.token != null
                                  ? 'available · ${EthereumTx.weiToEth(_balanceWei).toStringAsFixed(6)} ${widget.wallet.network.symbol} for gas'
                                  : 'available',
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
    final fee = _fee;
    if (_feeError != null) {
      return Text('Fee data unavailable: $_feeError',
          style: const TextStyle(color: PeekColors.red, fontSize: 12));
    }
    if (fee == null) {
      return const Text('Loading fee rates…',
          style: TextStyle(color: PeekColors.text3, fontSize: 12));
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Network fee (auto, MetaMask-style)',
                style: TextStyle(
                    color: PeekColors.text2, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              'Base ${_gwei(fee.baseFeeWei)} gwei · '
              'Tip ${_gwei(fee.maxPriorityFeeWei)} gwei · '
              'Max ${_gwei(fee.maxFeeWei)} gwei',
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
            width: 130,
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

  /// Format a wei value as a human-friendly gwei string. 1 gwei = 1e9 wei.
  String _gwei(BigInt wei) {
    final gwei = wei / BigInt.from(1000000000);
    if (gwei >= 1) return gwei.toStringAsFixed(2);
    // Sub-gwei (testnets) → show with more precision.
    return (wei.toDouble() / 1e9).toStringAsFixed(4);
  }
}

// _ExperimentalBanner / _errorBox moved to widgets/send_widgets.dart.
