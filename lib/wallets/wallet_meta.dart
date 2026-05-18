import 'package:flutter/foundation.dart';

import 'seed_format.dart';

/// Non-secret metadata about a wallet. Lives in [WalletStore]'s index
/// alongside the encrypted blob; readable without the master password
/// so the Wallets list can render names + coin badges before unlock.
///
/// Sensitive material (seed words, spend key, passphrase) lives in the
/// per-wallet [EncryptedWallet] blob and only decrypts on demand.
@immutable
class WalletMeta {
  const WalletMeta({
    required this.id,
    required this.name,
    required this.coinId,
    required this.format,
    required this.createdAt,
    this.primaryAddress,
    this.restoreHeight,
    this.order = 0,
  });

  /// Stable identifier. Generated from createdAt microseconds when the
  /// wallet is created — used for routing, disk paths, and as the key
  /// in any per-wallet maps (e.g. `WalletSession.openWallets[id]`).
  final String id;

  /// User-set display name ("My Monero", "Trading", "Cold storage").
  /// Editable via long-press → Rename on the Wallets list.
  final String name;

  /// 'XMR' / 'BTC' / 'ETH' / etc. Each coin module declares one
  /// canonical [Coin.id] and we match against it.
  final String coinId;

  /// Which way the user's recovery material was generated / supplied.
  /// Determines the Reveal-Seed UI and the available restore paths.
  final SeedFormat format;

  /// Public primary address. Cached at create-time so the Wallets list
  /// can show the user's deposit address without opening the wallet.
  /// Null for coins where derivation is non-trivial (multi-address BTC
  /// will compute the next receive address on the fly).
  final String? primaryAddress;

  /// Monero-only: block to start scanning from. Persisted here so we
  /// can re-clamp it on re-open without burning an RPC roundtrip.
  /// Null for coins where the concept doesn't apply.
  final int? restoreHeight;

  final DateTime createdAt;

  /// Display order in the Wallets list. Lower = top. Reorder UI
  /// rewrites these in bulk on drop.
  final int order;

  WalletMeta copyWith({
    String? name,
    String? primaryAddress,
    int? restoreHeight,
    int? order,
  }) =>
      WalletMeta(
        id: id,
        name: name ?? this.name,
        coinId: coinId,
        format: format,
        createdAt: createdAt,
        primaryAddress: primaryAddress ?? this.primaryAddress,
        restoreHeight: restoreHeight ?? this.restoreHeight,
        order: order ?? this.order,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'coinId': coinId,
        'format': format.name,
        'createdAt': createdAt.toIso8601String(),
        if (primaryAddress != null) 'primaryAddress': primaryAddress,
        if (restoreHeight != null) 'restoreHeight': restoreHeight,
        'order': order,
      };

  factory WalletMeta.fromJson(Map<String, dynamic> json) => WalletMeta(
        id: json['id'] as String,
        name: json['name'] as String,
        coinId: json['coinId'] as String,
        format: SeedFormat.values
            .firstWhere((f) => f.name == json['format'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        primaryAddress: json['primaryAddress'] as String?,
        restoreHeight: json['restoreHeight'] as int?,
        order: (json['order'] as int?) ?? 0,
      );
}

/// The encrypted seed material for a single wallet. Salt + nonce
/// embedded inline so each wallet is decryptable independently.
/// On disk: base64-encoded `salt(16) || nonce(12) || ciphertext || tag(16)`.
@immutable
class EncryptedWalletBlob {
  const EncryptedWalletBlob(this.base64);
  final String base64;

  Map<String, dynamic> toJson() => {'b': base64};
  factory EncryptedWalletBlob.fromJson(Map<String, dynamic> json) =>
      EncryptedWalletBlob(json['b'] as String);
}
