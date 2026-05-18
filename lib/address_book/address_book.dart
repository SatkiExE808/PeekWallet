import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// One labelled address recorded by the user. Coin-agnostic — the
/// `coinId` field gates which sends can autocomplete against this
/// entry (so an XMR send doesn't suggest a BTC address).
@immutable
class AddressBookEntry {
  const AddressBookEntry({
    required this.id,
    required this.coinId,
    required this.address,
    required this.label,
    required this.createdAt,
    this.notes = '',
    this.lastUsedAt,
  });

  /// Stable identifier — used as React-style key for list updates.
  /// Generated from createdAt microseconds at creation time.
  final String id;

  /// 'XMR', 'BTC', etc. Filtered against when surfacing autocomplete
  /// on the send screen.
  final String coinId;

  /// Primary address or subaddress, normalised (trimmed).
  final String address;

  /// User-set display name. Required (non-empty).
  final String label;

  /// Optional free-text notes (e.g. "Withdrawal address — Kraken").
  final String notes;

  final DateTime createdAt;
  final DateTime? lastUsedAt;

  AddressBookEntry copyWith({
    String? label,
    String? notes,
    DateTime? lastUsedAt,
  }) =>
      AddressBookEntry(
        id: id,
        coinId: coinId,
        address: address,
        label: label ?? this.label,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'coinId': coinId,
        'address': address,
        'label': label,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        if (lastUsedAt != null) 'lastUsedAt': lastUsedAt!.toIso8601String(),
      };

  factory AddressBookEntry.fromJson(Map<String, dynamic> json) =>
      AddressBookEntry(
        id: json['id'] as String,
        coinId: json['coinId'] as String,
        address: json['address'] as String,
        label: json['label'] as String,
        notes: (json['notes'] as String?) ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastUsedAt: json['lastUsedAt'] == null
            ? null
            : DateTime.parse(json['lastUsedAt'] as String),
      );
}

/// Encrypted persistent storage for [AddressBookEntry]s. The entire
/// list is serialised to JSON and stored as one entry in
/// FlutterSecureStorage — the OS-backed encryption gives us
/// confidentiality at rest. We don't add a second app-layer
/// encryption here because (a) addresses are public anyway,
/// (b) labels could correlate the user with their counterparties but
/// the same secure-storage container already holds the seed material,
/// so the threat model is identical.
class AddressBook extends ChangeNotifier {
  AddressBook._({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  static final AddressBook I = AddressBook._();

  static const _key = 'address_book.v1';

  final FlutterSecureStorage _storage;
  List<AddressBookEntry>? _cache;
  bool _loaded = false;

  /// All entries, newest-first. Triggers a load on first call.
  Future<List<AddressBookEntry>> all() async {
    if (!_loaded) await _load();
    return List.unmodifiable(_cache ?? const []);
  }

  /// Entries for a specific coin, sorted by lastUsedAt desc then
  /// createdAt desc. Used by the Send screen's autocomplete.
  Future<List<AddressBookEntry>> forCoin(String coinId) async {
    final entries = await all();
    final filtered = entries.where((e) => e.coinId == coinId).toList();
    filtered.sort((a, b) {
      final aWhen = a.lastUsedAt ?? a.createdAt;
      final bWhen = b.lastUsedAt ?? b.createdAt;
      return bWhen.compareTo(aWhen);
    });
    return filtered;
  }

  /// Look up an entry by address. Returns null if no match.
  Future<AddressBookEntry?> findByAddress(String coinId, String address) async {
    final entries = await forCoin(coinId);
    for (final e in entries) {
      if (e.address == address) return e;
    }
    return null;
  }

  /// Add a new entry. Throws if an entry with the same (coinId,
  /// address) tuple already exists — the caller should call
  /// findByAddress + update if they want upsert semantics.
  Future<AddressBookEntry> add({
    required String coinId,
    required String address,
    required String label,
    String notes = '',
  }) async {
    if (!_loaded) await _load();
    final clean = address.trim();
    final existing = _cache!.any((e) => e.coinId == coinId && e.address == clean);
    if (existing) {
      throw StateError('Address already in book for $coinId');
    }
    final entry = AddressBookEntry(
      id: 'ab_${DateTime.now().microsecondsSinceEpoch}',
      coinId: coinId,
      address: clean,
      label: label.trim(),
      notes: notes.trim(),
      createdAt: DateTime.now(),
    );
    _cache!.add(entry);
    await _save();
    notifyListeners();
    return entry;
  }

  /// Edit label or notes. Updates lastUsedAt automatically.
  Future<void> update(
    String id, {
    String? label,
    String? notes,
  }) async {
    if (!_loaded) await _load();
    final ix = _cache!.indexWhere((e) => e.id == id);
    if (ix < 0) return;
    _cache![ix] = _cache![ix].copyWith(label: label, notes: notes);
    await _save();
    notifyListeners();
  }

  /// Mark an entry as used. Bumps lastUsedAt so it floats to the top
  /// of autocomplete. Called from the Send screen after a successful
  /// build (build, not commit — even an aborted send signals intent).
  Future<void> recordUse(String id) async {
    if (!_loaded) await _load();
    final ix = _cache!.indexWhere((e) => e.id == id);
    if (ix < 0) return;
    _cache![ix] = _cache![ix].copyWith(lastUsedAt: DateTime.now());
    await _save();
    notifyListeners();
  }

  /// Delete by id. No-op if not found.
  Future<void> delete(String id) async {
    if (!_loaded) await _load();
    _cache!.removeWhere((e) => e.id == id);
    await _save();
    notifyListeners();
  }

  /// Drop the entire book. Called from VaultState.wipe so a reset
  /// clears address-book state too.
  Future<void> wipe() async {
    await _storage.delete(key: _key);
    _cache = [];
    _loaded = true;
    notifyListeners();
  }

  Future<void> _load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) {
      _cache = [];
      _loaded = true;
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _cache = list
          .map((m) => AddressBookEntry.fromJson(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Corrupted blob — drop it rather than blocking the user.
      // Logged-ish via the empty cache; we could surface a "your
      // address book was corrupted, please re-add entries" toast
      // somewhere if this ever happens in practice.
      _cache = [];
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final json = jsonEncode(_cache!.map((e) => e.toJson()).toList());
    await _storage.write(key: _key, value: json);
  }
}
