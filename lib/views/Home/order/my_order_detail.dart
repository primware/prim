import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/theme/colors.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:primware/views/Home/order/my_order_print_generator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:printing/printing.dart';
import '../../../API/pos.api.dart';
import '../../../localization/app_locale.dart';
import '../../../shared/footer.dart';
import 'package:primware/views/Home/order/my_order_new.dart';
import 'package:primware/views/Home/order/order_funtions.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../shared/toast_message.dart';
import '../../../shared/doc_type_chip.dart';

class OrderDetailPage extends StatelessWidget {
  final Map<String, dynamic> order;

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
        title: Column(
          children: [
            Icon(Icons.check, size: 45, color: Colors.green),
            SizedBox(height: 10),
            Text(
              AppLocale.completeOrderTitle.getString(context),
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(AppLocale.completeOrderBody.getString(context), textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(AppLocale.no.getString(context))),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(AppLocale.yes.getString(context))),
        ],
      ),
    );
  }

  // confirmación para sincronizar factura electrónica (FE)
  Future<bool?> _syncFEConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).cardColor,
        title: Column(
          children: [
            Icon(Icons.error_outline, size: 45, color: Colors.red),
            SizedBox(height: 10),
            Text(
              AppLocale.syncFETitle.getString(context),
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(AppLocale.syncFEBody.getString(context), textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
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
    final String? docName = order['doctypetarget']?['name'];

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: DocTypeChip(
        docTypeName: docName,
        isReturn: isReturn,
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

  Widget _buildDashedDivider({Color color = Colors.grey}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final boxWidth = constraints.constrainWidth();
          const dashWidth = 5.0;
          const dashHeight = 1.0;
          final dashCount = (boxWidth / (2 * dashWidth)).floor();
          return Flex(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            direction: Axis.horizontal,
            children: List.generate(dashCount, (_) {
              return SizedBox(
                width: dashWidth,
                height: dashHeight,
                child: DecoratedBox(decoration: BoxDecoration(color: color.withOpacity(0.5))),
              );
            }),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lines = (order['C_OrderLine'] as List?) ?? [];
    final taxSummary = _calculateTaxSummary([order]);
    final int? orderId = (order['id'] as int?);
    final Future<Map<String, dynamic>?> feFuture = orderId != null ? fetchElectronicInvoiceInfo(orderId: orderId) : Future.value(null);

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

    // Colores para el "Ticket"
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ticketBgColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;
    final Color textColor = isDark ? Colors.grey.shade300 : Colors.black87;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF0F2F5), // Fondo de la app (gris claro/oscuro)
      appBar: AppBar(
        backgroundColor: (isReturn) ? Colors.red : Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
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

              void actionConvert() {
                if (POS.docTypesComplete.isEmpty) {
                  ToastMessage.show(context: context, message: 'No hay tipos de documento disponibles para convertir.', type: ToastType.failure);
                  return;
                }

                showModalBottomSheet(
                  context: context,
                  backgroundColor: Theme.of(context).cardColor,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (BuildContext context) {
                    return SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Convertir documento a...', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const Divider(),
                            ...POS.docTypesComplete.map((doc) {
                              final dynamic rawId = doc['id'];
                              final int? docTypeId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
                              final String docName = (doc['name'] ?? doc['Name'] ?? 'Documento').toString();

                              // Excluir notas de crédito (RM) y el MISMO tipo de documento actual
                              if (doc['DocSubTypeSO'] == 'RM' || docTypeId == POS.docTypeRefundID || docTypeId == order['doctypetarget']?['id']) {
                                return const SizedBox.shrink();
                              }

                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                                  child: Icon(Icons.transform_outlined, color: Theme.of(context).primaryColor),
                                ),
                                title: Text(docName, style: Theme.of(context).textTheme.bodyLarge),
                                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OrderNewPage(isRefund: false, doctypeID: docTypeId, orderName: docName, sourceOrderId: order['id']),
                                    ),
                                  );
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
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
                      ToastMessage.show(context: context, message: completeResult['summary'] ?? 'Orden completada con éxito', type: ToastType.success);
                      Navigator.pop(context, true);
                    }
                  } else {
                    if (context.mounted) {
                      ToastMessage.show(context: context, message: completeResult['summary'] ?? 'Error al completar la orden', type: ToastType.failure);
                    }
                  }
                }
              }

              if (isMobileVertical) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      switch (value) {
                        case 'share':
                          actionShare();
                          break;
                        case 'duplicate':
                          actionDuplicate();
                          break;
                        case 'convert':
                          actionConvert();
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
                          break;
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
                        PopupMenuItem<String>(
                          value: 'convert',
                          child: Row(
                            children: [
                              Icon(Icons.transform_outlined, color: Colors.purple.shade400),
                              const SizedBox(width: 8),
                              const Text('Convertir'),
                            ],
                          ),
                        ),
                      ];

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
                      if (POS.isPOS == false && isComplete == true && !hasCreditNote && invoices.isNotEmpty) {
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
                  ),
                );
              } else {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.share), tooltip: AppLocale.exportPdf.getString(context), onPressed: actionShare),
                    IconButton(icon: const Icon(Icons.copy), tooltip: AppLocale.duplicate.getString(context), onPressed: actionDuplicate),
                    IconButton(icon: const Icon(Icons.transform_outlined), tooltip: 'Convertir Documento', onPressed: actionConvert),

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

                    if (POS.isPOS == false && isComplete == true && !hasCreditNote && invoices.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.receipt_long_outlined, color: Colors.redAccent),
                        tooltip: AppLocale.arc.getString(context),
                        onPressed: actionArc,
                      ),

                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: IconButton(icon: const Icon(Icons.print_rounded), tooltip: AppLocale.printTicket.getString(context), onPressed: actionPrint),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: CustomFooter(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600), // Ancho máximo para que parezca ticket en Desktop/Tablet
              decoration: BoxDecoration(
                color: ticketBgColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- CABECERA DEL TICKET ---
                    Center(
                      child: Column(
                        children: [
                          if (POSPrinter.logo != null) ...[Image.memory(POSPrinter.logo!, height: 60, fit: BoxFit.contain), const SizedBox(height: 12)],
                          Text(
                            POSPrinter.headerName ?? order['doctypetarget']['name'] ?? 'Documento',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: textColor),
                            textAlign: TextAlign.center,
                          ),
                          if (POSPrinter.headerTaxID != null) Text('RUC: ${POSPrinter.headerTaxID}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),

                    _buildHeader(order: order, context: context, feFuture: feFuture, hasCreditNote: hasCreditNote, textColor: textColor),

                    _buildDashedDivider(),

                    Text(
                      AppLocale.productSummary.getString(context).toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1.2, fontSize: 12),
                    ),
                    const SizedBox(height: 12),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: lines.length,
                      separatorBuilder: (_, __) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(color: Colors.grey.shade200, height: 1),
                      ),
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

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
                                  ),
                                  const SizedBox(height: 4),
                                  Text("${qty.toStringAsFixed(qty % 1 == 0 ? 0 : 2)} x \$${price.toStringAsFixed(2)}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                  if (discountPct > 0.0)
                                    Text(
                                      "Desc: ${discountPct.toStringAsFixed(0)}%",
                                      style: TextStyle(color: Colors.red.shade400, fontSize: 12, fontStyle: FontStyle.italic),
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "\$${total.toStringAsFixed(2)}",
                                    style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                                  ),
                                  const SizedBox(height: 4),
                                  Text("${line['C_Tax_ID']['Name']} (${rate.toStringAsFixed(0)}%)", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    _buildDashedDivider(),

                    Text(
                      AppLocale.paymentMethods.getString(context).toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1.2, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    if (payments.isEmpty)
                      Text(
                        AppLocale.noData.getString(context),
                        style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                      )
                    else
                      ...payments.map((p) {
                        final dynamic tenderField = p['C_POSTenderType_ID'];
                        final String tenderName = (tenderField is Map) ? (tenderField['identifier'] ?? tenderField['name'] ?? '---').toString() : tenderField?.toString() ?? '---';
                        final double payAmt = ((p['PayAmt'] ?? p['Amount'] ?? 0) as num).toDouble();
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(tenderName, style: TextStyle(color: textColor)),
                              Text(
                                "\$${payAmt.toStringAsFixed(2)}",
                                style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        );
                      }),

                    _buildDashedDivider(),

                    _buildFinalSummary(taxSummary: taxSummary, grandTotal: (order['GrandTotal'] as num).toDouble(), context: context, textColor: textColor),

                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        "",
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

  Widget _buildHeader({required Map<String, dynamic> order, required BuildContext context, required Future<Map<String, dynamic>?> feFuture, required bool hasCreditNote, required Color textColor}) {
    void syncFE({required int cInvoiceID}) async {
      final bool? confirmComplete = await _syncFEConfirmation(context);
      if (confirmComplete == true) {
        final Map<String, dynamic> syncResult = await syncFEProcess(cInvoiceID: cInvoiceID);
        if (syncResult['success'] == true && syncResult['isError'] != true) {
          if (context.mounted) {
            Fluttertoast.showToast(msg: syncResult['summary'] ?? AppLocale.invoiceSentSuccess.getString(context), backgroundColor: Colors.green, textColor: Colors.white, gravity: ToastGravity.BOTTOM, toastLength: Toast.LENGTH_LONG);
            Navigator.pop(context, true);
          }
        } else {
          if (context.mounted) {
            Fluttertoast.showToast(msg: syncResult['summary'] ?? AppLocale.invoiceSendError.getString(context), backgroundColor: Colors.red, textColor: Colors.white, gravity: ToastGravity.BOTTOM, toastLength: Toast.LENGTH_LONG);
          }
        }
      }
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: feFuture,
      builder: (context, snapshot) {
        final fe = snapshot.data;
        final bool isMobile = MediaQuery.of(context).size.width < 600;

        final left = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order['bpartner']['name'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 4),
            Text(order['DateOrdered'], style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),

            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 4, children: [_buildSubtypePill(context, order), _buildDocStatusPill(context, order), if (hasCreditNote) _buildCreditMemoPill()]),
          ],
        );

        Widget? right;
        if (fe != null && (fe['url']?.isNotEmpty ?? false)) {
          final qrUrlData = fe['url']!;
          right = Column(
            crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.end,
            children: [
              Text(AppLocale.electronicBill.getString(context), style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              const SizedBox(height: 6),
              if (fe['responseCode'] != null && fe['responseCode']!.isNotEmpty && fe['responseCode'] != '200') ...[
                Text(fe['responseMessage']!, style: const TextStyle(fontSize: 10, color: Colors.red)),
                const SizedBox(height: 6),
                ElevatedButton(
                  onPressed: () => syncFE(cInvoiceID: fe['cInvoiceID']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorTheme.info,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text(AppLocale.retryFE.getString(context), style: const TextStyle(fontSize: 10, color: Colors.white)),
                ),
              ],

              InkWell(
                onTap: () {
                  launchUrl(Uri.parse(qrUrlData));
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: QrImageView(data: qrUrlData, size: 80),
                ),
              ),
            ],
          );
        }

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              left,
              if (right != null) ...[const SizedBox(height: 16), Center(child: right)],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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

  Widget _buildFinalSummary({required Map<String, Map<String, double>> taxSummary, required double grandTotal, required BuildContext context, required Color textColor}) {
    final double totalNeto = taxSummary.values.map((e) => e['net'] ?? 0.0).fold(0.0, (a, b) => a + b);
    final double totalImpuesto = taxSummary.values.map((e) => e['tax'] ?? 0.0).fold(0.0, (a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppLocale.grossTotal.getString(context), style: TextStyle(color: Colors.grey.shade600)),
            Text(
              "\$${totalNeto.toStringAsFixed(2)}",
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...taxSummary.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(entry.key, style: TextStyle(color: Colors.grey.shade600)),
                Text(
                  "\$${entry.value['tax']!.toStringAsFixed(2)}",
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        if (taxSummary.isEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocale.taxTotal.getString(context), style: TextStyle(color: Colors.grey.shade600)),
              Text(
                "\$${totalImpuesto.toStringAsFixed(2)}",
                style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocale.finalTotal.getString(context).toUpperCase(),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).primaryColor),
              ),
              Text(
                "\$${grandTotal.toStringAsFixed(2)}",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Theme.of(context).primaryColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
