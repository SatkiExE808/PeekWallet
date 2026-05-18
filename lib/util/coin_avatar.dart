import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme.dart';

/// Per-coin avatar — proper SVG logos bundled under assets/coins/.
/// Replaces the earlier Material-icon + Unicode-glyph approach with
/// recognizable approximations of each project's official mark.
///
/// Each SVG is sized to a 64×64 viewBox; rendering at any radius
/// scales cleanly. Background colors are baked into the SVG itself
/// so an opaque circular widget like CircleAvatar isn't strictly
/// needed — but we still wrap with `ClipOval` so users on devices
/// without ClipPath antialiasing get a clean edge.
Widget coinAvatar(String coinId, {double radius = 18}) {
  final asset = _assetFor(coinId);
  if (asset == null) {
    // Unknown coin — neutral fallback with the first character.
    final ch = coinId.isEmpty ? '?' : coinId.substring(0, 1);
    return CircleAvatar(
      radius: radius,
      backgroundColor: PeekColors.text3,
      child: Text(ch,
          style: TextStyle(
              color: Colors.white,
              fontSize: radius * 0.85,
              fontWeight: FontWeight.w700)),
    );
  }
  final diameter = radius * 2;
  return SizedBox(
    width: diameter,
    height: diameter,
    child: ClipOval(
      child: SvgPicture.asset(
        asset,
        width: diameter,
        height: diameter,
        fit: BoxFit.cover,
      ),
    ),
  );
}

/// The color the coin uses elsewhere (subtitle accents, etc.). Kept
/// in sync with the background fill in each SVG so the rest of the
/// UI stays on-brand even when the SVG itself isn't visible.
Color coinColor(String coinId) {
  switch (coinId) {
    case 'BTC':
      return const Color(0xFFF7931A);
    case 'ETH':
      return const Color(0xFF627EEA);
    case 'LTC':
      return const Color(0xFF345D9D);
    case 'BCH':
      return const Color(0xFF0AC18E);
    case 'XMR':
      return const Color(0xFFFF6600);
    case 'SOL':
      return const Color(0xFF9945FF);
    case 'TRX':
      return const Color(0xFFEB0029);
    case 'MATIC':
      return const Color(0xFF8247E5);
    default:
      return PeekColors.text3;
  }
}

String? _assetFor(String coinId) {
  switch (coinId) {
    case 'BTC':
      return 'assets/coins/btc.svg';
    case 'ETH':
      return 'assets/coins/eth.svg';
    case 'LTC':
      return 'assets/coins/ltc.svg';
    case 'BCH':
      return 'assets/coins/bch.svg';
    case 'XMR':
      return 'assets/coins/xmr.svg';
    case 'SOL':
      return 'assets/coins/sol.svg';
    case 'TRX':
      return 'assets/coins/trx.svg';
    case 'MATIC':
      return 'assets/coins/matic.svg';
    default:
      return null;
  }
}
