// theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart'; // Tu archivo donde defines ColorTheme

class AppThemes {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: ColorTheme.accentLight,
      scaffoldBackgroundColor: ColorTheme.aD200,
      cardColor: ColorTheme.textDark,
      appBarTheme: AppBarTheme(
        backgroundColor: ColorTheme.textLight,
        foregroundColor: ColorTheme.aD100,
        elevation: 0,
        centerTitle: true,
        titleTextStyle:
            GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w600),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
            color: ColorTheme.textLight,
            fontSize: 32,
            fontWeight: FontWeight.w700),
        headlineLarge: GoogleFonts.poppins(
            color: ColorTheme.textLight,
            fontSize: 28,
            fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.poppins(
            color: ColorTheme.textLight,
            fontSize: 24,
            fontWeight: FontWeight.w500),
        titleMedium: GoogleFonts.poppins(
            color: ColorTheme.textLight,
            fontSize: 22,
            fontWeight: FontWeight.w500),
        bodyLarge: GoogleFonts.poppins(
            color: ColorTheme.textLight,
            fontSize: 20,
            fontWeight: FontWeight.w400),
        bodyMedium: GoogleFonts.poppins(
            color: ColorTheme.textLight,
            fontSize: 18,
            fontWeight: FontWeight.w400),
        bodySmall: GoogleFonts.poppins(
            color: ColorTheme.textLight,
            fontSize: 14,
            fontWeight: FontWeight.w400),
      ),
      dividerColor: ColorTheme.aL500,
      colorScheme: ColorScheme.light(
        primary: ColorTheme.accentLight,
        secondary: ColorTheme.aD100,
        surface: Colors.white,
        onPrimary: ColorTheme.textDark,
        onSecondary: ColorTheme.textLight,
      ),
      listTileTheme: ListTileThemeData(
        textColor: ColorTheme.textDark,
        iconColor: ColorTheme.textDark,
        tileColor: ColorTheme.accentLight,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorTheme.accentLight,
          foregroundColor: ColorTheme.textDark,
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: ColorTheme.accentDark,
      scaffoldBackgroundColor: ColorTheme.aD100,
      cardColor: ColorTheme.tD100,
      appBarTheme: AppBarTheme(
        backgroundColor: ColorTheme.textDark,
        foregroundColor: ColorTheme.aD200,
        elevation: 0,
        centerTitle: true,
        titleTextStyle:
            GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w600),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
            color: ColorTheme.textDark,
            fontSize: 32,
            fontWeight: FontWeight.w700),
        headlineLarge: GoogleFonts.poppins(
            color: ColorTheme.textDark,
            fontSize: 28,
            fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.poppins(
            color: ColorTheme.textDark,
            fontSize: 24,
            fontWeight: FontWeight.w500),
        titleMedium: GoogleFonts.poppins(
            color: ColorTheme.textDark,
            fontSize: 22,
            fontWeight: FontWeight.w500),
        bodyLarge: GoogleFonts.poppins(
            color: ColorTheme.textDark,
            fontSize: 20,
            fontWeight: FontWeight.w400),
        bodyMedium: GoogleFonts.poppins(
            color: ColorTheme.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w400),
        bodySmall: GoogleFonts.poppins(
            color: ColorTheme.textDark,
            fontSize: 14,
            fontWeight: FontWeight.w400),
      ),
      dividerColor: ColorTheme.aD500,
      colorScheme: ColorScheme.dark(
        primary: ColorTheme.accentDark,
        secondary: ColorTheme.aD200,
        surface: ColorTheme.textDark,
        onPrimary: ColorTheme.textLight,
        onSecondary: ColorTheme.textDark,
      ),
      listTileTheme: ListTileThemeData(
        textColor: ColorTheme.textDark,
        iconColor: ColorTheme.textDark,
        tileColor: ColorTheme.accentLight,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorTheme.accentDark,
          foregroundColor: ColorTheme.textLight,
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
