import 'package:flutter/foundation.dart';

import 'vault_storage.dart';

/// App-wide vault state. Holds the decrypted mnemonic in memory after
/// unlock; the rest of the app reads `mnemonic` rather than touching
/// secure storage directly.
///
/// Single-instance globally via [VaultState.I]. Coin-derivation modules
/// read `VaultState.I.mnemonic` when they need to sign or derive.
class VaultState extends ChangeNotifier {
  VaultState._();
  static final I = VaultState._();

  final VaultStorage _storage = VaultStorage();

  String? _mnemonic;
  bool _hasWalletKnown = false;
  bool _hasWallet = false;

  /// Null until [unlock] succeeds. Cleared by [lock].
  String? get mnemonic => _mnemonic;

  /// True once an encrypted seed exists on disk (regardless of
  /// whether this session has unlocked it). Cached; refresh with
  /// [refreshHasWallet] if you've just saved.
  bool get hasWallet => _hasWallet;
  bool get isUnlocked => _mnemonic != null;
  bool get hasWalletKnown => _hasWalletKnown;

  Future<bool> refreshHasWallet() async {
    _hasWallet = await _storage.hasWallet();
    _hasWalletKnown = true;
    notifyListeners();
    return _hasWallet;
  }

  /// Encrypts + stores `mnemonic`, then unlocks the session.
  Future<void> create(String mnemonic, String password) async {
    await _storage.save(mnemonic, password);
    _mnemonic = mnemonic;
    _hasWallet = true;
    _hasWalletKnown = true;
    notifyListeners();
  }

  /// Decrypts the stored seed and unlocks the session.
  Future<void> unlock(String password) async {
    _mnemonic = await _storage.unlock(password);
    notifyListeners();
  }

  /// Clears the in-memory seed. Encrypted blob stays on disk for the
  /// next unlock.
  void lock() {
    _mnemonic = null;
    notifyListeners();
  }

  /// Permanently removes the encrypted seed.
  Future<void> wipe() async {
    await _storage.wipe();
    _mnemonic = null;
    _hasWallet = false;
    _hasWalletKnown = true;
    notifyListeners();
  }
}
