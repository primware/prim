import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FontsTheme {
  static TextStyle mont = GoogleFonts.montserrat();
  static TextStyle inter = GoogleFonts.inter();

  static TextStyle h1Bold({Color? color}) {
    return inter.copyWith(
        color: color, fontSize: 72, fontWeight: FontWeight.w700);
  }

  static TextStyle h1({Color? color}) {
    return inter.copyWith(
      color: color,
      fontSize: 72,
    );
  }

  static TextStyle h2Bold({Color? color}) {
    return inter.copyWith(
        color: color, fontSize: 48, fontWeight: FontWeight.w700);
  }

  static TextStyle h2({Color? color}) {
    return inter.copyWith(
      color: color,
      fontSize: 48,
    );
  }

  static TextStyle h3Bold({Color? color}) {
    return inter.copyWith(
        color: color, fontSize: 42, fontWeight: FontWeight.w700);
  }

  static TextStyle h3({Color? color}) {
    return inter.copyWith(
      color: color,
      fontSize: 42,
    );
  }

  static TextStyle h4Bold({Color? color}) {
    return inter.copyWith(
        color: color, fontSize: 24, fontWeight: FontWeight.w700);
  }

  static TextStyle h4({Color? color}) {
    return inter.copyWith(
      color: color,
      fontSize: 24,
    );
  }

  static TextStyle h5Bold({Color? color}) {
    return inter.copyWith(
        color: color, fontSize: 18, fontWeight: FontWeight.w700);
  }

  static TextStyle h5({Color? color}) {
    return inter.copyWith(
      color: color,
      fontSize: 18,
    );
  }

  static TextStyle h6Bold({Color? color}) {
    return inter.copyWith(
        color: color, fontSize: 12, fontWeight: FontWeight.w700);
  }

  static TextStyle h6({Color? color}) {
    return inter.copyWith(
      color: color,
      fontSize: 12,
    );
  }

  static TextStyle pBold({Color? color}) {
    return mont.copyWith(
        color: color, fontSize: 18, fontWeight: FontWeight.w700);
  }

  static TextStyle p({Color? color}) {
    return mont.copyWith(
      color: color,
      fontSize: 18,
    );
  }

  static TextStyle pMini({Color? color}) {
    return mont.copyWith(
      color: color,
      fontSize: 14,
    );
  }
}
