import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../coins/coin.dart';
import '../theme.dart';
import '../vault/vault_state.dart';

/// Receive-focused coin detail page: shows the primary address, a
/// QR code, and Copy. Send / History / sync-driven balance land here
/// in subsequent commits.
class CoinScreen extends StatefulWidget {
  const CoinScreen({super.key, required this.coin});
  final Coin coin;

  @override
  State<CoinScreen> createState() => _CoinScreenState();
}

class _CoinScreenState extends State<CoinScreen> {
  String? _address;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final mn = VaultState.I.mnemonic;
    if (mn == null) {
      setState(() => _error = 'Wallet is locked');
      return;
    }
    try {
      final a = await widget.coin.deriveAddress(mn);
      setState(() => _address = a);
    } catch (e) {
      setState(() => _error = 'Address derivation failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.coin.name)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: widget.coin.color,
                    radius: 18,
                    child: Icon(widget.coin.icon, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${widget.coin.symbol} balance',
                    style: const TextStyle(color: PeekColors.text2, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                '… XMR',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
              ),
              const Text(
                'Sync engine wires in next — address is live now so you can already receive.',
                style: TextStyle(color: PeekColors.text3, fontSize: 11),
              ),
              const SizedBox(height: 20),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x33EF4444),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!, style: const TextStyle(color: PeekColors.text)),
                )
              else if (_address == null)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: PeekColors.accent),
                  ),
                )
              else ...[
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.white,
                    child: QrImageView(
                      data: _address!,
                      version: QrVersions.auto,
                      size: 240,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: PeekColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: PeekColors.border),
                  ),
                  child: SelectableText(
                    _address!,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: _address!));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Address copied')),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy address'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
