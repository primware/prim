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
import '../../../shared/footer.dart';
import 'my_order_print_generator.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true, isSearchLoading = false;
  String _searchQuery = '';
  Timer? _debounce;
  TextEditingController searchController = TextEditingController();

  // Confirmación para imprimir ticket
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

  // Imprimir ticket directamente desde la lista
  Future<void> _printTicket(Map<String, dynamic> order) async {
    final bool? confirm = await _printTicketConfirmation(context);
    if (confirm == true) {
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
          onLayout: (_) => pdfBytes,
        );
      } catch (e) {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'Order_${order['DocumentNo']}.pdf',
        );
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

    final result =
        await fetchOrders(context: context, filter: searchController.text);
    setState(() {
      _orders = result;
      _isLoading = false;
      isSearchLoading = false;
    });
  }

  void debouncedOrders() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    final searchText = searchController.text.trim();
    if (searchText.length < 3 && searchText.isNotEmpty) {
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 3000), () {
      _fetchOrders(showLoadingIndicator: true);
    });
  }

  List<Map<String, dynamic>> _getFilteredOrders() {
    return _orders
        .where((order) => order['DocumentNo']
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _onOrderAction(String action, Map<String, dynamic> order) {
    switch (action) {
      case 'refund':
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
        break;
      case 'printTicket':
        _printTicket(order);
        break;
      default:
        break;
    }
  }

  Widget _buildSubtypePill(Map<String, dynamic> order) {
    final sub = order['doctypetarget']?['subtype']?['id'];
    final bool isReturn = sub == 'RM' && POS.docTypeRefundID != null;

    final Color baseColor = isReturn ? Colors.red : Colors.green;
    final Color bgColor = baseColor.withOpacity(0.12);
    final String label = isReturn
        ? AppLocale.refund.getString(context)
        : AppLocale.order.getString(context);
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
            style: TextStyle(
                fontSize: 12, color: baseColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

//TODO quitar el boton de devolucion si no vienen por el CPOSID
  Widget _buildOrderList(List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Text(AppLocale.errorNoOrders.getString(context)),
      );
    }
    return Column(
      children: orders.map((order) {
        final bool isReturn = order['doctypetarget']?['subtype']?['id'] == 'RM';
        return GestureDetector(
          onTap: () async {
            final refreshed = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailPage(order: order),
              ),
            );

            if (refreshed == true) {
              _fetchOrders();
            }
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              title: Row(
                children: [
                  Icon(Icons.person_outline,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: CustomSpacer.small),
                  Expanded(
                    child: Text(
                        '${order['bpartner']['name']} - ${order['doctypetarget']['name']} #${order['DocumentNo']}',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.attach_money_rounded,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: CustomSpacer.small),
                      Expanded(
                        child: Text(order['GrandTotal'].toString(),
                            style: Theme.of(context).textTheme.bodyLarge),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.calendar_month_outlined,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: CustomSpacer.small),
                      Expanded(
                        child: Text(order['DateOrdered'],
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildSubtypePill(order),
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
                          const Icon(Icons.receipt_long_rounded,
                              color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(AppLocale.printTicket.getString(context)),
                        ],
                      ),
                    ),
                  ];
                  if (!isReturn) {
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DashboardPage(),
          ),
        );
        return Future.value(false);
      },
      child: Scaffold(
        appBar: AppBar(
            title: Text(
          AppLocale.myOrders.getString(context),
        )),
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
        body: SingleChildScrollView(
          child: Center(
            child: CustomContainer(
              child: Column(
                children: [
                  if (isSearchLoading) ...[
                    const SizedBox(height: 4),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextfieldTheme(
                          controlador: searchController,
                          texto: AppLocale.searchOrder.getString(context),
                          icono: Icons.search,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                              debouncedOrders();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: CustomSpacer.small),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _fetchOrders,
                      ),
                    ],
                  ),
                  const SizedBox(height: CustomSpacer.medium),
                  _isLoading
                      ? ShimmerList(
                          separation: CustomSpacer.medium,
                        )
                      : _buildOrderList(_getFilteredOrders()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
