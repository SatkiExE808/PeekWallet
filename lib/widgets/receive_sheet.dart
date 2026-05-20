import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/gen/app_localizations.dart';
import '../theme.dart';
import '../util/coin_avatar.dart';
import 'frosted_sheet.dart';

/// Shared, premium bottom sheet for "Receive [coin]". Used by every
/// coin screen so they all look the same — drag handle, coin chip,
/// large QR, mono address, copy + share actions, derivation hint.
///
/// Call via [showReceiveSheet] which wraps showModalBottomSheet with
/// our preferred shape and a scaffold messenger for the "Copied"
/// snackbar.
Future<void> showReceiveSheet(
  BuildContext context, {
  required String coinId,
  required String coinName,
  required String address,
  required String derivationHint,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l = AppLocalizations.of(context);
  await showFrostedBottomSheet<void>(
    context: context,
    builder: (ctx) => _ReceiveSheetBody(
      coinId: coinId,
      coinName: coinName,
      address: address,
      derivationHint: derivationHint,
      onCopied: () {
        messenger.showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, size: 16, color: PeekColors.green),
            const SizedBox(width: 8),
            Text(l.receiveAddressCopied),
          ]),
          duration: const Duration(seconds: 2),
        ));
      },
    ),
  );
}

class _ReceiveSheetBody extends StatelessWidget {
  const _ReceiveSheetBody({
    required this.coinId,
    required this.coinName,
    required this.address,
    required this.derivationHint,
    required this.onCopied,
  });

  final String coinId;
  final String coinName;
  final String address;
  final String derivationHint;
  final VoidCallback onCopied;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Builder(builder: (context) {
        final l = AppLocalizations.of(context);
        return Padding(
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
            Row(
              children: [
                coinAvatar(coinId, radius: 18),
                const SizedBox(width: PeekDesign.sp3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.receiveTitle(coinId),
                        style: const TextStyle(
                          color: PeekColors.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        coinName,
                        style: const TextStyle(
                            color: PeekColors.text3, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: PeekDesign.sp5),
            // QR card — white surface with a coin-tinted frame so
            // each chain's receive screen reads as its own. The
            // outer glow + inset border give the card weight against
            // the frosted sheet behind it.
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  // Subtle gradient frame around the white QR card —
                  // takes its colors from the coin's brand accent.
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      PeekColors.coinAccent(coinId).withAlpha(120),
                      PeekColors.coinAccent(coinId).withAlpha(40),
                    ],
                  ),
                  borderRadius: PeekDesign.brCard,
                  boxShadow: [
                    BoxShadow(
                      color: PeekColors.coinAccent(coinId).withAlpha(36),
                      blurRadius: 32,
                      spreadRadius: -4,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: PeekDesign.brCard,
                  ),
                  child: QrImageView(
                    data: address,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF0A0E18),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF0A0E18),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: PeekDesign.sp5),
            Text(
              l.receiveAddressLabel,
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
                address,
                style: const TextStyle(
                  fontSize: 13,
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
                  child: Material(
                    color: PeekColors.surface2,
                    borderRadius: PeekDesign.brButton,
                    child: InkWell(
                      borderRadius: PeekDesign.brButton,
                      onTap: () async {
                        await SharePlus.instance.share(
                          ShareParams(
                            text: address,
                            subject: '$coinId address',
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: PeekDesign.brButton,
                          border:
                              Border.all(color: PeekColors.border2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.ios_share_rounded,
                                size: 18, color: PeekColors.text),
                            const SizedBox(width: 8),
                            Text(
                              l.actionShare,
                              style: const TextStyle(
                                color: PeekColors.text,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: PeekDesign.sp3),
                Expanded(
                  child: Material(
                    color: PeekColors.accent,
                    borderRadius: PeekDesign.brButton,
                    child: InkWell(
                      borderRadius: PeekDesign.brButton,
                      onTap: () async {
                        await Clipboard.setData(
                            ClipboardData(text: address));
                        if (context.mounted) Navigator.of(context).pop();
                        onCopied();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.copy_rounded,
                                size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              l.actionCopy,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: PeekDesign.sp3),
            Container(
              padding: const EdgeInsets.all(PeekDesign.sp3),
              decoration: BoxDecoration(
                color: PeekColors.surface2,
                borderRadius: PeekDesign.brSmall,
                border: Border.all(color: PeekColors.hairline),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 14, color: PeekColors.text3),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      derivationHint,
                      style: const TextStyle(
                        color: PeekColors.text3,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        );
      }),
    );
  }
}
