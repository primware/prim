import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../theme/fonts.dart';

class CustomDateField extends StatelessWidget {
  final TextEditingController controller;
  final Function(DateTime?) onChanged;
  final String labelText;
  final DateTime? initialValue;
  final bool readOnly;

  const CustomDateField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.labelText,
    this.initialValue,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: readOnly
          ? null
          : () async {
              DateTime initialDate = initialValue ?? DateTime.now();
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
                initialEntryMode: DatePickerEntryMode.calendarOnly,
              );
              if (pickedDate != null) {
                String formattedDate =
                    DateFormat('yyyy-MM-dd').format(pickedDate);
                controller.text = formattedDate;
                onChanged(pickedDate);
              }
            },
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          readOnly: readOnly,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(
              Icons.event_note,
              color: ColorTheme.accentLight,
            ),
            labelText: labelText,
            floatingLabelStyle: FontsTheme.h5(color: ColorTheme.accentLight),
            hoverColor: ColorTheme.aL100,
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  width: 1,
                  color: controller.text.isEmpty
                      ? ColorTheme.error
                      : ColorTheme.textLight),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: controller.text.isEmpty
                      ? ColorTheme.error
                      : ColorTheme.textLight),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
      ),
    );
  }
}
