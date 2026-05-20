import 'dart:async';

import 'package:flutter/widgets.dart';

/// Mixin for [State] classes that run a `Timer.periodic` to poll for
/// blockchain data. Without this, every coin screen's 30-second poll
/// keeps firing while the app is backgrounded or screen-off, burning
/// the user's battery and quota on a balance they can't see.
///
/// Usage:
///
/// ```
/// class _BitcoinCoinScreenState extends State<BitcoinCoinScreen>
///     with LifecyclePoller {
///   @override
///   Duration get pollInterval => const Duration(seconds: 30);
///
///   @override
///   Future<void> onPollTick() => _refresh();
/// }
/// ```
///
/// The mixin handles initState/dispose plumbing, AppLifecycleState
/// observation, and immediate first-tick on init so behaviour matches
/// the old `Timer.periodic(... _refresh)` pattern. Implementers don't
/// touch the timer directly.
mixin LifecyclePoller<T extends StatefulWidget> on State<T> {
  Timer? _poll;
  AppLifecycleListener? _lifecycle;
  bool _everStarted = false;

  /// How often [onPollTick] should fire while the screen is visible.
  /// Return null to disable polling entirely.
  Duration? get pollInterval;

  /// Called on each tick while the app is foregrounded. Implementers
  /// usually delegate to their existing `_refresh()` method.
  Future<void> onPollTick();

  /// Begin polling. Idempotent. Fires [onPollTick] immediately so
  /// the screen lands with fresh data, then on every [pollInterval]
  /// until [stopPolling] is called or the State is disposed.
  void startPolling() {
    final iv = pollInterval;
    if (iv == null || _poll != null) return;
    _lifecycle ??= AppLifecycleListener(
      onPause: _onAppPaused,
      onHide: _onAppPaused,
      onInactive: _onAppPaused,
      onResume: _onAppResumed,
    );
    _everStarted = true;
    unawaited(onPollTick());
    _poll = Timer.periodic(iv, (_) => unawaited(onPollTick()));
  }

  /// Cancel the active timer. Called automatically on dispose. Safe
  /// to call multiple times.
  void stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  void _onAppPaused() {
    // Cancel the timer but keep _everStarted so we know to restart
    // on resume. Inactive fires while the OS is transitioning (e.g.
    // notification shade pull-down) — being conservative + cancelling
    // there too means a quick peek at the shade doesn't burn a poll
    // cycle.
    _poll?.cancel();
    _poll = null;
  }

  void _onAppResumed() {
    final iv = pollInterval;
    if (iv == null || _poll != null || !_everStarted || !mounted) return;
    unawaited(onPollTick());
    _poll = Timer.periodic(iv, (_) => unawaited(onPollTick()));
  }

  @override
  void dispose() {
    stopPolling();
    _lifecycle?.dispose();
    _lifecycle = null;
    super.dispose();
  }
}
