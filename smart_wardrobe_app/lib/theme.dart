import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Smart Wardrobe Design System
/// Aesthetic: Leica × Fashion Editorial — Dark, precise, warm gold accent.

class AppColors {
  // Background layers
  static const bgBase = Color(0xFF09090B);
  static const bgSurface1 = Color(0xFF111114);
  static const bgSurface2 = Color(0xFF17171A);
  static const bgSurface3 = Color(0xFF1E1E22);

  // Borders
  static const borderSubtle = Color(0xFF252529);
  static const borderDefault = Color(0xFF2E2E33);
  static const borderFocus = Color(0xFF3E3E46);

  // Gold accent
  static const gold = Color(0xFFC9A96E);
  static const goldHi = Color(0xFFDFBE84);
  static const goldDim = Color(0xFF8A7045);
  static const goldFaint = Color(0x14C9A96E);
  static const goldTint = Color(0x28C9A96E);

  // Text
  static const textPrimary = Color(0xFFEDE8DE);
  static const textSecondary = Color(0xFF8A8A96);
  static const textTertiary = Color(0xFF4A4A54);
  static const textGold = Color(0xFFC9A96E);

  // Semantic
  static const green = Color(0xFF5DBB8C);
  static const greenFaint = Color(0x145DBB8C);
  static const red = Color(0xFFD96464);
  static const redFaint = Color(0x14D96464);
  static const amber = Color(0xFFD4A846);
  static const amberFaint = Color(0x14D4A846);
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 36;
  static const double xxl = 56;

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 18;
  static const double radiusXl = 24;
  static const double radiusFull = 9999;

  static const double bottomNavHeight = 72;
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgBase,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        secondary: AppColors.goldHi,
        surface: AppColors.bgSurface1,
        error: AppColors.red,
        onPrimary: Color(0xFF1A1208),
        onSecondary: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
        onError: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgBase,
        elevation: 0,
        titleTextStyle: _cormorant(32, FontWeight.w400, AppColors.textPrimary),
        iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 20),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgSurface1,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.0,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.0,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgSurface1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: const BorderSide(color: AppColors.borderSubtle, width: 0.5),
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgSurface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.goldDim),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 15),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      dividerColor: AppColors.borderSubtle,
      useMaterial3: true,
    );
  }

  // ─── Typography Helpers ──────────────────────────────────────

  static TextStyle _cormorant(double size, FontWeight weight, Color color, {
    bool italic = false,
    double? height,
  }) {
    return GoogleFonts.cormorantGaramond(
      fontSize: size,
      fontWeight: weight,
      color: color,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      height: height,
    );
  }

  static TextStyle _dmSans(double size, FontWeight weight, Color color, {
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.dmSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  // Display: Cormorant 44px / 300
  static TextStyle get display => _cormorant(44, FontWeight.w300, AppColors.textPrimary, height: 1.15);

  // Title: Cormorant 32px / 400
  static TextStyle get title => _cormorant(32, FontWeight.w400, AppColors.textPrimary, height: 1.2);

  // Subtitle: Cormorant 22px / 400 italic
  static TextStyle get subtitle => _cormorant(22, FontWeight.w400, AppColors.textPrimary, italic: true, height: 1.3);

  // Outfit headline: Cormorant 30px / 300 italic
  static TextStyle get outfitHeadline => _cormorant(30, FontWeight.w300, AppColors.textPrimary, italic: true, height: 1.2);

  // Body: DM Sans 15px / 400
  static TextStyle get body => _dmSans(15, FontWeight.w400, AppColors.textPrimary, height: 1.7);

  // Label: DM Sans 12px / 500 / UPPERCASE
  static TextStyle get label => _dmSans(12, FontWeight.w500, AppColors.textSecondary, letterSpacing: 0.72);

  // Caption: DM Sans 11px / 400
  static TextStyle get caption => _dmSans(11, FontWeight.w400, AppColors.textSecondary);

  // Micro: DM Sans 10px / 500 / UPPERCASE — status badges
  static TextStyle get micro => _dmSans(10, FontWeight.w500, AppColors.textSecondary, letterSpacing: 1.0);

  // Button text
  static TextStyle get button => _dmSans(15, FontWeight.w500, const Color(0xFF1A1208));

  // Metric value: Cormorant 32px / 300
  static TextStyle get metricValue => _cormorant(32, FontWeight.w300, AppColors.textPrimary);
}
