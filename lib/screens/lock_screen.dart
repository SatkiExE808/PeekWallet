import 'dart:async';

import 'package:flutter/material.dart';

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
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) async {
        if (!mounted) return;
        if (DateTime.now().toUtc().isAfter(until)) {
          await _checkLockout();
        } else {
          // Cheap repaint so the countdown ticks.
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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.lock_outline, size: 56, color: PeekColors.accent),
              const SizedBox(height: 20),
              const Text(
                'PeekWallet',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your password to unlock.',
                textAlign: TextAlign.center,
                style: TextStyle(color: PeekColors.text2, fontSize: 14),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _pwd,
                obscureText: true,
                autofocus: !lockedOut,
                enabled: !lockedOut,
                onSubmitted: (_) => _unlock(),
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              if (lockedOut) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x33EF4444),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0x66EF4444)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Too many failed attempts',
                        style: TextStyle(
                            color: PeekColors.text,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Try again in ${_countdown(_lockoutUntil!)}.',
                        style: const TextStyle(
                            color: PeekColors.text2, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Locking your phone or restarting the app won\'t '
                        'reset the timer — this is intentional.',
                        style: TextStyle(color: PeekColors.text3, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ] else if (_err != null) ...[
                const SizedBox(height: 8),
                Text(_err!,
                    style:
                        const TextStyle(color: PeekColors.red, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: (_busy || lockedOut) ? null : _unlock,
                child: _busy
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Unlock'),
              ),
              if (_biometricEnabled && !lockedOut) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed:
                      _busy ? null : () => VaultState.I.unlockBiometric(),
                  icon: const Icon(Icons.fingerprint, size: 18),
                  label: const Text('Use biometric'),
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
