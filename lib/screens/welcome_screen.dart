import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'create_wallet_screen.dart';
import 'import_wallet_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.account_balance_wallet, size: 64, color: PeekColors.accent),
              const SizedBox(height: 20),
              const Text(
                'PeekWallet',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Self-custodial wallet for BTC, ETH, XMR, and more.',
                textAlign: TextAlign.center,
                style: TextStyle(color: PeekColors.text2, fontSize: 14),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateWalletScreen()),
                ),
                child: const Text('Create new wallet'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ImportWalletScreen()),
                ),
                child: const Text('I already have a recovery phrase'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your 12-word recovery phrase is the only backup. Anyone with it can take your funds.',
                textAlign: TextAlign.center,
                style: TextStyle(color: PeekColors.text3, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _showDisclaimer(context),
                child: const Text(
                  'Read the no-warranty disclaimer',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDisclaimer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: PeekColors.bg2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _DisclaimerSheet(),
    );
  }
}

/// In-app rendering of DISCLAIMER.md's key points. Mirrors the wording
/// of that file (which is the authoritative source). Keep them in sync
/// when either is edited.
class _DisclaimerSheet extends StatelessWidget {
  const _DisclaimerSheet();

  static const _body = '''
PeekWallet is free, open-source, self-custodial software, released under GPL-3.0-or-later.

By using it you acknowledge:

• No warranty — the software is provided AS IS. The authors are not liable for any losses.

• Self-custody — your 12-word recovery phrase (or 25-word Monero seed) is the only backup. If you lose it, your funds are unrecoverable. Nobody can help you.

• No support service — anyone offering "PeekWallet recovery" in exchange for your seed is trying to steal from you. We will never ask for your seed, password, or private keys.

• Cryptocurrency risk — values are volatile. Sending to the wrong address is irreversible.

• Software risk — under active development. Bugs may cause loss of funds. No external security audit yet. Don't store more than you can afford to lose to a software bug.

• Privacy — by default we talk to a public Monero node which sees your IP. Run your own daemon (Settings → Monero Node) for better privacy.

• Compliance — tax reporting, KYC, and other legal obligations in your jurisdiction are your responsibility.

Full text: DISCLAIMER.md in the source repo.
''';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: PeekColors.border2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Disclaimer',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            SelectableText(
              _body,
              style: const TextStyle(
                color: PeekColors.text,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(const ClipboardData(text: _body));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied')),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy text'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('I understand'),
            ),
          ],
        ),
      ),
    );
  }
}
