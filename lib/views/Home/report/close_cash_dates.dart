import 'package:intl/intl.dart';

// iDempiere usa estos campos como hora de pared. La Z pertenece al formato
// del servicio existente; no convertir a UTC ni aplicar el offset del equipo.
String formatCloseCashDateForApi(String input) {
  final s = input.trim();
  if (s.isEmpty) return s;

  if (RegExp(r"Z$").hasMatch(s) && s.contains('T')) return s;

  DateTime dt;
  try {
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) {
      dt = DateFormat('yyyy-MM-dd').parseStrict(s);
    } else if (RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$').hasMatch(s)) {
      dt = DateFormat('yyyy-MM-dd HH:mm:ss').parseStrict(s);
    } else {
      dt = DateFormat('yyyy-MM-dd HH:mm').parseStrict(s);
    }
  } catch (e) {
    throw FormatException('Formato de fecha no soportado: $s');
  }

  return DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(dt);
}

// Conserva la hora recibida para coincidir con el encabezado de iDempiere.
String formatCloseCashDateUI(String value) {
  if (value.isEmpty) return '---';
  try {
    final date = DateTime.parse(value);
    return DateFormat('dd/MM/yyyy hh:mm a').format(date);
  } catch (_) {
    return value;
  }
}
