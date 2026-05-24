import 'dart:async';
import 'dart:ui';
import 'package:primware/Widgets/GlassDesign.dart';
import 'package:flutter/material.dart';
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
import 'product_funtions.dart';
import '../../../shared/toast_message.dart';

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
    final product = await fetchProductInPriceList(
      context: context,
      categoryID: selectedCategories.isNotEmpty ? selectedCategories.toList() : null,
      searchTerm: productController.text.trim(),
    );
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
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'SKU: ${record['sku']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.attach_money_rounded, color: Theme.of(context).colorScheme.secondary, size: 18),
                      Text(
                        record['price'].toString(),
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold),
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
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return GlassContainer(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65),
              hasShadow: true,
              shadowBlur: 20,
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
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

                            return GlassPressable(
                              onTap: () {
                                setModalState(() {
                                  if (isSelected) {
                                    tempSelected.remove(cat['id']);
                                  } else {
                                    tempSelected.add(cat['id']);
                                  }
                                });
                              },
                              child: GlassContainer(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                borderRadius: BorderRadius.circular(12),
                                hasShadow: false,
                                customBorderColor: isSelected ? Theme.of(context).primaryColor : null,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        cat['name'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected
                                              ? Theme.of(context).primaryColor
                                              : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
                                    else
                                      Icon(Icons.circle_outlined, color: Colors.grey.withOpacity(0.4)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      GlassContainer(
                        padding: const EdgeInsets.all(24.0),
                        borderRadius: BorderRadius.zero,
                        hasShadow: true,
                        shadowBlur: 10,
                        shadowOffset: const Offset(0, -5),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: GlassPressable(
                                onTap: () => Navigator.pop(context, tempSelected),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    AppLocale.apply.getString(context),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: GlassPressable(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    AppLocale.cancel.getString(context),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
                                    ),
                                  ),
                                ),
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
    bool isCreating = false;
    bool isCatNameValid = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16.0),
              elevation: 0,
              child: GlassContainer(
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(24.0),
                hasShadow: true,
                shadowBlur: 20.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Nueva Categoría', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextfieldTheme(
                      controlador: catNameController,
                      texto: '${AppLocale.name.getString(context)}*',
                      colorEmpty: catNameController.text.trim().isEmpty,
                      inputType: TextInputType.text,
                      onChanged: (value) {
                        setModalState(() {
                          isCatNameValid = value.trim().isNotEmpty;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!isCreating)
                          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(AppLocale.cancel.getString(context))),
                        if (!isCreating)
                          ElevatedButton(
                    onPressed: isCatNameValid
                        ? () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                backgroundColor: Theme.of(context).cardColor,
                                title: Column(
                                  children: [
                                    Icon(Icons.help_outline, size: 45, color: Colors.blueAccent),
                                    SizedBox(height: 10),
                                    Text(
                                      AppLocale.newCategory.getString(context),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                  ],
                                ),
                                content: Text(
                                  AppLocale.confirmCreateCategory.getString(context),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                actionsAlignment: MainAxisAlignment.spaceEvenly,
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocale.no.getString(context))),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(AppLocale.yes.getString(context)),
                                  ),
                                ],
                              ),
                            );

                            if (confirm != true) return;

                            // Pasamos a modo cargando
                            setModalState(() => isCreating = true);

                            final result = await postProductCategory(name: catNameController.text, context: context);
                            if (!mounted) return;

                            if (result['success'] == true) {
                              Navigator.pop(dialogContext);
                              ToastMessage.show(context: context, message: 'Categoría creada con éxito', type: ToastType.success);
                              _loadProductCategory();
                            } else {
                              setModalState(() => isCreating = false);
                              ToastMessage.show(context: context, message: result['message'] ?? 'Error al crear', type: ToastType.failure);
                            }
                          }
                        : null,
                    child: Text(AppLocale.save.getString(context)),
                  ),
                        if (isCreating) const CircularProgressIndicator(),
                      ],
                    ),
                  ],
                ),
              ),
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
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
          title: Text(
            AppLocale.products.getString(context),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          flexibleSpace: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.6),
                      Theme.of(context).primaryColor.withOpacity(0.4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
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
                      GlassPressable(
                        onTap: () {
                          setState(() => _isFabExpanded = false);
                          _showCreateCategoryDialog();
                        },
                        child: GlassContainer(
                          padding: EdgeInsets.zero,
                          borderRadius: BorderRadius.circular(20),
                          hasShadow: false,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.category, color: Theme.of(context).primaryColor),
                                const SizedBox(width: 8),
                                Text('Crear Categoría', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GlassPressable(
                        onTap: () async {
                          setState(() => _isFabExpanded = false);
                          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductNewPage()));

                          if (result != null && result['created'] == true) {
                            _loadProduct(showLoadingIndicator: true);
                          }
                        },
                        child: GlassContainer(
                          padding: EdgeInsets.zero,
                          borderRadius: BorderRadius.circular(20),
                          hasShadow: false,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inventory_2, color: Theme.of(context).primaryColor),
                                const SizedBox(width: 8),
                                Text('Crear Producto', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
            GlassPressable(
              onTap: () {
                setState(() {
                  _isFabExpanded = !_isFabExpanded;
                });
              },
              child: GlassContainer(
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(20),
                hasShadow: false,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: AnimatedRotation(
                    turns: _isFabExpanded ? 0.125 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    child: Icon(Icons.add, color: Theme.of(context).primaryColor, size: 28),
                  ),
                ),
              ),
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 250,
                        child: TextfieldTheme(
                          texto: AppLocale.searchProducts.getString(context),
                          controlador: productController,
                          onSubmitted: (_) => _loadProduct(showLoadingIndicator: true),
                        ),
                      ),
                      const SizedBox(width: CustomSpacer.small),
                      AnimatedSearchButton(
                        controller: productController,
                        isLoading: isProductSearchLoading,
                        onPressed: () => _loadProduct(showLoadingIndicator: true),
                      ),
                    ],
                  ),

                  if (isProductSearchLoading) ...[const SizedBox(height: CustomSpacer.small), const LinearProgressIndicator()],

                  const SizedBox(height: CustomSpacer.medium),

                  AnimatedCategoryButton(
                    child: GlassMenuButton(
                      label: AppLocale.categories.getString(context),
                      currentValue: selectedCategories.isEmpty ? '' : '${selectedCategories.length} seleccionadas',
                      icon: Icons.category_outlined,
                      onTap: _openCategoryFilter,
                    ),
                  ),

                  if (selectedCategories.isNotEmpty) ...[
                    const SizedBox(height: CustomSpacer.small),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: selectedCategories.map((catId) {
                          final cat = categpryOptions.where((element) => element['id'] == catId);
                          final catName = cat.isNotEmpty ? cat.first['name'] : 'Categoría';
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
                        }).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: CustomSpacer.medium),

                  Expanded(
                    child: _isLoading
                        ? ShimmerList(separation: CustomSpacer.medium)
                        : _getFilteredOrders().isEmpty
                        ? Center(
                            child: Text(
                              AppLocale.noProductsFound.getString(context),
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                            ),
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

class AnimatedSearchButton extends StatefulWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onPressed;

  const AnimatedSearchButton({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  State<AnimatedSearchButton> createState() => _AnimatedSearchButtonState();
}

class _AnimatedSearchButtonState extends State<AnimatedSearchButton> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _spinController;

  bool _isTyping = false;
  String _lastSearchedText = '';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _spinController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));

    widget.controller.addListener(_onTextChanged);
    _updateAnimations();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final isTyping = text != _lastSearchedText;
    if (_isTyping != isTyping) {
      setState(() {
        _isTyping = isTyping;
      });
      _updateAnimations();
    }
  }

  @override
  void didUpdateWidget(AnimatedSearchButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading != widget.isLoading) {
      if (!widget.isLoading) {
        _lastSearchedText = widget.controller.text;
        _isTyping = false;
      }
      _updateAnimations();
    }
  }

  void _updateAnimations() {
    if (widget.isLoading) {
      _spinController.repeat();
      _pulseController.stop();
      _pulseController.value = 0.0;
    } else if (_isTyping) {
      _spinController.stop();
      _pulseController.repeat(reverse: true);
    } else {
      _spinController.stop();
      _pulseController.stop();
      _pulseController.value = 0.0;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _pulseController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassPressable(
      onTap: () {
        _lastSearchedText = widget.controller.text;
        widget.onPressed();
      },
      child: GlassContainer(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(20),
        hasShadow: false,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: _isTyping && !widget.isLoading
                ? ScaleTransition(
                    key: const ValueKey('search'),
                    scale: _pulseAnimation,
                    child: Icon(Icons.search, color: Theme.of(context).primaryColor, size: 28),
                  )
                : RotationTransition(
                    key: const ValueKey('refresh'),
                    turns: _spinController,
                    child: Icon(Icons.refresh, color: Theme.of(context).primaryColor, size: 28),
                  ),
          ),
        ),
      ),
    );
  }
}

class AnimatedCategoryButton extends StatefulWidget {
  final Widget child;

  const AnimatedCategoryButton({super.key, required this.child});

  @override
  State<AnimatedCategoryButton> createState() => _AnimatedCategoryButtonState();
}

class _AnimatedCategoryButtonState extends State<AnimatedCategoryButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _controller.forward(),
      onPointerUp: (_) => _controller.reverse(),
      onPointerCancel: (_) => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

