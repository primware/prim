import 'package:flutter/material.dart';

import '../theme/fonts.dart';

class CustomFlatButton extends StatefulWidget {
  final String text;
  final Color fontcolor, backgroundcolor;
  final Function onPressed;

  const CustomFlatButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.fontcolor,
    required this.backgroundcolor,
  });

  @override
  State<CustomFlatButton> createState() => _CustomFlatButtonState();
}

class _CustomFlatButtonState extends State<CustomFlatButton> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: widget.backgroundcolor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: () => widget.onPressed(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text(
              widget.text,
              style: FontsTheme.h5(color: widget.fontcolor),
            ),
          )),
    );
  }
}
