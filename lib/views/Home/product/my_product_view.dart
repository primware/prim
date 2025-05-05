import 'package:flutter/material.dart';
import 'package:primware/shared/custom_container.dart';
import 'package:shimmer/shimmer.dart';

import '../../../shared/custom_spacer.dart';
import '../../../shared/textfield.widget.dart';
import '../dashboard/dashboard_view.dart';
import 'product_funtions.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    final result = await fetchProducts(context: context);
    setState(() {
      _products = result;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _getFilteredOrders() {
    return _products
        .where((product) => product['Name']
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Widget _buildShimmerList() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: List.generate(4, (index) {
            return Container(
              height: 80,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders) {
    return Column(
      children: orders.map((order) {
        return GestureDetector(
          onTap: () async {
            // final refreshed = await Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (_) => OrderDetailPage(order: order),
            //   ),
            // );

            // if (refreshed == true) {
            //   _fetchOrders();
            // }
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
                  Icon(Icons.inventory_2_outlined,
                      color: Theme.of(context).colorScheme.onSecondary),
                  const SizedBox(width: CustomSpacer.small),
                  Text('${order['Name']} (${order['SKU']})',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSecondary)),
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
                      Text(order['Price'].toString(),
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.primary)),
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
          appBar: AppBar(title: Text('Mis productos')),
          body: SingleChildScrollView(
            child: CustomContainer(
                child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextfieldTheme(
                        texto: 'Buscar producto',
                        icono: Icons.search,
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                      ),
                    ),
                    const SizedBox(width: CustomSpacer.small),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _fetchProducts,
                    ),
                  ],
                ),
                const SizedBox(height: CustomSpacer.medium),
                _isLoading
                    ? _buildShimmerList()
                    : _buildOrderList(_getFilteredOrders()),
              ],
            )),
          ),
        ));
  }
}
