import 'dart:async';

import 'package:flutter/services.dart';

/// Drop-in for `Clipboard.setData(...)` when the copied value is
/// sensitive (seed phrases, private keys, recipient addresses).
///
/// After the configured TTL, replaces the clipboard contents with an
/// empty string — but **only** if our value is still the most-recent
/// thing in the clipboard. If the user copied something else in the
/// meantime, we leave their selection alone.
///
/// Rationale: every modern mobile OS exposes the clipboard to every
/// running app. Ad SDKs read it for "paste-detection" tracking, system
/// overlays surface URLs, Android 12+ shows a clipboard toast on every
/// paste. Holding 12 words in the clipboard indefinitely is a
/// material data leak.
class SensitiveClipboard {
  SensitiveClipboard._();

  /// How long sensitive material may sit in the clipboard before we
  /// clear it. 30 s gives the user time to paste into another app
  /// but limits exposure to passive-collector apps.
  static const Duration ttl = Duration(seconds: 30);

  /// Active timers, keyed by the value they'll clear. Multiple copies
  /// in close succession overwrite each other naturally.
  static final Map<String, Timer> _pending = {};

  /// Copy [value] to the clipboard and schedule it to be wiped after
  /// [ttl]. Returns once the OS clipboard has accepted the new value.
  ///
  /// [label] is informational — surfaced in logs only, not displayed
  /// to the user. Use it to distinguish "seed" / "spend key" / etc.
  /// in crash diagnostics so the kind of leak is debuggable without
  /// the value itself being recorded.
  static Future<void> copy(String value, {String label = 'sensitive'}) async {
    await Clipboard.setData(ClipboardData(text: value));

    // Cancel any prior timer for the same value — re-copies extend the
    // window rather than firing two clears.
    _pending.remove(value)?.cancel();

    _pending[value] = Timer(ttl, () async {
      _pending.remove(value);
      try {
        final current = await Clipboard.getData(Clipboard.kTextPlain);
        // Only wipe if our value is still there. The user may have
        // copied something else in the meantime; respect that.
        if (current?.text == value) {
          await Clipboard.setData(const ClipboardData(text: ''));
        }
      } catch (_) {
        // Clipboard read can fail on some Android versions when the
        // app isn't foreground. Fall back to an unconditional clear
        // — better to over-clear than to leave a seed sitting there.
        try {
          await Clipboard.setData(const ClipboardData(text: ''));
        } catch (_) {/* give up silently */}
      }
    });
  }

  /// Cancel all pending auto-clears. Called from VaultState.lock so
  /// no orphan timer fires after the seed material is gone.
  static void cancelAll() {
    for (final t in _pending.values) {
      t.cancel();
    }
    _pending.clear();
  }
}
