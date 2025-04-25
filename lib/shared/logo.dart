import 'package:flutter/material.dart';

class Logo extends StatelessWidget {
  const Logo({super.key, this.width});

  final double? width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/img/logo.png',
      width: width,
    );
  }
}
