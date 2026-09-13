import 'package:flutter/material.dart';

class Logo extends StatelessWidget {
  const Logo({super.key, this.width});

  final double? width;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      isDark ? 'assets/img/logoBlanco.png' : 'assets/img/logo.png',
      width: width,
    );
  }
}
