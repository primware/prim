import 'package:flutter/material.dart';
import '../theme/fonts.dart';

class BotonDialog extends StatelessWidget {
  const BotonDialog(
      {super.key,
      required this.text,
      required this.bgcolor,
      required this.onPressed});

  final String text;
  final void Function()? onPressed;
  final Color bgcolor;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: ButtonStyle(
        padding: WidgetStateProperty.resolveWith(
          (states) => const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) => bgcolor),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: FontsTheme.h4Bold(color: Colors.white),
      ),
    );
  }
}
