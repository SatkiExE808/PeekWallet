import 'package:flutter/foundation.dart';

import '../coins/monero/monero_wallet.dart';
import 'biometric_auth.dart';
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
  String? _walletFilePassword;
  bool _hasWalletKnown = false;
  bool _hasWallet = false;

  /// Null until [unlock] / [create] succeeds. Cleared by [lock].
  String? get mnemonic => _mnemonic;

  /// BIP39 passphrase ("25th word"). Empty string when not used.
  /// Coin derivations must include this in their PBKDF2 salt.
  String get passphrase => _passphrase;

  /// Per-vault password used to encrypt on-disk per-coin wallet files
  /// (e.g. the Monero `.wallet`). Derived from the user's master
  /// password — see VaultStorage._deriveWalletFilePassword. Null while
  /// the vault is locked.
  String? get walletFilePassword => _walletFilePassword;

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
    _walletFilePassword = seed.walletFilePassword;
    _hasWallet = true;
    _hasWalletKnown = true;
    notifyListeners();
  }

  /// Decrypts the stored seed and unlocks the session.
  Future<void> unlock(String password) async {
    final seed = await _storage.unlock(password);
    _mnemonic = seed.mnemonic;
    _passphrase = seed.passphrase;
    _walletFilePassword = seed.walletFilePassword;
    notifyListeners();
  }

  /// True when the user has previously opted in to biometric unlock.
  /// Surfaced in the lock screen so we know whether to auto-prompt
  /// for fingerprint/face on launch.
  Future<bool> biometricEnabled() => _storage.biometricEnabled();

  /// Run a biometric prompt; on success, decrypt the seed using the
  /// password stashed in OS-backed secure storage and unlock the
  /// session. Returns false on cancel / auth failure / missing
  /// stash, so the caller can fall through to password entry.
  Future<bool> unlockBiometric() async {
    if (!await _storage.biometricEnabled()) return false;
    if (!await BiometricAuth.I.isAvailable()) return false;
    final authed = await BiometricAuth.I.authenticate();
    if (!authed) return false;
    final password = await _storage.readBiometricPassword();
    if (password == null) return false;
    try {
      await unlock(password);
      return true;
    } catch (_) {
      // The stashed password got out of sync with the actual seed
      // password somehow (user changed it via some future flow).
      // Clear the stash so we stop trying biometric and force a
      // clean password entry.
      await _storage.clearBiometricPassword();
      return false;
    }
  }

  /// Opt in to biometric unlock. Requires the wallet to already be
  /// unlocked (i.e. we have the current password). On Android, the
  /// password is written into encryptedSharedPreferences; on iOS,
  /// the Keychain with first_unlock accessibility.
  Future<void> enableBiometric(String currentPassword) async {
    // Re-verify the password before stashing it — if the user
    // typo'd we don't want to lock biometric to the wrong value.
    await _storage.unlock(currentPassword);
    await _storage.saveBiometricPassword(currentPassword);
    notifyListeners();
  }

  /// Turn off biometric unlock. The encrypted seed stays put, the
  /// user just has to type their password from now on.
  Future<void> disableBiometric() async {
    await _storage.clearBiometricPassword();
    notifyListeners();
  }

  /// Clears the in-memory seed. Encrypted blob stays on disk for the
  /// next unlock. Also tears down any running native wallet — keeping
  /// the monero_c engine alive past lock would leave keys in memory
  /// and a sync thread polling the daemon.
  void lock() {
    MoneroSession.I.stop();
    _mnemonic = null;
    _passphrase = '';
    _walletFilePassword = null;
    notifyListeners();
  }

  /// Permanently removes the encrypted seed.
  Future<void> wipe() async {
    MoneroSession.I.stop();
    await _storage.wipe();
    _mnemonic = null;
    _passphrase = '';
    _walletFilePassword = null;
    _hasWallet = false;
    _hasWalletKnown = true;
    notifyListeners();
  }
}
