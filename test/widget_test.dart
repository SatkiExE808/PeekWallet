import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:peek_wallet/main.dart';
import 'package:peek_wallet/theme.dart';

void main() {
  testWidgets('App boots and renders the loading splash', (tester) async {
    await tester.pumpWidget(const PeekWalletApp());
    // Before vault state resolves (storage is platform-channel-backed
    // and stays pending in widget tests without a mock), the app
    // sits on the loading splash. That's enough of a smoke test to
    // catch import / route / theme regressions at CI time.
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  test('Colour palette matches vault-wallet tokens', () {
    expect(PeekColors.accent.toARGB32(), 0xFFF97316);
    expect(PeekColors.bg.toARGB32(), 0xFF07090E);
  });
}
