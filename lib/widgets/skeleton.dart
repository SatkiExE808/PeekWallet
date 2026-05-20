import 'package:flutter/material.dart';

import '../theme.dart';

/// Pulsing-rectangle loading placeholder. Replaces the generic
/// [CircularProgressIndicator] in places where the eventual content
/// is a row / card so the layout doesn't jump when real data lands.
///
/// Tangem, Cake Wallet, Exodus all use this pattern: the screen
/// renders the same boxes that will eventually hold content, in a
/// muted gray, with a soft pulse so the user knows something is
/// loading. Much more premium than a spinner that says "wait".
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  /// Width in logical pixels. Pass `double.infinity` for a row-wide
  /// placeholder inside a flex parent.
  final double width;
  final double height;

  /// Defaults to [PeekDesign.brSmall] (the same shape we use for
  /// rounded chips + small status pills) so the loader looks like
  /// the content it stands in for.
  final BorderRadius? borderRadius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(
            PeekColors.surface2,
            PeekColors.surface3,
            _ctrl.value,
          ),
          borderRadius: widget.borderRadius ?? PeekDesign.brSmall,
        ),
      ),
    );
  }
}

/// Skeleton mock of a [_WalletRow] in [WalletsScreen]. Used as the
/// cold-load placeholder so the wallets list shimmers a sensible
/// shape (avatar + two text lines + trailing value) instead of
/// showing a centered spinner that gives no hint of layout.
class WalletRowSkeleton extends StatelessWidget {
  const WalletRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: PeekDesign.brCard,
        border: Border.all(color: PeekColors.hairline, width: 1),
        color: PeekColors.surface,
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: PeekDesign.sp4, vertical: PeekDesign.sp3),
      child: Row(
        children: [
          const Skeleton(width: 44, height: 44, borderRadius: null),
          const SizedBox(width: PeekDesign.sp4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Skeleton(
                    width: 120, height: 14, borderRadius: PeekDesign.brPill),
                const SizedBox(height: 8),
                Skeleton(
                    width: 80, height: 12, borderRadius: PeekDesign.brPill),
              ],
            ),
          ),
          const SizedBox(width: PeekDesign.sp3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Skeleton(width: 60, height: 14, borderRadius: PeekDesign.brPill),
              const SizedBox(height: 8),
              Skeleton(width: 30, height: 10, borderRadius: PeekDesign.brPill),
            ],
          ),
        ],
      ),
    );
  }
}
