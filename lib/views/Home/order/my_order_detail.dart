import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/shared/custom_container.dart';
import 'package:primware/shared/custom_spacer.dart';
import 'package:primware/views/Home/order/my_order_detail_pdf_generator.dart';
import 'package:printing/printing.dart';
import '../../../localization/app_locale.dart';

import 'order_funtions.dart';

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
          ElevatedButton(
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

    // Detectar si es devolución (RM)
    final dynamic subField = order['doctypetarget']?['subtype'];
    final String? subId = (subField is Map) ? subField['id'] : subField;
    final bool isReturn = subId == 'RM';

    // Obtener métodos de pago
    final List<dynamic> payments =
        (order['C_POSPayment'] ?? order['payments'] ?? []) as List<dynamic>;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: (isReturn) ? Colors.red : null,
        foregroundColor: (isReturn) ? Colors.white : null,
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
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: AppLocale.printTicket.getString(context),
            onPressed: () async {
              final bool? confirmPrintTicket =
                  await _printTicketConfirmation(context);
              if (confirmPrintTicket == true) {
                final pdfBytes = await generateTicketPdf(order);

                try {
                  final printers = await Printing.listPrinters();
                  final defaultPrinter = printers.firstWhere(
                    (p) => p.isDefault,
                    orElse: () => printers.isNotEmpty
                        ? printers.first
                        : throw Exception('No hay impresoras disponibles'),
                  );

                  await Printing.directPrintPdf(
                    printer: defaultPrinter,
                    onLayout: (_) => pdfBytes,
                  );
                } catch (e) {
                  await Printing.layoutPdf(
                    onLayout: (_) => pdfBytes,
                  );
                }
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
              const SizedBox(height: CustomSpacer.large),
              Text(AppLocale.paymentMethods.getString(context),
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: CustomSpacer.small),
              if (payments.isEmpty)
                Text(AppLocale.noData.getString(context),
                    style: Theme.of(context).textTheme.bodySmall)
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: payments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final p = payments[index] as Map<String, dynamic>;
                    final dynamic tenderField = p['C_POSTenderType_ID'];
                    final String tenderName = (tenderField is Map)
                        ? (tenderField['identifier'] ??
                                tenderField['name'] ??
                                '---')
                            .toString()
                        : tenderField?.toString() ?? '---';
                    final double payAmt =
                        ((p['PayAmt'] ?? p['Amount'] ?? 0) as num).toDouble();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .scaffoldBackgroundColor
                            .withOpacity(0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              tenderName,
                              style: Theme.of(context).textTheme.bodyMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "\$${payAmt.toStringAsFixed(2)}",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  },
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
