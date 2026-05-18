import 'package:flutter/foundation.dart';

import 'vault_storage.dart';

/// App-wide vault state. Holds the decrypted mnemonic (+ BIP39
/// passphrase if any) in memory after unlock; the rest of the app
/// reads `mnemonic` / `passphrase` rather than touching secure storage
/// directly.
class VaultState extends ChangeNotifier {
  VaultState._();
  static final I = VaultState._();

  final VaultStorage _storage = VaultStorage();

  String? _mnemonic;
  String _passphrase = '';
  bool _hasWalletKnown = false;
  bool _hasWallet = false;

  /// Null until [unlock] / [create] succeeds. Cleared by [lock].
  String? get mnemonic => _mnemonic;

  /// BIP39 passphrase ("25th word"). Empty string when not used.
  /// Coin derivations must include this in their PBKDF2 salt.
  String get passphrase => _passphrase;

  bool get hasWallet => _hasWallet;
  bool get isUnlocked => _mnemonic != null;
  bool get hasWalletKnown => _hasWalletKnown;

  Future<bool> refreshHasWallet() async {
    _hasWallet = await _storage.hasWallet();
    _hasWalletKnown = true;
    notifyListeners();
    return _hasWallet;
  }

  /// Encrypts + stores `mnemonic` (+ optional passphrase), then
  /// unlocks the session.
  Future<void> create(String mnemonic, String password,
      {String passphrase = ''}) async {
    final seed = await _storage.save(mnemonic, password, passphrase: passphrase);
    _mnemonic = seed.mnemonic;
    _passphrase = seed.passphrase;
    _hasWallet = true;
    _hasWalletKnown = true;
    notifyListeners();
  }

  /// Decrypts the stored seed and unlocks the session.
  Future<void> unlock(String password) async {
    final seed = await _storage.unlock(password);
    _mnemonic = seed.mnemonic;
    _passphrase = seed.passphrase;
    notifyListeners();
  }

  /// Clears the in-memory seed. Encrypted blob stays on disk for the
  /// next unlock.
  void lock() {
    _mnemonic = null;
    _passphrase = '';
    notifyListeners();
  }

  /// Permanently removes the encrypted seed.
  Future<void> wipe() async {
    await _storage.wipe();
    _mnemonic = null;
    _passphrase = '';
    _hasWallet = false;
    _hasWalletKnown = true;
    notifyListeners();
  }
}
