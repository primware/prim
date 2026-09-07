import 'package:intl/intl.dart';

String formatDateUI(String dateStr) {
  if (dateStr.isEmpty) return '---';
  try {
    final DateTime dt = DateTime.parse(dateStr);
    return DateFormat('dd/MM/yyyy hh:mm a').format(dt);
  } catch (e) {
    return dateStr;
  }
}
