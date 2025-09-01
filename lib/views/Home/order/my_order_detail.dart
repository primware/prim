import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/shared/custom_container.dart';
import 'package:primware/shared/custom_spacer.dart';
import 'package:primware/views/Home/order/my_order_detail_pdf_generator.dart';
import 'package:printing/printing.dart';
import '../../../localization/app_locale.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:typed_data';

class OrderDetailPage extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailPage({super.key, required this.order});

  // Función para mostrar la confirmación de imprimir ticket
  Future<bool?> _printTicketConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocale.confirmPrintTicket.getString(context)),
        content: Text(AppLocale.printTicketMessage.getString(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocale.no.getString(context)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocale.yes.getString(context)),
          ),
        ],
      ),
    );
  }

  Future<Uint8List> _generateTicketPdf(Map<String, dynamic> order) async {
    // Thermal ticket on 80mm roll with monospace layout
    final pdf = pw.Document();

    // Page format: 80mm roll (use PdfPageFormat.roll57 for 58mm if needed)
    final pageFormat = PdfPageFormat.roll80;

    // Monospace fonts to align columns
    final theme = pw.ThemeData.withFont(
      base: pw.Font.courier(),
      bold: pw.Font.courierBold(),
    );

    // Helpers
    String str(dynamic v) => v?.toString() ?? '';
    String money(num? v) => 'B/.${(v ?? 0).toDouble().toStringAsFixed(2)}';
    String truncate(String s, int max) =>
        s.length <= max ? s : s.substring(0, max);

    // Order fields (safe access)
    final docNo = str(order['DocumentNo']);
    final date = str(order['DateOrdered']);
    final servedBy = str(order['SalesRep_ID']?['name'] ?? '');
    final account = str(order['PaymentRule'] ?? 'CONTADO');
    final bp = order['bpartner'] ?? {};
    final customerName = str(bp['name'] ?? 'CONTADO');
    final customeLocation = str(bp['location'] ?? '');

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
            marginLeft: 8, marginRight: 8, marginTop: 8, marginBottom: 8),
        theme: theme,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Encabezado centrado
              pw.Text('Punto de Venta Lirion', textAlign: pw.TextAlign.center),
              pw.Text('Punto de Venta Táctil', textAlign: pw.TextAlign.center),
              pw.Text('Derechos reservados (c) 2009–2018 Lirion',
                  textAlign: pw.TextAlign.center),
              pw.Text('Cambie el encabezado en Configuración',
                  textAlign: pw.TextAlign.center),
              pw.Text('Impresión de Ticket', textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 6),

              // Detalles (alineados a la izquierda)
              pw.Text('Recibo: $docNo'),
              pw.Text('Fecha: $date'),
              if (servedBy.isNotEmpty) pw.Text('Atendido por: $servedBy'),
              pw.Text('Cuenta #: $account'),
              pw.Text('Cliente: $customerName'),
              if (customeLocation.isNotEmpty)
                pw.Text('Dirección: $customeLocation'),
              pw.SizedBox(height: 6),

              // Tabla de ítems (alineada en 4 columnas)
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 20,
                    child: pw.Text('Artículo', maxLines: 1),
                  ),
                  pw.Expanded(
                    flex: 15,
                    child: pw.Align(
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Text('B/.', maxLines: 1),
                    ),
                  ),
                  pw.Expanded(
                    flex: 10,
                    child: pw.Align(
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Text('#', maxLines: 1),
                    ),
                  ),
                  pw.Expanded(
                    flex: 10,
                    child: pw.Align(
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Text('Importe', maxLines: 1),
                    ),
                  ),
                ],
              ),
              pw.Divider(),
              ...lines.map((line) {
                final name = (line['M_Product_ID']?['identifier'] ?? 'Ítem')
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

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Proporciones similares al ticket: 20/10/5/10
                        pw.Expanded(
                          flex: 20,
                          child: pw.Text(
                            truncate(name, 24),
                            maxLines: 1,
                            overflow: pw.TextOverflow.clip,
                          ),
                        ),
                        pw.Expanded(
                          flex: 15,
                          child: pw.Align(
                            alignment: pw.Alignment.centerLeft,
                            child: pw.Text(money(price), maxLines: 1),
                          ),
                        ),
                        pw.Expanded(
                          flex: 10,
                          child: pw.Align(
                            alignment: pw.Alignment.centerLeft,
                            child: pw.Text(
                                qty.toStringAsFixed(qty % 1 == 0 ? 0 : 2),
                                maxLines: 1),
                          ),
                        ),
                        pw.Expanded(
                          flex: 10,
                          child: pw.Align(
                            child: pw.Text(money(value), maxLines: 1),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                        'Impuesto ${rate.toStringAsFixed(0)}%: ${money(tax)}',
                        textAlign: pw.TextAlign.left,
                        maxLines: 1),
                  ],
                );
              }),

              pw.SizedBox(height: 6),

              // Totales
              pw.Text('Cantidad de artículos: ${lines.length}'),
              pw.Divider(),
              pw.Text('Total: ${money(grandTotal)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),

              // Impuestos
              pw.Text('Neto (sin impuesto): ${money(netSum)}'),
              pw.Text('Impuestos: ${money(taxTotal)}'),
              pw.SizedBox(height: 6),

              // Footer
              pw.Text('Cambie el texto del pie en Configuración'),
              pw.Divider(),
              pw.Text('Gracias por su compra'),
              pw.Text('Por favor vuelva pronto'),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    final lines = (order['C_OrderLine'] as List?) ?? [];
    final taxSummary = _calculateTaxSummary([order]);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          //'${AppLocale.orderHash.getString(context)}${order['DocumentNo']}',
          '${order['doctypetarget']['name']} #${order['DocumentNo']}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: AppLocale.exportPdf.getString(context),
            onPressed: () async {
              final pdf = await generateOrderSummaryPdf(order);
              await Printing.sharePdf(
                  bytes: await pdf.save(),
                  filename: 'Order_${order['DocumentNo']}.pdf');
            },
          ),
          IconButton(
            icon: const Icon(Icons.receipt),
            tooltip: AppLocale.printTicket.getString(context),
            onPressed: () async {
              final bool? confirmPrintTicket =
                  await _printTicketConfirmation(context);
              if (confirmPrintTicket == true) {
                // Aquí va tu lógica

                // Generar el PDF
                //final pdfDocument = await generateOrderSummaryPdf(order);
                final pdfBytes = await _generateTicketPdf(order);
                //final pdfBytes = await pdfDocument.save();

                // Mostrar la vista previa del PDF
                //await _showPdfPreview(context, pdfBytes);

                // Mostrar la vista previa del PDF
                await Printing.layoutPdf(
                  onLayout: (_) => pdfBytes,
                );

                // Mientras tanto, mostramos un snackbar de confirmación
                /*ScaffoldMessenger.of(context).showSnackBar(
                  //SnackBar(content: Text(AppLocale.logoutSuccess.getString(context))),
                  SnackBar(content: Text('Mensaje')),
                );*/

                // Cerrar la página actual y volver al login
                //Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: CustomContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(order: order, context: context),
              const SizedBox(height: CustomSpacer.large),
              Text(AppLocale.productSummary.getString(context),
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: CustomSpacer.small),
              Expanded(
                child: ListView.builder(
                  itemCount: lines.length,
                  itemBuilder: (context, index) {
                    final line = lines[index];
                    final String name =
                        (line['M_Product_ID']?['identifier']?.toString() ??
                                AppLocale.noName.getString(context))
                            .split('_')
                            .skip(1)
                            .join(' ');
                    final double qty = (line['QtyOrdered'] as num).toDouble();
                    final double price =
                        (line['PriceActual'] as num).toDouble();
                    final double net = (line['LineNetAmt'] as num).toDouble();
                    final double rate =
                        (line['C_Tax_ID']['Rate'] as num).toDouble();
                    final double tax = net * (rate / 100);
                    final double total = net + tax;

                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .scaffoldBackgroundColor
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        tileColor: Colors.transparent,
                        title: Text(name,
                            style: Theme.of(context).textTheme.bodyMedium),
                        subtitle: Text(
                            "${AppLocale.quantity.getString(context)}: $qty | ${AppLocale.price.getString(context)}: \$${price.toStringAsFixed(2)}",
                            style: Theme.of(context).textTheme.bodySmall),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${line['C_Tax_ID']['Name']} ($rate%)",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontSize: 12),
                            ),
                            Text(
                              "${AppLocale.subtotal.getString(context)}: \$${net.toStringAsFixed(2)}",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontSize: 12),
                            ),
                            Text(
                              "${AppLocale.total.getString(context)}: \$${total.toStringAsFixed(2)}",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              _buildFinalSummary(
                  taxSummary: taxSummary,
                  grandTotal: (order['GrandTotal'] as num).toDouble(),
                  context: context),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildHeader(
      {required Map<String, dynamic> order, required BuildContext context}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person_outline,
                color: Theme.of(context).colorScheme.onSecondary),
            const SizedBox(width: CustomSpacer.small),
            Text(order['bpartner']['name'],
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.calendar_month_outlined),
            const SizedBox(width: CustomSpacer.small),
            Text(order['DateOrdered'],
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }

  Widget _buildFinalSummary({
    required Map<String, Map<String, double>> taxSummary,
    required double grandTotal,
    required BuildContext context,
  }) {
    final double totalNeto =
        taxSummary.values.map((e) => e['net']!).reduce((a, b) => a + b);
    final double totalImpuesto =
        taxSummary.values.map((e) => e['tax']!).reduce((a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocale.finalSummary.getString(context),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: CustomSpacer.small),
        Text(
            "${AppLocale.grossTotal.getString(context)} \$${totalNeto.toStringAsFixed(2)}",
            style: Theme.of(context).textTheme.bodyMedium),
        ...taxSummary.entries.map((entry) => Text(
            "${entry.key}: \$${entry.value['tax']!.toStringAsFixed(2)}",
            style: Theme.of(context).textTheme.bodyMedium)),
        Text(
            "${AppLocale.taxTotal.getString(context)} \$${totalImpuesto.toStringAsFixed(2)}",
            style: Theme.of(context).textTheme.titleMedium),
        Text(
            "${AppLocale.finalTotal.getString(context)} \$${grandTotal.toStringAsFixed(2)}",
            style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
