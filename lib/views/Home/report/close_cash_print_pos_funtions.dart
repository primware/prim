import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:primware/API/pos.api.dart';
import '../../../shared/format_date.dart';

Future<Uint8List> generateCloseCashPOSTicket(Map<String, dynamic> data) async {
  final pdf = pw.Document();
  final pageFormat = PdfPageFormat.roll80;

  // Helpers
  String str(dynamic v) => v?.toString() ?? '';
  bool hasHeaderValue(dynamic value) => value != null && value.toString().isNotEmpty;
  String money(num? v) => 'B/.${(v ?? 0).toDouble().toStringAsFixed(2)}';
  double toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  // Data fields
  final terminal = str(data['C_POS_ID']?['name'] ?? '---');
  final rep = str(data['SalesRep_ID']?['name'] ?? '---');
  final String dateTrx = formatDateUI(str(data['DateTrx']));
  final String dateFrom = formatDateUI(str(data['DateFrom']));
  final int totalOrders = (data['QtyOrders'] ?? 0) as int;

  final double taxBase = toDouble(data['TaxBaseAmt']);
  final double taxAmt = toDouble(data['TaxAmt']);
  final double exemptAmt = toDouble(data['ExemptAmt']);
  final double totalOrdersAmt = toDouble(data['TotalOrdersAmt']);
  final double grandTotal = toDouble(data['GrandTotal']);

  // Devoluciones
  final int totalReturns = (data['QtyReturns'] ?? 0) as int;
  final double returnTaxBase = toDouble(data['ReturnTaxBaseAmt']);
  final double returnTaxAmt = toDouble(data['ReturnTaxAmt']);
  final double returnExemptAmt = toDouble(data['ReturnExemptAmt']);
  final double totalReturnsAmt = toDouble(data['TotalReturnsAmt']);

  final List<dynamic> payments = (data['payments'] ?? []) as List<dynamic>;

  final baseTextStyle = pw.TextStyle(fontSize: 8);
  final boldTextStyle = pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold);

  final theme = pw.ThemeData.withFont(base: pw.Font.helvetica(), bold: pw.Font.helveticaBold()).copyWith(defaultTextStyle: baseTextStyle);

  pdf.addPage(
    pw.Page(
      pageFormat: pageFormat,
      theme: theme,
      margin: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (POSPrinter.isLogoSet && POSPrinter.logo != null)
              pw.Image(pw.MemoryImage(POSPrinter.logo!), width: 100, height: 100, fit: pw.BoxFit.contain)
            else
              pw.SizedBox(),
            pw.SizedBox(height: 4),
            if (hasHeaderValue(POSPrinter.headerName)) pw.Text(POSPrinter.headerName!, textAlign: pw.TextAlign.center),
            if (hasHeaderValue(POSPrinter.headerAddress)) pw.Text(POSPrinter.headerAddress!, textAlign: pw.TextAlign.center),
            if (hasHeaderValue(POSPrinter.headerTaxID)) pw.Text('RUC: ${POSPrinter.headerTaxID}', textAlign: pw.TextAlign.center),
            if (hasHeaderValue(POSPrinter.headerDV)) pw.Text('DV: ${POSPrinter.headerDV}', textAlign: pw.TextAlign.center),
            if (hasHeaderValue(POSPrinter.headerPhone)) pw.Text('Tel: ${POSPrinter.headerPhone}', textAlign: pw.TextAlign.center),
            if (hasHeaderValue(POSPrinter.headerEmail)) pw.Text(POSPrinter.headerEmail!, textAlign: pw.TextAlign.center),

            if (hasHeaderValue(POSPrinter.header1)) pw.Text(POSPrinter.header1!, textAlign: pw.TextAlign.center),
            if (hasHeaderValue(POSPrinter.header2)) pw.Text(POSPrinter.header2!, textAlign: pw.TextAlign.center),
            if (hasHeaderValue(POSPrinter.header3)) pw.Text(POSPrinter.header3!, textAlign: pw.TextAlign.center),
            if (hasHeaderValue(POSPrinter.header4)) pw.Text(POSPrinter.header4!, textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 12),
            pw.Text(
              'Cierre de Caja',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
            pw.SizedBox(height: 12),

            // Detalles (alineados a la izquierda)
            pw.Container(
              alignment: pw.Alignment.centerLeft,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Terminal: $terminal'),
                  pw.Text('Representante: $rep'),
                  pw.Text('Fecha: ${dateTrx.isEmpty ? "---" : dateTrx}'),
                  pw.Text('Desde: ${dateFrom.isEmpty ? "---" : dateFrom}'),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Resumen de Ordenes
            pw.Text('--- ÓRDENES ---', style: boldTextStyle),
            pw.SizedBox(height: 4),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Cantidad:'), pw.Text('$totalOrders')]),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Base Impuesto:'), pw.Text(money(taxBase))]),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Impuesto:'), pw.Text(money(taxAmt))]),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Exento:'), pw.Text(money(exemptAmt))]),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Órdenes:', style: boldTextStyle),
                pw.Text(money(totalOrdersAmt), style: boldTextStyle),
              ],
            ),
            pw.SizedBox(height: 8),

            // Resumen de Devoluciones
            pw.Text('--- DEVOLUCIONES ---', style: boldTextStyle),
            pw.SizedBox(height: 4),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Cantidad:'), pw.Text('$totalReturns')]),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [pw.Text('Base Imp. Dev:'), pw.Text(money(returnTaxBase))],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [pw.Text('Impuesto Dev:'), pw.Text(money(returnTaxAmt))],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [pw.Text('Exento Dev:'), pw.Text(money(returnExemptAmt))],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Devoluciones:', style: boldTextStyle),
                pw.Text(money(totalReturnsAmt), style: boldTextStyle),
              ],
            ),
            pw.SizedBox(height: 12),

            // Gran Total
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('GRAN TOTAL:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text(money(grandTotal), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Metodos de Pago
            if (payments.isNotEmpty) ...[
              pw.Text('--- MÉTODOS DE PAGO ---', style: boldTextStyle),
              pw.SizedBox(height: 6),
              pw.Column(
                children: payments.map((p) {
                  final dynamic tenderField = p['C_POSTenderType_ID'] ?? p['TenderType'] ?? p['tender'] ?? p['PaymentMethod'];
                  final String tenderName = (tenderField is Map)
                      ? (tenderField['identifier'] ?? tenderField['name'] ?? '---').toString()
                      : tenderField?.toString() ?? '---';
                  final double amt = toDouble(p['PayAmt'] ?? p['Amount'] ?? p['Amt'] ?? 0);
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(child: pw.Text(tenderName)),
                        pw.Text(money(amt)),
                      ],
                    ),
                  );
                }).toList(),
              ),
              pw.SizedBox(height: 12),
            ],

            // Pie de pagina (footer)
            if (hasHeaderValue(POSPrinter.footer1)) pw.Text(POSPrinter.footer1!, textAlign: pw.TextAlign.center),
            if (hasHeaderValue(POSPrinter.footer2)) pw.Text(POSPrinter.footer2!, textAlign: pw.TextAlign.center),
            if (hasHeaderValue(POSPrinter.footer3)) pw.Text(POSPrinter.footer3!, textAlign: pw.TextAlign.center),
            if (hasHeaderValue(POSPrinter.footer4)) pw.Text(POSPrinter.footer4!, textAlign: pw.TextAlign.center),
          ],
        );
      },
    ),
  );

  return pdf.save();
}
