import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Per-install non-sensitive preferences (current Monero node, etc.).
/// Stored in flutter_secure_storage to avoid pulling in a second
/// persistence dep — the data isn't secret but the platform-channel
/// boundary is the same either way.
class Prefs {
  Prefs._();
  static final I = Prefs._();

  static const _moneroDaemonKey = 'prefs.monero_daemon_uri.v1';
  static const _autoLockKey = 'prefs.auto_lock_seconds.v1';

  /// Default auto-lock interval when the user hasn't set one yet.
  /// 2 min — short enough to mitigate phone-found attacks, long
  /// enough to survive a quick app switch to a 2FA app.
  static const int defaultAutoLockSeconds = 120;

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// User-configured Monero daemon URL, or null if they're using the
  /// app default (kDefaultMoneroDaemon). Trimmed strings only.
  Future<String?> moneroDaemonUri() => _storage.read(key: _moneroDaemonKey);

  /// Persist a new daemon URL. Pass null (or empty) to clear the
  /// override and fall back to kDefaultMoneroDaemon.
  Future<void> setMoneroDaemonUri(String? uri) async {
    final trimmed = uri?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      await _storage.delete(key: _moneroDaemonKey);
    } else {
      await _storage.write(key: _moneroDaemonKey, value: trimmed);
    }
  }

  /// Auto-lock interval in seconds. Zero means "lock immediately on
  /// background"; a very large value effectively disables auto-lock.
  /// The router consults this on every AppLifecycleState.paused.
  Future<int> autoLockSeconds() async {
    final raw = await _storage.read(key: _autoLockKey);
    return int.tryParse(raw ?? '') ?? defaultAutoLockSeconds;
  }

  Future<void> setAutoLockSeconds(int seconds) async {
    await _storage.write(key: _autoLockKey, value: '$seconds');
  }
}
