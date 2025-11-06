import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../API/endpoint.api.dart';
import '../../../API/pos.api.dart';
import '../../../API/token.api.dart';

Future<Uint8List> generateOrderTicket(Map<String, dynamic> order) async {
  final pdf = pw.Document();
  final List lines = (order['C_OrderLine'] as List?) ?? const [];

  pdf.addPage(pw.MultiPage(
    build: (context) => [
      pw.Header(
        level: 0,
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            (POSPrinter.logo != null)
                ? pw.Container(
                    width: 48,
                    height: 48,
                    child: pw.Image(
                      pw.MemoryImage(POSPrinter.logo!),
                      fit: pw.BoxFit.contain,
                    ),
                  )
                : pw.SizedBox(width: 48, height: 48),
            pw.Expanded(
              child: pw.Center(
                child: pw.Text(
                  'Resumen de la Orden #${order['DocumentNo']}',
                ),
              ),
            ),
            pw.SizedBox(width: 48, height: 48),
          ],
        ),
      ),
      pw.Text("Cliente: ${order['bpartner']['name']}"),
      pw.Text("Fecha: ${order['DateOrdered']}"),
      pw.SizedBox(height: 10),
      if (lines.isNotEmpty) ...[
        pw.Text("Productos:"),
        pw.Table.fromTextArray(
          headers: [
            'Producto',
            'Descripción',
            'Precio',
            'Impuesto',
            'Subtotal',
            'Total'
          ],
          data: lines.map((line) {
            final name = (line['M_Product_ID']?['identifier'] ??
                    '_${line['Description']}')
                .toString()
                .split('_')
                .skip(1)
                .join(' ');
            final qty = (line['QtyOrdered'] ?? 0).toString();
            final price = (line['PriceActual'] as num?)?.toDouble() ?? 0.0;
            final rate = line['C_Tax_ID']['Rate'];
            final taxName = line['C_Tax_ID']['Name'];
            final net = line['LineNetAmt'] ?? 0;
            final tax = (net * rate / 100);
            final total = net + tax;
            final description = line['Description']?.toString() ?? '';

            return [
              name,
              description,
              "$qty x \$${price.toStringAsFixed(2)}",
              "$taxName ($rate%)",
              "\$${net.toStringAsFixed(2)}",
              "\$${total.toStringAsFixed(2)}",
            ];
          }).toList(),
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 12,
          ),
          cellStyle: pw.TextStyle(
            fontSize: 10,
          ),
          columnWidths: {
            0: pw.FixedColumnWidth(95), // Producto
            1: pw.FlexColumnWidth(3), // Descripción
            2: pw.FixedColumnWidth(90), // Cant. x Precio
            3: pw.FixedColumnWidth(80), // Impuesto
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
      pw.Text("Total bruto: \$${order['TotalLines']}"),
      pw.Text("Total final: \$${order['GrandTotal']}"),
    ],
  ));

  return pdf.save();
}

Future<Map<String, String>?> fetchElectronicInvoiceInfo(
    {required int orderId}) async {
  try {
    final uri = Uri.parse(
        '${EndPoints.cInvoice}?\$filter=C_Order_ID eq $orderId&\$expand=FE_InvoiceResponseLog');
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
    final match = logs.firstWhere(
      (e) {
        final code = e['FE_ResponseCode'];
        if (code == null) return false;
        if (code is num) return code == 200;
        if (code is String) return code.trim() == '200';
        return false;
      },
      orElse: () => null,
    );

    if (match == null) return null;

    final cufe = match['FE_ResponseCUFE']?.toString();
    final protocolo = match['FE_NroProtocoloAutorizacion']?.toString();
    final url = match['FE_ResponseQR']?.toString();

    if (cufe == null || protocolo == null || url == null) return null;

    return {
      'cufe': cufe,
      'protocolo': protocolo,
      'url': url,
    };
  } catch (e) {
    debugPrint('Error consultando FE_InvoiceResponseLog: $e');
    return null;
  }
}

