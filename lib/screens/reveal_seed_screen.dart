import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../coins/monero/monero_keys.dart';
import '../theme.dart';
import '../vault/vault_state.dart';
import '../vault/vault_storage.dart';

/// Two-step viewer for the wallet's recovery material:
///   1. Re-prompt for the master password (even when unlocked, so a
///      brief unlocked session can't be turned into a seed leak by
///      a passerby).
///   2. Show: BIP39 phrase, BIP39 passphrase (if any), Monero
///      primary address, private spend key, private view key.
///
/// Nothing is persisted — leaving the screen drops the in-memory
/// copy. Password is held in a local controller only.
class RevealSeedScreen extends StatefulWidget {
  const RevealSeedScreen({super.key});

  @override
  State<RevealSeedScreen> createState() => _RevealSeedScreenState();
}

class _RevealSeedScreenState extends State<RevealSeedScreen> {
  final _pwd = TextEditingController();
  String? _err;
  bool _busy = false;
  DecryptedSeed? _seed;
  MoneroKeys? _moneroKeys;

  @override
  void dispose() {
    _pwd.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() {
      _err = null;
      _busy = true;
    });
    try {
      // Routes through the same unlock path as LockScreen so we
      // don't trust any in-memory state.
      final storage = VaultStorage();
      final seed = await storage.unlock(_pwd.text);
      final keys = deriveMoneroKeys(seed.mnemonic, passphrase: seed.passphrase);
      setState(() {
        _seed = seed;
        _moneroKeys = keys;
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _err = e.toString();
        _busy = false;
        _pwd.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reveal recovery phrase')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _seed == null ? _verifyForm() : _revealView(),
        ),
      ),
    );
  }

  Widget _verifyForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0x33EF4444),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x66EF4444)),
          ),
          child: const Text(
            'You are about to reveal your seed phrase and Monero keys. '
            'Anyone who sees them can take your funds — make sure no one '
            'is looking at your screen and you are not screen-sharing.',
            style: TextStyle(color: PeekColors.text, fontSize: 13, height: 1.4),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Enter your app password to continue.',
          style: TextStyle(color: PeekColors.text2, fontSize: 13),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _pwd,
          obscureText: true,
          autofocus: true,
          onSubmitted: (_) => _verify(),
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        if (_err != null) ...[
          const SizedBox(height: 8),
          Text(_err!, style: const TextStyle(color: PeekColors.red, fontSize: 13)),
        ],
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _busy ? null : _verify,
          child: _busy
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Reveal'),
        ),
      ],
    );
  }

  Widget _revealView() {
    final seed = _seed!;
    final keys = _moneroKeys!;
    final words = seed.mnemonic.split(' ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel('BIP39 recovery phrase'),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisExtent: 44,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: words.length,
          itemBuilder: (_, i) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: PeekColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: PeekColors.border),
            ),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${i + 1}  ',
                    style: const TextStyle(color: PeekColors.text3, fontSize: 12),
                  ),
                  TextSpan(
                    text: words[i],
                    style: const TextStyle(
                      color: PeekColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        _CopyRow(label: 'Copy phrase', value: seed.mnemonic),
        if (seed.passphrase.isNotEmpty) ...[
          const SizedBox(height: 18),
          const _SectionLabel('BIP39 passphrase (25th word)'),
          const SizedBox(height: 6),
          _MonoBlock(text: seed.passphrase),
          _CopyRow(label: 'Copy passphrase', value: seed.passphrase),
        ],
        const SizedBox(height: 18),
        const _SectionLabel('Monero primary address'),
        const SizedBox(height: 6),
        _MonoBlock(text: keys.primaryAddress),
        _CopyRow(label: 'Copy address', value: keys.primaryAddress),
        const SizedBox(height: 18),
        const _SectionLabel('Monero private spend key'),
        const SizedBox(height: 6),
        _MonoBlock(text: keys.privateSpendHex),
        _CopyRow(label: 'Copy spend key', value: keys.privateSpendHex),
        const SizedBox(height: 18),
        const _SectionLabel('Monero private view key'),
        const SizedBox(height: 6),
        _MonoBlock(text: keys.privateViewHex),
        _CopyRow(label: 'Copy view key', value: keys.privateViewHex),
        const SizedBox(height: 24),
        const Text(
          'You can restore this wallet in Cake / Feather / Monero GUI '
          'using "Restore from keys" with the address + view key + spend '
          'key above (or "Restore from seed" with the BIP39 phrase in any '
          'BIP39-compatible wallet).',
          style: TextStyle(color: PeekColors.text3, fontSize: 11),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(color: PeekColors.text2, fontSize: 12),
    );
  }
}

class _MonoBlock extends StatelessWidget {
  const _MonoBlock({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: PeekColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PeekColors.border),
      ),
      child: SelectableText(
        text,
        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: value));
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Copied — clear your clipboard after use')),
          );
        },
        icon: const Icon(Icons.copy, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
