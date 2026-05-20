import 'package:flutter/material.dart';

/// Color tokens. Dark, low-contrast surfaces with an orange accent.
/// Most surfaces sit between bg (deepest) and surface3 (highest) so
/// elevation reads as a faint lift rather than a heavy shadow — the
/// "premium dark" look used by Phantom, Cake, Exodus, etc.
class PeekColors {
  PeekColors._();

  static const bg = Color(0xFF07090E);
  static const bg2 = Color(0xFF0C0F16);
  static const surface = Color(0xFF161B27);
  static const surface2 = Color(0xFF1E2331);
  static const surface3 = Color(0xFF2A3043);
  static const border = Color(0xFF252B3C);
  static const border2 = Color(0xFF353B4F);
  static const hairline = Color(0x14FFFFFF); // 8% white — premium dividers

  static const accent = Color(0xFFF97316);
  static const accent2 = Color(0xFFFB923C);
  static const accent3 = Color(0xFFFDBA74);
  static const accentMuted = Color(0x33F97316); // 20% accent, hover/active

  static const text = Color(0xFFF1F3F7);
  static const text2 = Color(0xFFA3AABB);
  static const text3 = Color(0xFF6B7286);
  static const textMute = Color(0xFF4B5266);

  static const green = Color(0xFF22C55E);
  static const greenSoft = Color(0x3322C55E);
  static const red = Color(0xFFEF4444);
  static const redSoft = Color(0x33EF4444);

  /// Per-coin brand-accent colors. Used for the left-edge stripe on
  /// wallet cards + the soft ring around coin avatars so the user
  /// can tell coins apart at a glance — Exodus / Tangem / Phantom
  /// all lean on this for visual hierarchy.
  ///
  /// Falls back to [accent] when the coin id isn't recognised. The
  /// values match each chain's canonical brand color where possible
  /// (BTC orange, ETH iris, SOL purple, etc.); for stablecoins we
  /// blend with the host chain so USDT-on-TRC20 reads as a USDT row,
  /// not a TRX row.
  static Color coinAccent(String coinId) {
    switch (coinId.toUpperCase()) {
      case 'BTC':
        return const Color(0xFFF7931A); // Bitcoin orange
      case 'LTC':
        return const Color(0xFF345D9D); // Litecoin steel blue
      case 'BCH':
        return const Color(0xFF0AC18E); // Bitcoin Cash green
      case 'ETH':
        return const Color(0xFF627EEA); // Ethereum iris
      case 'POL':
      case 'MATIC':
        return const Color(0xFF8247E5); // Polygon purple
      case 'SOL':
        return const Color(0xFF9945FF); // Solana neon purple
      case 'TRX':
        return const Color(0xFFFF060A); // Tron red
      case 'XMR':
        return const Color(0xFFFF6600); // Monero orange
      case 'USDT':
        return const Color(0xFF26A17B); // Tether green
      case 'USDC':
        return const Color(0xFF2775CA); // USDC blue
      case 'DAI':
        return const Color(0xFFF5AC37); // DAI yellow
      default:
        return accent;
    }
  }
}

/// Design tokens — radii, spacing, motion, shadows. Use these instead
/// of magic numbers so the visual language stays consistent and a
/// future restyle is one file away.
class PeekDesign {
  PeekDesign._();

  // Corner radii. Larger than Material defaults — feels softer and
  // more contemporary, in line with Phantom / Trust / Exodus.
  static const rCard = 18.0;
  static const rButton = 14.0;
  static const rInput = 14.0;
  static const rPill = 999.0;
  static const rSmall = 10.0;
  static const rHero = 24.0;

  static BorderRadius get brCard => BorderRadius.circular(rCard);
  static BorderRadius get brButton => BorderRadius.circular(rButton);
  static BorderRadius get brInput => BorderRadius.circular(rInput);
  static BorderRadius get brPill => BorderRadius.circular(rPill);
  static BorderRadius get brSmall => BorderRadius.circular(rSmall);
  static BorderRadius get brHero => BorderRadius.circular(rHero);

  // Spacing scale — multiples of 4 keep vertical rhythm clean.
  static const sp1 = 4.0;
  static const sp2 = 8.0;
  static const sp3 = 12.0;
  static const sp4 = 16.0;
  static const sp5 = 20.0;
  static const sp6 = 24.0;
  static const sp8 = 32.0;
  static const sp10 = 40.0;

  // Motion. Short, soft curves. Used for fade-in on balance reveal,
  // tap feedback, bottom-sheet entry.
  static const tFast = Duration(milliseconds: 140);
  static const tMed = Duration(milliseconds: 220);
  static const tSlow = Duration(milliseconds: 360);
  static const easeOut = Curves.easeOutCubic;

