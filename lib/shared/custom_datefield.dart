import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';

class CustomDateField extends StatelessWidget {
  final TextEditingController controller;
  final Function(DateTime?) onChanged;
  final String labelText;
  final DateTime? initialValue;
  final bool readOnly;
  final bool includeTime;

  const CustomDateField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.labelText,
    this.initialValue,
    this.readOnly = false,
    this.includeTime = false,
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
                DateTime finalDate = pickedDate;

                if (includeTime) {
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );

                  if (pickedTime != null) {
                    finalDate = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      pickedTime.hour,
                      pickedTime.minute,
                    );
                  }
                }

                final String formatted = includeTime
                    ? DateFormat('yyyy-MM-dd HH:mm').format(finalDate)
                    : DateFormat('yyyy-MM-dd').format(finalDate);

                controller.text = formatted;
                onChanged(finalDate);
              }
            },
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          readOnly: readOnly,
          decoration: InputDecoration(
            fillColor: Theme.of(context).colorScheme.surface,
            filled: true,
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
                    : Theme.of(context).colorScheme.outline,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: controller.text.isEmpty
                    ? ColorTheme.error
                    : Theme.of(context).colorScheme.onSurface,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
      ),
    );
  }
}
