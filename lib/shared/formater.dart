import 'package:flutter/services.dart';

class CurrencyTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return getCurrencyValue(newValue: newValue, oldValue: oldValue);
  }
}

TextEditingValue getCurrencyValue(
    {required TextEditingValue newValue, required TextEditingValue oldValue}) {
  const int maxValue = 100000; //MAX VALUE OF TEXTFIELD
  final int selectionIndexFromTheRight =
      newValue.text.length - newValue.selection.end;
  double newValueNumber =
      double.tryParse(newValue.text.replaceAll("\$", "")) ?? 0;
  final oldValueNumber =
      double.tryParse(oldValue.text.replaceAll("\$", "")) ?? 0;

  if (newValueNumber == 0 && oldValueNumber == 0) {
    final newString = oldValueNumber.toStringAsFixed(2);
    return TextEditingValue(
        text: newString,
        selection: TextSelection.collapsed(
            offset: newString.length - selectionIndexFromTheRight));
  }
  if (oldValueNumber > newValueNumber ||
      (newValue.text.length < oldValue.text.length &&
          oldValueNumber == newValueNumber)) {
    newValueNumber = newValueNumber / 10;
  } else if (oldValueNumber == 0) {
    final lastNumber =
        int.tryParse(newValue.text.substring(newValue.text.length - 1)) ?? 0;
    newValueNumber = oldValueNumber + (lastNumber / 100);
  } else {
    final lastNumber =
        int.tryParse(newValue.text.substring(newValue.text.length - 1)) ?? 0;
    newValueNumber = (oldValueNumber * 10) + (lastNumber / 100);
  }
  if (newValueNumber >= maxValue) {
    final newString = oldValueNumber.toStringAsFixed(2);
    return TextEditingValue(
        text: newString,
        selection: TextSelection.collapsed(
            offset: newString.length - selectionIndexFromTheRight));
  }
  final newString = newValueNumber.toStringAsFixed(2);
  return TextEditingValue(
    text: newString,
    selection: TextSelection.collapsed(
        offset: newString.length - selectionIndexFromTheRight),
  );
}

class NumericTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    if (int.tryParse(newValue.text) != null) {
      return newValue;
    }
    return oldValue;
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(
      text: newValue.text.toLowerCase(),
      selection: newValue.selection,
    );
  }
}

class NoAccentsFormatter extends TextInputFormatter {
  static final _allowedChars = RegExp(r"[A-Za-zÑñ\s,.\#\-_]");

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final filtered = newValue.text
        .split('')
        .where((char) => _allowedChars.hasMatch(char))
        .join();

    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }
}
