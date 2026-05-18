import 'dart:async';

import 'package:flutter/material.dart';

import 'prefs/prefs.dart';
import 'prices/price_feed.dart';
import 'theme.dart';
import 'shell.dart';
import 'screens/welcome_screen.dart';
import 'screens/lock_screen.dart';
import 'vault/vault_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Boot the price feed BEFORE runApp so the first frame has cached
  // prices (or an empty cache if the user has it disabled).
  unawaited(PriceFeed.I.start());
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

// Auto-lock interval is configurable in Settings → Auto-lock; defaults
// to 2 min. Read fresh on every backgrounding so the new setting takes
// effect immediately, no app restart needed.

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
        if (!VaultState.I.isUnlocked) return;
        _bgLockTimer?.cancel();
        unawaited(_armBackgroundLock());
        break;
      case AppLifecycleState.resumed:
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

  Future<void> _armBackgroundLock() async {
    // Read fresh on every backgrounding so the user's most-recent
    // Settings change takes effect immediately.
    final seconds = await Prefs.I.autoLockSeconds();
    if (seconds <= 0) {
      // 0 = lock immediately.
      if (VaultState.I.isUnlocked) VaultState.I.lock();
      return;
    }
    // A very large value (>~24h) is interpreted as "never auto-lock".
    if (seconds >= 86400) return;
    _bgLockTimer = Timer(Duration(seconds: seconds), () {
      if (VaultState.I.isUnlocked) VaultState.I.lock();
    });
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
