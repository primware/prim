import 'package:flutter/material.dart';

class CustomContainer extends StatelessWidget {
  const CustomContainer(
      {super.key,
      this.maxWidthContainer = 800,
      this.padding = 16,
      required this.child,
      this.margin = const EdgeInsets.all(12)});
  final double maxWidthContainer, padding;
  final Widget child;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.none,
      margin: margin,
      constraints: BoxConstraints(maxWidth: maxWidthContainer),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withAlpha(40),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(12, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}
