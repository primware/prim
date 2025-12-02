import 'dart:convert';
import 'dart:typed_data';
// import 'package:printing_ffi/printing_ffi.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../../API/endpoint.api.dart';
import '../../../API/pos.api.dart';
import '../../../API/token.api.dart';

Future<Uint8List> generateOrderTicket(Map<String, dynamic> order) async {
  // Currency formatter
  final NumberFormat nf = NumberFormat.currency(locale: 'es_PA', symbol: 'B/.');

  // Fetch FE info if order['id'] exists
  Map<String, String>? feInfo;
  if (order['id'] != null) {
    feInfo = await fetchElectronicInvoiceInfo(orderId: order['id']);
  }

  final pdf = pw.Document();
  final List lines = (order['C_OrderLine'] as List?) ?? const [];

  // Header fields (as in generatePOSTicket)
  String str(dynamic v) => v?.toString() ?? '';
  String docTypename = order['doctypetarget']?['name'] ?? '';
  final docNo = str(order['DocumentNo']);
  final date = str(order['DateOrdered']);
  final servedBy = str(order['SalesRep_ID']?['name'] ?? '');
  final taxID = str(order['bpartner']?['taxID'] ?? '');
  final phone = str(order['bpartner']?['phone'] ?? '');
  final customerName = str(order['bpartner']?['name'] ?? 'CONTADO');
  final customeLocation = str(order['bpartner']?['location'] ?? '');

  pdf.addPage(
    pw.MultiPage(
      build: (context) => [
        // Header (same as generatePOSTicket) - flattened: all widgets directly in the list
        POSPrinter.logo != null
            ? pw.Center(
                child: pw.Image(
                  pw.MemoryImage(POSPrinter.logo!),
                  width: 60,
                  height: 60,
                  fit: pw.BoxFit.contain,
                ),
              )
            : pw.SizedBox(),
        pw.SizedBox(height: 4),
        pw.Text(POSPrinter.headerName ?? '', textAlign: pw.TextAlign.center),
        pw.Text(POSPrinter.headerAddress ?? '', textAlign: pw.TextAlign.center),
        if (POSPrinter.headerTaxID != null)
          pw.Text(
            'RUC: ${POSPrinter.headerTaxID ?? ''}',
            textAlign: pw.TextAlign.center,
          ),
        if (POSPrinter.headerDV != null)
          pw.Text(
            'DV: ${POSPrinter.headerDV ?? ''}',
            textAlign: pw.TextAlign.center,
          ),
        if (POSPrinter.headerPhone != null)
          pw.Text(
            'Tel: ${POSPrinter.headerPhone ?? ''}',
            textAlign: pw.TextAlign.center,
          ),
        pw.Text(POSPrinter.headerEmail ?? '', textAlign: pw.TextAlign.center),
        pw.SizedBox(height: 12),
        pw.Text(
          docTypename,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
        ),
        pw.SizedBox(height: 18),
        // Order details
        pw.Text('Recibo: $docNo'),
        pw.Text('Fecha: $date'),
        if (servedBy.isNotEmpty) pw.Text('Atendido por: $servedBy'),
        if (taxID.isNotEmpty) pw.Text('Cédula: $taxID'),
        pw.Text('Cliente: $customerName'),
        if (customeLocation.isNotEmpty) pw.Text('Dirección: $customeLocation'),
        if (phone.isNotEmpty) pw.Text('Teléfono: $phone'),
        pw.SizedBox(height: 12),
        // Products table
        if (lines.isNotEmpty) ...[
          pw.Text(
            "Productos:",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Table.fromTextArray(
            headers: [
              'Producto',
              'Descripción',
              'Precio',
              'Imp',
              'Subtotal',
              'Total',
            ],
            data: lines.map((line) {
              final name =
                  (line['M_Product_ID']?['identifier'] ??
                          '_${line['Description']}')
                      .toString()
                      .split('_')
                      .skip(1)
                      .join(' ');
              final qty = (line['QtyOrdered'] ?? 0);
              final price = (line['PriceActual'] as num?)?.toDouble() ?? 0.0;
              final rate =
                  (line['C_Tax_ID']?['Rate'] as num?)?.toDouble() ?? 0.0;
              final net = (line['LineNetAmt'] as num?) ?? 0;
              final tax = (net * rate / 100);
              final total = net + tax;
              final description = line['Description']?.toString() ?? '';
              return [
                name,
                description,
                "${qty} x ${nf.format(price)}",
                "${rate.toStringAsFixed(0)}%",
                nf.format(net),
                nf.format(total),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
            cellStyle: pw.TextStyle(fontSize: 10),
            columnWidths: {
              0: pw.FixedColumnWidth(95), // Producto
              1: pw.FlexColumnWidth(3), // Descripción
              2: pw.FixedColumnWidth(90), // Cant. x Precio
              3: pw.FixedColumnWidth(40), // Impuesto
              4: pw.FixedColumnWidth(65), // Subtotal
              5: pw.FixedColumnWidth(65), // Total
            },
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
            },
          ),
          pw.SizedBox(height: 20),
        ],
        // Totals section
        pw.Text(
          "Total bruto: ${nf.format(order['TotalLines'])}",
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          "Total final: ${nf.format(order['GrandTotal'])}",
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
        ),
        pw.SizedBox(height: 16),
        // FE section if present
        if (feInfo != null) ...[
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            'FACTURA ELECTRÓNICA',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Protocolo de Autorización: ${feInfo['protocolo']}',
            style: pw.TextStyle(fontSize: 8),
          ),
          pw.Text(
            'Consulte por la clave de acceso en:',
            style: pw.TextStyle(fontSize: 8),
          ),
          pw.Text(feInfo['url'] ?? '', style: pw.TextStyle(fontSize: 8)),
          pw.SizedBox(height: 6),
          pw.Text(
            'o escaneando el código QR:',
            style: pw.TextStyle(fontSize: 8),
          ),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.BarcodeWidget(
              data: feInfo['url'] ?? '',
              barcode: pw.Barcode.qrCode(),
              width: 120,
              height: 120,
            ),
          ),
          pw.SizedBox(height: 10),
        ],
      ],
    ),
  );
  return pdf.save();
}

Future<Map<String, String>?> fetchElectronicInvoiceInfo({
  required int orderId,
}) async {
  try {
    final uri = Uri.parse(
      '${EndPoints.cInvoice}?\$filter=C_Order_ID eq $orderId&\$expand=FE_InvoiceResponseLog',
    );
    final response = await get(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode != 200) {
      // Si la tabla/expand no existe o hay otro problema, devolver null silenciosamente
      debugPrint('FE query non-200: ${response.statusCode}');
      return null;
    }

    final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
    final List records = (jsonResponse['records'] as List?) ?? const [];
    if (records.isEmpty) return null;

    final invoice = records.first;
    final List logs = (invoice['FE_InvoiceResponseLog'] as List?) ?? const [];
    if (logs.isEmpty) return null;

    // Buscar el primer log con FE_ResponseCode == 200 (num o string)
    final match = logs.firstWhere((e) {
      final code = e['FE_ResponseCode'];
      if (code == null) return false;
      if (code is num) return code == 200;
      if (code is String) return code.trim() == '200';
      return false;
    }, orElse: () => null);

    if (match == null) return null;

    final cufe = match['FE_ResponseCUFE']?.toString();
    final protocolo = match['FE_NroProtocoloAutorizacion']?.toString();
    final url = match['FE_ResponseQR']?.toString();

    if (cufe == null || protocolo == null || url == null) return null;

    return {'cufe': cufe, 'protocolo': protocolo, 'url': url};
  } catch (e) {
    debugPrint('Error consultando FE_InvoiceResponseLog: $e');
    return null;
  }
}

Future<Uint8List> generatePOSTicket(Map<String, dynamic> order) async {
  // Consultar datos de Factura Electrónica (FE)
  final int? orderId = (order['id'] as int?);
  final feInfo = orderId != null
      ? await fetchElectronicInvoiceInfo(orderId: orderId)
      : null;

  final pdf = pw.Document();
  final pageFormat = PdfPageFormat.roll80;

  // Helpers
  String str(dynamic v) => v?.toString() ?? '';
  String money(num? v) => 'B/.${(v ?? 0).toDouble().toStringAsFixed(2)}';

  String docTypename = order['doctypetarget']?['name'] ?? '';

  // Order fields (safe access)
  final docNo = str(order['DocumentNo']);
  final date = str(order['DateOrdered']);
  final servedBy = str(order['SalesRep_ID']?['name'] ?? '');
  final taxID = str(order['bpartner']['taxID'] ?? '');
  final phone = str(order['bpartner']['phone'] ?? '');
  final customerName = str(order['bpartner']?['name'] ?? 'CONTADO');
  final customeLocation = str(order['bpartner']?['location'] ?? '');

  // Lines & taxes
  final List lines = (order['C_OrderLine'] as List?) ?? const [];
  final taxSummary = _calculateTaxSummary([order]);

  final double taxTotal = taxSummary.values
      .map((e) => e['tax'] as double)
      .fold(0.0, (a, b) => a + b);
  final double grandTotal = (order['GrandTotal'] as num?)?.toDouble() ?? 0.0;

  // Taxes summary (net + taxes)
  final netSum = taxSummary.values
      .map((e) => e['net'] as double)
      .fold(0.0, (a, b) => a + b);

  final baseTextStyle = pw.TextStyle(fontSize: 8);
  final smallTextStyle = pw.TextStyle(fontSize: 6);

  final theme = pw.ThemeData.withFont(
    base: pw.Font.helvetica(),
    bold: pw.Font.helveticaBold(),
  ).copyWith(defaultTextStyle: baseTextStyle);

  // Render PDF
  pdf.addPage(
    pw.Page(
      pageFormat: pageFormat.copyWith(
        marginTop: 8,
        marginBottom: 8,
        width: 75 * PdfPageFormat.mm,
      ),
      theme: theme,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            POSPrinter.logo != null
                ? pw.Center(
                    child: pw.Image(
                      pw.MemoryImage(POSPrinter.logo!),
                      width: 60,
                      height: 60,
                      fit: pw.BoxFit.contain,
                    ),
                  )
                : pw.SizedBox(),
            pw.SizedBox(height: 4),
            pw.Text(
              POSPrinter.headerName ?? '',
              textAlign: pw.TextAlign.center,
            ),
            pw.Text(
              POSPrinter.headerAddress ?? '',
              textAlign: pw.TextAlign.center,
            ),
            if (POSPrinter.headerTaxID != null)
              pw.Text(
                'RUC: ${POSPrinter.headerTaxID ?? ''}',
                textAlign: pw.TextAlign.center,
              ),
            if (POSPrinter.headerDV != null)
              pw.Text(
                'DV: ${POSPrinter.headerDV ?? ''}',
                textAlign: pw.TextAlign.center,
              ),
            if (POSPrinter.headerPhone != null)
              pw.Text(
                'Tel: ${POSPrinter.headerPhone ?? ''}',
                textAlign: pw.TextAlign.center,
              ),
            pw.Text(
              POSPrinter.headerEmail ?? '',
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              docTypename,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),

            pw.SizedBox(height: 18),

            // Detalles (alineados a la izquierda)
            pw.Text('Recibo: $docNo'),
            pw.Text('Fecha: $date'),
            if (servedBy.isNotEmpty) pw.Text('Atendido por: $servedBy'),
            pw.Text('Cédula: $taxID'),
            pw.Text('Cliente: $customerName'),
            pw.Text('Dirección: $customeLocation'),
            if (phone.isNotEmpty) pw.Text('Teléfono: $phone'),
            pw.SizedBox(height: 12),

            if (lines.isNotEmpty) ...[
              // Tabla de ítems (alineada en 4 columnas)
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 20,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Ítem', maxLines: 1),
                        pw.Text(
                          'Precio x Cant',
                          maxLines: 1,
                          style: smallTextStyle,
                        ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    flex: 15,
                    child: pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text('Subtotal', maxLines: 1),
                    ),
                  ),
                ],
              ),
              pw.Divider(),
              pw.SizedBox(height: 6),
              ...lines.map((line) {
                final name =
                    (line['M_Product_ID']?['identifier'] ??
                            '_${line['Description']}')
                        .toString()
                        .split('_')
                        .skip(1)
                        .join(' ');
                final qty = (line['QtyOrdered'] as num?)?.toDouble() ?? 0.0;
                final price = (line['PriceActual'] as num?)?.toDouble() ?? 0.0;
                final net = (line['LineNetAmt'] as num?)?.toDouble() ?? 0.0;
                final rate =
                    (line['C_Tax_ID']?['Rate'] as num?)?.toDouble() ?? 0.0;
                final tax = double.parse(
                  (net * (rate / 100)).toStringAsFixed(2),
                );
                final value = net + tax;
                final description = line['Description']?.toString() ?? '';
                final discount = (line['Discount'] as num?)?.toDouble() ?? 0.0;

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          flex: 20,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(name, overflow: pw.TextOverflow.span),
                              pw.Text(
                                '${money(price)} x ${qty.toStringAsFixed(qty % 1 == 0 ? 0 : 2)}',
                                maxLines: 1,
                                style: smallTextStyle,
                              ),
                              if (discount > 0)
                                pw.Text(
                                  'Desc: ${discount.toStringAsFixed(2)}%',
                                  maxLines: 1,
                                  style: smallTextStyle.copyWith(
                                    fontStyle: pw.FontStyle.italic,
                                  ),
                                ),
                              if (description.isNotEmpty && description != name)
                                pw.Text(
                                  description,
                                  maxLines: 1,
                                  style: smallTextStyle.copyWith(
                                    fontStyle: pw.FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          flex: 15,
                          child: pw.Align(
                            alignment: pw.Alignment.centerRight,
                            child: pw.Text(money(value), maxLines: 1),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }),
              pw.SizedBox(height: 6),
              pw.Divider(),
              // Totales por items
              pw.Text('Cant. Items: ${lines.length}'),
              pw.SizedBox(height: 12),
            ],
            pw.Text(
              'Total: ${money(grandTotal)}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
            ),
            pw.SizedBox(height: 10),

            // Formas de pago
            pw.Text(
              'Formas de Pago:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            ...?order['payments']?.map<pw.Widget>((payment) {
              final payType =
                  payment['C_POSTenderType_ID']['identifier'] ?? 'Otro';
              final amount = (payment['PayAmt'] as num?)?.toDouble() ?? 0.0;
              return pw.Text('- $payType: ${money(amount)}');
            }),
            pw.SizedBox(height: 10),

            // Impuestos
            pw.Text(
              'Neto sin ITBMS: ${money(netSum)}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('ITBMS: ${money(taxTotal)}'),
            pw.SizedBox(height: 12),

            // Datos de Factura Electrónica (si existen)
            if (feInfo != null) ...[
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Text(
                'FACTURA ELECTRÓNICA',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Protocolo de Autorización: ${feInfo['protocolo']}',
                style: pw.TextStyle(fontSize: 6),
              ),
              pw.Text(
                'Consulte por la clave de acceso en:',
                style: pw.TextStyle(fontSize: 6),
              ),
              pw.Text(feInfo['url'] ?? '', style: pw.TextStyle(fontSize: 6)),
              pw.SizedBox(height: 6),
              pw.Text(
                'o escaneando el código QR:',
                style: pw.TextStyle(fontSize: 8),
              ),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.BarcodeWidget(
                  data: feInfo['url'] ?? '',
                  barcode: pw.Barcode.qrCode(),
                  width: 120,
                  height: 120,
                ),
              ),
              pw.SizedBox(height: 10),
            ],

            // Footer
            pw.Text(
              'Gracias por mantener sus pagos al día',
              textAlign: pw.TextAlign.center,
            ),

            pw.SizedBox(height: 56),
          ],
        );
      },
    ),
  );

  return pdf.save();
}

