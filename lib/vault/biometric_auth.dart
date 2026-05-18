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
      // local_auth 3.x: options are direct named params on authenticate,
      // not wrapped in AuthenticationOptions. biometricOnly: true so the
      // device PIN can't unlock the wallet (would silently downgrade
      // the security model — user falls back to typing the password
      // instead). persistAcrossBackgrounding so the prompt survives
      // the user briefly switching apps.
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException {
      return false;
    }
  }
}
