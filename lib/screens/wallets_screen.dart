import 'package:flutter/material.dart';

import '../theme.dart';

class WalletsScreen extends StatelessWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Wallets')),
      body: const Center(
        child: Text(
          'Coin list will appear here.',
          style: TextStyle(color: PeekColors.text3),
        ),
      ),
    );
  }
}
