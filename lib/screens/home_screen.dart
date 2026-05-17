import 'package:flutter/material.dart';

import '../theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PeekWallet')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Total balance', style: TextStyle(color: PeekColors.text2, fontSize: 13)),
            SizedBox(height: 6),
            Text('—', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700)),
            SizedBox(height: 24),
            Text(
              'No wallet loaded yet.',
              style: TextStyle(color: PeekColors.text3, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
