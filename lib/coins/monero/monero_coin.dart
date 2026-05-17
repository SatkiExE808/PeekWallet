import 'package:flutter/material.dart';

import '../coin.dart';
import 'monero_keys.dart';

class MoneroCoin implements Coin {
  const MoneroCoin();

  @override
  String get id => 'XMR';

  @override
  String get name => 'Monero';

  @override
  String get symbol => 'XMR';

  @override
  Color get color => const Color(0xFFFF6600);

  @override
  IconData get icon => Icons.privacy_tip;

  @override
  Future<String> deriveAddress(String mnemonic) async =>
      deriveMoneroKeys(mnemonic).primaryAddress;
}
