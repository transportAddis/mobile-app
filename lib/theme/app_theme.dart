import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppColors
//
// Every token is sourced directly from globals.css :root and .dark blocks.
// Use these constants everywhere – never write a raw Color() literal in a
// widget file.
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────────
  // --transit-primary / --primary (light)
  static const Color primary   = Color(0xFFDE613B);
  // --transit-secondary / --secondary
  static const Color secondary = Color(0xFFF19779);
  // --transit-accent / --accent
  static const Color accent    = Color(0xFFF8794F);

  // ── Light Surface Tokens ───────────────────────────────────────────────────
  // --background (light)
  static const Color backgroundLight      = Color(0xFFF6E3DF);
  // --card (light)
  static const Color surfaceLight         = Color(0xFFFFFFFF);
  // --foreground / --transit-text (light)
  static const Color textLight            = Color(0xFF0B0504);
  // --muted-foreground at 70% opacity (rgba(11,5,4,0.7))
  static const Color mutedForegroundLight = Color(0xB30B0504);
  // --border / --input at 10% opacity (rgba(11,5,4,0.1))
  static const Color borderLight          = Color(0x1A0B0504);

  // ── Dark Surface Tokens ────────────────────────────────────────────────────
  // Spec: dark background #200d09
  static const Color backgroundDark      = Color(0xFF200D09);
  // Elevated surface for cards in dark mode (slightly lifted from background)
  static const Color surfaceDark         = Color(0xFF2D1410);
  // Spec: dark text #fbf5f4
  static const Color textDark            = Color(0xFFFBF5F4);
  // Muted foreground at 70% opacity for dark
  static const Color mutedForegroundDark = Color(0xB3FBF5F4);
  // Border at 10% opacity for dark
  static const Color borderDark          = Color(0x1AFBF5F4);

  // ── Semantic ───────────────────────────────────────────────────────────────
  // --destructive
  static const Color error       = Color(0xFFD32F2F);
  // --primary-foreground / --accent-foreground
  static const Color onPrimary   = Color(0xFFFFFFFF);
  // --secondary-foreground (light)
  static const Color onSecondary = Color(0xFF0B0504);

  // ── Transit Domain Tokens ──────────────────────────────────────────────────
  // Used by StationQueueIndicator and VehicleOccupancyBadge widgets.
  // --transit-crowd-high
  static const Color crowdHigh   = Color(0xFFD32F2F);
  // --transit-crowd-medium
  static const Color crowdMedium = Color(0xFFF57C00);
  // --transit-crowd-low
  static const Color crowdLow    = Color(0xFF2E7D32);
  // --transit-unselected (bottom nav inactive icons)
  static const Color unselected  = Color(0xFFA09C9B);
}

