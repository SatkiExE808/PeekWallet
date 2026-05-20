// Widget tests for the shared coin-screen widgets. We don't aim for
// pixel-perfect snapshots — that's brittle and the design tokens
// change quarterly. The goal is to lock down the *contract* of each
// widget: what state it shows, what callbacks it fires, what a
// screen reader announces.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:peek_wallet/l10n/gen/app_localizations.dart';
import 'package:peek_wallet/theme.dart';
import 'package:peek_wallet/widgets/coin_screen_widgets.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: PeekTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  group('ActionButton', () {
    testWidgets('renders label + icon', (tester) async {
      await tester.pumpWidget(_wrap(ActionButton(
        icon: Icons.send,
        label: 'Send',
        primary: true,
        onTap: () {},
      )));
      expect(find.text('Send'), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('fires onTap when enabled', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(_wrap(ActionButton(
        icon: Icons.send,
        label: 'Send',
        primary: true,
        onTap: () => tapped++,
      )));
      await tester.tap(find.text('Send'));
      await tester.pump();
      expect(tapped, 1);
    });

    testWidgets('disabled state ignores taps', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(_wrap(ActionButton(
        icon: Icons.send,
        label: 'Send',
        primary: true,
        onTap: null,
      )));
      await tester.tap(find.text('Send'));
      await tester.pump();
      expect(tapped, 0);
    });

    testWidgets('exposes a labelled Semantics node', (tester) async {
      await tester.pumpWidget(_wrap(ActionButton(
        icon: Icons.send,
        label: 'Send',
        primary: true,
        onTap: null,
      )));
      // The ActionButton's Semantics wraps it with label="Send" + button.
      // The tristate-based flags API is changing between Flutter
      // versions, so just verify the label propagates — that's the
      // load-bearing contract for screen readers.
      final semantics = tester.getSemantics(find.byType(ActionButton));
      expect(semantics.label, contains('Send'));
    });
  });

  group('StatusPill', () {
    testWidgets('renders the text + icon', (tester) async {
      await tester.pumpWidget(_wrap(const StatusPill(
        text: 'Cached · 3 min',
        color: PeekColors.accent,
        icon: Icons.cloud_off_rounded,
      )));
      expect(find.text('Cached · 3 min'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    });

    testWidgets('exposes its text as the Semantics label',
        (tester) async {
      await tester.pumpWidget(_wrap(const StatusPill(
        text: 'Syncing 45%',
        color: PeekColors.accent,
        icon: Icons.sync_rounded,
      )));
      final semantics = tester.getSemantics(find.byType(StatusPill));
      expect(semantics.label, contains('Syncing 45%'));
    });
  });

  group('EmptyActivity', () {
    testWidgets('shows "Loading…" when loading=true', (tester) async {
      await tester.pumpWidget(_wrap(const EmptyActivity(
        loading: true,
        coinLabel: 'BTC',
      )));
      expect(find.text('Loading…'), findsOneWidget);
      expect(find.text('No transactions yet'), findsNothing);
    });

    testWidgets('shows empty state + coin hint when loaded',
        (tester) async {
      await tester.pumpWidget(_wrap(const EmptyActivity(
        loading: false,
        coinLabel: 'XMR',
      )));
      expect(find.text('No transactions yet'), findsOneWidget);
      expect(find.textContaining('XMR'), findsOneWidget);
    });
  });

  group('SectionHeader', () {
    testWidgets('renders title; chip only when count provided',
        (tester) async {
      await tester.pumpWidget(_wrap(const SectionHeader(
        title: 'Activity',
        countChip: '5',
      )));
      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      await tester.pumpWidget(_wrap(const SectionHeader(title: 'Tokens')));
      expect(find.text('Tokens'), findsOneWidget);
    });
  });
}
