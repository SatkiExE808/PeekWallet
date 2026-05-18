import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'erc20_tokens.dart';

/// Persistent per-wallet store of user-added ERC-20 tokens. Tokens
/// here show up alongside the hardcoded defaults (USDT/USDC/DAI) on
/// the EVM coin screen.
///
/// We key by walletId so a user can have different sets of tracked
/// tokens on different wallets — e.g., a DeFi wallet tracking 10
/// tokens vs a hot wallet tracking just stables.
class CustomTokenStore extends ChangeNotifier {
  CustomTokenStore._();
  static final CustomTokenStore I = CustomTokenStore._();

  static const _storageKey = 'custom_tokens.v1';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// walletId → list of custom tokens. Loaded lazily.
  Map<String, List<Erc20Token>> _cache = {};
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final raw = await _storage.read(key: _storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        _cache = json.map((walletId, tokens) {
          final list = (tokens as List).map((t) {
            final m = t as Map<String, dynamic>;
            return Erc20Token(
              symbol: m['symbol'] as String,
              name: m['name'] as String,
              contract: m['contract'] as String,
              decimals: (m['decimals'] as num).toInt(),
              chainId: (m['chainId'] as num).toInt(),
            );
          }).toList();
          return MapEntry(walletId, list);
        });
      } catch (_) {
        // Corrupted store — start clean rather than crash. Users
        // can re-add anything they lost.
      }
    }
    _loaded = true;
  }

  /// Tokens added by the user for this wallet. Doesn't include
  /// hardcoded defaults — callers union the two lists.
  Future<List<Erc20Token>> listFor(String walletId) async {
    await _ensureLoaded();
    return List.unmodifiable(_cache[walletId] ?? const []);
  }

  /// Add a token to this wallet's list. Refuses duplicates by
  /// (contract, chainId) tuple so the user can't accidentally add
  /// USDT twice.
  Future<void> add(String walletId, Erc20Token token) async {
    await _ensureLoaded();
    final list = _cache[walletId] ?? <Erc20Token>[];
    final exists = list.any((t) =>
        t.contract.toLowerCase() == token.contract.toLowerCase() &&
        t.chainId == token.chainId);
    if (exists) return;
    _cache[walletId] = [...list, token];
    await _persist();
    notifyListeners();
  }

  /// Remove a token by (contract, chainId) tuple.
  Future<void> remove(String walletId, String contract, int chainId) async {
    await _ensureLoaded();
    final list = _cache[walletId];
    if (list == null) return;
    final filtered = list
        .where((t) =>
            t.contract.toLowerCase() != contract.toLowerCase() ||
            t.chainId != chainId)
        .toList();
    if (filtered.length == list.length) return;
    _cache[walletId] = filtered;
    await _persist();
    notifyListeners();
  }

  /// Drop a wallet's entire token list — called when the wallet
  /// itself is deleted.
  Future<void> forget(String walletId) async {
    await _ensureLoaded();
    if (_cache.remove(walletId) != null) {
      await _persist();
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    final json = _cache.map((walletId, tokens) {
      return MapEntry(
        walletId,
        tokens
            .map((t) => {
                  'symbol': t.symbol,
                  'name': t.name,
                  'contract': t.contract,
                  'decimals': t.decimals,
                  'chainId': t.chainId,
                })
            .toList(),
      );
    });
    await _storage.write(key: _storageKey, value: jsonEncode(json));
  }
}
