import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/shared/custom_container.dart';
import 'package:primware/shared/custom_spacer.dart';
import 'package:primware/shared/custom_textfield.dart';
import 'package:primware/shared/shimmer_list.dart';
import 'package:primware/views/Home/dashboard/dashboard_view.dart';
import 'package:primware/views/Home/order/order_funtions.dart';
import 'package:primware/views/Home/order/my_order_detail.dart';
import 'package:primware/views/Home/order/my_order_new.dart';
import 'package:printing/printing.dart';
import '../../../API/pos.api.dart';
import '../../../shared/custom_app_menu.dart';
import '../../../localization/app_locale.dart';
import '../../../shared/custom_checkbox.dart';
import '../../../shared/footer.dart';
import 'my_order_print_generator.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true, isSearchLoading = false, onlyMyOrders = false;
  String _searchQuery = '';
  TextEditingController searchController = TextEditingController();

  // Mapa de estados de documento (DocStatus) a nombre en español y color
  final Map<String, Map<String, dynamic>> _docStatusMap = {
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

  // Confirmación para imprimir ticket
  Future<bool?> _printTicketConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).cardColor,
        title: Column(
          children: [
            Icon(Icons.print_rounded, size: 45, color: Theme.of(context).colorScheme.primary),
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

  // Confirmación para convertir a Nota de Crédito
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
              style: TextStyle(
                color: Colors.red, // Texto en rojo
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly, // Centra y separa los botones
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(AppLocale.no.getString(context))),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(AppLocale.yes.getString(context))),
        ],
      ),
    );
  }

  // Imprimir ticket directamente desde la lista
  Future<void> _printTicket(Map<String, dynamic> order) async {
    final bool? confirm = await _printTicketConfirmation(context);
    if (confirm == true) {
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
        // Último fallback silencioso: intentar compartir PDF genérico
        try {
          final pdfBytes = await generateOrderTicket(order);
          await Printing.sharePdf(bytes: pdfBytes, filename: 'Order_${order['DocumentNo']}.pdf');
        } catch (_) {}
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders({bool showLoadingIndicator = false}) async {
    setState(() {
      if (showLoadingIndicator) {
        isSearchLoading = true;
      }

      _isLoading = true;
    });

    final result = await fetchOrders(context: context, filter: searchController.text, onlyMyOrders: onlyMyOrders);
    setState(() {
      _orders = result;
      _isLoading = false;
      isSearchLoading = false;
    });
  }

  List<Map<String, dynamic>> _getFilteredOrders() {
    return _orders.where((order) => order['DocumentNo'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  void _onOrderAction(String action, Map<String, dynamic> order) async {
    switch (action) {
      case 'refund':
        // LLamamos al nuevo cuadro de confirmación
        final bool? confirm = await _refundConfirmation(context);

        // Si el usuario dijo que "Sí"
        if (confirm == true) {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderNewPage(isRefund: true, doctypeID: POS.docTypeRefundID, orderName: POS.docTypeRefundName, sourceOrderId: order['id'] ?? order['C_Order_ID'] ?? order['record_id']),
            ),
          );
        }
        break;
      case 'convertQuote':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderNewPage(isRefund: false, doctypeID: POS.docTypeID, orderName: POS.docTypeName, sourceOrderId: order['id'] ?? order['C_Order_ID'] ?? order['record_id']),
          ),
        );
        break;
      case 'printTicket':
        _printTicket(order);
        break;
      case 'arc':
        final bool? confirmArc = await _refundConfirmation(context);
        if (confirmArc == true) {
          final bool creditMemoSucces = await createCreditMemo(cInvoiceID: order['C_Invoice']?[0]?['id']);
          if (creditMemoSucces) {
            _fetchOrders(showLoadingIndicator: true);
          }
        }
        break;
      case 'docComplete':
        final bool? confirmDocComplete = await _refundConfirmation(context);
        if (confirmDocComplete == true) {
          final bool docCompleteSucces = await docComplete(cOrderID: order['id']);
          if (docCompleteSucces) {
            _fetchOrders(showLoadingIndicator: true);
          }
        }
        break;
      default:
        break;
    }
  }

  Widget _buildSubtypePill(Map<String, dynamic> order) {
    final sub = order['doctypetarget']?['subtype']?['id'];
    final bool isReturn = (sub == 'RM') || (order['doctypetarget']?['id'] == POS.docTypeRefundID);

    final Color baseColor = isReturn ? Colors.red : Colors.green;
    final Color bgColor = baseColor.withOpacity(0.12);
    final String label = isReturn ? AppLocale.refund.getString(context) : AppLocale.order.getString(context);
    final IconData icon = isReturn ? Icons.undo : Icons.shopping_cart;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    final Color baseColor = Colors.red;
    final Color bgColor = baseColor.withOpacity(0.12);
    final String label = AppLocale.creditNote.getString(context);
    final IconData icon = Icons.receipt_long_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  // Pill que muestra el estado del documento (DocStatus) en español
  Widget _buildDocStatusPill(Map<String, dynamic> order) {
    final String? statusCode = order['DocStatus'] as String?;
    if (statusCode == null) {
      return const SizedBox.shrink();
    }

    final meta = _docStatusMap[statusCode] ?? {'label': statusCode, 'color': Theme.of(context).colorScheme.primary, 'icon': Icons.flag_outlined};

    final Color baseColor = meta['color'] as Color;
    final Color bgColor = baseColor.withOpacity(0.12);
    final String label = meta['label'] as String;
    final IconData icon = meta['icon'] as IconData;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  Widget _buildEditPill(BuildContext context, Map<String, dynamic> order) {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderNewPage(isRefund: false, doctypeID: order['doctypetarget']?['id'] ?? POS.docTypeID, orderName: order['doctypetarget']?['name'] ?? POS.docTypeName, sourceOrderId: order['id']),
          ),
        );
        // Si se guardó con éxito, recargamos la lista de órdenes en automático
        if (result == true) {
          _fetchOrders(showLoadingIndicator: true);
        }
      },
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  Widget _buildOrderList(List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) {
      return Center(child: Text(AppLocale.errorNoOrders.getString(context)));
    }
    return Column(
      children: orders.map((order) {
        final bool isComplete = (order['DocStatus'] == 'CO');
        final bool isReturn = (order['doctypetarget']?['id'] == POS.docTypeRefundID);

        // --- REVISAR SI YA EXISTE NOTA DE CRÉDITO ---
        final List invoices = order['C_Invoice'] ?? [];
        final bool hasCreditNote = invoices.any((inv) {
          return inv['RelatedInvoice_ID'] != null;
        });

        return GestureDetector(
          onTap: () async {
            final refreshed = await Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailPage(order: order)));

            if (refreshed == true) {
              _fetchOrders();
            }
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
            child: ListTile(
              title: Row(
                children: [
                  Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: CustomSpacer.small),
                  Expanded(child: Text('${order['bpartner']['name']} - ${order['doctypetarget']['name']} #${order['DocumentNo']}', style: Theme.of(context).textTheme.bodyMedium)),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.attach_money_rounded, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: CustomSpacer.small),
                      Expanded(child: Text(order['GrandTotal'].toString(), style: Theme.of(context).textTheme.bodyLarge)),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.calendar_month_outlined, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: CustomSpacer.small),
                      Expanded(
                        child: Text(order['DateOrdered'], style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8, // Espacio horizontal entre los chips
                    runSpacing: 8, // Espacio vertical si saltan a otra línea
                    children: [
                      _buildSubtypePill(order),
                      _buildDocStatusPill(order),

                      // Píldora de Editar (Solo si es Borrador)
                      //if (order['DocStatus'] == 'DR')
                      //_buildEditPill(context, order),

                      // Píldora de Nota de Crédito
                      if (hasCreditNote) _buildCreditMemoPill(),
                    ],
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) => _onOrderAction(value, order),
                itemBuilder: (context) {
                  final items = <PopupMenuEntry<String>>[
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
                    if (order['DocStatus'] == 'DR')
                      PopupMenuItem<String>(
                        value: 'docComplete',
                        child: Row(
                          children: [
                            const Icon(Icons.check, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(AppLocale.complete.getString(context)),
                          ],
                        ),
                      ),
                  ];
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
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardPage()));
        return Future.value(false);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(AppLocale.myOrders.getString(context))),
        drawer: MenuDrawer(),
        floatingActionButton: POS.docTypeID != null
            ? FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderNewPage(doctypeID: POS.docTypeID, orderName: POS.docTypeName, isRefund: POS.docSubType == 'RM'),
                    ),
                  );
                },
                child: const Icon(Icons.add),
              )
            : null,
        bottomNavigationBar: CustomFooter(),
        body: SingleChildScrollView(
          child: Center(
            child: CustomContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomCheckbox(
                    value: onlyMyOrders,
                    text: AppLocale.onlyMyOrders.getString(context),
                    onChanged: (newValue) {
                      setState(() {
                        onlyMyOrders = newValue;
                        _fetchOrders(showLoadingIndicator: true);
                      });
                    },
                  ),
                  if (isSearchLoading) ...[const SizedBox(height: 4), const LinearProgressIndicator(), const SizedBox(height: 8)],
                  Row(
                    children: [
                      Expanded(
                        child: TextfieldTheme(
                          controlador: searchController,
                          texto: AppLocale.searchOrder.getString(context),
                          icono: Icons.receipt_long_rounded,
                          onSubmitted: (p0) => _fetchOrders(showLoadingIndicator: true),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: CustomSpacer.small),
                      IconButton(icon: const Icon(Icons.search), onPressed: () => _fetchOrders(showLoadingIndicator: true)),
                    ],
                  ),
                  const SizedBox(height: CustomSpacer.medium),
                  _isLoading ? ShimmerList(separation: CustomSpacer.medium) : _buildOrderList(_getFilteredOrders()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
