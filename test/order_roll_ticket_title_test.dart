import 'package:flutter_test/flutter_test.dart';
import 'package:primware/API/pos.api.dart';
import 'package:primware/localization/app_locale.dart';
import 'package:primware/views/Home/order/my_order_print_generator.dart';

void main() {
  tearDown(() => POS.docTypesComplete = []);

  test('order FE name takes priority over current session document types', () {
    POS.docTypesComplete = [
      {'id': '10', 'FE_tipoDocumento': 'Otro nombre'},
    ];
    expect(orderRollTicketTitle({
      'doctypetarget': {'id': 10, 'name': 'Orden POS', 'FE_tipoDocumento': 'Factura de operación interna'},
    }), 'Factura de operación interna');
  });

  test('explicit null keeps existing title even if session data differs', () {
    POS.docTypesComplete = [
      {'id': '10', 'FE_tipoDocumento': 'Otro nombre'},
    ];
    expect(orderRollTicketTitle({
      'doctypetarget': {'id': 10, 'name': 'Orden POS', 'FE_tipoDocumento': null},
    }), 'Orden POS');
  });

  test('older payload uses matching document map for sale and refund regardless of POS mode', () {
    POS.docTypesComplete = [
      {'id': '10', 'FE_tipoDocumento': 'Factura'},
      {'id': '20', 'FE_tipoDocumento': 'Nota de crédito'},
    ];
    for (final id in [10, 20]) {
      expect(orderRollTicketTitle({
        'doctypetarget': {'id': id, 'name': 'Nombre anterior'},
      }), id == 10 ? 'Factura' : 'Nota de crédito');
    }
  });

  test('missing FE name or document preserves fallback without errors', () {
    expect(orderRollTicketTitle({'doctypetarget': {'id': 99, 'name': 'Orden a crédito'}}), 'Orden a crédito');
    expect(orderRollTicketTitle({}), '');
    expect(AppLocale.es[AppLocale.ticketReceiptNumberLabel], 'Número');
    expect(AppLocale.en[AppLocale.ticketReceiptNumberLabel], 'Number');
  });
}
