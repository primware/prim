import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/shared/custom_container.dart';
import 'package:primware/localization/app_locale.dart';
import '../../../shared/custom_app_menu.dart';
import '../../../shared/custom_spacer.dart';
import '../../../shared/footer.dart';
import '../../../shared/shimmer_list.dart';
import '../../../shared/custom_textfield.dart';
import '../dashboard/dashboard_view.dart';
import '../order/order_funtions.dart';
import 'product_new.dart';
import 'product_details.dart';
import '../../../theme/colors.dart';
import 'product_funtions.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true, isProductSearchLoading = false, isProductCategoryLoading = true;
  bool _isFabExpanded = false;
  // ignore: prefer_final_fields
  String _searchQuery = '';
  Set<int> selectedCategories = {};
  List<Map<String, dynamic>> categpryOptions = [];
  TextEditingController productController = TextEditingController();

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

  Future<void> _loadProduct({bool showLoadingIndicator = false}) async {
    if (showLoadingIndicator) {
      setState(() {
        isProductSearchLoading = true;
      });
    }
    final product = await fetchProductInPriceList(context: context, categoryID: selectedCategories.isNotEmpty ? selectedCategories.toList() : null, searchTerm: productController.text.trim());
    setState(() {
      _products = product;
      isProductSearchLoading = false;
    });
  }

  List<Map<String, dynamic>> _getFilteredOrders() {
    return _products.where((product) => product['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  Widget _buildOrderList(List<Map<String, dynamic>> records) {
    return Column(
      children: records.map((record) {
        return GestureDetector(
          onTap: () async {
            final refreshed = await Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: record)));

            if (refreshed == true) {
              _loadProduct(showLoadingIndicator: true);
            }
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
            child: ListTile(
              title: Text('${record['name']} ${record['sku'] != null ? '(${record['sku']})' : ''}', style: Theme.of(context).textTheme.bodyLarge),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.attach_money_rounded, color: Theme.of(context).colorScheme.secondary, size: 18),
                      Text(record['price'].toString(), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.secondary)),
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

  Future<void> _showCreateCategoryDialog() async {
    final TextEditingController catNameController = TextEditingController();
    final TextEditingController catValueController = TextEditingController();
    final TextEditingController catDescController = TextEditingController();
    bool isCreating = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              insetPadding: const EdgeInsets.all(16.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Nueva Categoría', style: Theme.of(context).textTheme.bodyMedium),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextfieldTheme(controlador: catNameController, texto: '${AppLocale.name.getString(context)}*', inputType: TextInputType.text),
                    const SizedBox(height: CustomSpacer.medium),
                    TextfieldTheme(controlador: catValueController, texto: 'Código (ID)', inputType: TextInputType.text),
                    const SizedBox(height: CustomSpacer.medium),
                    TextfieldTheme(controlador: catDescController, texto: 'Descripción (Opcional)', inputType: TextInputType.text),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                if (!isCreating) TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(AppLocale.cancel.getString(context))),
                if (!isCreating)
                  ElevatedButton(
                    onPressed: () async {
                      if (catNameController.text.isEmpty) return;
                      setModalState(() => isCreating = true);

                      final result = await postProductCategory(name: catNameController.text, value: catValueController.text, description: catDescController.text, context: context);
                      if (!mounted) return;

                      if (result['success'] == true) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Categoría creada con éxito'), backgroundColor: ColorTheme.success));
                        _loadProductCategory();
                      } else {
                        setModalState(() => isCreating = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Error al crear'), backgroundColor: ColorTheme.error));
                      }
                    },
                    child: Text(AppLocale.save.getString(context)),
                  ),
                if (isCreating) const CircularProgressIndicator(),
              ],
            );
          },
        );
      },
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
        appBar: AppBar(title: Text(AppLocale.products.getString(context))),
        bottomNavigationBar: CustomFooter(),
        drawer: MenuDrawer(),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min, // Evita que la columna ocupe toda la pantalla
          children: [
            // --- BLOQUE ANIMADO PARA LAS OPCIONES ---
            AnimatedOpacity(
              opacity: _isFabExpanded ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: AnimatedSlide(
                offset: _isFabExpanded ? Offset.zero : const Offset(0, 0.4), // Sube ligeramente
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack, // Le da ese toque de "rebote" elástico premium
                child: IgnorePointer(
                  ignoring: !_isFabExpanded, // Desactiva los clics si está oculto
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FloatingActionButton.extended(
                        heroTag: 'catBtn',
                        onPressed: () {
                          setState(() => _isFabExpanded = false);
                          _showCreateCategoryDialog();
                        },
                        icon: const Icon(Icons.category),
                        label: const Text('Crear Categoría'),
                      ),
                      const SizedBox(height: 10),
                      FloatingActionButton.extended(
                        heroTag: 'prodBtn',
                        onPressed: () {
                          setState(() => _isFabExpanded = false);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductNewPage()));
                        },
                        icon: const Icon(Icons.inventory_2),
                        label: const Text('Crear Producto'),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
            // --- BOTÓN PRINCIPAL (LA CRUZ) ---
            FloatingActionButton(
              heroTag: 'mainBtn',
              onPressed: () {
                setState(() {
                  _isFabExpanded = !_isFabExpanded;
                });
              },
              child: AnimatedRotation(
                turns: _isFabExpanded ? 0.125 : 0.0, // Rota 45 grados de forma suave
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Center(
            child: CustomContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    style: ButtonStyle(textStyle: MaterialStateProperty.all(Theme.of(context).textTheme.bodyMedium), backgroundColor: MaterialStateProperty.all(Theme.of(context).colorScheme.secondary), foregroundColor: MaterialStateProperty.all(Theme.of(context).colorScheme.onSecondary)),
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
                                    constraints: const BoxConstraints(maxHeight: 400),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Text(AppLocale.selectCategories.getString(context), style: Theme.of(context).textTheme.bodyLarge),
                                        ),
                                        Expanded(
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: categpryOptions.length,
                                            itemBuilder: (context, idx) {
                                              final cat = categpryOptions[idx];
                                              final isSelected = tempSelected.contains(cat['id']);
                                              return ListTile(
                                                title: Text(cat['name']),
                                                selected: isSelected,
                                                onTap: () {
                                                  setModalState(() {
                                                    if (isSelected) {
                                                      tempSelected.remove(cat['id']);
                                                    } else {
                                                      tempSelected.add(cat['id']);
                                                    }
                                                  });
                                                },
                                                trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
                                              );
                                            },
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: Text(AppLocale.cancel.getString(context)),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context, tempSelected);
                                                },
                                                child: Text(AppLocale.apply.getString(context)),
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
                          _loadProduct(showLoadingIndicator: true);
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
                          final cat = categpryOptions.firstWhere((c) => c['id'] == catId, orElse: () => <String, dynamic>{});
                          final catName = cat.isNotEmpty ? cat['name'] : 'Categoría';
                          return Chip(
                            label: Text(catName),
                            onDeleted: () {
                              setState(() {
                                selectedCategories.remove(catId);
                              });
                              _loadProduct(showLoadingIndicator: true);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: CustomSpacer.medium),

                  // Campo de producto
                  if (isProductSearchLoading) ...[const SizedBox(height: 4), const LinearProgressIndicator(), const SizedBox(height: 8)],
                  Row(
                    children: [
                      Expanded(
                        child: TextfieldTheme(texto: AppLocale.searchProducts.getString(context), controlador: productController, onSubmitted: (_) => _loadProduct(showLoadingIndicator: true)),
                      ),
                      const SizedBox(width: CustomSpacer.small),
                      IconButton(icon: const Icon(Icons.search), onPressed: () => _loadProduct(showLoadingIndicator: true)),
                    ],
                  ),
                  const SizedBox(height: CustomSpacer.medium),
                  _isLoading
                      ? ShimmerList(separation: CustomSpacer.medium)
                      : _getFilteredOrders().isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 32.0),
                          child: Center(child: Text(AppLocale.noProductsFound.getString(context), style: Theme.of(context).textTheme.bodyLarge)),
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
