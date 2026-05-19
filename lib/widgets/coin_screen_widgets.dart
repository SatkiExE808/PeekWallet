import 'package:flutter/material.dart';

import '../theme.dart';

/// Small accent pill — used for "cached" + error indicators under
/// the hero balance. Premium alternative to inline-red error text.
/// Auto-truncates long messages so multi-line errors stay tidy.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.text,
    required this.color,
    required this.icon,
  });

  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: PeekDesign.brPill,
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium Receive/Send action button. Pill-shaped, generous vertical
/// padding, primary (filled accent) vs secondary (outlined) variants.
/// Disabled state dims both background and label.
class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.primary,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    final bgColor = primary
        ? (isDisabled ? PeekColors.surface2 : PeekColors.accent)
        : PeekColors.surface2;
    final fgColor = primary
        ? (isDisabled ? PeekColors.text3 : Colors.white)
        : PeekColors.text;
    final borderColor =
        primary ? Colors.transparent : PeekColors.border2;
    return Material(
      color: bgColor,
      borderRadius: PeekDesign.brButton,
      child: InkWell(
        onTap: onTap,
        borderRadius: PeekDesign.brButton,
        splashColor: primary
            ? Colors.white.withAlpha(40)
            : PeekColors.accentMuted,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: PeekDesign.brButton,
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: fgColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: fgColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "No transactions yet" empty card for activity sections. Same
/// rounded surface as a tx row but with a centered icon + label so
/// the area doesn't feel empty.
class EmptyActivity extends StatelessWidget {
  const EmptyActivity({
    super.key,
    required this.loading,
    required this.coinLabel,
  });

  final bool loading;
  final String coinLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: PeekColors.surface.withAlpha(120),
        borderRadius: PeekDesign.brCard,
        border: Border.all(color: PeekColors.hairline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            loading ? Icons.hourglass_top_rounded : Icons.inbox_rounded,
            size: 28,
            color: PeekColors.text3,
          ),
          const SizedBox(height: 10),
          Text(
            loading ? 'Loading…' : 'No transactions yet',
            style: const TextStyle(
                color: PeekColors.text2,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          if (!loading) ...[
            const SizedBox(height: 4),
            Text(
              'Share your address to receive $coinLabel',
              style:
                  const TextStyle(color: PeekColors.text3, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

/// Section header — small caps label + optional trailing count chip.
/// Used above transaction lists, token lists, etc.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.countChip,
  });

  final String title;
  final String? countChip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
              color: PeekColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1),
        ),
        const SizedBox(width: 8),
        if (countChip != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: PeekColors.surface2,
              borderRadius: PeekDesign.brPill,
            ),
            child: Text(
              countChip!,
              style: const TextStyle(
                  color: PeekColors.text2,
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }
}
