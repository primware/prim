import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:primware/shared/custom_container.dart';
import 'package:primware/shared/custom_spacer.dart';
import 'package:primware/views/Home/order/my_order_print_generator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:printing/printing.dart';
import '../../../API/pos.api.dart';
import '../../../API/token.api.dart';
import '../../../localization/app_locale.dart';
import '../../../shared/footer.dart';

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
    final int? orderId = (order['id'] as int?);
    final Future<Map<String, String>?> feFuture = orderId != null
        ? fetchElectronicInvoiceInfo(orderId: orderId)
        : Future.value(null);

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
          '${order['doctypetarget']['name']} #${order['DocumentNo']}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: AppLocale.exportPdf.getString(context),
            onPressed: () async {
              final pdfBytes = await generateOrderTicket(order);
              await Printing.sharePdf(
                bytes: pdfBytes,
                filename: 'Order_${order['DocumentNo']}.pdf',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: AppLocale.printTicket.getString(context),
            onPressed: () async {
              final bool? confirmPrintTicket = await _printTicketConfirmation(
                context,
              );
              if (confirmPrintTicket == true) {
                try {
                  if (POS.cPosID != null) {
                    CurrentLogMessage.add(
                      'POS mode detected. Trying RAW print (ESC/POS)...',
                      tag: 'PRINT',
                    );
                    try {
                      await printPOSTicketRaw(order, autoCut: true);
                      CurrentLogMessage.add(
                        'RAW print sent successfully',
                        tag: 'PRINT',
                      );
                      return; // listo, no seguimos al PDF
                    } on UnsupportedError catch (e) {
                      CurrentLogMessage.add(
                        'RAW print unsupported on this platform: ${e.message}',
                        level: 'WARN',
                        tag: 'PRINT',
                      );
                      // Plataforma no soporta RAW -> seguimos al PDF de respaldo
                    } catch (e) {
                      CurrentLogMessage.add(
                        'RAW print error: $e',
                        level: 'ERROR',
                        tag: 'PRINT',
                      );
                      // Cualquier otro error en RAW -> seguimos al PDF de respaldo
                    }
                  }

                  // Respaldo: PDF (POS -> ticket; no POS -> resumen de orden)
                  final pdfBytes = POS.cPosID != null
                      ? await generatePOSTicket(order)
                      : await generateOrderTicket(order);

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
                      usePrinterSettings: true,
                      dynamicLayout: true,
                      onLayout: (_) => pdfBytes,
                    );
                  } catch (e) {
                    await Printing.sharePdf(
                      bytes: pdfBytes,
                      filename: 'Order_${order['DocumentNo']}.pdf',
                    );
                  }
                } catch (e) {
                  // Último fallback silencioso: intentar compartir PDF genérico
                  try {
                    final pdfBytes = await generateOrderTicket(order);
                    await Printing.sharePdf(
                      bytes: pdfBytes,
                      filename: 'Order_${order['DocumentNo']}.pdf',
                    );
                  } catch (_) {}
                }
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: CustomFooter(),
      body: Center(
        child: CustomContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(order: order, context: context, feFuture: feFuture),
              const SizedBox(height: CustomSpacer.large),
              Text(
                AppLocale.productSummary.getString(context),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: CustomSpacer.small),
              Expanded(
                child: ListView.builder(
                  itemCount: lines.length,
                  itemBuilder: (context, index) {
                    final line = lines[index];
                    final String name =
                        (line['M_Product_ID']?['identifier'] ??
                                '_${line['Description']}')
                            .split('_')
                            .skip(1)
                            .join(' ');
                    final double qty = (line['QtyOrdered'] as num).toDouble();
                    final double price = (line['PriceActual'] as num)
                        .toDouble();
                    final double net = (line['LineNetAmt'] as num).toDouble();
                    final double rate = (line['C_Tax_ID']['Rate'] as num)
                        .toDouble();
                    final double tax = net * (rate / 100);
                    final double total = net + tax;

                    // Precio original (PriceList) y descuento
                    final double priceList =
                        (line['PriceList'] as num?)?.toDouble() ?? price;
                    final double discountPct =
                        (line['Discount'] as num?)?.toDouble() ??
                        ((priceList > 0)
                            ? (1 - (price / priceList)) * 100
                            : 0.0);

                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).scaffoldBackgroundColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        tileColor: Colors.transparent,
                        title: Text(
                          name,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${AppLocale.quantity.getString(context)}: $qty",
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              [
                                "${AppLocale.priceList.getString(context)}: \$${priceList.toStringAsFixed(2)}",
                                if (discountPct > 0.0)
                                  "${AppLocale.discount.getString(context)}: ${discountPct.toStringAsFixed(0)}%",
                                "${AppLocale.price.getString(context)}: \$${price.toStringAsFixed(2)}",
                              ].join(" | "),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${line['C_Tax_ID']['Name']} ($rate%)",
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(fontSize: 12),
                            ),
                            Text(
                              "${AppLocale.subtotal.getString(context)}: \$${net.toStringAsFixed(2)}",
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(fontSize: 12),
                            ),
                            Text(
                              "${AppLocale.total.getString(context)}: \$${total.toStringAsFixed(2)}",
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: CustomSpacer.large),
              Text(
                AppLocale.paymentMethods.getString(context),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: CustomSpacer.small),
              if (payments.isEmpty)
                Text(
                  AppLocale.noData.getString(context),
                  style: Theme.of(context).textTheme.bodySmall,
                )
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
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).scaffoldBackgroundColor.withOpacity(0.25),
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
                context: context,
              ),
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

  Widget _buildHeader({
    required Map<String, dynamic> order,
    required BuildContext context,
    required Future<Map<String, String>?> feFuture,
  }) {
    return FutureBuilder<Map<String, String>?>(
      future: feFuture,
      builder: (context, snapshot) {
        final fe = snapshot.data;
        final bool isMobile = MediaQuery.of(context).size.width < 600;

        final left = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, size: isMobile ? 20 : 32),
                const SizedBox(width: CustomSpacer.small),
                Text(
                  order['bpartner']['name'],
                  style: isMobile
                      ? Theme.of(context).textTheme.bodyMedium
                      : Theme.of(context).textTheme.headlineLarge,
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.calendar_month_outlined, size: isMobile ? 20 : 32),
                const SizedBox(width: CustomSpacer.small),
                Text(
                  order['DateOrdered'],
                  style: isMobile
                      ? Theme.of(context).textTheme.bodyMedium
                      : Theme.of(context).textTheme.headlineLarge,
                ),
              ],
            ),
          ],
        );

        Widget? right;
        if (fe != null && (fe['url']?.isNotEmpty ?? false)) {
          final qrUrlData = fe['url']!;
          right = Column(
            crossAxisAlignment: isMobile
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.end,
            children: [
              Text(
                AppLocale.electronicBill.getString(context),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: QrImageView(data: qrUrlData),
                ),
              ),
              if (isMobile) ...[
                InkWell(
                  onTap: () {
                    launchUrl(Uri.parse(qrUrlData));
                  },
                  child: Text(
                    AppLocale.seeReceipt.getString(context),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ],
          );
        }

        // Responsive: columna en móvil, fila en escritorio
        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              left,
              if (right != null) ...[const SizedBox(height: 12), right],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: left),
            if (right != null) const SizedBox(width: 12),
            if (right != null) right,
          ],
        );
      },
    );
  }

  Widget _buildFinalSummary({
    required Map<String, Map<String, double>> taxSummary,
    required double grandTotal,
    required BuildContext context,
  }) {
    final double totalNeto = taxSummary.values
        .map((e) => e['net']!)
        .reduce((a, b) => a + b);
    final double totalImpuesto = taxSummary.values
        .map((e) => e['tax']!)
        .reduce((a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocale.finalSummary.getString(context),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: CustomSpacer.small),
        Text(
          "${AppLocale.grossTotal.getString(context)} \$${totalNeto.toStringAsFixed(2)}",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        ...taxSummary.entries.map(
          (entry) => Text(
            "${entry.key}: \$${entry.value['tax']!.toStringAsFixed(2)}",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          "${AppLocale.taxTotal.getString(context)} \$${totalImpuesto.toStringAsFixed(2)}",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          "${AppLocale.finalTotal.getString(context)} \$${grandTotal.toStringAsFixed(2)}",
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}
