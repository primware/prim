import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:primware/shared/custom_container.dart';
import 'package:primware/shared/custom_spacer.dart';
import 'package:primware/views/Home/order/my_order_print_generator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:printing/printing.dart';
import '../../../API/pos.api.dart';
import '../../../localization/app_locale.dart';
import '../../../shared/footer.dart';
import 'package:primware/views/Home/order/my_order_new.dart';
import 'package:primware/views/Home/order/order_funtions.dart';

class OrderDetailPage extends StatelessWidget {
  final Map<String, dynamic> order;

  // Mapa de estados de documento (DocStatus) a nombre en español, color e icono
  static const Map<String, Map<String, Object>> _docStatusMap = {
    'DR': {'label': 'Borrador', 'color': Colors.grey, 'icon': Icons.edit_note},
    'CO': {'label': 'Completado', 'color': Colors.green, 'icon': Icons.check_circle_outline},
    'CL': {'label': 'Cerrado', 'color': Colors.blueGrey, 'icon': Icons.lock_outline},
    'VO': {'label': 'Anulado', 'color': Colors.red, 'icon': Icons.cancel_outlined},
    'IP': {'label': 'En proceso', 'color': Colors.orange, 'icon': Icons.hourglass_bottom},
    'PR': {'label': 'Preparado', 'color': Colors.orange, 'icon': Icons.hourglass_bottom},
    'WC': {'label': 'Esperando completar', 'color': Colors.orangeAccent, 'icon': Icons.hourglass_top},
    'AP': {'label': 'Aprobado', 'color': Colors.blue, 'icon': Icons.thumb_up_outlined},
    'RJ': {'label': 'Rechazado', 'color': Colors.redAccent, 'icon': Icons.thumb_down_outlined},
  };

  const OrderDetailPage({super.key, required this.order});

