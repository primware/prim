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
import '../../../API/pos.api.dart';
import '../../../shared/custom_app_menu.dart';
import '../../../localization/app_locale.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    final result = await fetchOrders(context: context);
    setState(() {
      _orders = result;
      _isLoading = false;
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
      default:
        break;
    }
  }

  Widget _buildSubtypePill(Map<String, dynamic> order) {
    final sub = order['doctypetarget']?['subtype']?['id'];
    final bool isReturn = sub == 'RM';

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

  Widget _buildOrderList(List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Text(AppLocale.errorNoOrders.getString(context)),
      );
    }
    return Column(
      children: orders.map((order) {
        final bool _isReturn =
            order['doctypetarget']?['subtype']?['id'] == 'RM';
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
              trailing: _isReturn
                  ? null
                  : PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) => _onOrderAction(value, order),
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: 'refund',
                          child: Row(
                            children: [
                              Icon(Icons.undo, color: Colors.red),
                              SizedBox(width: 8),
                              Text(AppLocale.refund.getString(context)),
                            ],
                          ),
                        ),
                      ],
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
        body: SingleChildScrollView(
          child: Center(
            child: CustomContainer(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextfieldTheme(
                          texto: AppLocale.searchOrder.getString(context),
                          icono: Icons.search,
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
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
