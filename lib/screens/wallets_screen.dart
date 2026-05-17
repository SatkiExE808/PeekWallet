import 'package:flutter/material.dart';

import '../coins/registry.dart';
import '../theme.dart';
import 'coin_screen.dart';

class WalletsScreen extends StatelessWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Wallets')),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: kCoins.length,
        separatorBuilder: (_, _) => const SizedBox(height: 6),
        itemBuilder: (_, i) {
          final coin = kCoins[i];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: coin.color,
                child: Icon(coin.icon, color: Colors.white),
              ),
              title: Text(coin.name),
              subtitle: Text(coin.symbol,
                  style: const TextStyle(color: PeekColors.text2, fontSize: 12)),
              trailing: Text('… ${coin.symbol}',
                  style: const TextStyle(color: PeekColors.text2)),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CoinScreen(coin: coin)),
              ),
            ),
          );
        },
      ),
    );
  }
}
