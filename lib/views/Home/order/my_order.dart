import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/shared/custom_container.dart';
import 'package:primware/shared/custom_spacer.dart';
import 'package:primware/shared/custom_textfield.dart';
import 'package:primware/shared/shimmer_list.dart';
import 'package:primware/shared/toast_message.dart';
import 'package:primware/views/Home/dashboard/dashboard_view.dart';
import 'package:primware/views/Home/order/order_funtions.dart';
import 'package:primware/views/Home/order/my_order_detail.dart';
import 'package:primware/views/Home/order/my_order_new.dart';
import 'package:printing/printing.dart';
import '../../../API/pos.api.dart';
import '../../../shared/custom_app_menu.dart';
import '../../../localization/app_locale.dart';
import '../../../shared/footer.dart';
import 'my_order_print_generator.dart';
import 'dart:ui';
import '../../../shared/doc_type_chip.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true, isSearchLoading = false, onlyMyOrders = false;
  String? selectedDocTypeFilter;
  String _searchQuery = '';
  TextEditingController searchController = TextEditingController();

  // Mapa de estados de documento (DocStatus) a nombre en español y color
  final Map<String, Map<String, dynamic>> _docStatusMap = {
    'DR': {'label': 'Borrador', 'color': Colors.grey, 'icon': Icons.edit_note},
    'CO': {
      'label': 'Completado',
      'color': Colors.green,
      'icon': Icons.check_circle_outline,
    },
    'CL': {
      'label': 'Cerrado',
      'color': Colors.blueGrey,
      'icon': Icons.lock_outline,
    },
    'VO': {
      'label': 'Anulado',
      'color': Colors.red,
      'icon': Icons.cancel_outlined,
    },
    'IP': {
      'label': 'En proceso',
      'color': Colors.orange,
      'icon': Icons.hourglass_bottom,
    },
    'PR': {
      'label': 'Preparado',
      'color': Colors.orange,
      'icon': Icons.hourglass_bottom,
    },
    'WC': {
      'label': 'Esperando completar',
      'color': Colors.orangeAccent,
      'icon': Icons.hourglass_top,
    },
    'AP': {
      'label': 'Aprobado',
      'color': Colors.blue,
      'icon': Icons.thumb_up_outlined,
    },
    'RJ': {
      'label': 'Rechazado',
      'color': Colors.redAccent,
      'icon': Icons.thumb_down_outlined,
    },
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
            Icon(
              Icons.print_rounded,
              size: 45,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 10),
            Text(
              AppLocale.confirmPrintTicket.getString(context),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          AppLocale.printTicketMessage.getString(context),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
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

  // Confirmación para convertir a Nota de Crédito
  Future<bool?> _refundConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).cardColor,
        title: Column(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 45,
              color: Colors.redAccent,
            ),
            SizedBox(height: 10),
            Text(
              AppLocale.confirmCreditNoteTitle.getString(context),
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocale.confirmCreditNoteBody.getString(context),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              AppLocale.cannotUndoWarning.getString(context),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red, // Texto en rojo
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actionsAlignment:
            MainAxisAlignment.spaceEvenly, // Centra y separa los botones
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
        content: Text(
          AppLocale.completeOrderBody.getString(context),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
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

  // Imprimir ticket directamente desde la lista
  Future<void> _printTicket(Map<String, dynamic> order) async {
    final bool? confirm = await _printTicketConfirmation(context);
    if (confirm == true) {
      try {
        final pdfBytes = POS.isPOS == true
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

    final result = await fetchOrders(
      context: context,
      filter: searchController.text,
      onlyMyOrders: onlyMyOrders,
    );
    setState(() {
      _orders = result;
      _isLoading = false;
      isSearchLoading = false;
    });
  }

  List<Map<String, dynamic>> _getFilteredOrders() {
    return _orders.where((order) {
      final matchesSearch = order['DocumentNo']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
      final matchesDocType =
          selectedDocTypeFilter == null ||
          order['doctypetarget']?['name'] == selectedDocTypeFilter;
      return matchesSearch && matchesDocType;
    }).toList();
  }

  void _onOrderAction(String action, Map<String, dynamic> order) async {
    switch (action) {
      case 'duplicate':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderNewPage(
              isRefund: false,
              doctypeID: order['doctypetarget']?['id'] ?? POS.docTypeID,
              orderName: order['doctypetarget']?['name'] ?? POS.docTypeName,
              sourceOrderId: order['id'],
            ),
          ),
        );
        break;
      case 'convert':
        if (POS.docTypesComplete.isEmpty) {
          ToastMessage.show(
            context: context,
            message: AppLocale.noDocTypesAvailable.getString(context),
            type: ToastType.help,
          );
          return;
        }

        showModalBottomSheet(
          context: context,
          backgroundColor: Theme.of(context).cardColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (BuildContext context) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocale.documentType.getString(context),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    ...POS.docTypesComplete.map((doc) {
                      final dynamic rawId = doc['id'];
                      final int? docTypeId = rawId is int
                          ? rawId
                          : int.tryParse(rawId?.toString() ?? '');
                      final String docName =
                          (doc['name'] ?? doc['Name'] ?? 'Documento')
                              .toString();

                      if (doc['DocSubTypeSO'] == 'RM' ||
                          docTypeId == POS.docTypeRefundID ||
                          docTypeId == order['doctypetarget']?['id']) {
                        return const SizedBox.shrink();
                      }

                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.transform_outlined,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        title: Text(
                          docName,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderNewPage(
                                isRefund: false,
                                doctypeID: docTypeId,
                                orderName: docName,
                                sourceOrderId: order['id'],
                              ),
                            ),
                          ).then((value) {
                            if (value == true)
                              _fetchOrders(showLoadingIndicator: true);
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
        break;
      case 'refund':
        final bool? confirm = await _refundConfirmation(context);

        if (confirm == true) {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderNewPage(
                isRefund: true,
                doctypeID: POS.docTypeRefundID,
                orderName: POS.docTypeRefundName,
                sourceOrderId:
                    order['id'] ?? order['C_Order_ID'] ?? order['record_id'],
              ),
            ),
          );
        }
        break;
      case 'convertQuote':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderNewPage(
              isRefund: false,
              doctypeID: POS.docTypeID,
              orderName: POS.docTypeName,
              sourceOrderId:
                  order['id'] ?? order['C_Order_ID'] ?? order['record_id'],
            ),
          ),
        );
        break;
      case 'printTicket':
        _printTicket(order);
        break;
      case 'arc':
        final bool? confirmArc = await _refundConfirmation(context);
        if (confirmArc == true) {
          final bool creditMemoSucces = await createCreditMemo(
            cInvoiceID: order['C_Invoice']?[0]?['id'],
          );
          if (creditMemoSucces) {
            _fetchOrders(showLoadingIndicator: true);
          }
        }
        break;
      case 'docComplete':
        final bool? confirmDocComplete = await _completeConfirmation(context);
        if (confirmDocComplete == true) {
          final docCompleteSucces = await docComplete(cOrderID: order['id']);
          if (docCompleteSucces["success"] == true &&
              docCompleteSucces["isError"] == false) {
            _fetchOrders(showLoadingIndicator: true);
          } else if (docCompleteSucces["success"] == true &&
              docCompleteSucces["isError"] == true) {
            if (mounted)
              ToastMessage.show(
                context: context,
                message: docCompleteSucces["summary"],
                type: ToastType.failure,
              );
          } else {
            if (mounted)
              ToastMessage.show(
                context: context,
                message: AppLocale.noDocComplete.getString(context),
                type: ToastType.failure,
              );
          }
        }
        break;
      default:
        break;
    }
  }

  Widget _buildSubtypePill(Map<String, dynamic> order) {
    final sub = order['doctypetarget']?['subtype']?['id'];
    final bool isReturn =
        (sub == 'RM') || (order['doctypetarget']?['id'] == POS.docTypeRefundID);
    final String? docName = order['doctypetarget']?['name'];

    return DocTypeChip(docTypeName: docName, isReturn: isReturn);
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
            style: TextStyle(
              fontSize: 12,
              color: baseColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocStatusPill(Map<String, dynamic> order) {
    final String? statusCode = order['DocStatus'] as String?;
    if (statusCode == null) {
      return const SizedBox.shrink();
    }

    final meta =
        _docStatusMap[statusCode] ??
        {
          'label': statusCode,
          'color': Theme.of(context).colorScheme.primary,
          'icon': Icons.flag_outlined,
        };

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
            style: TextStyle(
              fontSize: 12,
              color: baseColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountItem({
    required String label,
    required String value,
    required IconData icon,
    bool highlight = false,
  }) {
    final Color accentColor = highlight
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).primaryColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: accentColor),
        const SizedBox(width: 6),
        Flexible(
          child: RichText(
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: highlight
                        ? accentColor
                        : Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final bool isComplete = (order['DocStatus'] == 'CO');
    final bool isReturn =
        (order['doctypetarget']?['id'] == POS.docTypeRefundID);
    final double totalLines =
        double.tryParse(order['TotalLines']?.toString() ?? '0') ?? 0;
    final double grandTotal =
        double.tryParse(order['GrandTotal']?.toString() ?? '0') ?? 0;
    final double taxAmount = grandTotal - totalLines;

    final List invoices = order['C_Invoice'] ?? [];
    final bool hasCreditNote = invoices.any((inv) {
      return inv['RelatedInvoice_ID'] != null;
    });

    return GestureDetector(
      onTap: () async {
        final refreshed = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailPage(order: order)),
        );
        if (refreshed == true) {
          _fetchOrders();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['bpartner']['name'],
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${order['doctypetarget']['name']} #${order['DocumentNo']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Menú de opciones de la orden
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (value) => _onOrderAction(value, order),
                  itemBuilder: (context) {
                    final items = <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'printTicket',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.print_outlined,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(AppLocale.printTicket.getString(context)),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(
                              Icons.copy,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(AppLocale.duplicate.getString(context)),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'convert',
                        child: Row(
                          children: [
                            Icon(
                              Icons.transform_outlined,
                              color: Colors.purple.shade400,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppLocale.copyToNewDocument.getString(context),
                            ),
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
                    if (isReturn == false &&
                        POS.isPOS == true &&
                        !hasCreditNote) {
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
                    if (POS.isPOS == false &&
                        isComplete == true &&
                        !hasCreditNote &&
                        invoices.isNotEmpty) {
                      items.add(
                        PopupMenuItem<String>(
                          value: 'arc',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.receipt_long_rounded,
                                color: Colors.red,
                              ),
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
              ],
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.secondary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondary.withOpacity(0.12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocale.summary.getString(context),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.calendar_today_outlined,
                        color: Colors.grey.shade500,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        order['DateOrdered'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    runSpacing: 8,
                    children: [
                      _buildAmountItem(
                        label: AppLocale.subtotal.getString(context),
                        value: totalLines.toStringAsFixed(2),
                        icon: Icons.receipt_long_outlined,
                      ),
                      _buildAmountItem(
                        label: AppLocale.taxes.getString(context),
                        value: taxAmount.toStringAsFixed(2),
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                      _buildAmountItem(
                        label: AppLocale.total.getString(context),
                        value: grandTotal.toStringAsFixed(2),
                        icon: Icons.payments_rounded,
                        highlight: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, thickness: 0.5),
            ),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSubtypePill(order),
                _buildDocStatusPill(order),
                if (hasCreditNote) _buildCreditMemoPill(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardPage()),
        );
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
                      builder: (context) => OrderNewPage(
                        doctypeID: POS.docTypeID,
                        orderName: POS.docTypeName,
                        isRefund: POS.docSubType == 'RM',
                      ),
                    ),
                  );
                },
                child: const Icon(Icons.add),
              )
            : null,
        bottomNavigationBar: CustomFooter(),
        body: SafeArea(
          child: Center(
            child: CustomContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextfieldTheme(
                          controlador: searchController,
                          texto: AppLocale.searchOrder.getString(context),
                          icono: Icons.receipt_long_rounded,
                          onSubmitted: (p0) =>
                              _fetchOrders(showLoadingIndicator: true),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: CustomSpacer.small),
                      Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.search, color: Colors.white),
                          onPressed: () =>
                              _fetchOrders(showLoadingIndicator: true),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black.withOpacity(0.2)
                          : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.receipt,
                              size: 22,
                              color: onlyMyOrders
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade600,
                            ), // Icono más grande
                            const SizedBox(width: 12),
                            Text(
                              AppLocale.onlyMyOrders.getString(context),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: onlyMyOrders
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: onlyMyOrders
                                    ? (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black87)
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        GlassSwitch(
                          value: onlyMyOrders,
                          onChanged: (newValue) {
                            setState(() {
                              onlyMyOrders = newValue;
                              _fetchOrders(showLoadingIndicator: true);
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  if (_orders.isNotEmpty)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                right: 8.0,
                                left: 16.0,
                              ),
                              child: FilterChip(
                                label: const Text('Todos'),
                                selected: selectedDocTypeFilter == null,
                                selectedColor: Theme.of(context).primaryColor,
                                checkmarkColor: Theme.of(
                                  context,
                                ).colorScheme.onPrimary,
                                onSelected: (bool selected) {
                                  setState(() {
                                    selectedDocTypeFilter = null;
                                  });
                                },
                              ),
                            ),
                            ..._orders
                                .map(
                                  (e) =>
                                      e['doctypetarget']?['name']?.toString() ??
                                      '',
                                )
                                .where((name) => name.isNotEmpty)
                                .toSet()
                                .map((docName) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: FilterChip(
                                      label: Text(docName),
                                      selected:
                                          selectedDocTypeFilter == docName,
                                      selectedColor: Theme.of(
                                        context,
                                      ).primaryColor,
                                      checkmarkColor: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                      onSelected: (bool selected) {
                                        setState(() {
                                          selectedDocTypeFilter = selected
                                              ? docName
                                              : null;
                                        });
                                      },
                                    ),
                                  );
                                }),
                          ],
                        ),
                      ),
                    ),

                  if (isSearchLoading) ...[
                    const SizedBox(height: 4),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                  ],

                  const SizedBox(height: CustomSpacer.medium),

                  Expanded(
                    child: _isLoading
                        ? ShimmerList(separation: CustomSpacer.medium)
                        : _getFilteredOrders().isEmpty
                        ? Center(
                            child: Text(
                              AppLocale.errorNoOrders.getString(context),
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: _getFilteredOrders().length,
                            itemBuilder: (context, index) {
                              final order = _getFilteredOrders()[index];
                              return _buildOrderCard(order);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const GlassSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 56,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: value
              ? primary.withOpacity(0.3)
              : (isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05)),
          border: Border.all(
            color: value
                ? primary.withOpacity(0.6)
                : (isDark ? Colors.white30 : Colors.black12),
            width: 1.5,
          ),
          boxShadow: [
            if (value)
              BoxShadow(
                color: primary.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              top: 2,
              bottom: 2,
              left: value ? 26 : 2,
              right: value ? 2 : 26,
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: value
                          ? primary.withOpacity(0.8)
                          : (isDark ? Colors.white70 : Colors.white),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