Future<Uint8List> generatePOSTicketBackup(Map<String, dynamic> order) async {
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
  ).copyWith(
    defaultTextStyle: baseTextStyle,
  );

  // Render PDF
  pdf.addPage(
    pw.Page(
      pageFormat: pageFormat.copyWith(
          marginTop: 8, marginBottom: 8, width: 75 * PdfPageFormat.mm),
      theme: theme,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            POSPrinter.logo != null
                ? pw.Center(
                    child: pw.Image(pw.MemoryImage(POSPrinter.logo!),
                        width: 60, height: 60, fit: pw.BoxFit.contain))
                : pw.SizedBox(),
            pw.SizedBox(height: 4),
            pw.Text(POSPrinter.headerName ?? '',
                textAlign: pw.TextAlign.center),
            pw.Text(POSPrinter.headerAddress ?? '',
                textAlign: pw.TextAlign.center),
            if (POSPrinter.headerTaxID != null)
              pw.Text('RUC: ${POSPrinter.headerTaxID ?? ''}',
                  textAlign: pw.TextAlign.center),
            if (POSPrinter.headerDV != null)
              pw.Text('DV: ${POSPrinter.headerDV ?? ''}',
                  textAlign: pw.TextAlign.center),
            if (POSPrinter.headerPhone != null)
              pw.Text('Tel: ${POSPrinter.headerPhone ?? ''}',
                  textAlign: pw.TextAlign.center),
            pw.Text(POSPrinter.headerEmail ?? '',
                textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 12),
            pw.Text(docTypename,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                )),

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
                          pw.Text('Precio x Cant',
                              maxLines: 1, style: smallTextStyle),
                        ],
                      )),
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
                final name = (line['M_Product_ID']?['identifier'] ??
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
                final tax =
                    double.parse((net * (rate / 100)).toStringAsFixed(2));
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
                                pw.Text(
                                  name,
                                  overflow: pw.TextOverflow.span,
                                ),
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
                                if (description.isNotEmpty &&
                                    description != name)
                                  pw.Text(
                                    description,
                                    maxLines: 1,
                                    style: smallTextStyle.copyWith(
                                      fontStyle: pw.FontStyle.italic,
                                    ),
                                  ),
                              ],
                            )),
                        pw.Expanded(
                          flex: 15,
                          child: pw.Align(
                            alignment: pw.Alignment.centerRight,
                            child: pw.Text(
                              money(value),
                              maxLines: 1,
                            ),
                          ),
                        )
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
            pw.Text('Total: ${money(grandTotal)}',
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            pw.SizedBox(height: 10),

            // Formas de pago
            pw.Text('Formas de Pago:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ...?order['payments']?.map<pw.Widget>((payment) {
              final payType =
                  payment['C_POSTenderType_ID']['identifier'] ?? 'Otro';
              final amount = (payment['PayAmt'] as num?)?.toDouble() ?? 0.0;
              return pw.Text('- $payType: ${money(amount)}');
            }),
            pw.SizedBox(height: 10),

            // Impuestos
            pw.Text('Neto sin ITBMS: ${money(netSum)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('ITBMS: ${money(taxTotal)}'),
            pw.SizedBox(height: 12),

            // Datos de Factura Electrónica (si existen)
            if (feInfo != null) ...[
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Text('FACTURA ELECTRÓNICA',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 8)),
              pw.SizedBox(height: 6),
              pw.Text('Protocolo de Autorización: ${feInfo['protocolo']}',
                  style: pw.TextStyle(fontSize: 6)),
              pw.Text('Consulte por la clave de acceso en:',
                  style: pw.TextStyle(fontSize: 6)),
              pw.Text(feInfo['url'] ?? '', style: pw.TextStyle(fontSize: 6)),
              pw.SizedBox(height: 6),
              pw.Text('o escaneando el código QR:',
                  style: pw.TextStyle(fontSize: 8)),
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
            pw.Text('Gracias por mantener sus pagos al día',
                textAlign: pw.TextAlign.center),

            pw.SizedBox(height: 56),
          ],
        );
      },
    ),
  );

  return pdf.save();
}

