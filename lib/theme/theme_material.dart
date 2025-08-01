import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff01004f),
      surfaceTint: Color(0xff4b50c4),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff04008d),
      onPrimaryContainer: Color(0xff7b81f7),
      secondary: Color(0xff585b88),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffc9cbff),
      onSecondaryContainer: Color(0xff525481),
      tertiary: Color(0xff230030),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff440059),
      onTertiaryContainer: Color(0xffb774c9),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfffbf8ff),
      onSurface: Color(0xff1b1b22),
      onSurfaceVariant: Color(0xff464653),
      outline: Color(0xff767685),
      outlineVariant: Color(0xffc6c5d5),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff303037),
      inversePrimary: Color(0xffbfc2ff),
      primaryFixed: Color(0xffe0e0ff),
      onPrimaryFixed: Color(0xff02006d),
      primaryFixedDim: Color(0xffbfc2ff),
      onPrimaryFixedVariant: Color(0xff3136ab),
      secondaryFixed: Color(0xffe0e0ff),
      onSecondaryFixed: Color(0xff141740),
      secondaryFixedDim: Color(0xffc1c2f6),
      onSecondaryFixedVariant: Color(0xff40436e),
      tertiaryFixed: Color(0xfffbd7ff),
      onTertiaryFixed: Color(0xff330044),
      tertiaryFixedDim: Color(0xfff0b0ff),
      onTertiaryFixedVariant: Color(0xff692b7d),
      surfaceDim: Color(0xffdbd9e3),
      surfaceBright: Color(0xfffbf8ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff5f2fd),
      surfaceContainer: Color(0xffefecf7),
      surfaceContainerHigh: Color(0xffeae7f1),
      surfaceContainerHighest: Color(0xffe4e1eb),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff01004f),
      surfaceTint: Color(0xff4b50c4),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff04008d),
      onPrimaryContainer: Color(0xffa6aaff),
      secondary: Color(0xff30325d),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff676997),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff230030),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff440059),
      onTertiaryContainer: Color(0xffde98f1),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffbf8ff),
      onSurface: Color(0xff101117),
      onSurfaceVariant: Color(0xff353542),
      outline: Color(0xff51515f),
      outlineVariant: Color(0xff6c6c7a),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff303037),
      inversePrimary: Color(0xffbfc2ff),
      primaryFixed: Color(0xff5a60d4),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff4046ba),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff676997),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff4f517d),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff9453a6),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff793a8c),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffc7c5cf),
      surfaceBright: Color(0xfffbf8ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff5f2fd),
      surfaceContainer: Color(0xffeae7f1),
      surfaceContainerHigh: Color(0xffdedbe6),
      surfaceContainerHighest: Color(0xffd3d0da),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff01004f),
      surfaceTint: Color(0xff4b50c4),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff04008d),
      onPrimaryContainer: Color(0xffdadaff),
      secondary: Color(0xff262852),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff434571),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff230030),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff440059),
      onTertiaryContainer: Color(0xfff9d0ff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffbf8ff),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff2b2b38),
      outlineVariant: Color(0xff484856),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff303037),
      inversePrimary: Color(0xffbfc2ff),
      primaryFixed: Color(0xff3439ad),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff191b97),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff434571),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff2c2f59),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff6c2e7f),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff521367),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffbab7c1),
      surfaceBright: Color(0xfffbf8ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff2effa),
      surfaceContainer: Color(0xffe4e1eb),
      surfaceContainerHigh: Color(0xffd6d3dd),
      surfaceContainerHighest: Color(0xffc7c5cf),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffbfc2ff),
      surfaceTint: Color(0xffbfc2ff),
      onPrimary: Color(0xff161895),
      primaryContainer: Color(0xff04008d),
      onPrimaryContainer: Color(0xff7b81f7),
      secondary: Color(0xffc1c2f6),
      onSecondary: Color(0xff2a2c56),
      secondaryContainer: Color(0xff434571),
      onSecondaryContainer: Color(0xffb3b4e7),
      tertiary: Color(0xfff0b0ff),
      onTertiary: Color(0xff501064),
      tertiaryContainer: Color(0xff440059),
      onTertiaryContainer: Color(0xffb774c9),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff13131a),
      onSurface: Color(0xffe4e1eb),
      onSurfaceVariant: Color(0xffc6c5d5),
      outline: Color(0xff908f9f),
      outlineVariant: Color(0xff464653),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe4e1eb),
      inversePrimary: Color(0xff4b50c4),
      primaryFixed: Color(0xffe0e0ff),
      onPrimaryFixed: Color(0xff02006d),
      primaryFixedDim: Color(0xffbfc2ff),
      onPrimaryFixedVariant: Color(0xff3136ab),
      secondaryFixed: Color(0xffe0e0ff),
      onSecondaryFixed: Color(0xff141740),
      secondaryFixedDim: Color(0xffc1c2f6),
      onSecondaryFixedVariant: Color(0xff40436e),
      tertiaryFixed: Color(0xfffbd7ff),
      onTertiaryFixed: Color(0xff330044),
      tertiaryFixedDim: Color(0xfff0b0ff),
      onTertiaryFixedVariant: Color(0xff692b7d),
      surfaceDim: Color(0xff13131a),
      surfaceBright: Color(0xff393840),
      surfaceContainerLowest: Color(0xff0d0e14),
      surfaceContainerLow: Color(0xff1b1b22),
      surfaceContainer: Color(0xff1f1f26),
      surfaceContainerHigh: Color(0xff292931),
      surfaceContainerHighest: Color(0xff34343c),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffd9d9ff),
      surfaceTint: Color(0xffbfc2ff),
      onPrimary: Color(0xff04008b),
      primaryContainer: Color(0xff7e85fb),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffd9d9ff),
      onSecondary: Color(0xff1f214b),
      secondaryContainer: Color(0xff8b8dbd),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xfff8cfff),
      onTertiary: Color(0xff430058),
      tertiaryContainer: Color(0xffbb77cd),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffd2cc),
      onError: Color(0xff540003),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff13131a),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffdcdaec),
      outline: Color(0xffb2b0c0),
      outlineVariant: Color(0xff908f9e),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe4e1eb),
      inversePrimary: Color(0xff3337ac),
      primaryFixed: Color(0xffe0e0ff),
      onPrimaryFixed: Color(0xff01004e),
      primaryFixedDim: Color(0xffbfc2ff),
      onPrimaryFixedVariant: Color(0xff1e219a),
      secondaryFixed: Color(0xffe0e0ff),
      onSecondaryFixed: Color(0xff090b36),
      secondaryFixedDim: Color(0xffc1c2f6),
      onSecondaryFixedVariant: Color(0xff30325d),
      tertiaryFixed: Color(0xfffbd7ff),
      onTertiaryFixed: Color(0xff23002f),
      tertiaryFixedDim: Color(0xfff0b0ff),
      onTertiaryFixedVariant: Color(0xff56186a),
      surfaceDim: Color(0xff13131a),
      surfaceBright: Color(0xff44444c),
      surfaceContainerLowest: Color(0xff07070d),
      surfaceContainerLow: Color(0xff1d1d24),
      surfaceContainer: Color(0xff27272f),
      surfaceContainerHigh: Color(0xff32323a),
      surfaceContainerHighest: Color(0xff3d3d45),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xfff0eeff),
      surfaceTint: Color(0xffbfc2ff),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xffbbbdff),
      onPrimaryContainer: Color(0xff01003d),
      secondary: Color(0xfff0eeff),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffbdbef2),
      onSecondaryContainer: Color(0xff040530),
      tertiary: Color(0xffffe9ff),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xffeeaaff),
      onTertiaryContainer: Color(0xff1a0024),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff13131a),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xfff0eeff),
      outlineVariant: Color(0xffc3c1d1),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe4e1eb),
      inversePrimary: Color(0xff3337ac),
      primaryFixed: Color(0xffe0e0ff),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xffbfc2ff),
      onPrimaryFixedVariant: Color(0xff01004e),
      secondaryFixed: Color(0xffe0e0ff),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffc1c2f6),
      onSecondaryFixedVariant: Color(0xff090b36),
      tertiaryFixed: Color(0xfffbd7ff),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xfff0b0ff),
      onTertiaryFixedVariant: Color(0xff23002f),
      surfaceDim: Color(0xff13131a),
      surfaceBright: Color(0xff504f58),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff1f1f26),
      surfaceContainer: Color(0xff303037),
      surfaceContainerHigh: Color(0xff3b3b43),
      surfaceContainerHighest: Color(0xff46464e),
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
