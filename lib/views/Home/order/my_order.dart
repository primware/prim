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

  Widget _buildOrderList(List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Text(AppLocale.errorNoOrders.getString(context)),
      );
    }
    return Column(
      children: orders.map((order) {
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OrderNewPage(),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
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
