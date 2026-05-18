import 'dart:async';

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

/// How long the app may sit in the background before we re-lock the
/// vault. Two minutes balances "user briefly switched to a 2FA app and
/// came back" against "phone left on a table at a café". Lockable on
/// every app boot regardless.
const Duration _backgroundLockTimeout = Duration(minutes: 2);

/// Top-level state machine:
/// - hasWallet unknown → loading splash
/// - !hasWallet         → welcome / setup
/// - hasWallet && locked → lock screen
/// - hasWallet && unlocked → app shell
///
/// Also wears a [WidgetsBindingObserver] so we can re-lock the vault
/// when the app sits in the background past [_backgroundLockTimeout].
/// Without that, a phone with a defeated screen lock + a backgrounded
/// PeekWallet exposes everything inside on the next foreground.
class _Router extends StatefulWidget {
  const _Router();

  @override
  State<_Router> createState() => _RouterState();
}

class _RouterState extends State<_Router> with WidgetsBindingObserver {
  Timer? _bgLockTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    VaultState.I.addListener(_onVaultChange);
    VaultState.I.refreshHasWallet();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bgLockTimer?.cancel();
    VaultState.I.removeListener(_onVaultChange);
    super.dispose();
  }

  void _onVaultChange() => setState(() {});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // App sent to background. Start the lock countdown; if the
        // user returns within the timeout, we cancel it in `resumed`.
        // No-op if not unlocked (locking a locked vault is silly).
        if (!VaultState.I.isUnlocked) return;
        _bgLockTimer?.cancel();
        _bgLockTimer = Timer(_backgroundLockTimeout, () {
          if (VaultState.I.isUnlocked) VaultState.I.lock();
        });
        break;
      case AppLifecycleState.resumed:
        // User came back — cancel the pending lock.
        _bgLockTimer?.cancel();
        _bgLockTimer = null;
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // 'inactive' fires for transient overlays (incoming call,
        // notification panel). Doing anything here would over-lock.
        break;
    }
  }

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
