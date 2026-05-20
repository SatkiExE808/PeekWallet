import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/gen/app_localizations.dart';
import '../theme.dart';
import '../util/coin_avatar.dart';
import '../util/explorer_links.dart';
import 'frosted_sheet.dart';

/// One labelled key/value row in the tx-detail sheet (e.g. "Fee",
/// "Block height"). Status / amount rows have their own variants
/// below so we can color them differently.
class TxDetailRow {
  const TxDetailRow(this.label, this.value, {this.isAmount = false});
  final String label;
  final String value;
  /// Tweaks emphasis — `true` renders the value larger and tracks
  /// tighter, used for the "Net amount" row.
  final bool isAmount;
}

/// Premium tx-detail bottom sheet — drag handle, big "incoming /
/// outgoing" amount row with directional pill, key/value table, mono
/// hash box, copy + explorer actions. Every coin screen funnels its
/// transaction taps through this so they all look the same.
///
/// Pass [hashLabel] to control the box label ("Hash", "Signature",
/// "TX ID"). [hashValue] is the value shown + copied; [coinId] is
/// the coin used by explorerTxUrl + the snack-bar copy hint.
Future<void> showTxDetailSheet(
  BuildContext context, {
  required String coinId,
  required bool isIncoming,
  required String amountText,
  required Color amountColor,
  required List<TxDetailRow> rows,
  required String hashLabel,
  required String hashValue,
  String? statusText,
  Color? statusColor,
  IconData? statusIcon,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l = AppLocalizations.of(context);
  await showFrostedBottomSheet<void>(
    context: context,
    builder: (ctx) => _TxDetailBody(
      coinId: coinId,
      isIncoming: isIncoming,
      amountText: amountText,
      amountColor: amountColor,
      rows: rows,
      hashLabel: hashLabel,
      hashValue: hashValue,
      statusText: statusText,
      statusColor: statusColor,
      statusIcon: statusIcon,
      onCopied: () {
        messenger.showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle,
                size: 16, color: PeekColors.green),
            const SizedBox(width: 8),
            Text(l.txCopiedToClipboard),
          ]),
          duration: const Duration(seconds: 2),
        ));
      },
      onExplorerFailed: () {
        messenger.showSnackBar(SnackBar(
            content: Text(l.receiveCouldNotOpenBrowser)));
      },
    ),
  );
}

class _TxDetailBody extends StatelessWidget {
  const _TxDetailBody({
    required this.coinId,
    required this.isIncoming,
    required this.amountText,
    required this.amountColor,
    required this.rows,
    required this.hashLabel,
    required this.hashValue,
    required this.statusText,
    required this.statusColor,
    required this.statusIcon,
    required this.onCopied,
    required this.onExplorerFailed,
  });

  final String coinId;
  final bool isIncoming;
  final String amountText;
  final Color amountColor;
  final List<TxDetailRow> rows;
  final String hashLabel;
  final String hashValue;
  final String? statusText;
  final Color? statusColor;
  final IconData? statusIcon;
  final VoidCallback onCopied;
  final VoidCallback onExplorerFailed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: PeekColors.border2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: PeekDesign.sp5),
            // Direction header — coin avatar + "Incoming/Outgoing"
            // chip + amount line on the right. Replaces the old
            // centered "Incoming/Outgoing" Text + stack of kv rows.
            Row(
              children: [
                coinAvatar(coinId, radius: 18),
                const SizedBox(width: PeekDesign.sp3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isIncoming
                                  ? PeekColors.green
                                  : PeekColors.accent)
                              .withAlpha(36),
                          borderRadius: PeekDesign.brPill,
                          border: Border.all(
                            color: (isIncoming
                                    ? PeekColors.green
                                    : PeekColors.accent)
                                .withAlpha(96),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isIncoming
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
                              size: 12,
                              color: isIncoming
                                  ? PeekColors.green
                                  : PeekColors.accent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isIncoming
                                  ? l.txDirectionIncoming
                                  : l.txDirectionOutgoing,
                              style: TextStyle(
                                color: isIncoming
                                    ? PeekColors.green
                                    : PeekColors.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        amountText,
                        style: TextStyle(
                          color: amountColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (statusText != null) ...[
              const SizedBox(height: PeekDesign.sp4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (statusColor ?? PeekColors.text2).withAlpha(28),
                  borderRadius: PeekDesign.brPill,
                  border: Border.all(
                    color: (statusColor ?? PeekColors.text2).withAlpha(80),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      statusIcon ?? Icons.info_outline_rounded,
                      size: 13,
                      color: statusColor ?? PeekColors.text2,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        statusText!,
                        style: TextStyle(
                          color: statusColor ?? PeekColors.text2,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: PeekDesign.sp5),
            Container(
              decoration: BoxDecoration(
                color: PeekColors.surface,
                borderRadius: PeekDesign.brCard,
                border: Border.all(color: PeekColors.hairline),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: PeekDesign.sp4, vertical: PeekDesign.sp2),
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    _KvRow(row: rows[i]),
                    if (i < rows.length - 1)
                      const Divider(
                          height: 1, color: PeekColors.hairline),
                  ],
                ],
              ),
            ),
            const SizedBox(height: PeekDesign.sp4),
            Text(
              hashLabel.toUpperCase(),
              style: const TextStyle(
                  color: PeekColors.text3,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(PeekDesign.sp3),
              decoration: BoxDecoration(
                color: PeekColors.surface,
                borderRadius: PeekDesign.brSmall,
                border: Border.all(color: PeekColors.border),
              ),
              child: SelectableText(
                hashValue,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: PeekColors.text,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: PeekDesign.sp4),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                          ClipboardData(text: hashValue));
                      if (context.mounted) Navigator.of(context).pop();
                      onCopied();
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: Text(l.actionCopy),
                  ),
                ),
                const SizedBox(width: PeekDesign.sp2),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final url =
                          explorerTxUrl(coinId: coinId, txid: hashValue);
                      if (url == null) return;
                      final ok = await openExplorerUrl(url);
                      if (!ok) onExplorerFailed();
                    },
                    icon:
                        const Icon(Icons.open_in_new_rounded, size: 16),
                    label: Text(l.actionExplorer),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KvRow extends StatelessWidget {
  const _KvRow({required this.row});
  final TxDetailRow row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              row.label,
              style: const TextStyle(
                color: PeekColors.text3,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              row.value,
              style: TextStyle(
                color: PeekColors.text,
                fontSize: row.isAmount ? 14 : 13,
                fontWeight: row.isAmount ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: row.isAmount ? -0.1 : 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper: pretty timestamp format used by every coin's tx detail
/// row. Extracted here so each coin file doesn't need its own
/// _fmtDate copy.
String fmtTxDate(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)} '
      '${two(d.hour)}:${two(d.minute)}';
}
