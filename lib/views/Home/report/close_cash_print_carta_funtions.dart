import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:primware/API/pos.api.dart';
import 'package:intl/intl.dart';

Future<Uint8List> generateCloseCashCartaTicket(Map<String, dynamic> data) async {
  final pdf = pw.Document();
  final pageFormat = PdfPageFormat.letter;

  // Helpers
  String str(dynamic v) => v?.toString() ?? '';
  bool hasHeaderValue(dynamic value) => value != null && value.toString().isNotEmpty;
  String money(num? v) => 'B/.${(v ?? 0).toDouble().toStringAsFixed(2)}';
  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final DateTime dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd/MM/yyyy hh:mm a').format(dt);
    } catch (e) {
      return dateStr;
    }
  }

  // Data fields
  final docNo = str(data['DocumentNo']);
  final terminal = str(data['C_POS_ID']?['name'] ?? '---');
  final rep = str(data['SalesRep_ID']?['name'] ?? '---');
  final String dateTrx = _formatDate(str(data['DateTrx']));
  final String dateFrom = _formatDate(str(data['DateFrom']));
  final int totalOrders = (data['QtyOrders'] ?? 0) as int;

  final double taxBase = _toDouble(data['TaxBaseAmt']);
  final double taxAmt = _toDouble(data['TaxAmt']);
  final double exemptAmt = _toDouble(data['ExemptAmt']);
  final double totalOrdersAmt = _toDouble(data['TotalOrdersAmt']);
  final double grandTotal = _toDouble(data['GrandTotal']);

  // Devoluciones
  final int totalReturns = (data['QtyReturns'] ?? 0) as int;
  final double returnTaxBase = _toDouble(data['ReturnTaxBaseAmt']);
  final double returnTaxAmt = _toDouble(data['ReturnTaxAmt']);
  final double returnExemptAmt = _toDouble(data['ReturnExemptAmt']);
  final double totalReturnsAmt = _toDouble(data['TotalReturnsAmt']);

  final List<dynamic> payments = (data['payments'] ?? []) as List<dynamic>;

  final baseTextStyle = pw.TextStyle(fontSize: 10);
  final smallTextStyle = pw.TextStyle(fontSize: 8);
  final boldTextStyle = pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);
  final titleStyle = pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold);
  final headerStyle = pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white);

  final theme = pw.ThemeData.withFont(
    base: pw.Font.helvetica(),
    bold: pw.Font.helveticaBold(),
  ).copyWith(defaultTextStyle: baseTextStyle);

  // Table Headers
  pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      color: PdfColors.blueGrey800,
      alignment: pw.Alignment.centerLeft,
      child: pw.Text(text, style: headerStyle),
    );
  }

  // Cell formatters
  pw.Widget _buildCell(String text, {pw.TextAlign align = pw.TextAlign.left, bool isBold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      alignment: align == pw.TextAlign.right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
      child: pw.Text(text, style: isBold ? boldTextStyle : baseTextStyle),
    );
  }

  pdf.addPage(
    pw.Page(
      pageFormat: pageFormat,
      theme: theme,
      margin: const pw.EdgeInsets.all(40),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // HEADER SECTION
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Logo
                if (POSPrinter.isLogoSet && POSPrinter.logo != null)
                  pw.Image(
                    pw.MemoryImage(POSPrinter.logo!),
                    width: 120,
                    height: 120,
                    fit: pw.BoxFit.contain,
                  )
                else
                  pw.SizedBox(width: 120, height: 120),

                // Company Info
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      if (hasHeaderValue(POSPrinter.headerName))
                        pw.Text(POSPrinter.headerName!, style: titleStyle),
                      if (hasHeaderValue(POSPrinter.headerAddress))
                        pw.Text(POSPrinter.headerAddress!, textAlign: pw.TextAlign.right),
                      if (hasHeaderValue(POSPrinter.headerTaxID))
                        pw.Text('RUC: ${POSPrinter.headerTaxID}'),
                      if (hasHeaderValue(POSPrinter.headerDV))
                        pw.Text('DV: ${POSPrinter.headerDV}'),
                      if (hasHeaderValue(POSPrinter.headerPhone))
                        pw.Text('Tel: ${POSPrinter.headerPhone}'),
                      if (hasHeaderValue(POSPrinter.headerEmail))
                        pw.Text(POSPrinter.headerEmail!),
                      if (hasHeaderValue(POSPrinter.header1))
                        pw.Text(POSPrinter.header1!),
                      if (hasHeaderValue(POSPrinter.header2))
                        pw.Text(POSPrinter.header2!),
                      if (hasHeaderValue(POSPrinter.header3))
                        pw.Text(POSPrinter.header3!),
                      if (hasHeaderValue(POSPrinter.header4))
                        pw.Text(POSPrinter.header4!),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 10),

            // REPORT TITLE
            pw.Center(
              child: pw.Text('REPORTE DE CIERRE DE CAJA', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),

            // METADATA
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(children: [pw.Text('Terminal: ', style: boldTextStyle), pw.Text(terminal)]),
                      pw.SizedBox(height: 4),
                      pw.Row(children: [pw.Text('Cajero/Responsable: ', style: boldTextStyle), pw.Text(rep)]),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [pw.Text('Desde Fecha: ', style: boldTextStyle), pw.Text(dateFrom.isEmpty ? "---" : dateFrom)]),
                      pw.SizedBox(height: 4),
                      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [pw.Text('Fecha de Cierre: ', style: boldTextStyle), pw.Text(dateTrx.isEmpty ? "---" : dateTrx)]),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 25),

            // SUMMARY TABLES
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Orders Table
                pw.Expanded(
                  child: pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    children: [
                      pw.TableRow(children: [_buildTableHeader('ÓRDENES')]),
                      pw.TableRow(children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Column(
                            children: [
                              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Cantidad de Órdenes:'), pw.Text('$totalOrders')]),
                              pw.SizedBox(height: 4),
                              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Base Impuesto:'), pw.Text(money(taxBase))]),
                              pw.SizedBox(height: 4),
                              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Total Impuesto:'), pw.Text(money(taxAmt))]),
                              pw.SizedBox(height: 4),
                              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Total Exento:'), pw.Text(money(exemptAmt))]),
                              pw.Divider(),
                              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Total Órdenes:', style: boldTextStyle), pw.Text(money(totalOrdersAmt), style: boldTextStyle)]),
                            ],
                          ),
                        )
                      ]),
                    ],
                  ),
                ),
                pw.SizedBox(width: 15),
                // Returns Table
                pw.Expanded(
                  child: pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    children: [
                      pw.TableRow(children: [_buildTableHeader('DEVOLUCIONES')]),
                      pw.TableRow(children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Column(
                            children: [
                              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Cantidad de Devoluciones:'), pw.Text('$totalReturns')]),
                              pw.SizedBox(height: 4),
                              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Base Imp. (Devolución):'), pw.Text(money(returnTaxBase))]),
                              pw.SizedBox(height: 4),
                              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Impuesto (Devolución):'), pw.Text(money(returnTaxAmt))]),
                              pw.SizedBox(height: 4),
                              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Exento (Devolución):'), pw.Text(money(returnExemptAmt))]),
                              pw.Divider(),
                              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Total Devoluciones:', style: boldTextStyle), pw.Text(money(totalReturnsAmt), style: boldTextStyle)]),
                            ],
                          ),
                        )
                      ]),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 25),

            // GRAND TOTAL
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('GRAN TOTAL', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text(money(grandTotal), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                ],
              ),
            ),
            pw.SizedBox(height: 25),

            // PAYMENTS TABLE
            if (payments.isNotEmpty) ...[
              pw.Text('MÉTODOS DE PAGO', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                    children: [
                      _buildTableHeader('Método'),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text('Monto', style: headerStyle),
                      ),
                    ],
                  ),
                  ...payments.map((p) {
                    final dynamic tenderField = p['C_POSTenderType_ID'] ?? p['TenderType'] ?? p['tender'] ?? p['PaymentMethod'];
                    final String tenderName = (tenderField is Map) ? (tenderField['identifier'] ?? tenderField['name'] ?? '---').toString() : tenderField?.toString() ?? '---';
                    final double amt = _toDouble(p['PayAmt'] ?? p['Amount'] ?? p['Amt'] ?? 0);

                    return pw.TableRow(
                      children: [
                        _buildCell(tenderName),
                        _buildCell(money(amt), align: pw.TextAlign.right),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ],

            pw.Spacer(),

            // FOOTER SECTION
            pw.Center(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Divider(color: PdfColors.grey300),
                  pw.SizedBox(height: 8),
                  if (hasHeaderValue(POSPrinter.footer1))
                    pw.Text(POSPrinter.footer1!, style: smallTextStyle),
                  if (hasHeaderValue(POSPrinter.footer2))
                    pw.Text(POSPrinter.footer2!, style: smallTextStyle),
                  if (hasHeaderValue(POSPrinter.footer3))
                    pw.Text(POSPrinter.footer3!, style: smallTextStyle),
                  if (hasHeaderValue(POSPrinter.footer4))
                    pw.Text(POSPrinter.footer4!, style: smallTextStyle),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}
