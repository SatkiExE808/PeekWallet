import 'package:flutter/material.dart';

/// Color tokens lifted from vault-wallet/css/style.css. Keeping the
/// names in lockstep with the web app makes it easy to port a screen
/// without re-mapping the palette every time.
class PeekColors {
  PeekColors._();

  static const bg = Color(0xFF07090E);
  static const bg2 = Color(0xFF0C0F16);
  static const surface = Color(0xFF161B27);
  static const surface2 = Color(0xFF222838);
  static const surface3 = Color(0xFF2E3447);
  static const border = Color(0xFF2A3146);
  static const border2 = Color(0xFF3A4159);

  static const accent = Color(0xFFF97316);
  static const accent2 = Color(0xFFFB923C);
  static const accent3 = Color(0xFFFDBA74);

  static const text = Color(0xFFF1F3F7);
  static const text2 = Color(0xFFA3AABB);
  static const text3 = Color(0xFF6B7286);

  static const green = Color(0xFF22C55E);
  static const red = Color(0xFFEF4444);
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
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: PeekColors.text),
      bodyMedium: TextStyle(color: PeekColors.text),
      bodySmall: TextStyle(color: PeekColors.text2),
      titleLarge: TextStyle(color: PeekColors.text, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: PeekColors.text, fontWeight: FontWeight.w600),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: PeekColors.bg,
      foregroundColor: PeekColors.text,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: PeekColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: EdgeInsets.zero,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: PeekColors.bg2,
      selectedItemColor: PeekColors.accent,
      unselectedItemColor: PeekColors.text3,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: PeekColors.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: PeekColors.text,
        side: const BorderSide(color: PeekColors.border),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: PeekColors.surface2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: PeekColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: PeekColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: PeekColors.accent),
      ),
    ),
    dividerColor: PeekColors.border,
  );
}