  // Subtle elevation via shadow. Dark UIs work better with a soft
  // glow at the same hue as the accent than a hard drop-shadow.
  static List<BoxShadow> get cardShadow => [
        const BoxShadow(
          color: Color(0x33000000),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get heroGlow => [
        BoxShadow(
          color: PeekColors.accent.withAlpha(40),
          blurRadius: 32,
          spreadRadius: -8,
          offset: const Offset(0, 12),
        ),
      ];

  /// Hairline 1px border that reads as a refined edge on dark surfaces.
  static Border get hairlineBorder =>
      Border.all(color: PeekColors.hairline, width: 1);

  /// The accent gradient — used on the portfolio hero card and the
  /// primary CTA when we want it to feel premium.
  static LinearGradient get accentGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF97316), Color(0xFFFB923C), Color(0xFFFFA94D)],
      );

  /// The surface gradient — used on cards that want a faint sheen
  /// without going all the way to a colored accent.
  static LinearGradient get surfaceGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A1F2D), Color(0xFF161B27)],
      );
}

class PeekTheme {
  PeekTheme._();

  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: PeekColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: PeekColors.accent,
      secondary: PeekColors.accent2,
      surface: PeekColors.surface,
      onPrimary: Colors.white,
      onSurface: PeekColors.text,
      error: PeekColors.red,
    ),
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      // Headlines — heavier weight, tighter tracking on big numbers
      // so balances feel deliberate, not generic Material.
      displayLarge: TextStyle(
          color: PeekColors.text,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8),
      displayMedium: TextStyle(
          color: PeekColors.text,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6),
      headlineMedium: TextStyle(
          color: PeekColors.text,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3),
      titleLarge: TextStyle(
          color: PeekColors.text, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(
          color: PeekColors.text, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: PeekColors.text, height: 1.4),
      bodyMedium: TextStyle(color: PeekColors.text, height: 1.4),
      bodySmall: TextStyle(color: PeekColors.text2, height: 1.4),
      labelLarge: TextStyle(
          color: PeekColors.text, fontWeight: FontWeight.w600),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: PeekColors.bg,
      foregroundColor: PeekColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: PeekColors.text,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      iconTheme: IconThemeData(color: PeekColors.text2, size: 22),
    ),
    cardTheme: CardThemeData(
      color: PeekColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: PeekDesign.brCard,
        side: BorderSide(color: PeekColors.hairline, width: 1),
      ),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: PeekColors.text2,
      textColor: PeekColors.text,
      contentPadding:
          EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      minVerticalPadding: 8,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: PeekColors.bg2,
      selectedItemColor: PeekColors.accent,
      unselectedItemColor: PeekColors.text3,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: PeekColors.accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: PeekColors.surface2,
        disabledForegroundColor: PeekColors.text3,
        padding: const EdgeInsets.symmetric(
            vertical: PeekDesign.sp4, horizontal: PeekDesign.sp5),
        shape: RoundedRectangleBorder(borderRadius: PeekDesign.brButton),
        textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: PeekColors.text,
        side: const BorderSide(color: PeekColors.border2, width: 1),
        padding: const EdgeInsets.symmetric(
            vertical: PeekDesign.sp3, horizontal: PeekDesign.sp5),
        shape: RoundedRectangleBorder(borderRadius: PeekDesign.brButton),
        textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: PeekColors.accent,
        padding: const EdgeInsets.symmetric(
            vertical: PeekDesign.sp2, horizontal: PeekDesign.sp3),
        textStyle: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: PeekColors.text2,
        shape: const CircleBorder(),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: PeekColors.surface2,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: PeekDesign.sp4, vertical: PeekDesign.sp4),
      border: OutlineInputBorder(
        borderRadius: PeekDesign.brInput,
        borderSide: const BorderSide(color: PeekColors.border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: PeekDesign.brInput,
        borderSide: const BorderSide(color: PeekColors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: PeekDesign.brInput,
        borderSide: const BorderSide(color: PeekColors.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: PeekDesign.brInput,
        borderSide: const BorderSide(color: PeekColors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: PeekDesign.brInput,
        borderSide: const BorderSide(color: PeekColors.red, width: 1.5),
      ),
      hintStyle: const TextStyle(color: PeekColors.text3),
      labelStyle: const TextStyle(color: PeekColors.text2),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: PeekColors.surface3,
      contentTextStyle: const TextStyle(color: PeekColors.text),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: PeekDesign.brButton),
      elevation: 0,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: PeekColors.bg2,
      elevation: 0,
      modalBackgroundColor: PeekColors.bg2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: PeekColors.bg2,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: PeekDesign.brHero),
      titleTextStyle: const TextStyle(
          color: PeekColors.text,
          fontSize: 17,
          fontWeight: FontWeight.w600),
      contentTextStyle:
          const TextStyle(color: PeekColors.text2, height: 1.4),
    ),
    dividerTheme: const DividerThemeData(
      color: PeekColors.hairline,
      thickness: 1,
      space: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: PeekColors.surface2,
      labelStyle: const TextStyle(color: PeekColors.text2, fontSize: 12),
      shape: RoundedRectangleBorder(borderRadius: PeekDesign.brPill),
      side: const BorderSide(color: PeekColors.border),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: PeekColors.accent,
      linearTrackColor: PeekColors.surface2,
    ),
    splashColor: PeekColors.accentMuted,
    highlightColor: PeekColors.accentMuted,
  );
}
