import 'package:flutter/material.dart';

import '../theme.dart';

/// Premium settings-list row. Squared accent-tile icon, larger
/// vertical padding, title + subtitle stack, optional trailing
/// widget (defaults to a chevron). Used in place of ListTile so the
/// Settings page reads as a series of deliberate rows rather than
/// the stock Material list look.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconAccent = false,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  /// When true, the icon tile uses the accent palette instead of the
  /// neutral surface — for rows that nudge the user toward an action
  /// like "Restore all coins from vault seed".
  final bool iconAccent;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isDisabled = !enabled || onTap == null;
    final iconColor = iconAccent
        ? PeekColors.accent
        : (isDisabled ? PeekColors.text3 : PeekColors.text2);
    final tileColor = iconAccent
        ? PeekColors.accentMuted
        : PeekColors.surface2;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: PeekDesign.brSmall,
        splashColor: PeekColors.accentMuted,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 4, vertical: PeekDesign.sp3),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tileColor,
                  borderRadius: PeekDesign.brSmall,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: PeekDesign.sp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color:
                            isDisabled ? PeekColors.text3 : PeekColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: PeekColors.text3,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (onTap != null)
                const Icon(Icons.chevron_right,
                    color: PeekColors.text3, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

/// Variant for settings rows that toggle a boolean (biometric, log
/// retention, etc.). Same row shape but with a Switch on the right.
class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SettingsRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      enabled: onChanged != null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: PeekColors.accent,
        inactiveThumbColor: PeekColors.text3,
        inactiveTrackColor: PeekColors.surface3,
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      onTap: onChanged == null ? null : () => onChanged!(!value),
    );
  }
}
