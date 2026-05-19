import 'package:flutter/material.dart';

import '../theme.dart';

/// Red warning banner shown at the top of every send screen.
/// Single source of truth instead of a per-screen `_ExperimentalBanner`
/// class with slightly drifting wording.
class ExperimentalBanner extends StatelessWidget {
  const ExperimentalBanner({super.key, required this.body});

  /// Chain-specific tail text — e.g. "send is BIP-0143 spec-vector
  /// tested but has not been audited end-to-end".
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PeekDesign.sp3),
      decoration: BoxDecoration(
        color: PeekColors.red.withAlpha(28),
        border: Border.all(color: PeekColors.red.withAlpha(96)),
        borderRadius: PeekDesign.brCard,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: PeekColors.red.withAlpha(40),
              borderRadius: PeekDesign.brSmall,
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: PeekColors.red, size: 18),
          ),
          const SizedBox(width: PeekDesign.sp3),
          Expanded(
            child: Text(
              'Experimental — $body Test with small amounts first.',
              style: const TextStyle(
                  color: PeekColors.text, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact error tile used by the send screens' inline error
/// surfacing. Same red palette as ExperimentalBanner but tighter
/// padding because the text is usually one line.
class SendErrorTile extends StatelessWidget {
  const SendErrorTile({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PeekDesign.sp3),
      decoration: BoxDecoration(
        color: PeekColors.red.withAlpha(28),
        border: Border.all(color: PeekColors.red.withAlpha(96)),
        borderRadius: PeekDesign.brSmall,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: PeekColors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: PeekColors.red, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
