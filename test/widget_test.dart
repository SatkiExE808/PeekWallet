import 'package:flutter_test/flutter_test.dart';

import 'package:peek_wallet/main.dart';

void main() {
  testWidgets('App shell renders three bottom tabs', (tester) async {
    await tester.pumpWidget(const PeekWalletApp());
    await tester.pump();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Wallets'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
