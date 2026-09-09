import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:primware/API/pos.api.dart';

import 'invoice_payment_receipt.dart';
import '../../../shared/document_number_barcode.dart';

String _money(num value) => 'B/.${value.toStringAsFixed(2)}';

List<pw.Widget> _header(InvoicePaymentReceipt receipt, {required bool compact}) => [
  if (POSPrinter.logo != null)
    pw.Center(
      child: pw.Image(pw.MemoryImage(POSPrinter.logo!), width: compact ? 72 : 90, height: compact ? 72 : 90),
    ),
  if ((POSPrinter.headerName ?? '').trim().isNotEmpty)
    pw.Text(
      POSPrinter.headerName!,
      textAlign: pw.TextAlign.center,
      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
    ),
  if ((POSPrinter.headerAddress ?? '').trim().isNotEmpty) pw.Text(POSPrinter.headerAddress!, textAlign: pw.TextAlign.center),
  if ((POSPrinter.headerTaxID ?? '').trim().isNotEmpty) pw.Text('RUC: ${POSPrinter.headerTaxID}', textAlign: pw.TextAlign.center),
  if ((POSPrinter.headerDV ?? '').trim().isNotEmpty) pw.Text('DV: ${POSPrinter.headerDV}', textAlign: pw.TextAlign.center),
  if ((POSPrinter.headerPhone ?? '').trim().isNotEmpty) pw.Text('Tel: ${POSPrinter.headerPhone}', textAlign: pw.TextAlign.center),
  pw.SizedBox(height: 10),
  pw.Text(
    'RECIBO DE PAGO A FACTURAS',
    textAlign: pw.TextAlign.center,
    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: compact ? 12 : 16),
  ),
  pw.SizedBox(height: 10),
  pw.Text('Recibo: ${receipt.displayDocumentNo}'),
  pw.Text('Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(receipt.date)}'),
  pw.Text('Cliente: ${receipt.customerName}'),
  if (receipt.customerTaxId.isNotEmpty) pw.Text('Identificación: ${receipt.customerTaxId}'),
  if (receipt.customerAddress.isNotEmpty) pw.Text('Dirección: ${receipt.customerAddress}'),
  if (receipt.customerPhone.isNotEmpty) pw.Text('Teléfono: ${receipt.customerPhone}'),
  pw.Text('Representante: ${receipt.salesRepName}'),
  if (receipt.posName.isNotEmpty || receipt.posId != null) pw.Text('POS: ${receipt.posName.isNotEmpty ? receipt.posName : receipt.posId}'),
];

pw.Widget _invoiceTable(InvoicePaymentReceipt receipt, {required bool compact}) => pw.Table.fromTextArray(
  headers: const ['Factura', 'Valor', 'Aplicado'],
  data: receipt.invoices.map((item) => [item.documentNo, _money(item.originalAmount), _money(item.appliedAmount)]).toList(),
  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: compact ? 8 : 10),
  cellStyle: pw.TextStyle(fontSize: compact ? 8 : 10),
  cellAlignments: const {1: pw.Alignment.centerRight, 2: pw.Alignment.centerRight},
);

pw.Widget _paymentTable(InvoicePaymentReceipt receipt, {required bool compact}) => pw.Table.fromTextArray(
  headers: const ['Pago', 'Método', 'Monto'],
  data: receipt.payments.map((item) => [item.documentNo, item.methodName, _money(item.amount)]).toList(),
  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: compact ? 8 : 10),
  cellStyle: pw.TextStyle(fontSize: compact ? 8 : 10),
  cellAlignments: const {2: pw.Alignment.centerRight},
);

List<pw.Widget> _body(InvoicePaymentReceipt receipt, {required bool compact}) => [
  ..._header(receipt, compact: compact),
  pw.SizedBox(height: 12),
  pw.Text('FACTURAS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
  pw.SizedBox(height: 4),
  _invoiceTable(receipt, compact: compact),
  pw.SizedBox(height: 12),
  pw.Text('MÉTODOS DE PAGO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
  pw.SizedBox(height: 4),
  _paymentTable(receipt, compact: compact),
  pw.SizedBox(height: 12),
  pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.end,
    children: [
      pw.Text('Total aplicado: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      pw.Text(_money(receipt.totalApplied), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    ],
  ),
  pw.SizedBox(height: 14),
  pw.Divider(),
  pw.Text(
    'Este recibo acredita un pago y no reemplaza la factura original.',
    textAlign: pw.TextAlign.center,
    style: pw.TextStyle(fontSize: compact ? 7 : 9),
  ),
  documentNumberBarcode(receipt.displayDocumentNo, isPOS: compact),
];

Future<Uint8List> generateInvoicePaymentPOSTicket(InvoicePaymentReceipt receipt) async {
  final document = pw.Document();
  final rowCount = receipt.invoices.length + receipt.payments.length;
  final configuredHeaderLines = [
    POSPrinter.headerName,
    POSPrinter.headerAddress,
    POSPrinter.headerTaxID,
    POSPrinter.headerDV,
    POSPrinter.headerPhone,
    POSPrinter.headerEmail,
  ].where((value) => (value ?? '').trim().isNotEmpty).length;
  // Reserva 25 mm para el código de barras y sus espacios superior e inferior.
  final heightMm = 190 + rowCount * 9 + configuredHeaderLines * 6 + (POSPrinter.logo == null ? 0 : 32);
  final pageFormat = PdfPageFormat.roll80.copyWith(
    width: 75 * PdfPageFormat.mm,
    height: heightMm * PdfPageFormat.mm,
    marginTop: 8,
    marginBottom: 8,
  );
  document.addPage(
    pw.Page(
      pageFormat: pageFormat,
      build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: _body(receipt, compact: true)),
    ),
  );
  return document.save();
}

Future<Uint8List> generateInvoicePaymentReceipt(InvoicePaymentReceipt receipt) async {
  final document = pw.Document();
  document.addPage(
    pw.MultiPage(pageFormat: PdfPageFormat.letter, margin: const pw.EdgeInsets.all(36), build: (_) => _body(receipt, compact: false)),
  );
  return document.save();
}
