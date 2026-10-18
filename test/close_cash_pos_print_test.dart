import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:primware/API/pos.api.dart';
import 'package:primware/views/Home/report/close_cash_print_pos_funtions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('POS cash closing uses 75 mm paper and grows with payment content', () async {
    POSPrinter.logo = null;
    final heights = <double>[];
    for (final count in [0, 2, 60]) {
      final bytes = await generateCloseCashPOSTicket({
        'C_POS_ID': {'name': 'Caja de prueba'},
        'QtyOrders': 2,
        'payments': List.generate(count, (i) => {'TenderType': 'Pago $i', 'PayAmt': 10}),
      });
      final source = latin1.decode(bytes);
      final boxes = RegExp(r'/MediaBox\s*\[\s*([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s*\]').allMatches(source).toList();
      expect(boxes, hasLength(1));
      final width = double.parse(boxes.single.group(3)!) - double.parse(boxes.single.group(1)!);
      final height = double.parse(boxes.single.group(4)!) - double.parse(boxes.single.group(2)!);
      expect(width, closeTo(75 * PdfPageFormat.mm, 0.01));
      expect(height.isFinite, isTrue);
      expect(height, greaterThan(0));
      heights.add(height);
    }
    expect(heights[1], greaterThan(heights[0]));
    expect(heights[2], greaterThan(heights[1]));
  });
}
