import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Frosted-glass backdrop for bottom sheets. Sits behind the sheet's
/// content and blurs whatever the underlying screen is showing, then
/// overlays a translucent surface color so the sheet still reads as
/// a distinct UI layer.
///
/// Used by [showReceiveSheet], [showTxDetailSheet], and any other
/// premium modal that wants the "looking through a frosted window"
/// effect Apple's UIKit popovers + Tangem / Phantom bottom sheets
/// use. The blur sigma + tint alpha are tuned so the underlying
/// content is recognisable as background (you can see the shape of
/// the hero you came from) without competing for attention.
///
/// Call [showFrostedBottomSheet] instead of `showModalBottomSheet`
/// directly so every sheet picks up the same treatment.
Future<T?> showFrostedBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: Colors.black.withAlpha(110),
    builder: (ctx) => _FrostedSheetShell(child: builder(ctx)),
  );
}

class _FrostedSheetShell extends StatelessWidget {
  const _FrostedSheetShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            // Translucent surface — lets the blur show through but
            // still gives the sheet a body. Border at the top reads
            // as a refined edge against the blurred background.
            color: PeekColors.bg2.withAlpha(220),
            border: Border(
              top: BorderSide(color: Colors.white.withAlpha(20), width: 1),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
