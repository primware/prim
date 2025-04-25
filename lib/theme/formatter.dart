import 'package:flutter/services.dart';

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    final formattedText = _applyPhoneMask(text);
    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }

  String _applyPhoneMask(String text) {
    if (text.length <= 4) {
      return text;
    } else {
      return '${text.substring(0, 4)}-${text.substring(4)}';
    }
  }
}
