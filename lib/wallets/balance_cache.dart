import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Last-known balance for one wallet. Display-only — the source of
/// truth is whatever the coin's RPC says right now. We snapshot
/// these so the wallets list can show a meaningful subtitle (and the
/// portfolio total) without waiting on N HTTP round-trips at boot.
class CachedBalance {
  const CachedBalance({
    required this.walletId,
    required this.symbol,
    required this.displayAmount,
    required this.fiatValue,
    required this.fiatCurrency,
    required this.updatedAt,
  });

  factory CachedBalance.fromJson(Map<String, dynamic> json) => CachedBalance(
        walletId: json['walletId'] as String,
        symbol: json['symbol'] as String,
        displayAmount: json['displayAmount'] as String,
        fiatValue: (json['fiatValue'] as num?)?.toDouble() ?? 0,
        fiatCurrency: json['fiatCurrency'] as String? ?? 'usd',
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
            (json['updatedAt'] as num).toInt()),
      );

  final String walletId;
  final String symbol;
  /// Pre-formatted for display, e.g. "0.00100000 BTC".
  final String displayAmount;
  /// Fiat equivalent at last refresh — 0 if the price feed hadn't
  /// loaded yet or the user disabled it.
  final double fiatValue;
  final String fiatCurrency;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'walletId': walletId,
        'symbol': symbol,
        'displayAmount': displayAmount,
        'fiatValue': fiatValue,
        'fiatCurrency': fiatCurrency,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  Duration get age => DateTime.now().difference(updatedAt);
}

/// Singleton balance snapshot cache. Persisted to flutter_secure_storage
/// (not because balances are sensitive — they're not, given the
/// addresses are public on-chain — but because we already use that
/// storage layer for everything else and consistency is cheap).
///
/// Each coin screen pushes a snapshot via [put] after its periodic
/// refresh. The wallets-list pulls everything via [all] to render
/// subtitles + total.
class BalanceCache extends ChangeNotifier {
  BalanceCache._();
  static final BalanceCache I = BalanceCache._();

  static const _storageKey = 'balance_cache.v1';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  final Map<String, CachedBalance> _cache = {};
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final raw = await _storage.read(key: _storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List;
        for (final e in list) {
          final entry = CachedBalance.fromJson(e as Map<String, dynamic>);
          _cache[entry.walletId] = entry;
        }
      } catch (_) {
        // Corrupt cache — just start over. Worst case the user sees
        // empty subtitles until the next refresh.
      }
    }
    _loaded = true;
  }

  /// Snapshot view of all cached entries.
  Future<Map<String, CachedBalance>> all() async {
    await _ensureLoaded();
    return Map.unmodifiable(_cache);
  }

  /// Just for a specific wallet.
  Future<CachedBalance?> get(String walletId) async {
    await _ensureLoaded();
    return _cache[walletId];
  }

  /// Write a fresh snapshot. Triggers a notifyListeners so any UI
  /// watching the cache (i.e. the wallets list) repaints.
  Future<void> put(CachedBalance b) async {
    await _ensureLoaded();
    _cache[b.walletId] = b;
    await _persist();
    notifyListeners();
  }

  /// Forget a wallet's snapshot — called when the user deletes the
  /// wallet so we don't dangle stale data in the cache forever.
  Future<void> forget(String walletId) async {
    await _ensureLoaded();
    final removed = _cache.remove(walletId);
    if (removed != null) {
      await _persist();
      notifyListeners();
    }
  }

  /// Wipe everything — used on full wallet-reset.
  Future<void> wipe() async {
    _cache.clear();
    await _storage.delete(key: _storageKey);
    notifyListeners();
  }

  Future<void> _persist() async {
    final list = _cache.values.map((b) => b.toJson()).toList();
    await _storage.write(key: _storageKey, value: jsonEncode(list));
  }
}
