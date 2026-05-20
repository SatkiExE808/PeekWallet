import 'dart:ui';

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
      // extendBody = the body paints behind the tab bar so the
      // translucent + blurred bar reveals what's underneath (the
      // tail of the wallets list, etc.) instead of an opaque cut.
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: _tabs.map((t) => t.screen).toList(),
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              // 88%-opaque bg2 over the blur — gives the bar enough
              // weight to be readable while letting underlying
              // motion (like a refreshing balance row) flow through.
              color: PeekColors.bg2.withAlpha(225),
              border: Border(
                top: BorderSide(
                    color: Colors.white.withAlpha(20), width: 1),
              ),
            ),
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 4),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: PeekDesign.sp4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 0; i < _tabs.length; i++)
                      _NavItem(
                        tab: _tabs[i],
                        selected: i == _index,
                        onTap: () => setState(() => _index = i),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tab item with a sliding accent-pill underline + small fade
/// between selected and unselected icons. Premium alternative to
/// the stock BottomNavigationBar's flat colored icons.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });
  final _Tab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkResponse(
        onTap: onTap,
        radius: 60,
        splashColor: PeekColors.accentMuted,
        highlightColor: PeekColors.accentMuted,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: PeekDesign.sp2, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: PeekDesign.tFast,
                child: Icon(
                  selected ? tab.activeIcon : tab.icon,
                  key: ValueKey<bool>(selected),
                  color: selected
                      ? PeekColors.accent
                      : PeekColors.text3,
                  size: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tab.label,
                style: TextStyle(
                  color:
                      selected ? PeekColors.accent : PeekColors.text3,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 4),
              // Animated 3px pill under the selected tab.
              AnimatedContainer(
                duration: PeekDesign.tMed,
                curve: PeekDesign.easeOut,
                height: 3,
                width: selected ? 22 : 0,
                decoration: BoxDecoration(
                  color: PeekColors.accent,
                  borderRadius: PeekDesign.brPill,
                ),
              ),
            ],
          ),
        ),
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