// Convierte bytes (PNG/JPEG) a raster ESC/POS (GS v 0) monocromo.
// maxWidthPx típico 80mm: 384/512/576. Usamos 384 por compatibilidad.
Uint8List _escposRasterFromImage(Uint8List sourceBytes,
    {int maxWidthPx = 384}) {
  final img.Image? original = img.decodeImage(sourceBytes);
  if (original == null) return Uint8List(0);

  final int targetW = original.width > maxWidthPx ? maxWidthPx : original.width;
  final int targetH = (original.height * targetW / original.width).round();
  final img.Image resized = img.copyResize(
    original,
    width: targetW,
    height: targetH,
    interpolation: img.Interpolation.average,
  );

  // Pasar a escala de grises y umbral simple
  final img.Image mono = img.grayscale(resized);
  final int width = mono.width;
  final int height = mono.height;
  final int bytesPerRow = ((width + 7) ~/ 8);
  final out = BytesBuilder();

  // GS v 0 m xL xH yL yH  [data]
  final int xL = bytesPerRow & 0xFF;
  final int xH = (bytesPerRow >> 8) & 0xFF;
  final int yL = height & 0xFF;
  final int yH = (height >> 8) & 0xFF;
  out.add([0x1D, 0x76, 0x30, 0x00, xL, xH, yL, yH]);

  for (int y = 0; y < height; y++) {
    int bit = 0;
    int current = 0;
    for (int y = 0; y < height; y++) {
      int bit = 0;
      int current = 0;
      for (int x = 0; x < width; x++) {
        final px = mono.getPixel(x, y);

        final num luma =
            img.getLuminanceRgb(px.r.toInt(), px.g.toInt(), px.b.toInt());
        final bool isBlack = luma < 160;
        current = (current << 1) | (isBlack ? 1 : 0);
        bit++;
        if (bit == 8) {
          out.add([current & 0xFF]);
          bit = 0;
          current = 0;
        }
      }
      if (bit != 0) {
        current = current << (8 - bit);
        out.add([current & 0xFF]);
      }
    }
    if (bit != 0) {
      current = current << (8 - bit);
      out.add([current & 0xFF]);
    }
  }

  return out.toBytes();
}

// Agrega a 'out' un QR nativo (modelo 2). size: 1..16; ecc: 48(L) 49(M) 50(Q) 51(H)
void _escposAppendQr(BytesBuilder out, String data,
    {int size = 6, int ecc = 49}) {
  final List<int> bytes = const Latin1Codec().encode(data);
  final int pL = (bytes.length + 3) & 0xFF;
  final int pH = ((bytes.length + 3) >> 8) & 0xFF;

  // Select model 2
  out.add([0x1D, 0x28, 0x6B, 0x04, 0x00, 0x31, 0x41, 0x32, 0x00]);
  // Module size
  out.add([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, size.clamp(1, 16)]);
  // Error correction
  out.add([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, ecc]);
  // Store data
  out.add([0x1D, 0x28, 0x6B, pL, pH, 0x31, 0x50, 0x30]);
  out.add(bytes);
  // Print
  out.add([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30]);
}

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
            () => {
                  "net": 0.0,
                  "tax": 0.0,
                  "total": 0.0,
                });

        final double taxAmount =
            double.parse((lineNetAmt * (taxRate / 100)).toStringAsFixed(2));
        taxSummary[taxKey]!["net"] = taxSummary[taxKey]!["net"]! + lineNetAmt;
        taxSummary[taxKey]!["tax"] = taxSummary[taxKey]!["tax"]! + taxAmount;
        taxSummary[taxKey]!["total"] =
            taxSummary[taxKey]!["total"]! + lineNetAmt + taxAmount;
      }
    }
  }

  return taxSummary;
}

