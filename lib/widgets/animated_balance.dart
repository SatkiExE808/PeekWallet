import 'package:flutter/material.dart';

import '../theme.dart';

/// Animated balance number. When the [amount] changes, tweens
/// smoothly from the old value to the new one over [duration],
/// then renders via [formatter] into a styled [Text].
///
/// The point is the same effect Exodus / Tangem use on their
/// portfolio totals: instead of the number snapping (which feels
/// twitchy + cheap), the value rolls so the user can see the change
/// without having to mentally diff two snapshots.
///
/// Pass the same TextStyle you'd use for a plain Text so the
/// surrounding hero layout stays identical.
class AnimatedBalance extends StatelessWidget {
  const AnimatedBalance({
    super.key,
    required this.amount,
    required this.formatter,
    required this.style,
    this.duration = PeekDesign.tSlow,
    this.curve = Curves.easeOutCubic,
  });

  /// Current value to render. When this changes the widget tweens
  /// from the previous frame's value to here.
  final double amount;

  /// Formats the in-flight (tweened) value into display text. Receives
  /// the lerped double, returns whatever string the screen wants —
  /// `'${v.toStringAsFixed(8)} BTC'` for native balance, `'\$${v.toStringAsFixed(2)}'`
  /// for fiat, etc.
  final String Function(double value) formatter;

  /// Text style applied to the rendered number. Match the hero's
  /// existing style so the animation slots in without layout change.
  final TextStyle style;

  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: amount),
      duration: duration,
      curve: curve,
      builder: (_, value, _) => Text(formatter(value), style: style),
    );
  }
}
