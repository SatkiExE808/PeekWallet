import 'package:flutter/material.dart';

import 'theme.dart';
import 'shell.dart';
import 'screens/welcome_screen.dart';
import 'screens/lock_screen.dart';
import 'vault/vault_state.dart';

void main() {
  runApp(const PeekWalletApp());
}

class PeekWalletApp extends StatelessWidget {
  const PeekWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PeekWallet',
      debugShowCheckedModeBanner: false,
      theme: PeekTheme.dark,
      home: const _Router(),
    );
  }
}

/// Top-level state machine:
/// - hasWallet unknown → loading splash
/// - !hasWallet         → welcome / setup
/// - hasWallet && locked → lock screen
/// - hasWallet && unlocked → app shell
class _Router extends StatefulWidget {
  const _Router();

  @override
  State<_Router> createState() => _RouterState();
}

class _RouterState extends State<_Router> {
  @override
  void initState() {
    super.initState();
    VaultState.I.addListener(_onVaultChange);
    VaultState.I.refreshHasWallet();
  }

  @override
  void dispose() {
    VaultState.I.removeListener(_onVaultChange);
    super.dispose();
  }

  void _onVaultChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final vault = VaultState.I;
    if (!vault.hasWalletKnown) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: PeekColors.accent)),
      );
    }
    if (!vault.hasWallet) return const WelcomeScreen();
    if (!vault.isUnlocked) return const LockScreen();
    return const AppShell();
  }
}
