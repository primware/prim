import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';

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
            suffixIcon: Icon(
              Icons.event_note,
              color: Theme.of(context).colorScheme.primary,
            ),
            labelText: labelText,
            floatingLabelStyle: Theme.of(context).textTheme.bodySmall,
            hoverColor: Theme.of(context).colorScheme.primary,
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  width: 1,
                  color: controller.text.isEmpty
                      ? ColorTheme.error
                      : Theme.of(context).colorScheme.outline),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: controller.text.isEmpty
                      ? ColorTheme.error
                      : Theme.of(context).colorScheme.onSurface),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
      ),
    );
  }
}
