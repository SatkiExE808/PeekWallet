import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Thin wrapper over `local_auth` so the rest of the app only touches
/// a single async API. Handles the platform-specific availability
/// edge cases (no enrolled biometric, OS lockout, hardware absent).
class BiometricAuth {
  BiometricAuth._();
  static final I = BiometricAuth._();

  final LocalAuthentication _auth = LocalAuthentication();

  /// True when the device has biometric hardware AND at least one
  /// enrollment (e.g. a registered fingerprint). False on stock
  /// emulators, devices with no fingerprint, or after the user wiped
  /// their biometric enrollments. Use this to decide whether to show
  /// the "Enable biometric unlock" toggle in Settings.
  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  /// Prompts the user. Returns true only on a successful auth. False
  /// covers cancel, lockout, hardware errors — caller falls back to
  /// password entry in all "false" cases.
  Future<bool> authenticate({String reason = 'Unlock PeekWallet'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          // Don't let the system PIN/pattern unlock the wallet —
          // that would silently downgrade the security model. If
          // biometric isn't available the user can fall back to
          // typing the password.
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
