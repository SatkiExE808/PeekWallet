import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter/material.dart';

import '../theme.dart';
import '../vault/vault_state.dart';

class ImportWalletScreen extends StatefulWidget {
  const ImportWalletScreen({super.key});

  @override
  State<ImportWalletScreen> createState() => _ImportWalletScreenState();
}

class _ImportWalletScreenState extends State<ImportWalletScreen> {
  final _phrase = TextEditingController();
  final _passphrase = TextEditingController();
  final _p1 = TextEditingController();
  final _p2 = TextEditingController();
  String? _err;
  bool _busy = false;

  @override
  void dispose() {
    _phrase.dispose();
    _passphrase.dispose();
    _p1.dispose();
    _p2.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    setState(() => _err = null);
    final raw = _phrase.text.trim().toLowerCase();
    final words = raw.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length != 12 && words.length != 24) {
      setState(() => _err = 'Enter your 12 or 24-word recovery phrase.');
      return;
    }
    final normalized = words.join(' ');
    if (!bip39.validateMnemonic(normalized)) {
      setState(() => _err = 'Invalid recovery phrase (BIP39 checksum failed).');
      return;
    }
    if (_p1.text.length < 8) {
      setState(() => _err = 'App password must be at least 8 characters.');
      return;
    }
    if (_p1.text != _p2.text) {
      setState(() => _err = "Passwords don't match.");
      return;
    }
    setState(() => _busy = true);
    try {
      await VaultState.I.create(
        normalized,
        _p1.text,
        passphrase: _passphrase.text,
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      setState(() {
        _err = e.toString();
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import wallet')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Paste your existing BIP39 recovery phrase (12 or 24 words). Same format as vault-wallet.',
                style: TextStyle(color: PeekColors.text2, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phrase,
                minLines: 3,
                maxLines: 5,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(
                  labelText: 'Recovery phrase',
                  hintText: 'word1 word2 word3 ...',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passphrase,
                obscureText: true,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(
                  labelText: 'BIP39 passphrase (25th word) — optional',
                  hintText: 'Leave blank if you did not set one',
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'If you used a BIP39 passphrase in vault-wallet (or another wallet) you MUST enter it here — without it the imported addresses won\'t match and balances appear as zero.',
                style: TextStyle(color: PeekColors.text3, fontSize: 11),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _p1,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'App password (min 8 characters)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _p2,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm app password'),
              ),
              if (_err != null) ...[
                const SizedBox(height: 10),
                Text(_err!, style: const TextStyle(color: PeekColors.red, fontSize: 13)),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _busy ? null : _import,
                child: _busy
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Import wallet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