/// =============================== RAW FLOW (ESC/POS) ===============================
/// Construye bytes ESC/POS para enviar a una impresora térmica (raw).
class _EscPos {
  final List<int> _b = [];
  List<int> get bytes => _b;

  void init() => _b.addAll([0x1B, 0x40]); // ESC @
  void txt(String s, {bool ln = true}) {
    _b.addAll(utf8.encode(s));
    if (ln) _b.addAll([0x0A]);
  }

  void alignLeft() => _b.addAll([0x1B, 0x61, 0]);
  void alignCenter() => _b.addAll([0x1B, 0x61, 1]);
  void alignRight() => _b.addAll([0x1B, 0x61, 2]);
  void boldOn() => _b.addAll([0x1B, 0x45, 0x01]);
  void boldOff() => _b.addAll([0x1B, 0x45, 0x00]);
  void feed(int n) => _b.addAll([0x1B, 0x64, n]);
  void cut() => _b.addAll([0x1D, 0x56, 0x42, 0x00]); // GS V B m

  // QR estándar ESC/POS (Model 2). Si la impresora no lo soporta, simplemente imprimirá la URL.
  void qr(
    String data, {
    int size = 6,
    int ecLevel = 48 /* 48=L,49=M,50=Q,51=H */,
  }) {
    final bytes = utf8.encode(data);
    void gs(List<int> data) => _b.addAll([
      0x1D,
      0x28,
      0x6B,
      data.length & 0xFF,
      (data.length >> 8) & 0xFF,
      ...data,
    ]);
    // Select model 2
    gs([0x31, 0x41, 0x32, 0x00]);
    // Set module size
    gs([0x31, 0x43, size, 0x00]);
    // Set error correction
    gs([0x31, 0x45, ecLevel, 0x00]);
    // Store data
    final pL = (bytes.length + 3) & 0xFF;
    final pH = ((bytes.length + 3) >> 8) & 0xFF;
    _b.addAll([0x1D, 0x28, 0x6B, pL, pH, 0x31, 0x50, 0x30, ...bytes]);
    // Print
    gs([0x31, 0x51, 0x30, 0x00]);
  }
}

