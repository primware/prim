import 'package:flutter/material.dart';

class CustomFlatButton extends StatefulWidget {
  final String text;
  final Function onPressed;

  const CustomFlatButton({
    super.key,
    required this.text,
    required this.onPressed,
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
            backgroundColor: Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: () => widget.onPressed(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              widget.text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.surface,
                  ),
            ),
          )),
    );
  }
}
