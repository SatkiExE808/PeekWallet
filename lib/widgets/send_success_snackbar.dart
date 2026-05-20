import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Polished broadcast-success toast. Replaces the bare green
/// SnackBar that the send screens used to use after a successful
/// broadcast — that one was readable but didn't feel like a win.
///
/// This one comes in as a floating rounded card with a soft accent
/// glow, a green check, and the truncated tx ID in monospace so the
/// user gets an immediate "yes that broadcast" cue + a quick way to
/// confirm which tx they fired. Triggers a medium-impact haptic at
/// the moment of presentation — same tactile cue Tangem + Phantom
/// use to make a send feel "stamped".
void showSendSuccess(
  BuildContext context, {
  required String txid,
}) {
  HapticFeedback.mediumImpact();
  final messenger = ScaffoldMessenger.of(context);
  // Hide any earlier "broadcasting…" snack so the success replaces
  // it cleanly instead of stacking.
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.fromLTRB(
          PeekDesign.sp4, 0, PeekDesign.sp4, PeekDesign.sp4),
      duration: const Duration(seconds: 6),
      content: _SuccessCard(txid: txid),
    ),
  );
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.txid});
  final String txid;

  @override
  Widget build(BuildContext context) {
    final preview = txid.length >= 16
        ? '${txid.substring(0, 8)}…${txid.substring(txid.length - 6)}'
        : txid;
    return Container(
      padding: const EdgeInsets.fromLTRB(
          PeekDesign.sp4, PeekDesign.sp3, PeekDesign.sp4, PeekDesign.sp3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(PeekColors.surface, PeekColors.green, 0.10)!,
            PeekColors.surface,
          ],
        ),
        borderRadius: PeekDesign.brCard,
        border: Border.all(color: PeekColors.green.withAlpha(96), width: 1),
        boxShadow: [
          BoxShadow(
            color: PeekColors.green.withAlpha(48),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: PeekColors.green.withAlpha(40),
              border: Border.all(color: PeekColors.green.withAlpha(96)),
            ),
            child: const Icon(Icons.check_rounded,
                color: PeekColors.green, size: 20),
          ),
          const SizedBox(width: PeekDesign.sp3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Broadcast sent',
                  style: TextStyle(
                    color: PeekColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  preview,
                  style: const TextStyle(
                    color: PeekColors.text2,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