String _fmtMoney(num? v) => 'B/.${(v ?? 0).toDouble().toStringAsFixed(2)}';

// /// Construye los bytes ESC/POS del ticket POS (sin imprimir).
// Future<Uint8List> buildPOSTicketRawData(
//   Map<String, dynamic> order, {
//   bool autoCut = true,
// }) async {
//   final esc = _EscPos();
//   esc.init();

//   // Encabezado
//   esc.alignCenter();
//   if ((POSPrinter.headerName ?? '').isNotEmpty) esc.txt(POSPrinter.headerName!);
//   if ((POSPrinter.headerAddress ?? '').isNotEmpty) {
//     esc.txt(POSPrinter.headerAddress!);
//   }
//   if ((POSPrinter.headerTaxID ?? '').isNotEmpty) {
//     esc.txt('RUC: ${POSPrinter.headerTaxID}');
//   }
//   if ((POSPrinter.headerDV ?? '').isNotEmpty) {
//     esc.txt('DV: ${POSPrinter.headerDV}');
//   }
//   if ((POSPrinter.headerPhone ?? '').isNotEmpty) {
//     esc.txt('Tel: ${POSPrinter.headerPhone}');
//   }
//   if ((POSPrinter.headerEmail ?? '').isNotEmpty) {
//     esc.txt(POSPrinter.headerEmail!);
//   }
//   esc.feed(1);

