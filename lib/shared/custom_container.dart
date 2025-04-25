import 'package:flutter/material.dart';
import 'package:primware/theme/colors.dart';

class CustomContainer extends StatelessWidget {
  const CustomContainer(
      {super.key,
      required this.maxWidthContainer,
      required this.child,
      this.margin});
  final double maxWidthContainer;
  final Widget child;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      constraints: BoxConstraints(maxWidth: maxWidthContainer),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ColorTheme.textDark,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: ColorTheme.accentLight.withAlpha(40),
            spreadRadius: 8,
            blurRadius: 24,
            offset: const Offset(20, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}
