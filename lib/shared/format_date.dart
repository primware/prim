import 'package:intl/intl.dart';

// Mostrar las fechas del ERP en la zona horaria local del dispositivo.
String formatIdempiereDateUI(String dateStr) {
  if (dateStr.isEmpty) return '---';
  try {
    return DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.parse(dateStr).toLocal());
  } catch (_) {
    return dateStr;
  }
}

String formatDateUI(String dateStr) {
  if (dateStr.isEmpty) return '---';
  try {
    final DateTime dt = DateTime.parse(dateStr).toLocal();
    return DateFormat('dd/MM/yyyy hh:mm a').format(dt);
  } catch (e) {
    return dateStr;
  }
}