//   final docType = (order['doctypetarget']?['name'] ?? '').toString();
//   esc.boldOn();
//   esc.txt(docType);
//   esc.boldOff();
//   esc.feed(1);

//   esc.alignLeft();
//   final docNo = (order['DocumentNo'] ?? '').toString();
//   final date = (order['DateOrdered'] ?? '').toString();
//   final servedBy = (order['SalesRep_ID']?['name'] ?? '').toString();
//   final taxID = (order['bpartner']?['taxID'] ?? '').toString();
//   final customerName = (order['bpartner']?['name'] ?? 'CONTADO').toString();
//   final customeLocation = (order['bpartner']?['location'] ?? '').toString();
//   final phone = (order['bpartner']?['phone'] ?? '').toString();

//   esc.txt('Recibo: $docNo');
//   esc.txt('Fecha : $date');
//   if (servedBy.isNotEmpty) esc.txt('Atendido por: $servedBy');
//   if (taxID.isNotEmpty) esc.txt('Cédula: $taxID');
//   esc.txt('Cliente: $customerName');
//   if (customeLocation.isNotEmpty) esc.txt('Dirección: $customeLocation');
//   if (phone.isNotEmpty) esc.txt('Teléfono: $phone');
//   esc.feed(1);

//   // Detalle de líneas
//   final List lines = (order['C_OrderLine'] as List?) ?? const [];
//   if (lines.isNotEmpty) {
//     esc.boldOn();
//     esc.txt('Productos');
//     esc.boldOff();
//     esc.txt('--------------------------------');
//     for (final line in lines) {
//       final name =
//           ((line['M_Product_ID']?['identifier'] ?? '_${line['Description']}')
//                   .toString()
//                   .split('_')
//                   .skip(1)
//                   .join(' '))
//               .trim();
//       final qty = ((line['QtyOrdered'] as num?)?.toDouble() ?? 0.0);
//       final price = ((line['PriceActual'] as num?)?.toDouble() ?? 0.0);
//       final net = ((line['LineNetAmt'] as num?)?.toDouble() ?? 0.0);
//       final rate = ((line['C_Tax_ID']?['Rate'] as num?)?.toDouble() ?? 0.0);
//       final tax = double.parse((net * (rate / 100)).toStringAsFixed(2));
//       final total = net + tax;

