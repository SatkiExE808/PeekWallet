import 'package:flutter/material.dart';

import '../theme.dart';

/// Centralized "coin badge" — colored circle with the coin's
/// canonical text glyph. Replaces the off-brand Material icons we
/// were using before (Icons.bolt for SOL, Icons.diamond for ETH,
/// Icons.toll for LTC, etc.) with what users actually associate
/// with each coin.
///
/// Where Unicode has a recognizable symbol for a coin (₿ for BTC,
/// Ξ for ETH, Ł for LTC, ɱ for XMR) we use it. Coins without a
/// standard Unicode glyph (SOL, TRX, MATIC, BCH) get their ticker
/// letter on the brand color — same convention Trust Wallet and
/// Phantom use.
///
/// Sizing: [radius] controls the circle (Material default 18). The
/// glyph autoscales to ~80% of the diameter so the letter feels
/// substantial without crowding the edge.
Widget coinAvatar(String coinId, {double radius = 18}) {
  final spec = _spec(coinId);
  return CircleAvatar(
    radius: radius,
    backgroundColor: spec.color,
    child: Text(
      spec.glyph,
      style: TextStyle(
        color: Colors.white,
        fontSize: radius * spec.fontFactor,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    ),
  );
}

/// Color the coin uses elsewhere (subtitles, balance row, etc.).
/// Exposed so callers that build a CircleAvatar with a different
/// shape can still stay on-brand.
Color coinColor(String coinId) => _spec(coinId).color;

_CoinSpec _spec(String coinId) {
  switch (coinId) {
    case 'BTC':
      return const _CoinSpec(glyph: '₿', color: Color(0xFFF7931A));
    case 'ETH':
      return const _CoinSpec(glyph: 'Ξ', color: Color(0xFF627EEA));
    case 'LTC':
      return const _CoinSpec(glyph: 'Ł', color: Color(0xFF345D9D));
    case 'BCH':
      // BCH shares the ₿ symbol with BTC by convention; the green
      // color is what disambiguates the two visually.
      return const _CoinSpec(glyph: '₿', color: Color(0xFF0AC18E));
    case 'XMR':
      return const _CoinSpec(glyph: 'ɱ', color: Color(0xFFFF6600));
    case 'SOL':
      // Solana has no Unicode glyph; the ticker letter on the brand
      // purple gradient is the standard wallet-UI treatment.
      return const _CoinSpec(
          glyph: 'S', color: Color(0xFF9945FF), fontFactor: 0.75);
    case 'TRX':
      return const _CoinSpec(
          glyph: 'T', color: Color(0xFFEB0029), fontFactor: 0.75);
    case 'MATIC':
      return const _CoinSpec(
          glyph: 'M', color: Color(0xFF8247E5), fontFactor: 0.75);
    default:
      // Unknown coin id — fall back to a neutral chip with the
      // first character of whatever id was passed in.
      return _CoinSpec(
        glyph: coinId.isEmpty ? '?' : coinId.substring(0, 1),
        color: PeekColors.text3,
        fontFactor: 0.7,
      );
  }
}

class _CoinSpec {
  const _CoinSpec({
    required this.glyph,
    required this.color,
    this.fontFactor = 0.95,
  });
  final String glyph;
  final Color color;
  /// Multiplier on radius to compute glyph fontSize. Unicode coin
  /// symbols (₿, Ξ, Ł, ɱ) render at ~0.95×; plain letters get a
  /// slightly smaller treatment (0.75×) because they look too
  /// chunky at the same scale.
  final double fontFactor;
}
