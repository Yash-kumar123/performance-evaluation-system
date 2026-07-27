import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Color Palette (Indigo / Deep Slate Accent)
  static const Color primaryColor = Color(0xFF4F46E5); // Indigo 600
  static const Color primaryLight = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color secondaryColor = Color(0xFF0EA5E9); // Sky 500
  static const Color backgroundColor = Color(0xFFF8FAFC); // Slate 50
  static const Color cardBackgroundColor = Colors.white;
  static const Color surfaceColor = Colors.white;
  static const Color textPrimaryColor = Color(0xFF0F172A); // Slate 900
  static const Color textSecondaryColor = Color(0xFF64748B); // Slate 500
  static const Color borderSubtleColor = Color(0xFFE2E8F0); // Slate 200
  static const Color errorColor = Color(0xFFEF4444); // Red 500
  static const Color successColor = Color(0xFF10B981); // Emerald 500
  static const Color warningColor = Color(0xFFF59E0B); // Amber 500

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryColor,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: textPrimaryColor,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          color: textPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: textPrimaryColor),
      ),
      cardTheme: CardTheme(
        elevation: 0.5,
        color: cardBackgroundColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderSubtleColor, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderSubtleColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderSubtleColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        labelStyle: GoogleFonts.inter(color: textSecondaryColor, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: textSecondaryColor.withOpacity(0.7), fontSize: 14),
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: textPrimaryColor),
        headlineMedium: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: textPrimaryColor),
        titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimaryColor),
        titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimaryColor),
        bodyLarge: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.normal, color: textPrimaryColor),
        bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.normal, color: textSecondaryColor),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }
}
