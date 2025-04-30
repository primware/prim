import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static MaterialScheme lightScheme() {
    return const MaterialScheme(
      brightness: Brightness.light,
      primary: Color(0xff5e5791),
      surfaceTint: Color(0xff5e5791),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffe5deff),
      onPrimaryContainer: Color(0xff1a1249),
      secondary: Color(0xff466730),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffc7eea9),
      onSecondaryContainer: Color(0xff0a2100),
      tertiary: Color(0xff7b5265),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffffd8e7),
      onTertiaryContainer: Color(0xff301121),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff410002),
      background: Color(0xfffcf8ff),
      onBackground: Color(0xff1c1b20),
      surface: Color(0xfffcf8ff),
      onSurface: Color(0xff1c1b20),
      surfaceVariant: Color(0xffe5e0ec),
      onSurfaceVariant: Color(0xff48464f),
      outline: Color(0xff78767f),
      outlineVariant: Color(0xffc9c5d0),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff313036),
      inverseOnSurface: Color(0xfff4eff7),
      inversePrimary: Color(0xffc8bfff),
      primaryFixed: Color(0xffe5deff),
      onPrimaryFixed: Color(0xff1a1249),
      primaryFixedDim: Color(0xffc8bfff),
      onPrimaryFixedVariant: Color(0xff463f77),
      secondaryFixed: Color(0xffc7eea9),
      onSecondaryFixed: Color(0xff0a2100),
      secondaryFixedDim: Color(0xffabd28f),
      onSecondaryFixedVariant: Color(0xff2f4f1b),
      tertiaryFixed: Color(0xffffd8e7),
      onTertiaryFixed: Color(0xff301121),
      tertiaryFixedDim: Color(0xffecb8ce),
      onTertiaryFixedVariant: Color(0xff613b4d),
      surfaceDim: Color(0xffddd8e0),
      surfaceBright: Color(0xfffcf8ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff7f2fa),
      surfaceContainer: Color(0xfff1ecf4),
      surfaceContainerHigh: Color(0xffebe6ef),
      surfaceContainerHighest: Color(0xffe5e1e9),
    );
  }

  ThemeData light() {
    return theme(lightScheme().toColorScheme());
  }

  static MaterialScheme lightMediumContrastScheme() {
    return const MaterialScheme(
      brightness: Brightness.light,
      primary: Color(0xff423b73),
      surfaceTint: Color(0xff5e5791),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff756da9),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff2b4b17),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff5c7e44),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff5d3749),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff94687b),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff8c0009),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffda342e),
      onErrorContainer: Color(0xffffffff),
      background: Color(0xfffcf8ff),
      onBackground: Color(0xff1c1b20),
      surface: Color(0xfffcf8ff),
      onSurface: Color(0xff1c1b20),
      surfaceVariant: Color(0xffe5e0ec),
      onSurfaceVariant: Color(0xff44424b),
      outline: Color(0xff605e67),
      outlineVariant: Color(0xff7c7983),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff313036),
      inverseOnSurface: Color(0xfff4eff7),
      inversePrimary: Color(0xffc8bfff),
      primaryFixed: Color(0xff756da9),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff5c558e),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff5c7e44),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff44652e),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff94687b),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff795062),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffddd8e0),
      surfaceBright: Color(0xfffcf8ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff7f2fa),
      surfaceContainer: Color(0xfff1ecf4),
      surfaceContainerHigh: Color(0xffebe6ef),
      surfaceContainerHighest: Color(0xffe5e1e9),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme().toColorScheme());
  }

  static MaterialScheme lightHighContrastScheme() {
    return const MaterialScheme(
      brightness: Brightness.light,
      primary: Color(0xff211950),
      surfaceTint: Color(0xff5e5791),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff423b73),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff0d2800),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff2b4b17),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff381728),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff5d3749),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff4e0002),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff8c0009),
      onErrorContainer: Color(0xffffffff),
      background: Color(0xfffcf8ff),
      onBackground: Color(0xff1c1b20),
      surface: Color(0xfffcf8ff),
      onSurface: Color(0xff000000),
      surfaceVariant: Color(0xffe5e0ec),
      onSurfaceVariant: Color(0xff24232b),
      outline: Color(0xff44424b),
      outlineVariant: Color(0xff44424b),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff313036),
      inverseOnSurface: Color(0xffffffff),
      inversePrimary: Color(0xffefe9ff),
      primaryFixed: Color(0xff423b73),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff2c245b),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff2b4b17),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff163303),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff5d3749),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff442232),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffddd8e0),
      surfaceBright: Color(0xfffcf8ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff7f2fa),
      surfaceContainer: Color(0xfff1ecf4),
      surfaceContainerHigh: Color(0xffebe6ef),
      surfaceContainerHighest: Color(0xffe5e1e9),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme().toColorScheme());
  }

  static MaterialScheme darkScheme() {
    return const MaterialScheme(
      brightness: Brightness.dark,
      primary: Color(0xffc8bfff),
      surfaceTint: Color(0xffc8bfff),
      onPrimary: Color(0xff30285f),
      primaryContainer: Color(0xff463f77),
      onPrimaryContainer: Color(0xffe5deff),
      secondary: Color(0xffabd28f),
      onSecondary: Color(0xff193705),
      secondaryContainer: Color(0xff2f4f1b),
      onSecondaryContainer: Color(0xffc7eea9),
      tertiary: Color(0xffecb8ce),
      onTertiary: Color(0xff482536),
      tertiaryContainer: Color(0xff613b4d),
      onTertiaryContainer: Color(0xffffd8e7),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      background: Color(0xff141318),
      onBackground: Color(0xffe5e1e9),
      surface: Color(0xff141318),
      onSurface: Color(0xffe5e1e9),
      surfaceVariant: Color(0xff48464f),
      onSurfaceVariant: Color(0xffc9c5d0),
      outline: Color(0xff928f99),
      outlineVariant: Color(0xff48464f),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe5e1e9),
      inverseOnSurface: Color(0xff313036),
      inversePrimary: Color(0xff5e5791),
      primaryFixed: Color(0xffe5deff),
      onPrimaryFixed: Color(0xff1a1249),
      primaryFixedDim: Color(0xffc8bfff),
      onPrimaryFixedVariant: Color(0xff463f77),
      secondaryFixed: Color(0xffc7eea9),
      onSecondaryFixed: Color(0xff0a2100),
      secondaryFixedDim: Color(0xffabd28f),
      onSecondaryFixedVariant: Color(0xff2f4f1b),
      tertiaryFixed: Color(0xffffd8e7),
      onTertiaryFixed: Color(0xff301121),
      tertiaryFixedDim: Color(0xffecb8ce),
      onTertiaryFixedVariant: Color(0xff613b4d),
      surfaceDim: Color(0xff141318),
      surfaceBright: Color(0xff3a383e),
      surfaceContainerLowest: Color(0xff0e0e13),
      surfaceContainerLow: Color(0xff1c1b20),
      surfaceContainer: Color(0xff201f25),
      surfaceContainerHigh: Color(0xff2a292f),
      surfaceContainerHighest: Color(0xff35343a),
    );
  }

  ThemeData dark() {
    return theme(darkScheme().toColorScheme());
  }

  static MaterialScheme darkMediumContrastScheme() {
    return const MaterialScheme(
      brightness: Brightness.dark,
      primary: Color(0xffccc4ff),
      surfaceTint: Color(0xffc8bfff),
      onPrimary: Color(0xff150b44),
      primaryContainer: Color(0xff9189c7),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffb0d693),
      onSecondary: Color(0xff071b00),
      secondaryContainer: Color(0xff779b5e),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xfff1bcd2),
      onTertiary: Color(0xff2a0b1c),
      tertiaryContainer: Color(0xffb28398),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffbab1),
      onError: Color(0xff370001),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      background: Color(0xff141318),
      onBackground: Color(0xffe5e1e9),
      surface: Color(0xff141318),
      onSurface: Color(0xfffef9ff),
      surfaceVariant: Color(0xff48464f),
      onSurfaceVariant: Color(0xffcdc9d4),
      outline: Color(0xffa5a1ac),
      outlineVariant: Color(0xff85828c),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe5e1e9),
      inverseOnSurface: Color(0xff2b292f),
      inversePrimary: Color(0xff484078),
      primaryFixed: Color(0xffe5deff),
      onPrimaryFixed: Color(0xff10043f),
      primaryFixedDim: Color(0xffc8bfff),
      onPrimaryFixedVariant: Color(0xff362e65),
      secondaryFixed: Color(0xffc7eea9),
      onSecondaryFixed: Color(0xff051500),
      secondaryFixedDim: Color(0xffabd28f),
      onSecondaryFixedVariant: Color(0xff1f3d0b),
      tertiaryFixed: Color(0xffffd8e7),
      onTertiaryFixed: Color(0xff230616),
      tertiaryFixedDim: Color(0xffecb8ce),
      onTertiaryFixedVariant: Color(0xff4f2b3c),
      surfaceDim: Color(0xff141318),
      surfaceBright: Color(0xff3a383e),
      surfaceContainerLowest: Color(0xff0e0e13),
      surfaceContainerLow: Color(0xff1c1b20),
      surfaceContainer: Color(0xff201f25),
      surfaceContainerHigh: Color(0xff2a292f),
      surfaceContainerHighest: Color(0xff35343a),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme().toColorScheme());
  }

  static MaterialScheme darkHighContrastScheme() {
    return const MaterialScheme(
      brightness: Brightness.dark,
      primary: Color(0xfffef9ff),
      surfaceTint: Color(0xffc8bfff),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xffccc4ff),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xfff3ffe4),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffb0d693),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xfffff9f9),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xfff1bcd2),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xfffff9f9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffbab1),
      onErrorContainer: Color(0xff000000),
      background: Color(0xff141318),
      onBackground: Color(0xffe5e1e9),
      surface: Color(0xff141318),
      onSurface: Color(0xffffffff),
      surfaceVariant: Color(0xff48464f),
      onSurfaceVariant: Color(0xfffef9ff),
      outline: Color(0xffcdc9d4),
      outlineVariant: Color(0xffcdc9d4),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe5e1e9),
      inverseOnSurface: Color(0xff000000),
      inversePrimary: Color(0xff292258),
      primaryFixed: Color(0xffe9e3ff),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xffccc4ff),
      onPrimaryFixedVariant: Color(0xff150b44),
      secondaryFixed: Color(0xffcbf3ad),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffb0d693),
      onSecondaryFixedVariant: Color(0xff071b00),
      tertiaryFixed: Color(0xffffdeea),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xfff1bcd2),
      onTertiaryFixedVariant: Color(0xff2a0b1c),
      surfaceDim: Color(0xff141318),
      surfaceBright: Color(0xff3a383e),
      surfaceContainerLowest: Color(0xff0e0e13),
      surfaceContainerLow: Color(0xff1c1b20),
      surfaceContainer: Color(0xff201f25),
      surfaceContainerHigh: Color(0xff2a292f),
      surfaceContainerHighest: Color(0xff35343a),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme().toColorScheme());
  }

  ThemeData theme(ColorScheme colorScheme) => ThemeData(
        useMaterial3: true,
        brightness: colorScheme.brightness,
        colorScheme: colorScheme,
        textTheme: textTheme.apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        ),
        scaffoldBackgroundColor: colorScheme.background,
        canvasColor: colorScheme.surface,
      );

  List<ExtendedColor> get extendedColors => [];
}

