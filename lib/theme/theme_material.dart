import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff494371),
      surfaceTint: Color(0xff5f5987),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff615b8a),
      onPrimaryContainer: Color(0xffded8ff),
      secondary: Color(0xff356813),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff4d812c),
      onSecondaryContainer: Color(0xfff9ffed),
      tertiary: Color(0xff683a57),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff83516f),
      onTertiaryContainer: Color(0xffffcfe8),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfffdf8fd),
      onSurface: Color(0xff1c1b1e),
      onSurfaceVariant: Color(0xff48464e),
      outline: Color(0xff78767f),
      outlineVariant: Color(0xffc9c5cf),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff313033),
      inversePrimary: Color(0xffc8c0f6),
      primaryFixed: Color(0xffe5deff),
      onPrimaryFixed: Color(0xff1b1540),
      primaryFixedDim: Color(0xffc8c0f6),
      onPrimaryFixedVariant: Color(0xff47416e),
      secondaryFixed: Color(0xffb7f38e),
      onSecondaryFixed: Color(0xff0a2100),
      secondaryFixedDim: Color(0xff9cd675),
      onSecondaryFixedVariant: Color(0xff225100),
      tertiaryFixed: Color(0xffffd8eb),
      onTertiaryFixed: Color(0xff330c27),
      tertiaryFixedDim: Color(0xfff2b4d7),
      onTertiaryFixedVariant: Color(0xff663854),
      surfaceDim: Color(0xffddd9dd),
      surfaceBright: Color(0xfffdf8fd),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff7f2f7),
      surfaceContainer: Color(0xfff1ecf1),
      surfaceContainerHigh: Color(0xffebe7eb),
      surfaceContainerHighest: Color(0xffe5e1e6),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff36305c),
      surfaceTint: Color(0xff5f5987),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff615b8a),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff193e00),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff467a25),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff532743),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff83516f),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffdf8fd),
      onSurface: Color(0xff111114),
      onSurfaceVariant: Color(0xff37353d),
      outline: Color(0xff53515a),
      outlineVariant: Color(0xff6e6c75),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff313033),
      inversePrimary: Color(0xffc8c0f6),
      primaryFixed: Color(0xff6d6797),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff554f7d),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff467a25),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff2e600b),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff915d7c),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff764563),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffc9c5ca),
      surfaceBright: Color(0xfffdf8fd),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff7f2f7),
      surfaceContainer: Color(0xffebe7eb),
      surfaceContainerHigh: Color(0xffe0dbe0),
      surfaceContainerHighest: Color(0xffd4d0d5),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff2c2652),
      surfaceTint: Color(0xff5f5987),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff494371),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff133300),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff235400),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff471d39),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff683a57),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffdf8fd),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff2d2b33),
      outlineVariant: Color(0xff4a4851),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff313033),
      inversePrimary: Color(0xffc8c0f6),
      primaryFixed: Color(0xff494371),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff322d59),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff235400),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff173a00),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff683a57),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff4f243f),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffbbb8bc),
      surfaceBright: Color(0xfffdf8fd),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff4eff4),
      surfaceContainer: Color(0xffe5e1e6),
      surfaceContainerHigh: Color(0xffd7d3d8),
      surfaceContainerHighest: Color(0xffc9c5ca),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffc8c0f6),
      surfaceTint: Color(0xffc8c0f6),
      onPrimary: Color(0xff302a56),
      primaryContainer: Color(0xff615b8a),
      onPrimaryContainer: Color(0xffded8ff),
      secondary: Color(0xff9cd675),
      onSecondary: Color(0xff153800),
      secondaryContainer: Color(0xff689f45),
      onSecondaryContainer: Color(0xff0f2b00),
      tertiary: Color(0xfff2b4d7),
      onTertiary: Color(0xff4c213d),
      tertiaryContainer: Color(0xff83516f),
      onTertiaryContainer: Color(0xffffcfe8),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff141316),
      onSurface: Color(0xffe5e1e6),
      onSurfaceVariant: Color(0xffc9c5cf),
      outline: Color(0xff928f99),
      outlineVariant: Color(0xff48464e),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe5e1e6),
      inversePrimary: Color(0xff5f5987),
      primaryFixed: Color(0xffe5deff),
      onPrimaryFixed: Color(0xff1b1540),
      primaryFixedDim: Color(0xffc8c0f6),
      onPrimaryFixedVariant: Color(0xff47416e),
      secondaryFixed: Color(0xffb7f38e),
      onSecondaryFixed: Color(0xff0a2100),
      secondaryFixedDim: Color(0xff9cd675),
      onSecondaryFixedVariant: Color(0xff225100),
      tertiaryFixed: Color(0xffffd8eb),
      onTertiaryFixed: Color(0xff330c27),
      tertiaryFixedDim: Color(0xfff2b4d7),
      onTertiaryFixedVariant: Color(0xff663854),
      surfaceDim: Color(0xff141316),
      surfaceBright: Color(0xff3a383c),
      surfaceContainerLowest: Color(0xff0e0e11),
      surfaceContainerLow: Color(0xff1c1b1e),
      surfaceContainer: Color(0xff201f22),
      surfaceContainerHigh: Color(0xff2b292d),
      surfaceContainerHighest: Color(0xff353438),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffded8ff),
      surfaceTint: Color(0xffc8c0f6),
      onPrimary: Color(0xff251f4b),
      primaryContainer: Color(0xff928bbd),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffb1ed89),
      onSecondary: Color(0xff0f2c00),
      secondaryContainer: Color(0xff689f45),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xffffcfe8),
      onTertiary: Color(0xff3f1732),
      tertiaryContainer: Color(0xffb880a0),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffd2cc),
      onError: Color(0xff540003),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff141316),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffdfdae5),
      outline: Color(0xffb4b0bb),
      outlineVariant: Color(0xff928f99),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe5e1e6),
      inversePrimary: Color(0xff48426f),
      primaryFixed: Color(0xffe5deff),
      onPrimaryFixed: Color(0xff100935),
      primaryFixedDim: Color(0xffc8c0f6),
      onPrimaryFixedVariant: Color(0xff36305c),
      secondaryFixed: Color(0xffb7f38e),
      onSecondaryFixed: Color(0xff051500),
      secondaryFixedDim: Color(0xff9cd675),
      onSecondaryFixedVariant: Color(0xff193e00),
      tertiaryFixed: Color(0xffffd8eb),
      onTertiaryFixed: Color(0xff27031c),
      tertiaryFixedDim: Color(0xfff2b4d7),
      onTertiaryFixedVariant: Color(0xff532743),
      surfaceDim: Color(0xff141316),
      surfaceBright: Color(0xff454447),
      surfaceContainerLowest: Color(0xff07070a),
      surfaceContainerLow: Color(0xff1e1d20),
      surfaceContainer: Color(0xff28272b),
      surfaceContainerHigh: Color(0xff333235),
      surfaceContainerHighest: Color(0xff3e3d41),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xfff3edff),
      surfaceTint: Color(0xffc8c0f6),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xffc4bcf2),
      onPrimaryContainer: Color(0xff0a0330),
      secondary: Color(0xffcbffa6),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xff99d272),
      onSecondaryContainer: Color(0xff030e00),
      tertiary: Color(0xffffebf3),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xffeeb1d3),
      onTertiaryContainer: Color(0xff1e0015),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff141316),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xfff3eef9),
      outlineVariant: Color(0xffc5c1cb),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe5e1e6),
      inversePrimary: Color(0xff48426f),
      primaryFixed: Color(0xffe5deff),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xffc8c0f6),
      onPrimaryFixedVariant: Color(0xff100935),
      secondaryFixed: Color(0xffb7f38e),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xff9cd675),
      onSecondaryFixedVariant: Color(0xff051500),
      tertiaryFixed: Color(0xffffd8eb),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xfff2b4d7),
      onTertiaryFixedVariant: Color(0xff27031c),
      surfaceDim: Color(0xff141316),
      surfaceBright: Color(0xff514f53),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff201f22),
      surfaceContainer: Color(0xff313033),
      surfaceContainerHigh: Color(0xff3c3b3e),
      surfaceContainerHighest: Color(0xff48464a),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
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