//       // Nombre (puede ser largo)
//       esc.txt(name);
//       // Precio x Cant a la izquierda, total a la derecha (formato manual)
//       final left =
//           '${_fmtMoney(price)} x ${qty % 1 == 0 ? qty.toStringAsFixed(0) : qty.toStringAsFixed(2)}';
//       final right = _fmtMoney(total);
//       final pad = 32; // ancho típico de 80mm fuentes estándar
//       final lineTxt = (left.length + right.length >= pad)
//           ? '$left\n${right.padLeft(pad)}'
//           : left + right.padLeft(pad - left.length);
//       esc.txt(lineTxt);
//       final desc = (line['Description']?.toString() ?? '').trim();
//       if (desc.isNotEmpty && desc != name) esc.txt('  $desc');
//     }
//     esc.txt('--------------------------------');
//   }

//   // Totales
//   final taxSummary = _calculateTaxSummary([order]);
//   final double taxTotal = taxSummary.values
//       .map((e) => e['tax'] as double)
//       .fold(0.0, (a, b) => a + b);
//   final double netSum = taxSummary.values
//       .map((e) => e['net'] as double)
//       .fold(0.0, (a, b) => a + b);
//   final double grandTotal = (order['GrandTotal'] as num?)?.toDouble() ?? 0.0;

