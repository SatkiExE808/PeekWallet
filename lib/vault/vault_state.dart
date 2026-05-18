import 'package:flutter/foundation.dart';

import '../address_book/address_book.dart';
import '../coins/monero/monero_wallet.dart';
import '../coins/monero/monero_keys.dart';
import '../util/sensitive_clipboard.dart';
import '../wallets/seed_format.dart';
import '../wallets/wallet_store.dart';
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
  String? _cachedPassword;
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

  /// The user's master password, held in memory after a successful
  /// unlock so opening additional wallets (multi-wallet model) doesn't
  /// re-prompt. Null while the vault is locked. Same security
  /// boundary as [mnemonic] — both live only in memory until [lock]
  /// or [wipe] runs.
  ///
  /// Consumers MUST treat this as sensitive: never serialize, never
  /// pass to non-PeekWallet code, never write to logs (PeekLogger
  /// auto-redacts but defense-in-depth is cheap).
  String? get cachedPassword => _cachedPassword;

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
    _cachedPassword = password;
    _hasWallet = true;
    _hasWalletKnown = true;
    notifyListeners();
  }

  /// Decrypts the stored seed and unlocks the session. Also runs a
  /// one-time migration: when WalletStore is empty but the legacy
  /// single-seed blob is present, silently re-encode the BIP39 seed
  /// as the first WalletStore entry. After this runs, every read
  /// elsewhere in the app can use WalletStore as the source of
  /// truth.
  Future<void> unlock(String password) async {
    final seed = await _storage.unlock(password);
    _mnemonic = seed.mnemonic;
    _passphrase = seed.passphrase;
    _walletFilePassword = seed.walletFilePassword;
    _cachedPassword = password;
    await _maybeMigrateLegacyWallet(password, seed);
    notifyListeners();
  }

  /// Idempotent: if WalletStore is empty AND we just unlocked a
  /// legacy single-seed vault, fold the legacy seed into a new
  /// WalletStore entry. The legacy VaultStorage blob stays put — old
  /// builds of the app would still want to unlock from it, and the
  /// data is the same.
  Future<void> _maybeMigrateLegacyWallet(
      String password, DecryptedSeed seed) async {
    if (await WalletStore.I.hasAny()) return;
    try {
      final keys = deriveMoneroKeys(seed.mnemonic, passphrase: seed.passphrase);
      await WalletStore.I.create(
        name: 'My Monero',
        coinId: 'XMR',
        format: SeedFormat.bip39_12,
        seedMaterial: {
          'mnemonic': seed.mnemonic,
          'passphrase': seed.passphrase,
        },
        password: password,
        primaryAddress: keys.primaryAddress,
      );
    } catch (e) {
      // Migration is best-effort — if it fails the user still has
      // their legacy single-seed wallet working. They can manually
      // add a new wallet later via the "+ Add wallet" flow.
      // ignore: avoid_print
      print('VaultState: legacy → WalletStore migration failed: $e');
    }
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
  /// and a sync thread polling the daemon. Cancels any pending
  /// sensitive-clipboard wipes too: their pending values may include
  /// seed material whose deferred clear we don't want firing after
  /// the app re-locks.
  void lock() {
    MoneroSession.I.stop();
    SensitiveClipboard.cancelAll();
    _mnemonic = null;
    _passphrase = '';
    _walletFilePassword = null;
    _cachedPassword = null;
    notifyListeners();
  }

  /// Permanently removes the encrypted seed AND every adjacent
  /// per-user store (biometric stash, address book). On a true reset
  /// nothing the user added should persist.
  Future<void> wipe() async {
    MoneroSession.I.stop();
    SensitiveClipboard.cancelAll();
    await _storage.wipe();
    await AddressBook.I.wipe();
    _mnemonic = null;
    _passphrase = '';
    _walletFilePassword = null;
    _cachedPassword = null;
    _hasWallet = false;
    _hasWalletKnown = true;
    notifyListeners();
  }
}
