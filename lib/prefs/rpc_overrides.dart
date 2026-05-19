import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Per-chain custom RPC / explorer endpoint overrides.
///
/// Every chain in PeekWallet ships with a sensible public default
/// (mempool.space, eth.blockscout.com, api.trongrid.io, etc.) so a
/// fresh install works without configuration. Users who run their
/// own infrastructure — or who care about NOT leaking their wallet
/// activity to public block explorers — can override any of these
/// per chain.
///
/// The cache is loaded once at app startup (call [load] from main())
/// and accessed synchronously thereafter. Wallets read [get] at
/// construction time; changing an override requires reopening the
/// affected wallet to take effect.
class RpcOverrides extends ChangeNotifier {
  RpcOverrides._();
  static final RpcOverrides I = RpcOverrides._();

  static const _storageKey = 'rpc_overrides.v1';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Cache of "coinId:kind" → endpoint URL. Kind is 'rpc' or
  /// 'explorer' depending on the chain's transport (UTXO chains
  /// have only explorer; EVM chains have both).
  Map<String, String> _cache = {};
  bool _loaded = false;

  /// Load the cache from secure storage. Idempotent — safe to call
  /// twice. Should be awaited before any wallet constructor runs.
  Future<void> load() async {
    if (_loaded) return;
    final raw = await _storage.read(key: _storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        _cache = json.map((k, v) => MapEntry(k, v as String));
        _migrateLegacyKeys();
      } catch (_) {
        // Corrupted store — fall back to defaults. Worst case the
        // user re-enters their custom endpoints.
      }
    }
    _loaded = true;
  }

  /// Rewrite legacy coin-id prefixes on load. MATIC → POL because
  /// Polygon migrated its native token in September 2024 and we
  /// follow the canonical POL ticker now.
  void _migrateLegacyKeys() {
    final migrated = <String, String>{};
    var changed = false;
    for (final entry in _cache.entries) {
      if (entry.key.startsWith('MATIC:')) {
        final newKey = 'POL:${entry.key.substring(6)}';
        migrated[newKey] = entry.value;
        changed = true;
      } else {
        migrated[entry.key] = entry.value;
      }
    }
    if (changed) {
      _cache = migrated;
      // Fire-and-forget persist — no point awaiting; the next read
      // already sees the migrated cache.
      unawaited(_persist());
    }
  }

  /// Synchronous lookup. Returns the user's override for
  /// [coinId]/[kind] or null if none / not loaded yet.
  ///
  /// kinds:
  ///   'rpc'      — JSON-RPC node (EVM chains, Solana)
  ///   'explorer' — Etherscan-compat read API (EVM, Tron, BCH)
  ///   'mempool'  — mempool.space-compat Esplora (BTC, LTC)
  String? get(String coinId, String kind) {
    if (!_loaded) return null;
    return _cache['$coinId:$kind'];
  }

  /// Persist a new override. Pass null/empty to clear and fall
  /// back to the default for the next open.
  Future<void> set(String coinId, String kind, String? value) async {
    if (!_loaded) await load();
    final key = '$coinId:$kind';
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      _cache.remove(key);
    } else {
      _cache[key] = trimmed;
    }
    await _persist();
    notifyListeners();
  }

  /// Drop every override — used for "Reset to defaults" UX.
  Future<void> clearAll() async {
    _cache.clear();
    await _storage.delete(key: _storageKey);
    notifyListeners();
  }

  /// Snapshot of every override for the Settings page. Returns a
  /// copy so callers can iterate without worrying about concurrent
  /// modification.
  Map<String, String> snapshot() => Map.unmodifiable(_cache);

  Future<void> _persist() async {
    await _storage.write(
        key: _storageKey, value: jsonEncode(_cache));
  }
}
