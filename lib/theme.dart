import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OTheme {
  static const Color neonPink = Color(0xFFFF4FA3);
  static const Color black = Color(0xFF000000);
  static const Color deepCharcoal = Color(0xFF0D0D0D);
  static const Color softRose = Color(0xFFFF8BC8);
  static const Color electricRedPink = Color(0xFFFF2E6E);
  static const Color softWhite = Color(0xFFE0E0E0);

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: black,
    primaryColor: neonPink,
    colorScheme: const ColorScheme.dark(
      primary: neonPink,
      secondary: softRose,
      surface: deepCharcoal,
      onPrimary: black,
      onSurface: Colors.white,
    ),
    textTheme: GoogleFonts.interTextTheme(
      const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: softRose,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displaySmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: softWhite,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: softWhite,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: neonPink,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: black,
        foregroundColor: neonPink,
        side: const BorderSide(color: neonPink, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    cardTheme: CardTheme(
      color: deepCharcoal,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
