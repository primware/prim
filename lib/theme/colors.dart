// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class ColorTheme {
  //* Colores Modo Claro
  static const Color accentLight = Color(0xFF1F67A6);
  //? colores mas claros que el primario
  static Color get aL100 => _getLighterColor(accentLight, 0.9);
  static Color get aL200 => _getLighterColor(accentLight, 0.8);
  static Color get aL300 => _getLighterColor(accentLight, 0.7);
  static Color get aL400 => _getLighterColor(accentLight, 0.6);
  static Color get aL500 => _getLighterColor(accentLight, 0.5);
  static Color get aL600 => _getLighterColor(accentLight, 0.4);
  //?Colores mas oscuro que el primario
  static Color get aL700 => _getDarkerColor(accentLight, 0.2);
  static Color get aL800 => _getDarkerColor(accentLight, 0.4);
  static Color get aL900 => _getDarkerColor(accentLight, 0.6);

  static const Color textLight = Color(0xFF0C1726);
  //? colores mas claros que el text
  static Color get tL100 => _getLighterColor(textLight, 0.9);
  static Color get tL200 => _getLighterColor(textLight, 0.8);
  static Color get tL300 => _getLighterColor(textLight, 0.7);

  static const Color backgroundLight = Color.fromARGB(255, 240, 240, 240);

  //* Colores Modo Oscuro
  static const Color accentDark = Color.fromARGB(255, 85, 166, 236);
  //? colores mas claros que el primario
  static Color get aD100 => _getLighterColor(accentDark, 0.9);
  static Color get aD200 => _getLighterColor(accentDark, 0.8);
  static Color get aD300 => _getLighterColor(accentDark, 0.7);
  static Color get aD400 => _getLighterColor(accentDark, 0.6);
  static Color get aD500 => _getLighterColor(accentDark, 0.5);
  static Color get aD600 => _getLighterColor(accentDark, 0.4);
  //?Colores mas oscuro que el primario
  static Color get aD700 => _getDarkerColor(accentDark, 0.2);
  static Color get aD800 => _getDarkerColor(accentDark, 0.4);
  static Color get aD900 => _getDarkerColor(accentDark, 0.6);

  static const Color textDark = Color(0xFFFFFFFF);
  //? colores mas oscuros que el text
  static Color get tD100 => _getDarkerColor(textDark, 0.9);
  static Color get tD200 => _getDarkerColor(textDark, 0.8);
  static Color get tD300 => _getDarkerColor(textDark, 0.7);

  static const Color backgroundDark = Color(0xFF0D0D0D);

  //* Colores de alertas
  static const Color success = Color(0xFF00B69B);
  static const Color atention = Color(0xFFFFA756);
  static const Color error = Color(0xFFEF3826);
  static const Color info = Color(0xFF5A8CFF);

  static Color _getLighterColor(Color color, double fraction) {
    return Color.fromARGB(
      color.alpha,
      (color.red + (255 - color.red) * fraction).round(),
      (color.green + (255 - color.green) * fraction).round(),
      (color.blue + (255 - color.blue) * fraction).round(),
    );
  }

  static Color _getDarkerColor(Color color, double fraction) {
    return Color.fromARGB(
      color.alpha,
      (color.red * (1 - fraction)).round(),
      (color.green * (1 - fraction)).round(),
      (color.blue * (1 - fraction)).round(),
    );
  }
}