class MaterialScheme {
  const MaterialScheme({
    required this.brightness,
    required this.primary,
    required this.surfaceTint,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.background,
    required this.onBackground,
    required this.surface,
    required this.onSurface,
    required this.surfaceVariant,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.shadow,
    required this.scrim,
    required this.inverseSurface,
    required this.inverseOnSurface,
    required this.inversePrimary,
    required this.primaryFixed,
    required this.onPrimaryFixed,
    required this.primaryFixedDim,
    required this.onPrimaryFixedVariant,
    required this.secondaryFixed,
    required this.onSecondaryFixed,
    required this.secondaryFixedDim,
    required this.onSecondaryFixedVariant,
    required this.tertiaryFixed,
    required this.onTertiaryFixed,
    required this.tertiaryFixedDim,
    required this.onTertiaryFixedVariant,
    required this.surfaceDim,
    required this.surfaceBright,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
  });

  final Brightness brightness;
  final Color primary;
  final Color surfaceTint;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color tertiary;
  final Color onTertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color background;
  final Color onBackground;
  final Color surface;
  final Color onSurface;
  final Color surfaceVariant;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color shadow;
  final Color scrim;
  final Color inverseSurface;
  final Color inverseOnSurface;
  final Color inversePrimary;
  final Color primaryFixed;
  final Color onPrimaryFixed;
  final Color primaryFixedDim;
  final Color onPrimaryFixedVariant;
  final Color secondaryFixed;
  final Color onSecondaryFixed;
  final Color secondaryFixedDim;
  final Color onSecondaryFixedVariant;
  final Color tertiaryFixed;
  final Color onTertiaryFixed;
  final Color tertiaryFixedDim;
  final Color onTertiaryFixedVariant;
  final Color surfaceDim;
  final Color surfaceBright;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
}

extension MaterialSchemeUtils on MaterialScheme {
  ColorScheme toColorScheme() {
    return ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      tertiary: tertiary,
      onTertiary: onTertiary,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer,
      error: error,
      onError: onError,
      errorContainer: errorContainer,
      onErrorContainer: onErrorContainer,
      background: background,
      onBackground: onBackground,
      surface: surface,
      onSurface: onSurface,
      surfaceVariant: surfaceVariant,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      shadow: shadow,
      scrim: scrim,
      inverseSurface: inverseSurface,
      onInverseSurface: inverseOnSurface,
      inversePrimary: inversePrimary,
    );
  }
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
