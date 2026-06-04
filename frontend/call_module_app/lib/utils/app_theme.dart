import 'package:flutter/material.dart';

class AppTheme {
  // ── Color Palette ──────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF5F7FA); // soft white-grey page bg
  static const Color surface = Color(0xFFFFFFFF); // pure white cards
  static const Color surfaceLight = Color(0xFFF0F3F8); // input fills, chips
  static const Color border = Color(0xFFE2E8F0); // subtle card borders

  static const Color cyan = Color(0xFF0EA5E9); // primary blue accent
  static const Color cyanDark = Color(0xFF0284C7); // pressed / darker shade
  static const Color amber = Color(0xFFF59E0B); // warning / pending
  static const Color green = Color(0xFF10B981); // success / completed
  static const Color red = Color(0xFFEF4444); // error / danger
  static const Color purple = Color(0xFF8B5CF6); // on the way

  static const Color textPrimary = Color(0xFF0F172A); // near-black headings
  static const Color textSecondary = Color(0xFF64748B); // body / labels
  static const Color textHint = Color(0xFFADB5C8); // placeholders

  // ── Status Colors ──────────────────────────────────────────────────────────
  static Color statusColor(String status) {
    switch (status) {
      case 'pending':
        return amber;
      case 'assigned':
        return cyan;
      case 'on_the_way':
        return purple;
      case 'on_site':
        return const Color(0xFF059669);
      case 'completed':
        return green;
      default:
        return textSecondary;
    }
  }

  // ── Theme Data ─────────────────────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.light(
      primary: cyan,
      secondary: amber,
      surface: surface,
      error: red,
    ),
    fontFamily: 'Roboto',

    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: border, width: 1),
      ),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: border,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: textSecondary),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: cyan, width: 1.5),
      ),
      labelStyle: const TextStyle(color: textSecondary),
      hintStyle: const TextStyle(color: textHint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: cyan,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: cyan,
      unselectedItemColor: textHint,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),

    dividerTheme: const DividerThemeData(color: border, thickness: 1),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: cyan),
    ),
  );
}
