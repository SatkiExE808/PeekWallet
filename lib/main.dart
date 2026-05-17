import 'package:flutter/material.dart';

import 'theme.dart';
import 'shell.dart';

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
      home: const AppShell(),
    );
  }
}
