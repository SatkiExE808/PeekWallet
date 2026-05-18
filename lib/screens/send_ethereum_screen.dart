import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../address_book/address_book.dart';
import '../coins/ethereum/ethereum_wallet.dart';
import '../coins/ethereum/etherscan_client.dart';
import '../prices/price_feed.dart';
import '../theme.dart';
import '../util/remember_recipient.dart';
import '../util/screenshot_guard.dart';
import '../util/sensitive_clipboard.dart';
import 'address_book_screen.dart';
import 'qr_scan_screen.dart';

/// Ethereum send screen. Same two-step flow as the Bitcoin one —
/// fill form → preview → type SEND to confirm. Marked experimental:
/// RLP + EIP-1559 sighash + ECDSA-recovery_id are unit-tested but
/// the full end-to-end "real money on chain" path has not been
/// adversarially audited.
class SendEthereumScreen extends StatefulWidget {
  const SendEthereumScreen({super.key, required this.wallet});
  final EthereumWallet wallet;

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
      if (mounted) {
        setState(() {
          _balanceWei = wei;
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
  BigInt? _parseAmountWei() {
    final raw = _amountCtrl.text.trim();
    if (raw.isEmpty) return null;
    if (raw.contains('.')) {
      final v = double.tryParse(raw);
      if (v == null || v <= 0) return null;
      // Convert ETH → wei via string arithmetic so we don't lose
      // precision past ~6 decimals (double is 53-bit mantissa, wei
      // uses up to 18 decimals).
      return _ethToWei(raw);
    }
    return BigInt.tryParse(raw);
  }

  BigInt _ethToWei(String dec) {
    final parts = dec.split('.');
    final whole = parts[0];
    final frac = parts.length > 1 ? parts[1] : '';
    if (frac.length > 18) {
      throw const FormatException('More than 18 decimals');
    }
    final padded = frac.padRight(18, '0');
    final combined = (whole.isEmpty ? '0' : whole) + padded;
    // Strip leading zeros for canonical parse.
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
    // Send-all is more nuanced than for BTC because every ETH send
    // pays gas. We subtract a conservative gas reserve (21000 gas
    // at the suggested maxFee) so the user doesn't try to send a
    // value the chain can never accept.
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
    final amount = _parseAmountWei();
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
    if (amount > _balanceWei) {
      setState(() => _error = 'Amount exceeds balance');
      return;
    }
    setState(() => _previewing = true);
  }

  Future<void> _onConfirm() async {
    if (_confirmCtrl.text.trim().toUpperCase() != 'SEND') {
      setState(() => _error = 'Type SEND to confirm');
      return;
    }
    final amount = _parseAmountWei();
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
        valueWei: amount,
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
        appBar: AppBar(title: Text('Send ${widget.wallet.network.name}')),
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
    final amountWei = _parseAmountWei();
    final symbol = widget.wallet.network.symbol;
    final fiat = amountWei == null
        ? ''
        : PriceFeed.I.formatFiat(
            symbol, EthereumTx.weiToEth(amountWei));
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
              child: Text('Amount ($symbol or wei)',
                  style: const TextStyle(
                      color: PeekColors.text2, fontSize: 12)),
            ),
            TextButton(
              onPressed: _balanceWei == BigInt.zero ? null : _onMax,
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
              (_loading || _balanceWei == BigInt.zero) ? null : _onContinue,
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    final amount = _parseAmountWei()!;
    final fee = _fee!;
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
                _kvRow(
                    'Amount',
                    '${EthereumTx.weiToEth(amount).toStringAsFixed(6)} '
                        '${widget.wallet.network.symbol}'),
                _kvRow('Max fee per gas',
                    '${_gwei(fee.maxFeeWei)} gwei'),
                _kvRow('Priority fee per gas',
                    '${_gwei(fee.maxPriorityFeeWei)} gwei'),
                const SizedBox(height: 8),
                const Text(
                  'Final fee depends on the network base fee at '
                  'inclusion time. Anything below max is refunded — '
                  'overpaying doesn\'t actually cost. Once submitted '
                  'this CANNOT be reversed.',
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
                          '${EthereumTx.weiToEth(_balanceWei).toStringAsFixed(6)} '
                          '${widget.wallet.network.symbol} available',
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
              'Experimental — RLP + EIP-1559 sighash + ECDSA-recovery '
              'are unit-tested but the end-to-end send path has not '
              'been audited. Test with small amounts first.',
              style: TextStyle(color: PeekColors.text, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
