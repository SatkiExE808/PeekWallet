import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../coins/monero/monero_keys.dart';
import '../theme.dart';
import '../util/screenshot_guard.dart';
import '../util/sensitive_clipboard.dart';
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
    // Wrap the whole screen so FLAG_SECURE is applied as soon as the
    // route lands — the password-verification step also benefits
    // (a shoulder-surfer's recents thumbnail wouldn't capture the
    // password, but the broader "this user is about to reveal a seed"
    // context is already sensitive).
    return ScreenshotGuard(
      child: Scaffold(
        appBar: AppBar(title: const Text('Reveal recovery phrase')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _seed == null ? _verifyForm() : _revealView(),
          ),
        ),
      ),
    );
  }

  Widget _verifyForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(PeekDesign.sp4),
          decoration: BoxDecoration(
            color: PeekColors.red.withAlpha(28),
            borderRadius: PeekDesign.brCard,
            border: Border.all(color: PeekColors.red.withAlpha(96)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: PeekColors.red.withAlpha(40),
                  borderRadius: PeekDesign.brSmall,
                ),
                child: const Icon(Icons.visibility_off_rounded,
                    color: PeekColors.red, size: 18),
              ),
              const SizedBox(width: PeekDesign.sp3),
              const Expanded(
                child: Text(
                  'You are about to reveal your seed phrase and Monero '
                  'keys. Anyone who sees them can take your funds — make '
                  "sure no one is looking at your screen and you're not "
                  'screen-sharing.',
                  style: TextStyle(
                      color: PeekColors.text, fontSize: 12, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PeekDesign.sp5),
        const Text(
          'Enter your app password to continue.',
          style: TextStyle(color: PeekColors.text2, fontSize: 13),
        ),
        const SizedBox(height: PeekDesign.sp3),
        TextField(
          controller: _pwd,
          obscureText: true,
          autofocus: true,
          onSubmitted: (_) => _verify(),
          decoration: const InputDecoration(
            hintText: 'Password',
            prefixIcon: Icon(Icons.password_rounded,
                size: 18, color: PeekColors.text2),
          ),
        ),
        if (_err != null) ...[
          const SizedBox(height: PeekDesign.sp2),
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 14, color: PeekColors.red),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _err!,
                  style: const TextStyle(
                      color: PeekColors.red, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: PeekDesign.sp4),
        ElevatedButton(
          onPressed: _busy ? null : _verify,
          child: _busy
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
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
              borderRadius: PeekDesign.brSmall,
              border: Border.all(color: PeekColors.hairline),
            ),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${(i + 1).toString().padLeft(2, '0')}  ',
                    style: const TextStyle(
                        color: PeekColors.text3,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        fontFeatures: [FontFeature.tabularFigures()]),
                  ),
                  TextSpan(
                    text: words[i],
                    style: const TextStyle(
                      color: PeekColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        _CopyRow(label: 'Copy phrase', value: seed.mnemonic, sensitive: true),
        if (seed.passphrase.isNotEmpty) ...[
          const SizedBox(height: 18),
          const _SectionLabel('BIP39 passphrase (25th word)'),
          const SizedBox(height: 6),
          _MonoBlock(text: seed.passphrase),
          _CopyRow(label: 'Copy passphrase', value: seed.passphrase, sensitive: true),
        ],
        const SizedBox(height: 18),
        const _SectionLabel('Monero primary address'),
        const SizedBox(height: 6),
        _MonoBlock(text: keys.primaryAddress),
        // Address is public — no auto-clear. User may want to paste
        // it into a watch-only wallet hours later.
        _CopyRow(label: 'Copy address', value: keys.primaryAddress),
        const SizedBox(height: 18),
        const _SectionLabel('Monero private spend key'),
        const SizedBox(height: 6),
        _MonoBlock(text: keys.privateSpendHex),
        _CopyRow(label: 'Copy spend key', value: keys.privateSpendHex, sensitive: true),
        const SizedBox(height: 18),
        const _SectionLabel('Monero private view key'),
        const SizedBox(height: 6),
        _MonoBlock(text: keys.privateViewHex),
        // View key gives read-only access — sensitive enough to clear.
        _CopyRow(label: 'Copy view key', value: keys.privateViewHex, sensitive: true),
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
      label.toUpperCase(),
      style: const TextStyle(
        color: PeekColors.text3,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _MonoBlock extends StatelessWidget {
  const _MonoBlock({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PeekDesign.sp3),
      decoration: BoxDecoration(
        color: PeekColors.surface,
        borderRadius: PeekDesign.brSmall,
        border: Border.all(color: PeekColors.border),
      ),
      child: SelectableText(
        text,
        style: const TextStyle(
            fontSize: 12, fontFamily: 'monospace', color: PeekColors.text),
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({
    required this.label,
    required this.value,
    this.sensitive = false,
  });
  final String label;
  final String value;

  /// When true, copies through SensitiveClipboard so the value is
  /// auto-wiped from the clipboard after 30 s. Use for seed phrases
  /// and private keys; leave false for public material (addresses,
  /// TX hashes) the user may want to paste later.
  final bool sensitive;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () async {
          if (sensitive) {
            await SensitiveClipboard.copy(value, label: label);
          } else {
            await Clipboard.setData(ClipboardData(text: value));
          }
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(sensitive
                ? 'Copied — clipboard auto-clears in 30 s'
                : 'Copied')),
          );
        },
        icon: const Icon(Icons.copy, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
