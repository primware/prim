import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/shared/custom_container.dart';
import 'package:primware/shared/custom_spacer.dart';

import 'package:primware/views/Home/order/my_order_detail_pdf_generator.dart';
import 'package:printing/printing.dart';

import '../../../localization/app_locale.dart';

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
            icon: const Icon(Icons.logout),
            tooltip: AppLocale.logout.getString(context),
            onPressed: () async {
              final bool? confirmPrintTicket = await _printTicketConfirmation(context);
              if (confirmPrintTicket == true) {
                // Aquí va tu lógica de logout
                // Por ejemplo: 
                // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
                // O si usas un state management:
                // context.read<AuthProvider>().logout();
                
                // Mientras tanto, mostramos un snackbar de confirmación
                ScaffoldMessenger.of(context).showSnackBar(
                  //SnackBar(content: Text(AppLocale.logoutSuccess.getString(context))),
                  SnackBar(content: Text('Mensaje')),
                );
                
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
