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

  Widget _buildProductCard(Map<String, dynamic> record) {
    return GestureDetector(
      onTap: () async {
        final refreshed = await Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: record)));
        if (refreshed == true) _loadProduct(showLoadingIndicator: true);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
          border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            // Ícono principal (Estilo inventario)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.inventory_2_outlined, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(width: 16),
            // Información central
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record['name'],
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (record['sku'] != null && record['sku'].toString().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Theme.of(context).dividerColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text('SKU: ${record['sku']}', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.attach_money_rounded, color: Theme.of(context).colorScheme.secondary, size: 18),
                      Text(
                        record['price'].toString(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Flecha indicadora de acción
            Icon(Icons.chevron_right, color: Colors.grey.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Future<void> _openCategoryFilter() async {
    Set<int> tempSelected = Set<int>.from(selectedCategories);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    AppLocale.selectCategories.getString(context),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      physics: const BouncingScrollPhysics(),
                      itemCount: categpryOptions.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final cat = categpryOptions[idx];
                        final isSelected = tempSelected.contains(cat['id']);

                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setModalState(() {
                              if (isSelected) {
                                tempSelected.remove(cat['id']);
                              } else {
                                tempSelected.add(cat['id']);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.grey.withOpacity(0.2), width: isSelected ? 1.5 : 1.0),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    cat['name'],
                                    style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? Theme.of(context).primaryColor : null),
                                  ),
                                ),
                                if (isSelected) Icon(Icons.check_circle, color: Theme.of(context).primaryColor) else Icon(Icons.circle_outlined, color: Colors.grey.withOpacity(0.4)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: Theme.of(context).primaryColor,
                              elevation: 0,
                            ),
                            onPressed: () => Navigator.pop(context, tempSelected),
                            child: Text(
                              AppLocale.apply.getString(context),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: TextButton(
                            style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            onPressed: () => Navigator.pop(context),
                            child: Text(AppLocale.cancel.getString(context), style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((result) {
      if (result != null && result is Set<int>) {
        setState(() => selectedCategories = Set<int>.from(result));
        _loadProduct(showLoadingIndicator: true);
      }
    });
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
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedOpacity(
              opacity: _isFabExpanded ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: AnimatedSlide(
                offset: _isFabExpanded ? Offset.zero : const Offset(0, 0.4),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                child: IgnorePointer(
                  ignoring: !_isFabExpanded,
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
            FloatingActionButton(
              heroTag: 'mainBtn',
              onPressed: () {
                setState(() {
                  _isFabExpanded = !_isFabExpanded;
                });
              },
              child: AnimatedRotation(turns: _isFabExpanded ? 0.125 : 0.0, duration: const Duration(milliseconds: 250), curve: Curves.easeOutBack, child: const Icon(Icons.add)),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: CustomContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextfieldTheme(texto: AppLocale.searchProducts.getString(context), controlador: productController, onSubmitted: (_) => _loadProduct(showLoadingIndicator: true)),
                      ),
                      const SizedBox(width: CustomSpacer.small),
                      Container(
                        height: 55,
                        decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(8)),
                        child: IconButton(
                          icon: const Icon(Icons.search, color: Colors.white),
                          tooltip: 'Buscar',
                          onPressed: () => _loadProduct(showLoadingIndicator: true),
                        ),
                      ),
                    ],
                  ),

                  if (isProductSearchLoading) ...[const SizedBox(height: CustomSpacer.small), const LinearProgressIndicator()],

                  const SizedBox(height: CustomSpacer.medium),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        ActionChip(
                          avatar: Icon(Icons.tune, color: Theme.of(context).colorScheme.onSecondary, size: 18),
                          label: Text(
                            AppLocale.categories.getString(context),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSecondary, fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          side: BorderSide.none,
                          onPressed: _openCategoryFilter,
                        ),

                        if (selectedCategories.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Container(width: 1, height: 24, color: Colors.grey.withOpacity(0.4)),
                          const SizedBox(width: 12),
                          ...selectedCategories.map((catId) {
                            final cat = categpryOptions.firstWhere((c) => c['id'] == catId, orElse: () => <String, dynamic>{});
                            final catName = cat.isNotEmpty ? cat['name'] : 'Categoría';
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Chip(
                                label: Text(catName, style: const TextStyle(fontSize: 12)),
                                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                deleteIconColor: Theme.of(context).primaryColor,
                                side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                onDeleted: () {
                                  setState(() => selectedCategories.remove(catId));
                                  _loadProduct(showLoadingIndicator: true);
                                },
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: CustomSpacer.medium),

                  Expanded(
                    child: _isLoading
                        ? ShimmerList(separation: CustomSpacer.medium)
                        : _getFilteredOrders().isEmpty
                        ? Center(
                            child: Text(AppLocale.noProductsFound.getString(context), style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: _getFilteredOrders().length,
                            itemBuilder: (context, index) {
                              final record = _getFilteredOrders()[index];
                              return _buildProductCard(record);
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
