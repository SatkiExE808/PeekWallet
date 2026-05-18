import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_windowmanager_plus/flutter_windowmanager_plus.dart';

/// Drop this widget around any screen that shows recovery-phrase /
/// private-key / send-confirm material. While the widget is mounted,
/// FLAG_SECURE is applied on Android — the OS recents thumbnail goes
/// black, screenshots from other apps return no data, and screen
/// mirroring (e.g., to a Chromecast) blanks the protected view.
///
/// On iOS the same protection comes from a separate blur-on-inactive
/// treatment (handled by an AppLifecycleState observer that the
/// MaterialApp installs); we leave a hook here for symmetry.
///
/// Cleanly re-enables capture in [dispose] so other (non-sensitive)
/// screens behave normally.
class ScreenshotGuard extends StatefulWidget {
  const ScreenshotGuard({super.key, required this.child});
  final Widget child;

  @override
  State<ScreenshotGuard> createState() => _ScreenshotGuardState();
}

class _ScreenshotGuardState extends State<ScreenshotGuard> {
  /// Cache the last-applied flag state so we can no-op redundant calls
  /// when a guard nests inside another guard (e.g., reveal-seed sheet
  /// over an already-guarded screen).
  static bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _apply();
  }

  Future<void> _apply() async {
    if (!Platform.isAndroid) return;
    if (_enabled) return;
    try {
      await FlutterWindowManagerPlus.addFlags(
          FlutterWindowManagerPlus.FLAG_SECURE);
      _enabled = true;
    } catch (_) {
      // Plugin not available on this build target — fail open.
      // Better to leave the user with no screenshot block than to
      // crash on a sensitive screen.
    }
  }

  Future<void> _clear() async {
    if (!Platform.isAndroid) return;
    if (!_enabled) return;
    try {
      await FlutterWindowManagerPlus.clearFlags(
          FlutterWindowManagerPlus.FLAG_SECURE);
      _enabled = false;
    } catch (_) {/* best effort */}
  }

  @override
  void dispose() {
    // Schedule the clear after the build pop animation so the
    // outgoing screen doesn't visibly desensitize mid-transition.
    unawaited(Future<void>.delayed(
      const Duration(milliseconds: 250),
      _clear,
    ));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
