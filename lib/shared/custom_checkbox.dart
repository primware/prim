import 'package:flutter/material.dart';
import 'package:primware/theme/fonts.dart';

import '../theme/colors.dart';

class CustomCheckbox extends StatefulWidget {
  final bool value;
  final String text;
  final ValueChanged<bool> onChanged;

  const CustomCheckbox({
    super.key,
    required this.value,
    required this.text,
    required this.onChanged,
  });

  @override
  State<CustomCheckbox> createState() => _CustomCheckboxState();
}

class _CustomCheckboxState extends State<CustomCheckbox> {
  late bool _status;

  @override
  void initState() {
    super.initState();
    _status = widget.value;
  }

  @override
  void didUpdateWidget(CustomCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      setState(() {
        _status = widget.value;
      });
    }
  }

  void _toggleCheckbox() {
    setState(() {
      _status = !_status;
    });
    widget.onChanged(_status);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _toggleCheckbox,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: _status,
            checkColor: ColorTheme.textDark,
            activeColor: ColorTheme.accentLight,
            onChanged: (bool? value) {
              if (value != null) {
                _toggleCheckbox();
              }
            },
          ),
          const SizedBox(width: 4),
          Text(
            widget.text,
            style: FontsTheme.p(),
          ),
        ],
      ),
    );
  }
}
