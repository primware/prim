import 'dart:async';
import 'dart:ui';
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
import '../../../Widgets/GlassDesign.dart';

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
  double _reloadTurns = 0.0;

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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () async {
          final refreshed = await Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: record)));
          if (refreshed == true) _loadProduct(showLoadingIndicator: true);
        },
        child: GlassContainer(
          padding: const EdgeInsets.all(12),
          borderRadius: BorderRadius.circular(12),
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
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final primary = Theme.of(context).primaryColor;

            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A2D3E).withOpacity(0.75) // Gris azulado premium
                        : Colors.white.withOpacity(0.85),
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2))),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16),
                        // Pill superior
                        Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(color: isDark ? Colors.white30 : Colors.black26, borderRadius: BorderRadius.circular(10)),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          AppLocale.selectCategories.getString(context),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),

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
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  setModalState(() {
                                    if (isSelected) {
                                      tempSelected.remove(cat['id']);
                                    } else {
                                      tempSelected.add(cat['id']);
                                    }
                                  });
                                },
                                // 👇 Tarjetas mucho más contrastadas y legibles
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: isSelected ? primary.withOpacity(0.15) : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.03)),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: isSelected ? primary : (isDark ? Colors.white24 : Colors.black12), width: isSelected ? 1.5 : 1.0),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          cat['name'],
                                          style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? primary : null),
                                        ),
                                      ),
                                      if (isSelected) Icon(Icons.check_circle, color: primary) else Icon(Icons.circle_outlined, color: isDark ? Colors.white30 : Colors.black26),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    backgroundColor: primary,
                                    elevation: 0,
                                  ),
                                  onPressed: () => Navigator.pop(context, tempSelected),
                                  child: Text(
                                    AppLocale.apply.getString(context),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: TextButton(
                                  style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(AppLocale.cancel.getString(context), style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.black54)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
      child: LightAccentBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,

          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: const GlassContainer(borderRadius: BorderRadius.zero, padding: EdgeInsets.zero, child: SizedBox.expand()),
            title: Text(AppLocale.products.getString(context), style: const TextStyle(fontWeight: FontWeight.bold)),
            iconTheme: Theme.of(context).iconTheme,
          ),
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
            bottom: false,
            child: Center(
              child: CustomContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextfieldTheme(
                                    texto: AppLocale.searchProducts.getString(context),
                                    controlador: productController,
                                    onSubmitted: (_) => _loadProduct(showLoadingIndicator: true),
                                    onChanged: (val) {
                                      setState(() {
                                        _searchQuery = val;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: CustomSpacer.small),
                                Container(
                                  height: 55,
                                  decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(8)),
                                  child: IconButton(
                                    icon: AnimatedRotation(
                                      turns: _reloadTurns,
                                      duration: const Duration(milliseconds: 800),
                                      curve: Curves.easeOutExpo,
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 300),
                                        transitionBuilder: (Widget child, Animation<double> animation) {
                                          return ScaleTransition(scale: animation, child: child);
                                        },
                                        child: Icon(_searchQuery.isNotEmpty ? Icons.search : Icons.refresh, key: ValueKey<bool>(_searchQuery.isNotEmpty), color: Colors.white),
                                      ),
                                    ),
                                    tooltip: 'Buscar / Recargar',
                                    onPressed: () {
                                      if (_searchQuery.isEmpty) {
                                        setState(() {
                                          _reloadTurns += 1.0;
                                        });
                                      }
                                      _loadProduct(showLoadingIndicator: true);
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),
                            GlassMenuButton(
                              label: AppLocale.categories.getString(context),
                              // Lógica para mostrar cuántas categorías hay seleccsonadas
                              currentValue: selectedCategories.isEmpty ? '' : (selectedCategories.length == 1 ? categpryOptions.firstWhere((c) => c['id'] == selectedCategories.first, orElse: () => <String, dynamic>{})['name'] ?? 'Seleccionado' : '${selectedCategories.length} seleccionadas'),
                              onTap: _openCategoryFilter,
                            ),
                            if (selectedCategories.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: [
                                    ...selectedCategories.map((catId) {
                                      final cat = categpryOptions.firstWhere((c) => c['id'] == catId, orElse: () => <String, dynamic>{});
                                      final catName = cat.isNotEmpty ? cat['name'] : 'Categoría';
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        // Chips de cristal para borrar
                                        child: Chip(
                                          label: Text(catName, style: const TextStyle(fontSize: 12)),
                                          backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
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
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    if (isProductSearchLoading) ...[const SizedBox(height: 16), const LinearProgressIndicator(), const SizedBox(height: 8)],

                    const SizedBox(height: CustomSpacer.medium),

                    Expanded(
                      child: _isLoading
                          ? ShimmerList(separation: CustomSpacer.medium)
                          : _getFilteredOrders().isEmpty
                          ? Center(
                              child: Text(AppLocale.noProductsFound.getString(context), style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      ),
    );
  }
}
