import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../theme.dart';
import '../vault/vault_state.dart';
import '../vault/vault_storage.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _pwd = TextEditingController();
  String? _err;
  bool _busy = false;
  bool _biometricEnabled = false;

  /// Countdown state. _lockoutUntil is the absolute deadline; the
  /// _ticker re-renders every second so the displayed countdown
  /// drops. Null both → not currently locked out.
  DateTime? _lockoutUntil;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _maybeTryBiometric();
    _checkLockout();
  }

  @override
  void dispose() {
    _pwd.dispose();
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _maybeTryBiometric() async {
    final enabled = await VaultState.I.biometricEnabled();
    if (!mounted) return;
    setState(() => _biometricEnabled = enabled);
    if (!enabled) return;
    await VaultState.I.unlockBiometric();
  }

  Future<void> _checkLockout() async {
    final until = await VaultState.I.currentLockout();
    if (!mounted) return;
    if (until == null) {
      setState(() => _lockoutUntil = null);
      _ticker?.cancel();
      _ticker = null;
    } else {
      setState(() => _lockoutUntil = until);
      // Read from the field rather than the captured local — a new
      // lockout may extend the window after this Timer is wired, and
      // we want the existing ticker to honor the latest deadline
      // instead of expiring against the stale closure value.
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) async {
        if (!mounted) return;
        final deadline = _lockoutUntil;
        if (deadline == null) {
          await _checkLockout();
          return;
        }
        if (DateTime.now().toUtc().isAfter(deadline)) {
          await _checkLockout();
        } else {
          setState(() {});
        }
      });
    }
  }

  Future<void> _unlock() async {
    setState(() {
      _err = null;
      _busy = true;
    });
    try {
      await VaultState.I.unlock(_pwd.text);
      // Routing handled by main.dart listening to VaultState.
    } on VaultLockoutError catch (e) {
      // Show countdown UI instead of the generic password error.
      setState(() {
        _err = null;
        _lockoutUntil = e.until;
        _busy = false;
        _pwd.clear();
      });
      _checkLockout();
    } catch (e) {
      final msg = e is VaultError ? e.message : e.toString();
      setState(() {
        _err = msg;
        _busy = false;
        _pwd.clear();
      });
      // Even on a non-lockout error, refresh the lockout state — the
      // 5th wrong guess flips us into a lockout immediately and the
      // user should see that.
      _checkLockout();
    }
  }

  String _countdown(DateTime until) {
    final remaining = until.difference(DateTime.now().toUtc());
    if (remaining.isNegative) return '0 s';
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    if (minutes <= 0) return '$seconds s';
    if (minutes < 60) return '${minutes}m ${seconds}s';
    final hours = remaining.inHours;
    return '${hours}h ${minutes % 60}m';
  }

  @override
  Widget build(BuildContext context) {
    final lockedOut = _lockoutUntil != null;
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: PeekDesign.sp6, vertical: PeekDesign.sp8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Soft accent glow behind the lock icon — same pattern
              // as the wallets-list empty state. Makes the splash
              // feel deliberate rather than blank-and-iconic.
              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    PeekColors.accent.withAlpha(54),
                    PeekColors.accent.withAlpha(0),
                  ]),
                ),
                child: Container(
                  width: 68,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: PeekColors.surface2,
                    border: Border.all(color: PeekColors.border),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    size: 32,
                    color: PeekColors.accent,
                  ),
                ),
              ),
              const SizedBox(height: PeekDesign.sp5),
              Text(
                l.appName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5),
              ),
              const SizedBox(height: 6),
              Text(
                l.lockScreenSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: PeekColors.text2, fontSize: 13),
              ),
              const SizedBox(height: PeekDesign.sp8),
              TextField(
                controller: _pwd,
                obscureText: true,
                autofocus: !lockedOut,
                enabled: !lockedOut,
                onSubmitted: (_) => _unlock(),
                decoration: InputDecoration(
                  hintText: l.lockPasswordHint,
                  prefixIcon: Icon(
                    Icons.password_rounded,
                    size: 18,
                    color: lockedOut ? PeekColors.text3 : PeekColors.text2,
                  ),
                ),
              ),
              if (lockedOut) ...[
                const SizedBox(height: PeekDesign.sp3),
                Container(
                  padding: const EdgeInsets.all(PeekDesign.sp4),
                  decoration: BoxDecoration(
                    color: PeekColors.red.withAlpha(28),
                    borderRadius: PeekDesign.brCard,
                    border: Border.all(color: PeekColors.red.withAlpha(72)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.timer_off_rounded,
                              size: 16, color: PeekColors.red),
                          const SizedBox(width: 8),
                          Text(
                            l.lockTooManyAttempts,
                            style: const TextStyle(
                                color: PeekColors.text,
                                fontWeight: FontWeight.w600,
                                fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Try again in ${_countdown(_lockoutUntil!)}.',
                        style: const TextStyle(
                            color: PeekColors.text2, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.lockTimerWarning,
                        style: const TextStyle(
                            color: PeekColors.text3, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ] else if (_err != null) ...[
                const SizedBox(height: PeekDesign.sp2),
                Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 14, color: PeekColors.red),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _err!,
                        style: const TextStyle(
                            color: PeekColors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: PeekDesign.sp4),
              Material(
                color: (_busy || lockedOut)
                    ? PeekColors.surface2
                    : PeekColors.accent,
                borderRadius: PeekDesign.brButton,
                child: InkWell(
                  onTap: (_busy || lockedOut) ? null : _unlock,
                  borderRadius: PeekDesign.brButton,
                  splashColor: Colors.white.withAlpha(40),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            l.lockUnlock,
                            style: TextStyle(
                              color: (_busy || lockedOut)
                                  ? PeekColors.text3
                                  : Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                            ),
                          ),
                  ),
                ),
              ),
              if (_biometricEnabled && !lockedOut) ...[
                const SizedBox(height: PeekDesign.sp3),
                OutlinedButton.icon(
                  onPressed:
                      _busy ? null : () => VaultState.I.unlockBiometric(),
                  icon: const Icon(Icons.fingerprint_rounded, size: 20),
                  label: Text(l.lockUseBiometric),
                ),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
