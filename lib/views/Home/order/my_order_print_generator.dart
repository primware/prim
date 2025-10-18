import 'dart:convert';
import 'dart:typed_data';

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

Future<Map<String, String>?> _fetchElectronicInvoiceInfo(
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

Future<Uint8List> generatePOSTicket(Map<String, dynamic> order) async {
  // Consultar datos de Factura Electrónica (FE)
  final int? orderId = (order['id'] as int?);
  final feInfo = orderId != null
      ? await _fetchElectronicInvoiceInfo(orderId: orderId)
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

  // Render PDF
  pdf.addPage(
    pw.Page(
      pageFormat: pageFormat.copyWith(
          marginTop: 8, marginBottom: 8, width: 75 * PdfPageFormat.mm),
      // theme: theme,
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
            pw.Text('Teléfono: $phone'),
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
                              maxLines: 1, style: pw.TextStyle(fontSize: 12)),
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
                                  style: pw.TextStyle(fontSize: 12),
                                ),
                                if (discount > 0)
                                  pw.Text(
                                    'Desc: ${discount.toStringAsFixed(2)}%',
                                    maxLines: 1,
                                    style: pw.TextStyle(
                                      fontSize: 10,
                                      fontStyle: pw.FontStyle.italic,
                                    ),
                                  ),
                                if (description.isNotEmpty &&
                                    description != name)
                                  pw.Text(
                                    description,
                                    maxLines: 1,
                                    style: pw.TextStyle(
                                      fontSize: 10,
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
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text('Protocolo de Autorización: ${feInfo['protocolo']}'),
              pw.Text('Consulte por la clave de acceso en:'),
              pw.Text(feInfo['url'] ?? '', style: pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 6),
              pw.Text('o escaneando el código QR:'),
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

            pw.SizedBox(height: 48),
          ],
        );
      },
    ),
  );

  return pdf.save();
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