// Enviar ESC/POS a la impresora por defecto del sistema (macOS/Linux con CUPS)
Future<void> _printEscPosToDefault(Uint8List bytes) async {
  if (Platform.isMacOS || Platform.isLinux) {
    final process = await Process.start('lp', ['-o', 'raw', '-']);
    process.stdin.add(bytes);
    await process.stdin.close();
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      final err = await process.stderr.transform(utf8.decoder).join();
      throw Exception('Error enviando a lp: $err');
    }
  } else if (Platform.isWindows) {
    throw UnsupportedError(
        'ESC/POS por impresora predeterminada en Windows no implementado.');
  } else {
    throw UnsupportedError('Plataforma no soportada.');
  }
}

Future<void> printPOSTicketEscPosDefault(Map<String, dynamic> order) async {
  String s(dynamic v) => v?.toString() ?? '';
  String money(num? v) => 'B/.${(v ?? 0).toDouble().toStringAsFixed(2)}';

  final List lines = (order['C_OrderLine'] as List?) ?? const [];
  final bytes = BytesBuilder();

  // === ESC/POS init & codepage (Latin-1 ~ 17) ===
  bytes.add([0x1B, 0x40]); // ESC @ init
  bytes.add(
      [0x1B, 0x74, 17]); // ESC t 17 (Latin-1) — ajusta si tu impresora usa otro

// ===== Logo (si existe) =====
  if (POSPrinter.logo != null && POSPrinter.logo!.isNotEmpty) {
    final raster = _escposRasterFromImage(
      Uint8List.fromList(POSPrinter.logo!),
      maxWidthPx: 384, // ajusta a 512/576 si tu impresora lo soporta
    );
    if (raster.isNotEmpty) {
      bytes.add([0x1B, 0x61, 0x01]); // center
      bytes.add(raster); // GS v 0 raster image
      bytes.add([0x1B, 0x61, 0x00]); // left
      bytes.add([0x0A]);
    }
  }

  void txt(String t, {bool center = false, bool bold = false}) {
    // Alineación
    bytes.add([0x1B, 0x61, center ? 0x01 : 0x00]); // ESC a n
    // Negrita
    bytes.add([0x1B, 0x45, bold ? 0x01 : 0x00]); // ESC E n
    bytes.add(const Latin1Codec().encode(t));
    bytes.add([0x0A]); // LF
    if (bold) bytes.add([0x1B, 0x45, 0x00]); // quitar negrita
  }

  // ===== Encabezado =====
  final headerName = POSPrinter.headerName ?? '';
  final headerAddress = POSPrinter.headerAddress ?? '';
  final headerTaxID = POSPrinter.headerTaxID;
  final headerDV = POSPrinter.headerDV;
  final headerPhone = POSPrinter.headerPhone;
  final headerEmail = POSPrinter.headerEmail ?? '';

  if (headerName.isNotEmpty) txt(headerName, center: true, bold: true);
  if (headerAddress.isNotEmpty) txt(headerAddress, center: true);
  if (headerTaxID != null) txt('RUC: $headerTaxID', center: true);
  if (headerDV != null) txt('DV: $headerDV', center: true);
  if ((headerPhone ?? '').toString().isNotEmpty)
    txt('Tel: $headerPhone', center: true);
  if (headerEmail.isNotEmpty) txt(headerEmail, center: true);
  txt('----------------------------------------', center: true);

  // ===== Datos básicos =====
  final docTypename = s(order['doctypetarget']?['name'] ?? '');
  if (docTypename.isNotEmpty) txt(docTypename, center: true, bold: true);

  final docNo = s(order['DocumentNo']);
  final date = s(order['DateOrdered']);
  final servedBy = s(order['SalesRep_ID']?['name'] ?? '');
  final taxID = s(order['bpartner']?['taxID'] ?? '');
  final customerName = s(order['bpartner']?['name'] ?? 'CONTADO');
  final location = s(order['bpartner']?['location'] ?? '');
  final phone = s(order['bpartner']?['phone'] ?? '');

  txt('Recibo: $docNo');
  txt('Fecha : $date');
  if (servedBy.isNotEmpty) txt('Atendido por: $servedBy');
  if (taxID.isNotEmpty) txt('Cédula: $taxID');
  txt('Cliente: $customerName');
  if (location.isNotEmpty) txt('Dirección: $location');
  if (phone.isNotEmpty) txt('Teléfono: $phone');
  txt('');
  txt('Ítem / Precio x Cant           Subtotal');
  txt('----------------------------------------');

  // ===== Líneas =====
  for (final line in lines) {
    final name =
        (line['M_Product_ID']?['identifier'] ?? '_${line['Description']}')
            .toString()
            .split('_')
            .skip(1)
            .join(' ');
    final qty = ((line['QtyOrdered'] as num?) ?? 0).toDouble();
    final price = ((line['PriceActual'] as num?) ?? 0).toDouble();
    final net = ((line['LineNetAmt'] as num?) ?? 0).toDouble();
    final rate = ((line['C_Tax_ID']?['Rate'] as num?) ?? 0).toDouble();
    final tax = double.parse((net * (rate / 100)).toStringAsFixed(2));
    final total = net + tax;
    final discount = ((line['Discount'] as num?) ?? 0).toDouble();
    final description = s(line['Description'] ?? '');

    txt(name, bold: true);

    final qtyStr =
        qty % 1 == 0 ? qty.toStringAsFixed(0) : qty.toStringAsFixed(2);
    final left = '${money(price)} x $qtyStr'
        '${discount > 0 ? ' | Desc: ${discount.toStringAsFixed(2)}%' : ''}';
    final right = money(total);

    // Alineación simple a ancho fijo ~42 columnas
    final totalCols = 42;
    final leftTrim = left.length > totalCols - right.length - 1
        ? left.substring(
            0, (totalCols - right.length - 1).clamp(0, left.length))
        : left;
    final spaces = (totalCols - leftTrim.length - right.length).clamp(1, 40);
    txt('$leftTrim${' ' * spaces}$right');

    if (description.isNotEmpty && description != name) {
      txt('  $description');
    }
    txt('');
  }

  txt('----------------------------------------');
  txt('Cant. Items: ${lines.length}');

  // ===== Totales =====
  final taxSummary = _calculateTaxSummary([order]);
  final taxTotal = taxSummary.values
      .map((e) => (e['tax'] as double))
      .fold<double>(0.0, (a, b) => a + b);
  final netSum = taxSummary.values
      .map((e) => (e['net'] as double))
      .fold<double>(0.0, (a, b) => a + b);
  final grandTotal = (order['GrandTotal'] as num?)?.toDouble() ?? 0.0;

  txt('Neto sin ITBMS: ${money(netSum)}', bold: true);
  txt('ITBMS: ${money(taxTotal)}');
  txt('TOTAL: ${money(grandTotal)}', bold: true);
  txt('');

// ===== FE (QR) =====
  final int? orderId = (order['id'] as int?);
  Map<String, String>? feInfo;
  if (orderId != null) {
    feInfo = await fetchElectronicInvoiceInfo(orderId: orderId);
  }
  if (feInfo != null) {
    txt('----------------------------------------');
    txt('FACTURA ELECTRÓNICA', center: true, bold: true);
    final proto = feInfo['protocolo'] ?? '';
    if (proto.isNotEmpty) txt('Protocolo: $proto');
    final url = feInfo['url'] ?? '';
    if (url.isNotEmpty) {
      txt('Consulta:');
      txt(url);
      // QR centrado (ESC/POS nativo)
      bytes.add([0x1B, 0x61, 0x01]); // center
      _escposAppendQr(bytes, url, size: 6, ecc: 49); // ECC M
      bytes.add([0x1B, 0x61, 0x00]); // left
      bytes.add([0x0A]);
    }
  }

  // ===== Pie + corte =====
  txt('Gracias por mantener sus pagos al día', center: true);
  bytes.add([0x1B, 0x64, 0x05]); // ESC d 5 — feed 5 líneas
  bytes.add([0x1D, 0x56, 0x00]); // GS V 0 — corte total

  await _printEscPosToDefault(bytes.toBytes());
}
