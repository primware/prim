import 'package:intl/intl.dart';

// Las fechas del ERP contienen la hora de pared de iDempiere, incluso con Z.
// No aplicar la zona del dispositivo al mostrarlas.
String formatIdempiereDateUI(String dateStr) {
  if (dateStr.isEmpty) return '---';
  try {
    return DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.parse(dateStr));
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
