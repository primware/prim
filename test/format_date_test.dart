import 'package:flutter_test/flutter_test.dart';
import 'package:primware/shared/format_date.dart';

void main() {
  test('Mis órdenes conserva la hora de iDempiere', () {
    expect(formatIdempiereDateUI('2026-09-09T09:36:00Z'),
        '09/09/2026 09:36 AM');
    expect(formatIdempiereDateUI('2026-09-09T00:32:00Z'),
        '09/09/2026 12:32 AM');
    expect(formatIdempiereDateUI('2026-09-09T23:59:00Z'),
        '09/09/2026 11:59 PM');
  });

  test('admite fechas sin zona y valores faltantes', () {
    expect(formatIdempiereDateUI('2026-09-09T09:36:00'),
        '09/09/2026 09:36 AM');
    expect(formatIdempiereDateUI(''), '---');
    expect(formatIdempiereDateUI('inválida'), 'inválida');
  });

  test('los recibos locales mantienen su conversión a hora local', () {
    final local = DateTime(2026, 9, 9, 9, 36);
    expect(formatDateUI(local.toIso8601String()), '09/09/2026 09:36 AM');
    expect(formatDateUI(local.toUtc().toIso8601String()),
        '09/09/2026 09:36 AM');
  });
}
