import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/gen/app_localizations.dart';
import '../theme.dart';
import '../util/coin_avatar.dart';
import 'create_wallet_screen.dart';
import 'import_wallet_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _previewCoins = ['BTC', 'ETH', 'SOL', 'TRX', 'XMR'];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Breathing wallet emblem — first impression. Same
              // glow animation as the lock screen so the brand reads
              // as "alive" the moment the user opens the app.
              const _WelcomeEmblem(),
              const SizedBox(height: 24),
              Text(
                l.appName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              Text(
                l.welcomeTagline,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: PeekColors.text2, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: PeekDesign.sp5),
              // Coin-cluster preview — five overlapping brand-tinted
              // avatars hint at the supported chains so the user can
              // see at a glance what they're getting.
              SizedBox(
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    for (var i = 0; i < _previewCoins.length; i++)
                      Positioned(
                        left: i * 24.0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: PeekColors.bg,
                            border: Border.all(
                                color: PeekColors.coinAccent(_previewCoins[i])
                                    .withAlpha(110),
                                width: 1.5),
                          ),
                          child: coinAvatar(_previewCoins[i], radius: 16),
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateWalletScreen()),
                ),
                child: Text(l.welcomeCreateAction),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ImportWalletScreen()),
                ),
                child: Text(l.welcomeImportAction),
              ),
              const SizedBox(height: 16),
              Text(
                l.welcomeBackupWarning,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: PeekColors.text3, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _showDisclaimer(context),
                child: Text(
                  l.welcomeDisclaimerAction,
                  style: const TextStyle(fontSize: 11),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
    final l = AppLocalizations.of(context);
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
            Text(
              l.welcomeDisclaimerTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600),
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
                  SnackBar(content: Text(l.welcomeCopiedToast)),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: Text(l.welcomeCopyTextAction),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.welcomeIUnderstandAction),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated welcome-screen emblem. Soft accent halo breathes behind
/// a circular surface with the wallet glyph. Matches the lock-screen
/// lock-glow + the empty-state wallet-glow so the brand has a single
/// consistent "this app is alive" motion language.
class _WelcomeEmblem extends StatefulWidget {
  const _WelcomeEmblem();

  @override
  State<_WelcomeEmblem> createState() => _WelcomeEmblemState();
}

class _WelcomeEmblemState extends State<_WelcomeEmblem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        final scale = 0.94 + (t * 0.10);
        final glowAlpha = (44 + (t * 32)).round();
        return SizedBox(
          width: 132,
          height: 132,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      PeekColors.accent.withAlpha(glowAlpha),
                      PeekColors.accent.withAlpha(0),
                    ]),
                  ),
                ),
              ),
              Container(
                width: 80,
                height: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: PeekColors.surface2,
                  border: Border.all(color: PeekColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: PeekColors.accent.withAlpha(48),
                      blurRadius: 24,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 36,
                  color: PeekColors.accent,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
