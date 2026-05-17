import 'package:flutter/material.dart';

/// Minimal coin descriptor. Each concrete coin module (Monero, BTC,
/// etc.) provides an instance with the metadata + the address-
/// derivation hook. Balance + send live in coin-specific modules.
abstract class Coin {
  String get id;
  String get name;
  String get symbol;
  Color get color;
  IconData get icon;

  /// Async because some derivations (Monero, future BTC multi-addr)
  /// do non-trivial work.
  Future<String> deriveAddress(String mnemonic);
}
