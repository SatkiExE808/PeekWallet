import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme.dart';

/// Per-coin avatar — the actual CoinGecko logo, loaded from the same
/// CDN the price feed pulls from (assets.coingecko.com). The first
/// fetch is cached on disk by `cached_network_image`, so subsequent
/// renders are local even when offline.
///
/// Offline / failure path: errorWidget falls back to the bundled SVG
/// approximation under `assets/coins/`. So a freshly-installed app
/// with no network still shows a reasonable mark, and a long-running
/// install with prior cache is unaffected by transient CDN issues.
Widget coinAvatar(String coinId, {double radius = 18}) {
  final cgUrl = _coingeckoUrlFor(coinId);
  final svgAsset = _assetFor(coinId);
  final diameter = radius * 2;

  if (cgUrl == null && svgAsset == null) {
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

  return SizedBox(
    width: diameter,
    height: diameter,
    child: ClipOval(
      child: cgUrl != null
          ? CachedNetworkImage(
              imageUrl: cgUrl,
              width: diameter,
              height: diameter,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 120),
              placeholder: (_, _) =>
                  _svgOrPlaceholder(svgAsset, diameter, coinId),
              errorWidget: (_, _, _) =>
                  _svgOrPlaceholder(svgAsset, diameter, coinId),
            )
          : _svgOrPlaceholder(svgAsset, diameter, coinId),
    ),
  );
}

Widget _svgOrPlaceholder(String? svgAsset, double diameter, String coinId) {
  if (svgAsset != null) {
    return SvgPicture.asset(
      svgAsset,
      width: diameter,
      height: diameter,
      fit: BoxFit.cover,
    );
  }
  final ch = coinId.isEmpty ? '?' : coinId.substring(0, 1);
  return Container(
    width: diameter,
    height: diameter,
    color: PeekColors.text3,
    alignment: Alignment.center,
    child: Text(ch,
        style: TextStyle(
            color: Colors.white,
            fontSize: diameter * 0.42,
            fontWeight: FontWeight.w700)),
  );
}

/// The color the coin uses elsewhere (subtitle accents, etc.). Picked
/// to match each project's brand so the rest of the UI stays on-brand
/// even when only the symbol is rendered.
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

/// CoinGecko's canonical CDN image URLs for each supported coin.
/// These are the same `large` (200×200) PNG variants that the
/// CoinGecko website itself serves — the IDs are stable and have
/// been used for years.
String? _coingeckoUrlFor(String coinId) {
  switch (coinId) {
    case 'BTC':
      return 'https://assets.coingecko.com/coins/images/1/large/bitcoin.png';
    case 'ETH':
      return 'https://assets.coingecko.com/coins/images/279/large/ethereum.png';
    case 'LTC':
      return 'https://assets.coingecko.com/coins/images/2/large/litecoin.png';
    case 'BCH':
      return 'https://assets.coingecko.com/coins/images/780/large/bitcoin-cash-circle.png';
    case 'XMR':
      return 'https://assets.coingecko.com/coins/images/69/large/monero_logo.png';
    case 'SOL':
      return 'https://assets.coingecko.com/coins/images/4128/large/solana.png';
    case 'TRX':
      return 'https://assets.coingecko.com/coins/images/1094/large/tron-logo.png';
    case 'MATIC':
      return 'https://assets.coingecko.com/coins/images/4713/large/polygon-matic-logo.png';
    default:
      return null;
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