//   esc.boldOn();
//   esc.alignRight();
//   esc.txt('Neto:   ${_fmtMoney(netSum)}');
//   esc.txt('ITBMS:  ${_fmtMoney(taxTotal)}');
//   esc.txt('TOTAL:  ${_fmtMoney(grandTotal)}');
//   esc.boldOff();
//   esc.alignLeft();
//   esc.feed(1);

//   // Formas de pago
//   final pays = order['payments'] as List?;
//   if (pays != null && pays.isNotEmpty) {
//     esc.boldOn();
//     esc.txt('Formas de Pago:');
//     esc.boldOff();
//     for (final p in pays) {
//       final payType = (p['C_POSTenderType_ID']?['identifier'] ?? 'Otro')
//           .toString();
//       final amount = (p['PayAmt'] as num?)?.toDouble() ?? 0.0;
//       esc.txt('- $payType: ${_fmtMoney(amount)}');
//     }
//     esc.feed(1);
//   }

//   // QR (Factura Electrónica)
//   final int? orderId = (order['id'] as int?);
//   final feInfo = orderId != null
//       ? await fetchElectronicInvoiceInfo(orderId: orderId)
//       : null;
//   if (feInfo != null && (feInfo['url'] ?? '').toString().isNotEmpty) {
//     esc.alignCenter();
//     esc.txt('FACTURA ELECTRÓNICA');
//     esc.txt('Protocolo: ${feInfo['protocolo']}');
//     try {
//       esc.qr(feInfo['url']!);
//       esc.feed(1);
//     } catch (_) {
//       // Si la impresora no soporta QR, imprimimos la URL
//       esc.txt(feInfo['url']!);
//       esc.feed(1);
//     }
//     esc.alignLeft();
//   }

