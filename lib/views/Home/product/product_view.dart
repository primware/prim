import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/shared/custom_container.dart';
import 'package:primware/localization/app_locale.dart';
import '../../../shared/custom_app_menu.dart';
import '../../../shared/custom_spacer.dart';
import '../../../shared/shimmer_list.dart';
import '../../../shared/custom_textfield.dart';
import '../dashboard/dashboard_view.dart';
import '../invoice/invoice_funtions.dart';
import 'product_new.dart';
import 'product_details.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true,
      isProductSearchLoading = false,
      isProductCategoryLoading = true;
  // ignore: prefer_final_fields
  String _searchQuery = '';
  Set<int> selectedCategories = {};
  List<Map<String, dynamic>> categpryOptions = [];
  TextEditingController productController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadProductCategory();
    _fetchProducts();
  }

  Future<void> _loadProductCategory() async {
    final category = await fetchProductCategory();
    setState(() {
      categpryOptions = category;
      isProductCategoryLoading = false;
    });
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    final result = await fetchProductInPriceList(context: context);
    setState(() {
      _products = result;
      _isLoading = false;
    });
  }

  void debouncedLoadProduct() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    final searchText = productController.text.trim();
    if (searchText.length < 4 && searchText.isNotEmpty) {
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      _loadProduct(showLoadingIndicator: true);
    });
  }

  Future<void> _loadProduct({bool showLoadingIndicator = false}) async {
    if (showLoadingIndicator) {
      setState(() {
        isProductSearchLoading = true;
      });
    }
    final product = await fetchProductInPriceList(
      context: context,
      categoryID:
          selectedCategories.isNotEmpty ? selectedCategories.toList() : null,
      searchTerm: productController.text.trim(),
    );
    setState(() {
      _products = product;
      isProductSearchLoading = false;
    });
  }

  List<Map<String, dynamic>> _getFilteredOrders() {
    return _products
        .where((product) => product['name']
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Widget _buildOrderList(List<Map<String, dynamic>> records) {
    return Column(
      children: records.map((record) {
        return GestureDetector(
          onTap: () async {
            final refreshed = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailPage(product: record),
              ),
            );

            if (refreshed == true) {
              debouncedLoadProduct();
            }
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              title: Text('${record['name']} (${record['sku']})',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.secondary)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.attach_money_rounded,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: CustomSpacer.small),
                      Text(record['price'].toString(),
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
          appBar: AppBar(
            title: Text(AppLocale.products.getString(context)),
          ),
          drawer: MenuDrawer(),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductNewPage(),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
          body: SingleChildScrollView(
            child: Center(
              child: CustomContainer(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    style: ButtonStyle(
                      textStyle: MaterialStateProperty.all(
                          Theme.of(context).textTheme.bodyMedium),
                      backgroundColor: MaterialStateProperty.all(
                          Theme.of(context).colorScheme.secondary),
                      foregroundColor: MaterialStateProperty.all(
                          Theme.of(context).colorScheme.onSecondary),
                    ),
                    icon: const Icon(Icons.category),
                    label: Text(AppLocale.categories.getString(context)),
                    onPressed: () async {
                      Set<int> tempSelected = Set<int>.from(selectedCategories);
                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) {
                          return StatefulBuilder(
                            builder: (context, setModalState) {
                              return SafeArea(
                                child: Padding(
                                  padding: MediaQuery.of(context).viewInsets,
                                  child: Container(
                                    constraints:
                                        const BoxConstraints(maxHeight: 400),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Text(
                                            AppLocale.selectCategories
                                                .getString(context),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge,
                                          ),
                                        ),
                                        Expanded(
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: categpryOptions.length,
                                            itemBuilder: (context, idx) {
                                              final cat = categpryOptions[idx];
                                              final isSelected = tempSelected
                                                  .contains(cat['id']);
                                              return ListTile(
                                                title: Text(cat['name']),
                                                selected: isSelected,
                                                onTap: () {
                                                  setModalState(() {
                                                    if (isSelected) {
                                                      tempSelected
                                                          .remove(cat['id']);
                                                    } else {
                                                      tempSelected
                                                          .add(cat['id']);
                                                    }
                                                  });
                                                },
                                                trailing: isSelected
                                                    ? const Icon(Icons.check,
                                                        color: Colors.blue)
                                                    : null,
                                              );
                                            },
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: Text(AppLocale.cancel
                                                    .getString(context)),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(
                                                      context, tempSelected);
                                                },
                                                child: Text(AppLocale.apply
                                                    .getString(context)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ).then((result) {
                        if (result != null && result is Set<int>) {
                          setState(() {
                            selectedCategories = Set<int>.from(result);
                          });
                          debouncedLoadProduct();
                        }
                      });
                    },
                  ),
                  // Chips de categorías seleccionadas
                  if (selectedCategories.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: selectedCategories.map((catId) {
                          final cat = categpryOptions.firstWhere(
                            (c) => c['id'] == catId,
                            orElse: () => <String, dynamic>{},
                          );
                          final catName =
                              cat.isNotEmpty ? cat['name'] : 'Categoría';
                          return Chip(
                            label: Text(catName),
                            onDeleted: () {
                              setState(() {
                                selectedCategories.remove(catId);
                              });
                              debouncedLoadProduct();
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: CustomSpacer.medium),

                  // Campo de producto
                  if (isProductSearchLoading) ...[
                    const SizedBox(height: 4),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextfieldTheme(
                          texto: AppLocale.searchProducts.getString(context),
                          controlador: productController,
                          icono: Icons.search,
                          onChanged: (_) => debouncedLoadProduct(),
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
                      ? ShimmerList(separation: CustomSpacer.medium)
                      : _getFilteredOrders().isEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(top: 32.0),
                              child: Center(
                                child: Text(
                                  AppLocale.noProductsFound.getString(context),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                            )
                          : _buildOrderList(_getFilteredOrders()),
                ],
              )),
            ),
          ),
        ));
  }
}
