import 'package:flutter/material.dart';

import 'theme.dart';
import 'screens/wallets_screen.dart';
import 'screens/settings_screen.dart';

/// The persistent app shell — two bottom tabs (Wallets / Settings).
/// The Wallets tab carries the portfolio hero + per-wallet list, so
/// there's no separate "Home" landing — that was a vault-wallet
/// holdover stub from early development. Each tab keeps its own
/// navigation stack so deep pushes (e.g. coin detail) don't bleed
/// across tabs.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _tabs = [
    _Tab('Wallets', Icons.account_balance_wallet_outlined,
        Icons.account_balance_wallet, WalletsScreen()),
    _Tab('Settings', Icons.settings_outlined, Icons.settings, SettingsScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _tabs.map((t) => t.screen).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: [
          for (final t in _tabs)
            BottomNavigationBarItem(
              icon: Icon(t.icon),
              activeIcon: Icon(t.activeIcon, color: PeekColors.accent),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

class _Tab {
  const _Tab(this.label, this.icon, this.activeIcon, this.screen);
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget screen;
}
