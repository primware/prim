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
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
      // 🌟 INYECCIÓN DEL TEMA DE CRISTAL (MODO CLARO)
      extensions: <ThemeExtension<dynamic>>[
        GlassTheme(
          blur: 25.0,
          glassColor: Colors.white,
          opacityStart: 0.15,
          opacityEnd: 0.05,
          borderColor: Colors.white,
          borderOpacity: 0.4,
          shadowColor: Colors.black.withOpacity(0.08),
        ),
      ],
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
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
      // 🌟 INYECCIÓN DEL TEMA DE CRISTAL (MODO OSCURO)
      extensions: <ThemeExtension<dynamic>>[
        GlassTheme(
          blur: 25.0,
          glassColor: Colors.black,
          opacityStart: 0.15,
          opacityEnd: 0.05,
          borderColor: Colors.white,
          borderOpacity: 0.15, // Borde más sutil en oscuro
          shadowColor: Colors.black.withOpacity(
            0.4,
          ), // Sombra más fuerte en oscuro
        ),
      ],
    );
  }
}

// 🌟 EXTENSIÓN PARA EL DESIGN SYSTEM DE CRISTAL
class GlassTheme extends ThemeExtension<GlassTheme> {
  final double blur;
  final Color glassColor;
  final double opacityStart;
  final double opacityEnd;
  final Color borderColor;
  final double borderOpacity;
  final Color shadowColor;

  const GlassTheme({
    required this.blur,
    required this.glassColor,
    required this.opacityStart,
    required this.opacityEnd,
    required this.borderColor,
    required this.borderOpacity,
    required this.shadowColor,
  });

  @override
  GlassTheme copyWith({
    double? blur,
    Color? glassColor,
    double? opacityStart,
    double? opacityEnd,
    Color? borderColor,
    double? borderOpacity,
    Color? shadowColor,
  }) {
    return GlassTheme(
      blur: blur ?? this.blur,
      glassColor: glassColor ?? this.glassColor,
      opacityStart: opacityStart ?? this.opacityStart,
      opacityEnd: opacityEnd ?? this.opacityEnd,
      borderColor: borderColor ?? this.borderColor,
      borderOpacity: borderOpacity ?? this.borderOpacity,
      shadowColor: shadowColor ?? this.shadowColor,
    );
  }

  @override
  GlassTheme lerp(ThemeExtension<GlassTheme>? other, double t) {
    if (other is! GlassTheme) return this;
    return GlassTheme(
      blur: lerpDouble(blur, other.blur, t) ?? blur,
      glassColor: Color.lerp(glassColor, other.glassColor, t) ?? glassColor,
      opacityStart:
          lerpDouble(opacityStart, other.opacityStart, t) ?? opacityStart,
      opacityEnd: lerpDouble(opacityEnd, other.opacityEnd, t) ?? opacityEnd,
      borderColor: Color.lerp(borderColor, other.borderColor, t) ?? borderColor,
      borderOpacity:
          lerpDouble(borderOpacity, other.borderOpacity, t) ?? borderOpacity,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t) ?? shadowColor,
    );
  }

  // Helper para facilitar el lerp de doubles
  double? lerpDouble(double a, double b, double t) => a + (b - a) * t;
}
