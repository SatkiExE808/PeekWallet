/// How the wallet's recovery material is encoded.
///
/// Each coin module declares which formats it accepts. The user picks
/// one in the create-flow; the same format determines what the
/// Reveal-Seed screen shows them later (12 words, 25 words, or
/// "keys-only — no seed available").
enum SeedFormat {
  /// BIP39 12-word phrase. Universal across BTC, ETH, LTC, etc., and
  /// our existing pure-Dart Monero derivation also lives here for
  /// migration from vault-wallet.
  bip39_12,

  /// BIP39 24-word phrase. Same algorithm as bip39_12, just more
  /// entropy (256 bits vs 128).
  bip39_24,

  /// Monero's native 25-word electrum-style seed. Direct Cake /
  /// Feather / Monero GUI interop. monero_c generates this with
  /// WalletManager_createWallet; we read it back with Wallet_seed.
  monero25,

  /// 14-word Polyseed. Newer Monero standard that encodes the restore
  /// height in the words themselves, so the user doesn't have to
  /// remember a separate height number alongside the phrase.
  moneroPolyseed,

  /// No seed — wallet was restored from raw spend/view keys (+ a
  /// restore height + the primary address). Reveal-Seed shows the
  /// keys instead of words. The wallet is otherwise fully functional
  /// (can spend, can receive, can list history).
  keysOnly;

  String get displayName {
    switch (this) {
      case bip39_12:
        return '12-word BIP39';
      case bip39_24:
        return '24-word BIP39';
      case monero25:
        return '25-word Monero seed';
      case moneroPolyseed:
        return '14-word Polyseed';
      case keysOnly:
        return 'View / spend keys (no seed)';
    }
  }

  /// True if the user can be shown the seed words on the
  /// Reveal-Seed screen. False for [keysOnly] — there are no words
  /// to reveal.
  bool get hasMnemonic => this != keysOnly;

  /// True if this format is Monero-specific (won't show up in BTC /
  /// ETH wallet-creation flows).
  bool get isMoneroOnly =>
      this == monero25 || this == moneroPolyseed || this == keysOnly;
}
