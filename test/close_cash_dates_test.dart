import 'package:flutter_test/flutter_test.dart';
import 'package:primware/views/Home/report/close_cash_dates.dart';

void main() {
  test('envía la hora del cierre sin sumar cinco horas', () {
    expect(formatCloseCashDateForApi('2026-09-09 09:34:15'),
        '2026-09-09T09:34:15Z');
    expect(formatCloseCashDateForApi('2026-09-09 23:59:59'),
        '2026-09-09T23:59:59Z');
  });

  test('muestra Desde Fecha sin restar cinco horas', () {
    expect(formatCloseCashDateUI('2026-09-09T09:26:43Z'),
        '09/09/2026 09:26 AM');
    expect(formatCloseCashDateUI('2026-09-09T00:26:43Z'),
        '09/09/2026 12:26 AM');
  });

  test('crear y actualizar conservan la hora al volver a mostrarla', () {
    expect(
        formatCloseCashDateUI(
            formatCloseCashDateForApi('2026-09-09 09:34:15')),
        '09/09/2026 09:34 AM');
  });

  test('conserva los formatos admitidos y maneja valores vacíos', () {
    expect(formatCloseCashDateForApi('2026-09-09'), '2026-09-09T00:00:00Z');
    expect(formatCloseCashDateForApi('2026-09-09 09:34'),
        '2026-09-09T09:34:00Z');
    expect(formatCloseCashDateForApi('2026-09-09T09:34:15Z'),
        '2026-09-09T09:34:15Z');
    expect(formatCloseCashDateUI(''), '---');
    expect(formatCloseCashDateUI('inválida'), 'inválida');
    expect(() => formatCloseCashDateForApi('inválida'), throwsFormatException);
  });
}
