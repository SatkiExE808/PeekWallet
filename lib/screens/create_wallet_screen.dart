import 'dart:math';

import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../vault/vault_state.dart';

/// Three-step flow: show generated seed → confirm user wrote it down
/// → set unlock password. Once the password is saved the encrypted
/// seed lands in secure storage and the rest of the app routes to
/// the shell.
class CreateWalletScreen extends StatefulWidget {
  const CreateWalletScreen({super.key});

  @override
  State<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends State<CreateWalletScreen> {
  late final String _mnemonic = bip39.generateMnemonic(strength: 128);
  int _step = 0; // 0 = show seed, 1 = confirm, 2 = password

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titleFor(_step))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: switch (_step) {
            0 => _SeedDisplay(
                mnemonic: _mnemonic,
                onContinue: () => setState(() => _step = 1),
              ),
            1 => _ConfirmStep(
                mnemonic: _mnemonic,
                onBack: () => setState(() => _step = 0),
                onConfirmed: () => setState(() => _step = 2),
              ),
            _ => _PasswordStep(mnemonic: _mnemonic),
          },
        ),
      ),
    );
  }

  String _titleFor(int s) => switch (s) {
        0 => 'Recovery phrase',
        1 => 'Confirm phrase',
        _ => 'Set password',
      };
}

class _SeedDisplay extends StatelessWidget {
  const _SeedDisplay({required this.mnemonic, required this.onContinue});
  final String mnemonic;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final words = mnemonic.split(' ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0x33EF4444),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x66EF4444)),
          ),
          child: const Text(
            'Write these 12 words down on paper and store them somewhere safe. Anyone with the phrase can take your funds. Never type it on a website.',
            style: TextStyle(color: PeekColors.text, fontSize: 13, height: 1.4),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisExtent: 48,
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
                      style: const TextStyle(color: PeekColors.text, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: mnemonic));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copied — clear your clipboard after writing it down')),
            );
          },
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Copy phrase'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: onContinue,
          child: const Text('I have written it down'),
        ),
      ],
    );
  }
}

class _ConfirmStep extends StatefulWidget {
  const _ConfirmStep({
    required this.mnemonic,
    required this.onBack,
    required this.onConfirmed,
  });
  final String mnemonic;
  final VoidCallback onBack;
  final VoidCallback onConfirmed;

  @override
  State<_ConfirmStep> createState() => _ConfirmStepState();
}

class _ConfirmStepState extends State<_ConfirmStep> {
  late final List<String> _words = widget.mnemonic.split(' ');
  late final List<int> _quizIndices;
  final Map<int, String> _answers = {};

  @override
  void initState() {
    super.initState();
    // Pick 3 random positions to ask about — small enough not to be
    // annoying, large enough to make 'I forgot' obvious. A
    // microsecond seed is fine here; this isn't a security boundary
    // (worst case an attacker watching this widget knows which 3
    // indices we'll ask about, which doesn't help them at all).
    final rng = Random(DateTime.now().microsecondsSinceEpoch);
    final ix = List<int>.generate(12, (i) => i)..shuffle(rng);
    _quizIndices = ix.take(3).toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final allCorrect = _quizIndices.every((i) => _answers[i]?.trim() == _words[i]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Type the requested words to confirm you saved the phrase.',
          style: TextStyle(color: PeekColors.text2, fontSize: 13),
        ),
        const SizedBox(height: 20),
        for (final i in _quizIndices)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Word #${i + 1}',
                hintText: 'Lowercase, no spaces',
              ),
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              onChanged: (v) => setState(() => _answers[i] = v),
            ),
          ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onBack,
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: allCorrect ? widget.onConfirmed : null,
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PasswordStep extends StatefulWidget {
  const _PasswordStep({required this.mnemonic});
  final String mnemonic;

  @override
  State<_PasswordStep> createState() => _PasswordStepState();
}

class _PasswordStepState extends State<_PasswordStep> {
  final _p1 = TextEditingController();
  final _p2 = TextEditingController();
  String? _err;
  bool _busy = false;

  @override
  void dispose() {
    _p1.dispose();
    _p2.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _err = null);
    final p = _p1.text;
    if (p.length < 8) {
      setState(() => _err = 'Password must be at least 8 characters.');
      return;
    }
    if (p != _p2.text) {
      setState(() => _err = "Passwords don't match.");
      return;
    }
    setState(() => _busy = true);
    try {
      await VaultState.I.create(widget.mnemonic, p);
      if (!mounted) return;
      // Routing handled by main.dart listening to VaultState — pop back
      // to root so the new state picks up.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'This password encrypts your wallet on this device. You will need it every time you unlock.',
          style: TextStyle(color: PeekColors.text2, fontSize: 13),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _p1,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password (min 8 characters)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _p2,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Confirm password'),
        ),
        if (_err != null) ...[
          const SizedBox(height: 8),
          Text(_err!, style: const TextStyle(color: PeekColors.red, fontSize: 13)),
        ],
        const Spacer(),
        ElevatedButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Create wallet'),
        ),
      ],
    );
  }
}
