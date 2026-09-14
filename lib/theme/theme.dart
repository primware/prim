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
        bodyColor: colorScheme.primary,
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
    // Tonos más claros y azulados en lugar de negro puro
    final darkBackground = const Color(0xFF1A1A24); 
    final surfaceColor = const Color(0xFF262636);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme.copyWith(
        surface: surfaceColor,
        onSurface: Colors.white,
      ),
      primaryColor: colorScheme.primary, // EXPLICIT PRIMARY COLOR
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: Colors.white,
        elevation: 1, // Leve sombra
        centerTitle: true,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: surfaceColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: Colors.grey.shade300, // Texto secundario más claro
        displayColor: Colors.white,     // Títulos blancos
      ),
      cardColor: surfaceColor,
      dividerColor: Colors.white.withOpacity(0.15),
      listTileTheme: ListTileThemeData(
        textColor: Colors.white,
        iconColor: Colors.white70,
      ),
      iconTheme: const IconThemeData(
        color: Colors.white70,
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