// ─────────────────────────────────────────────────────────────────────────────
// AppTextStyles
//
// The default text theme (Inter) is set globally via ThemeData.textTheme.
// Use this class only when you explicitly need JetBrains Mono, e.g. in
// a live queue counter, ETA timer, or vehicle occupancy number.
//
// Usage:
//   Text('14 min', style: AppTextStyles.mono(fontSize: 20, color: AppColors.primary))
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppTextStyles {
  static TextStyle mono({
    double fontSize = 14.0,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// AppTheme
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppTheme {
  // --radius: 0.75rem → 12 logical pixels
  static const BorderRadius _radius =
      BorderRadius.all(Radius.circular(12));

  // Pill shape used for chips and filter buttons
  static const BorderRadius _pill =
      BorderRadius.all(Radius.circular(99));

  // ── Light Theme ─────────────────────────────────────────────────────────────

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: _lightColorScheme,
        scaffoldBackgroundColor: AppColors.backgroundLight,
        textTheme: _buildTextTheme(AppColors.textLight),

        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.backgroundLight,
          foregroundColor: AppColors.textLight,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          iconTheme: const IconThemeData(color: AppColors.textLight),
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textLight,
          ),
        ),

        cardTheme: const CardThemeData(
          color: AppColors.surfaceLight,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: _radius),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            elevation: 0,
            minimumSize: const Size.fromHeight(48),
            shape: const RoundedRectangleBorder(borderRadius: _radius),
            textStyle:
                GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            minimumSize: const Size.fromHeight(48),
            shape: const RoundedRectangleBorder(borderRadius: _radius),
            textStyle:
                GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle:
                GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceLight,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: const OutlineInputBorder(
            borderRadius: _radius,
            borderSide: BorderSide(color: AppColors.borderLight),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: _radius,
            borderSide: BorderSide(color: AppColors.borderLight),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: _radius,
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: const OutlineInputBorder(
            borderRadius: _radius,
            borderSide: BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: const OutlineInputBorder(
            borderRadius: _radius,
            borderSide: BorderSide(color: AppColors.error, width: 2),
          ),
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.mutedForegroundLight,
          ),
        ),

        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surfaceLight,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.unselected,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
        ),

        chipTheme: ChipThemeData(
          backgroundColor: AppColors.backgroundLight,
          selectedColor: AppColors.primary,
          checkmarkColor: AppColors.onPrimary,
          labelStyle:
              GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
          side: const BorderSide(color: AppColors.borderLight),
          shape: const RoundedRectangleBorder(borderRadius: _pill),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),

        dividerTheme: const DividerThemeData(
          color: AppColors.borderLight,
          thickness: 1,
          space: 1,
        ),

        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.textLight,
          contentTextStyle: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.backgroundLight,
          ),
          shape: const RoundedRectangleBorder(borderRadius: _radius),
          behavior: SnackBarBehavior.floating,
        ),
      );

  // ── Dark Theme ──────────────────────────────────────────────────────────────

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: _darkColorScheme,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        textTheme: _buildTextTheme(AppColors.textDark),

        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.backgroundDark,
          foregroundColor: AppColors.textDark,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          iconTheme: const IconThemeData(color: AppColors.textDark),
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),

        cardTheme: const CardThemeData(
          color: AppColors.surfaceDark,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: _radius),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            elevation: 0,
            minimumSize: const Size.fromHeight(48),
            shape: const RoundedRectangleBorder(borderRadius: _radius),
            textStyle:
                GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            minimumSize: const Size.fromHeight(48),
            shape: const RoundedRectangleBorder(borderRadius: _radius),
            textStyle:
                GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle:
                GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceDark,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: const OutlineInputBorder(
            borderRadius: _radius,
            borderSide: BorderSide(color: AppColors.borderDark),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: _radius,
            borderSide: BorderSide(color: AppColors.borderDark),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: _radius,
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: const OutlineInputBorder(
            borderRadius: _radius,
            borderSide: BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: const OutlineInputBorder(
            borderRadius: _radius,
            borderSide: BorderSide(color: AppColors.error, width: 2),
          ),
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.mutedForegroundDark,
          ),
        ),

        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surfaceDark,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.unselected,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
        ),

        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surfaceDark,
          selectedColor: AppColors.primary,
          checkmarkColor: AppColors.onPrimary,
          labelStyle:
              GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
          side: const BorderSide(color: AppColors.borderDark),
          shape: const RoundedRectangleBorder(borderRadius: _pill),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),

        dividerTheme: const DividerThemeData(
          color: AppColors.borderDark,
          thickness: 1,
          space: 1,
        ),

        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.surfaceDark,
          contentTextStyle: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textDark,
          ),
          shape: const RoundedRectangleBorder(borderRadius: _radius),
          behavior: SnackBarBehavior.floating,
        ),
      );

  // ── Private: ColorSchemes ────────────────────────────────────────────────────

  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    tertiary: AppColors.accent,
    onTertiary: AppColors.onPrimary,
    error: AppColors.error,
    onError: AppColors.onPrimary,
    // surface = card/dialog/sheet background
    surface: AppColors.surfaceLight,
    onSurface: AppColors.textLight,
    // surfaceContainerHighest = muted / tag backgrounds
    surfaceContainerHighest: AppColors.backgroundLight,
    onSurfaceVariant: AppColors.mutedForegroundLight,
    outline: AppColors.borderLight,
    outlineVariant: AppColors.borderLight,
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    secondary: AppColors.secondary,
    onSecondary: AppColors.textDark,
    tertiary: AppColors.accent,
    onTertiary: AppColors.onPrimary,
    error: AppColors.error,
    onError: AppColors.onPrimary,
    surface: AppColors.surfaceDark,
    onSurface: AppColors.textDark,
    surfaceContainerHighest: AppColors.backgroundDark,
    onSurfaceVariant: AppColors.mutedForegroundDark,
    outline: AppColors.borderDark,
    outlineVariant: AppColors.borderDark,
  );

  // ── Private: TextTheme (Inter via google_fonts) ───────────────────────────

  static TextTheme _buildTextTheme(Color textColor) =>
      GoogleFonts.interTextTheme(
        TextTheme(
          // Material 3 scale mapped to globals.css font-sans (Inter)
          displayLarge:  TextStyle(color: textColor, fontSize: 57, fontWeight: FontWeight.w700, letterSpacing: -0.25),
          displayMedium: TextStyle(color: textColor, fontSize: 45, fontWeight: FontWeight.w700),
          displaySmall:  TextStyle(color: textColor, fontSize: 36, fontWeight: FontWeight.w600),
          headlineLarge: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.w700),
          headlineMedium:TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.w600),
          titleLarge:    TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.w600),
          titleMedium:   TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.15),
          titleSmall:    TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.10),
          bodyLarge:     TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.50),
          bodyMedium:    TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25),
          bodySmall:     TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.40),
          labelLarge:    TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.10),
          labelMedium:   TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.50),
          labelSmall:    TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.50),
        ),
      );
}
