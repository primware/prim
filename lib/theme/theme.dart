import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme_material.dart';

class AppThemes {
  static ThemeData get lightTheme {
    final colorScheme = MaterialTheme.lightScheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.primaryFixed,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: colorScheme.onSecondaryContainer,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      cardColor: colorScheme.surface,
      dividerColor: colorScheme.outline,
      listTileTheme: ListTileThemeData(
        textColor: colorScheme.onSurface,
        iconColor: colorScheme.onSurfaceVariant,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = MaterialTheme.darkScheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surfaceDim,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
        elevation: 0,
        centerTitle: true,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      cardColor: colorScheme.surface,
      dividerColor: colorScheme.outline,
      listTileTheme: ListTileThemeData(
        textColor: colorScheme.onSurface,
        iconColor: colorScheme.onSurfaceVariant,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

//? Fuentes
// | Estilo                           | Tamaño aprox. | Uso común                        |
// | -------------------------------- | ------------- | -------------------------------- |
// | `displayLarge`                   | 57.0          | Titulares principales            |
// | `displayMedium`                  | 45.0          | Titulares secundarios            |
// | `displaySmall`                   | 36.0          | Titulares grandes                |
// | `headlineLarge`                  | 32.0          | Encabezado                       |
// | `headlineMedium`                 | 28.0          | Subtítulo                        |
// | `headlineSmall`                  | 24.0          | Secciones                        |
// | `titleLarge`                     | 22.0          | Títulos                          |
// | `titleMedium`                    | 16.0          | Título más pequeño (como AppBar) |
// | `titleSmall`                     | 14.0          | Subtítulos menores               |
// | `bodyLarge`                      | 16.0          | Texto principal                  |
// | `bodyMedium`                     | 14.0          | Texto normal                     |
// | `bodySmall`                      | 12.0          | Notas, descripciones             |
// | `labelLarge`, `labelSmall`, etc. | 11–14.0       | Botones, badges                  |
