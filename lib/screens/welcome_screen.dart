import 'package:flutter/material.dart';

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
            ],
          ),
        ),
      ),
    );
  }
}