//   esc.alignCenter();
//   esc.txt('Gracias por mantener sus pagos al día');
//   esc.feed(3);
//   if (autoCut) esc.cut();

//   return Uint8List.fromList(esc.bytes);
// }

// /// Imprime el ticket en crudo usando printing_ffi.
// Future<void> _safeRawPrint(Uint8List data, {String? printerName}) async {
//   // iOS y Web no soportan impresión RAW (AirPrint requiere PDF/imagen)
//   if (kIsWeb || Platform.isIOS) {
//     throw UnsupportedError('Raw printing not supported on this platform');
//   }
//   // Evitar error de compilación cuando el método no existe en ciertos targets.
//   final dynamic ffi =
//       PrintingFfi; // dynamic para no depender de la firma en cada plataforma
//   final Function? f = (ffi as dynamic).printRawData; // puede no existir en iOS
//   if (f == null) {
//     throw UnsupportedError('printing_ffi raw API not available');
//   }
//   // Llamada dinámica para plataformas soportadas (Windows/Linux/macOS/Android según plugin)
//   await Function.apply(f, const [], {#bytes: data, #printerName: printerName});
// }

// Future<void> printPOSTicketRaw(
//   Map<String, dynamic> order, {
//   String? printerName,
//   bool autoCut = true,
// }) async {
//   final data = await buildPOSTicketRawData(order, autoCut: autoCut);
//   await _safeRawPrint(data, printerName: printerName);
// }

Map<String, Map<String, double>> _calculateTaxSummary(List<dynamic> records) {
  final Map<String, Map<String, double>> taxSummary = {};

  for (var order in records) {
    if (order.containsKey("C_OrderLine")) {
      for (var line in order["C_OrderLine"]) {
        final tax = line["C_Tax_ID"];
        final String taxName = tax["Name"];
        final double taxRate = (tax["Rate"] as num).toDouble();
        final double lineNetAmt = (line["LineNetAmt"] as num).toDouble();

        final taxKey = "$taxName (${taxRate.toStringAsFixed(0)}%)";

        taxSummary.putIfAbsent(
          taxKey,
          () => {"net": 0.0, "tax": 0.0, "total": 0.0},
        );

        final double taxAmount = double.parse(
          (lineNetAmt * (taxRate / 100)).toStringAsFixed(2),
        );
        taxSummary[taxKey]!["net"] = taxSummary[taxKey]!["net"]! + lineNetAmt;
        taxSummary[taxKey]!["tax"] = taxSummary[taxKey]!["tax"]! + taxAmount;
        taxSummary[taxKey]!["total"] =
            taxSummary[taxKey]!["total"]! + lineNetAmt + taxAmount;
      }
    }
  }

  return taxSummary;
}