  // Función para mostrar la confirmación de imprimir ticket
  Future<bool?> _printTicketConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).cardColor,
        title: Column(
          children: [
            Icon(Icons.print_outlined, size: 45, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text(
              AppLocale.confirmPrintTicket.getString(context),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(AppLocale.printTicketMessage.getString(context), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(AppLocale.no.getString(context))),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(AppLocale.yes.getString(context))),
        ],
      ),
    );
  }

  Future<bool?> _refundConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).cardColor,
        title: const Column(
          children: [
            Icon(Icons.warning_amber_rounded, size: 45, color: Colors.redAccent),
            SizedBox(height: 10),
            Text(
              'Confirmar Devolución',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text('¿Seguro que quiere hacer una devolución?', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(AppLocale.no.getString(context))),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(AppLocale.yes.getString(context))),
        ],
      ),
    );
  }

  // Confirmación para convertir a Nota de Crédito
  Future<bool?> _creditMemoConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).cardColor,
        title: const Column(
          children: [
            Icon(Icons.warning_amber_rounded, size: 45, color: Colors.redAccent),
            SizedBox(height: 10),
            Text(
              'Confirmar Nota de Crédito',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Seguro que quiere convertir a nota de crédito?', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
            SizedBox(height: 12),
            Text(
              'Recuerde que esta acción no se puede deshacer.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(AppLocale.no.getString(context))),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(AppLocale.yes.getString(context))),
        ],
      ),
    );
  }

  // Confirmación para Completar la Orden
  Future<bool?> _completeConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).cardColor,
        title: const Column(
          children: [
            Icon(Icons.check, size: 45, color: Colors.green),
            SizedBox(height: 10),
            Text(
              'Completar Orden',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text('¿Seguro que desea completar esta orden?', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(AppLocale.no.getString(context))),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(AppLocale.yes.getString(context))),
        ],
      ),
    );
  }

  Widget _buildSubtypePill(BuildContext context, Map<String, dynamic> order) {
    final sub = order['doctypetarget']?['subtype']?['id'];
    final bool isReturn = (sub == 'RM') || (order['doctypetarget']?['id'] == POS.docTypeRefundID);

    final Color baseColor = isReturn ? Colors.red : Colors.green;
    final Color bgColor = baseColor.withOpacity(0.12);
    final String label = isReturn ? AppLocale.refund.getString(context) : AppLocale.order.getString(context);
    final IconData icon = isReturn ? Icons.undo : Icons.shopping_cart;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: baseColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: baseColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: baseColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditMemoPill() {
    const Color baseColor = Colors.red;
    final Color bgColor = baseColor.withOpacity(0.12);

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: baseColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 14, color: baseColor),
          const SizedBox(width: 6),
          const Text(
            'Nota de Crédito',
            style: TextStyle(fontSize: 12, color: baseColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildEditPill(BuildContext context, Map<String, dynamic> order) {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderNewPage(isRefund: false, doctypeID: order['doctypetarget']?['id'] ?? POS.docTypeID, orderName: order['doctypetarget']?['name'] ?? POS.docTypeName, sourceOrderId: order['id']),
          ),
        );
        // Si se guardó, refrescamos devolviendo un true
        if (result == true) {
          Navigator.pop(context, true);
        }
      },
      borderRadius: BorderRadius.circular(50),
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.amberAccent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: Colors.amber.shade700, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_document, size: 14, color: Colors.amber.shade800),
            const SizedBox(width: 6),
            Text(
              AppLocale.edit.getString(context),
              style: TextStyle(fontSize: 12, color: Colors.amber.shade800, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lines = (order['C_OrderLine'] as List?) ?? [];
    final taxSummary = _calculateTaxSummary([order]);
    final int? orderId = (order['id'] as int?);
    final Future<Map<String, String>?> feFuture = orderId != null ? fetchElectronicInvoiceInfo(orderId: orderId) : Future.value(null);

    // Detectar si es devolución (RM)
    final dynamic subField = order['doctypetarget']?['subtype'];
    final String? subId = (subField is Map) ? subField['id'] : subField;
    final bool isReturn = subId == 'RM';

    // --- Validaciones de Estado y Nota de Crédito ---
    final bool isComplete = (order['DocStatus'] == 'CO');
    final List invoices = order['C_Invoice'] ?? [];
    final bool hasCreditNote = invoices.any((inv) {
      return inv['RelatedInvoice_ID'] != null;
    });

    // Obtener métodos de pago
    final List<dynamic> payments = (order['C_POSPayment'] ?? order['payments'] ?? []) as List<dynamic>;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: (isReturn) ? Colors.red : null,
        foregroundColor: (isReturn) ? Colors.white : null,
        title: Text('${order['doctypetarget']['name']} #${order['DocumentNo']}'),
        actions: [
          Builder(
            builder: (context) {
              final bool isMobileVertical = MediaQuery.of(context).size.width < 600;

              void actionShare() async {
                final pdfBytes = await generateOrderTicket(order);
                await Printing.sharePdf(bytes: pdfBytes, filename: 'Order_${order['DocumentNo']}.pdf');
              }

              void actionDuplicate() {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderNewPage(isRefund: false, doctypeID: order['doctypetarget']?['id'] ?? POS.docTypeID, orderName: order['doctypetarget']?['name'] ?? POS.docTypeName, sourceOrderId: order['id']),
                  ),
                );
              }

              void actionRefund() async {
                final bool? confirm = await _refundConfirmation(context);
                if (confirm == true) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderNewPage(isRefund: true, doctypeID: POS.docTypeRefundID, orderName: POS.docTypeRefundName, sourceOrderId: order['id'] ?? order['C_Order_ID'] ?? order['record_id']),
                    ),
                  );
                }
              }

              void actionArc() async {
                final bool? confirm = await _creditMemoConfirmation(context);
                if (confirm == true) {
                  final bool creditMemoSucces = await createCreditMemo(cInvoiceID: order['C_Invoice']?[0]?['id']);
                  if (creditMemoSucces) {
                    Navigator.pop(context, true);
                  }
                }
              }

              void actionPrint() async {
                final bool? confirmPrintTicket = await _printTicketConfirmation(context);
                if (confirmPrintTicket == true) {
                  try {
                    final pdfBytes = POS.isPOS == true ? await generatePOSTicket(order) : await generateOrderTicket(order);
                    try {
                      final printers = await Printing.listPrinters();
                      final defaultPrinter = printers.firstWhere((p) => p.isDefault, orElse: () => printers.isNotEmpty ? printers.first : throw Exception('No hay impresoras disponibles'));
                      await Printing.directPrintPdf(printer: defaultPrinter, usePrinterSettings: true, dynamicLayout: true, onLayout: (_) => pdfBytes);
                    } catch (e) {
                      await Printing.sharePdf(bytes: pdfBytes, filename: 'Order_${order['DocumentNo']}.pdf');
                    }
                  } catch (e) {
                    try {
                      final pdfBytes = await generateOrderTicket(order);
                      await Printing.sharePdf(bytes: pdfBytes, filename: 'Order_${order['DocumentNo']}.pdf');
                    } catch (_) {}
                  }
                }
              }

              void actionComplete() async {
                final bool? confirmComplete = await _completeConfirmation(context);
                if (confirmComplete == true) {
                  final Map<String, dynamic> completeResult = await docComplete(cOrderID: order['id']);
                  if (completeResult['success'] == true && completeResult['isError'] != true) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(completeResult['summary'] ?? 'Orden completada con éxito'), backgroundColor: Colors.green));
                      Navigator.pop(context, true);
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(completeResult['summary'] ?? 'Error al completar la orden'), backgroundColor: Colors.red));
                    }
                  }
                }
              }

              if (isMobileVertical) {
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'share':
                        actionShare();
                        break;
                      case 'duplicate':
                        actionDuplicate();
                        break;
                      case 'refund':
                        actionRefund();
                        break;
                      case 'arc':
                        actionArc();
                        break;
                      case 'printTicket':
                        actionPrint();
                        break;
                      case 'complete':
                        actionComplete();
                        break; // <-- Lo agregamos al router
                    }
                  },
                  itemBuilder: (context) {
                    final items = <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'share',
                        child: Row(
                          children: [
                            const Icon(Icons.share, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(AppLocale.exportPdf.getString(context)),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'printTicket',
                        child: Row(
                          children: [
                            const Icon(Icons.print_outlined, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(AppLocale.printTicket.getString(context)),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Text(AppLocale.duplicate.getString(context)),
                          ],
                        ),
                      ),
                    ];

                    //Opción de Completar

                    if (order['DocStatus'] == 'DR') {
                      items.add(
                        const PopupMenuItem<String>(
                          value: 'complete',
                          child: Row(
                            children: [
                              Icon(Icons.check, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Completar'),
                            ],
                          ),
                        ),
                      );
                    }

                    if (isReturn == false && POS.isPOS == true && !hasCreditNote) {
                      items.add(
                        PopupMenuItem<String>(
                          value: 'refund',
                          child: Row(
                            children: [
                              const Icon(Icons.undo, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(AppLocale.refund.getString(context)),
                            ],
                          ),
                        ),
                      );
                    }
                    if (POS.isPOS == false && isComplete == true && !hasCreditNote) {
                      items.add(
                        PopupMenuItem<String>(
                          value: 'arc',
                          child: Row(
                            children: [
                              const Icon(Icons.receipt_long_rounded, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(AppLocale.arc.getString(context)),
                            ],
                          ),
                        ),
                      );
                    }
                    return items;
                  },
                );
              } else {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.share), tooltip: AppLocale.exportPdf.getString(context), onPressed: actionShare),
                    IconButton(icon: const Icon(Icons.copy), tooltip: AppLocale.duplicate.getString(context), onPressed: actionDuplicate),

                    if (order['DocStatus'] == 'DR')
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        tooltip: 'Completar',
                        onPressed: actionComplete,
                      ),

                    if (isReturn == false && POS.isPOS == true && !hasCreditNote)
                      IconButton(
                        icon: const Icon(Icons.undo, color: Colors.redAccent),
                        tooltip: AppLocale.refund.getString(context),
                        onPressed: actionRefund,
                      ),
                    if (POS.isPOS == false && isComplete == true && !hasCreditNote)
                      IconButton(
                        icon: const Icon(Icons.receipt_long_outlined, color: Colors.redAccent),
                        tooltip: AppLocale.arc.getString(context),
                        onPressed: actionArc,
                      ),
                    IconButton(icon: const Icon(Icons.print_rounded), tooltip: AppLocale.printTicket.getString(context), onPressed: actionPrint),
                  ],
                );
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: CustomFooter(),
      body: Center(
        child: CustomContainer(
          child: OrientationBuilder(
            builder: (context, orientation) {
              if (orientation == Orientation.portrait) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(order: order, context: context, feFuture: feFuture, hasCreditNote: hasCreditNote),
                    const SizedBox(height: CustomSpacer.large),
                    Text(AppLocale.productSummary.getString(context), style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: CustomSpacer.small),
                    Expanded(
                      child: ListView.builder(
                        itemCount: lines.length,
                        itemBuilder: (context, index) {
                          final line = lines[index];
                          final String name = (line['M_Product_ID']?['identifier'] ?? '_${line['Description']}').split('_').skip(1).join(' ');
                          final double qty = (line['QtyOrdered'] as num).toDouble();
                          final double price = (line['PriceActual'] as num).toDouble();
                          final double net = (line['LineNetAmt'] as num).toDouble();
                          final double rate = (line['C_Tax_ID']['Rate'] as num).toDouble();
                          final double tax = net * (rate / 100);
                          final double total = net + tax;

                          // Precio original (PriceList) y descuento
                          final double priceList = (line['PriceList'] as num?)?.toDouble() ?? price;
                          final double discountPct = (line['Discount'] as num?)?.toDouble() ?? ((priceList > 0) ? (1 - (price / priceList)) * 100 : 0.0);

                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
                            child: ListTile(
                              tileColor: Colors.transparent,
                              title: Text(name, style: Theme.of(context).textTheme.bodyMedium),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("${AppLocale.quantity.getString(context)}: $qty", style: Theme.of(context).textTheme.bodySmall),
                                  Text(["${AppLocale.priceList.getString(context)}: \$${priceList.toStringAsFixed(2)}", if (discountPct > 0.0) "${AppLocale.discount.getString(context)}: ${discountPct.toStringAsFixed(0)}%", "${AppLocale.price.getString(context)}: \$${price.toStringAsFixed(2)}"].join(" | "), style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("${line['C_Tax_ID']['Name']} ($rate%)", style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
                                  Text("${AppLocale.subtotal.getString(context)}: \$${net.toStringAsFixed(2)}", style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
                                  Text("${AppLocale.total.getString(context)}: \$${total.toStringAsFixed(2)}", style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: CustomSpacer.large),
                    Text(AppLocale.paymentMethods.getString(context), style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: CustomSpacer.small),
                    if (payments.isEmpty)
                      Text(AppLocale.noData.getString(context), style: Theme.of(context).textTheme.bodySmall)
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: payments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final p = payments[index] as Map<String, dynamic>;
                          final dynamic tenderField = p['C_POSTenderType_ID'];
                          final String tenderName = (tenderField is Map) ? (tenderField['identifier'] ?? tenderField['name'] ?? '---').toString() : tenderField?.toString() ?? '---';
                          final double payAmt = ((p['PayAmt'] ?? p['Amount'] ?? 0) as num).toDouble();
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.25), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(tenderName, style: Theme.of(context).textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 12),
                                Text("\$${payAmt.toStringAsFixed(2)}", style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          );
                        },
                      ),
                    const Divider(),
                    _buildFinalSummary(taxSummary: taxSummary, grandTotal: (order['GrandTotal'] as num).toDouble(), context: context),
                  ],
                );
              } else {
                // VISTA HORIZONTAL (Sin Expanded, con SingleChildScrollView)

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(order: order, context: context, feFuture: feFuture, hasCreditNote: hasCreditNote),
                      const SizedBox(height: CustomSpacer.large),
                      Text(AppLocale.productSummary.getString(context), style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: CustomSpacer.small),

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: lines.length,
                        itemBuilder: (context, index) {
                          final line = lines[index];
                          final String name = (line['M_Product_ID']?['identifier'] ?? '_${line['Description']}').split('_').skip(1).join(' ');
                          final double qty = (line['QtyOrdered'] as num).toDouble();
                          final double price = (line['PriceActual'] as num).toDouble();
                          final double net = (line['LineNetAmt'] as num).toDouble();
                          final double rate = (line['C_Tax_ID']['Rate'] as num).toDouble();
                          final double tax = net * (rate / 100);
                          final double total = net + tax;

                          final double priceList = (line['PriceList'] as num?)?.toDouble() ?? price;
                          final double discountPct = (line['Discount'] as num?)?.toDouble() ?? ((priceList > 0) ? (1 - (price / priceList)) * 100 : 0.0);

                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
                            child: ListTile(
                              tileColor: Colors.transparent,
                              title: Text(name, style: Theme.of(context).textTheme.bodyMedium),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("${AppLocale.quantity.getString(context)}: $qty", style: Theme.of(context).textTheme.bodySmall),
                                  Text(["${AppLocale.priceList.getString(context)}: \$${priceList.toStringAsFixed(2)}", if (discountPct > 0.0) "${AppLocale.discount.getString(context)}: ${discountPct.toStringAsFixed(0)}%", "${AppLocale.price.getString(context)}: \$${price.toStringAsFixed(2)}"].join(" | "), style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("${line['C_Tax_ID']['Name']} ($rate%)", style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
                                  Text("${AppLocale.subtotal.getString(context)}: \$${net.toStringAsFixed(2)}", style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
                                  Text("${AppLocale.total.getString(context)}: \$${total.toStringAsFixed(2)}", style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: CustomSpacer.large),
                      Text(AppLocale.paymentMethods.getString(context), style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: CustomSpacer.small),
                      if (payments.isEmpty)
                        Text(AppLocale.noData.getString(context), style: Theme.of(context).textTheme.bodySmall)
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: payments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final p = payments[index] as Map<String, dynamic>;
                            final dynamic tenderField = p['C_POSTenderType_ID'];
                            final String tenderName = (tenderField is Map) ? (tenderField['identifier'] ?? tenderField['name'] ?? '---').toString() : tenderField?.toString() ?? '---';
                            final double payAmt = ((p['PayAmt'] ?? p['Amount'] ?? 0) as num).toDouble();
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.25), borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(tenderName, style: Theme.of(context).textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
                                  ),
                                  const SizedBox(width: 12),
                                  Text("\$${payAmt.toStringAsFixed(2)}", style: Theme.of(context).textTheme.bodyMedium),
                                ],
                              ),
                            );
                          },
                        ),
                      const Divider(),
                      _buildFinalSummary(taxSummary: taxSummary, grandTotal: (order['GrandTotal'] as num).toDouble(), context: context),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDocStatusPill(BuildContext context, Map<String, dynamic> order) {
    final String? statusCode = order['DocStatus'] as String?;
    if (statusCode == null || statusCode.isEmpty) {
      return const SizedBox.shrink();
    }

    final meta = _docStatusMap[statusCode] ?? {'label': statusCode, 'color': Theme.of(context).colorScheme.primary, 'icon': Icons.flag_outlined};

    final Color baseColor = (meta['color'] as Color?) ?? Theme.of(context).colorScheme.primary;
    final Color bgColor = baseColor.withOpacity(0.12);
    final String label = meta['label'] as String? ?? statusCode;
    final IconData icon = (meta['icon'] as IconData?) ?? Icons.flag_outlined;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: baseColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: baseColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: baseColor, fontWeight: FontWeight.w600),
          ),
        ],
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

          taxSummary.putIfAbsent(taxKey, () => {"net": 0.0, "tax": 0.0, "total": 0.0});

          final double taxAmount = double.parse((lineNetAmt * (taxRate / 100)).toStringAsFixed(2));
          taxSummary[taxKey]!["net"] = taxSummary[taxKey]!["net"]! + lineNetAmt;
          taxSummary[taxKey]!["tax"] = taxSummary[taxKey]!["tax"]! + taxAmount;
          taxSummary[taxKey]!["total"] = taxSummary[taxKey]!["total"]! + lineNetAmt + taxAmount;
        }
      }
    }

    return taxSummary;
  }

  Widget _buildHeader({
    required Map<String, dynamic> order,
    required BuildContext context,
    required Future<Map<String, String>?> feFuture,
    required bool hasCreditNote, // NUEVO PARÁMETRO
  }) {
    return FutureBuilder<Map<String, String>?>(
      future: feFuture,
      builder: (context, snapshot) {
        final fe = snapshot.data;
        final bool isMobile = MediaQuery.of(context).size.width < 600;

        final left = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(order['bpartner']['name'], maxLines: 2, overflow: TextOverflow.ellipsis, style: isMobile ? Theme.of(context).textTheme.bodyMedium : Theme.of(context).textTheme.headlineSmall),
            Text(order['DateOrdered'], style: isMobile ? Theme.of(context).textTheme.bodyMedium : Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            // MOSTRAR TODOS LOS CHIPS JUNTOS ORDENADOS
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildSubtypePill(context, order),
                _buildDocStatusPill(context, order),
                //if (order['DocStatus'] == 'DR') _buildEditPill(context, order),
                if (hasCreditNote) _buildCreditMemoPill(),
              ],
            ),
          ],
        );

        Widget? right;
        if (fe != null && (fe['url']?.isNotEmpty ?? false)) {
          final qrUrlData = fe['url']!;
          right = Column(
            crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.end,
            children: [
              Text(AppLocale.electronicBill.getString(context), style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(width: 120, height: 120, child: QrImageView(data: qrUrlData)),
              ),
              if (isMobile) ...[
                InkWell(
                  onTap: () {
                    launchUrl(Uri.parse(qrUrlData));
                  },
                  child: Text(
                    AppLocale.seeReceipt.getString(context),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary),
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

  Widget _buildFinalSummary({required Map<String, Map<String, double>> taxSummary, required double grandTotal, required BuildContext context}) {
    final double totalNeto = taxSummary.values.map((e) => e['net']!).reduce((a, b) => a + b);
    final double totalImpuesto = taxSummary.values.map((e) => e['tax']!).reduce((a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocale.finalSummary.getString(context), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: CustomSpacer.small),
        Text("${AppLocale.grossTotal.getString(context)} \$${totalNeto.toStringAsFixed(2)}", style: Theme.of(context).textTheme.bodyMedium),
        ...taxSummary.entries.map((entry) => Text("${entry.key}: \$${entry.value['tax']!.toStringAsFixed(2)}", style: Theme.of(context).textTheme.bodyMedium)),
        Text("${AppLocale.taxTotal.getString(context)} \$${totalImpuesto.toStringAsFixed(2)}", style: Theme.of(context).textTheme.titleMedium),
        Text("${AppLocale.finalTotal.getString(context)} \$${grandTotal.toStringAsFixed(2)}", style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
