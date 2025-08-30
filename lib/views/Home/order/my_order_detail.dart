import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/shared/custom_container.dart';
import 'package:primware/shared/custom_spacer.dart';
import 'package:primware/views/Home/order/my_order_detail_pdf_generator.dart';
import 'package:printing/printing.dart';
import '../../../localization/app_locale.dart';
import 'package:pdf/widgets.dart' as pw;
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
    final pdf = pw.Document();

    // Obtener líneas del pedido
    final lines = (order['C_OrderLine'] as List?) ?? [];
    final taxSummary = _calculateTaxSummary([order]);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Pedido #${order['DocumentNo']}',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text('Cliente: ${order['bpartner']['name']}'),
            pw.Text('Fecha: ${order['DateOrdered']}'),
            pw.Divider(),
            pw.Text('Resumen de productos', style: pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 10),
            ...lines.map((line) {
              final name = (line['M_Product_ID']?['identifier']?.toString() ??
                      'Sin nombre')
                  .split('_')
                  .skip(1)
                  .join(' ');
              final qty = (line['QtyOrdered'] as num).toDouble();
              final price = (line['PriceActual'] as num).toDouble();
              final net = (line['LineNetAmt'] as num).toDouble();
              final rate = (line['C_Tax_ID']['Rate'] as num).toDouble();
              final tax = net * (rate / 100);
              final total = net + tax;

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(name,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                      'Cantidad: $qty | Precio: \$${price.toStringAsFixed(2)}'),
                  pw.Text('Impuesto: \$${tax.toStringAsFixed(2)}'),
                  pw.Text('Total: \$${total.toStringAsFixed(2)}'),
                  pw.Divider(),
                ],
              );
            }),
            pw.Divider(),
            pw.Text('Resumen final', style: pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 10),
            pw.Text(
                'Subtotal: \$${(order['GrandTotal'] as num).toDouble().toStringAsFixed(2)}'),
            ...taxSummary.entries.map((entry) => pw.Text(
                '${entry.key}: \$${entry.value['tax']!.toStringAsFixed(2)}')),
            pw.Text(
                'Total impuestos: \$${taxSummary.values.map((e) => e['tax']!).reduce((a, b) => a + b).toStringAsFixed(2)}'),
            pw.Text(
                'Total final: \$${(order['GrandTotal'] as num).toDouble().toStringAsFixed(2)}',
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  // Agrega este método a tu clase OrderDetailPage
  Future<void> _showPdfPreview(BuildContext context, Uint8List pdfBytes) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          //title: Text(AppLocale.previewTicket.getString(context)),
          title: Text('asdadsdad'),
          content: Container(
            width: double.maxFinite,
            height: 500,
            child: PdfPreview(
              build: (format) => pdfBytes,
              allowSharing: true,
              allowPrinting: true,
              canChangePageFormat: false,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocale.close.getString(context)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              //child: Text(AppLocale.print.getString(context)),
              child: Text('asdadaddd'),
              onPressed: () {
                Printing.layoutPdf(onLayout: (_) => pdfBytes);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
