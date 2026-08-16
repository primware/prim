import 'package:flutter/material.dart';
import 'package:primware/views/Home/order/order_funtions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../../../localization/app_locale.dart';

class ProductSelectionPopup extends StatefulWidget {
  final int? priceListID;

  const ProductSelectionPopup({super.key, this.priceListID});

  static Future<List<dynamic>?> show(BuildContext context, {int? priceListID}) {
    return showGeneralDialog<List<dynamic>?>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Cerrar selección de productos",
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ProductSelectionPopup(priceListID: priceListID);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return ScaleTransition(
          scale: curve,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<ProductSelectionPopup> createState() => _ProductSelectionPopupState();
}

class _ProductSelectionPopupState extends State<ProductSelectionPopup>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _products = [];
  List<dynamic> _categories = [];
  List<dynamic> _favorites = [];
  Set<int> _favoriteIds = {};

  bool _isLoading = false;

  Map<int, dynamic> _selectedProducts = {};
  Set<int> _selectedCategoryIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadFavorites().then((_) {
      _loadData();
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {});
  }

  int? _getId(dynamic item) {
    if (item == null) return null;
    return item['id'] ?? item['M_Product_ID'] ?? item['Product_ID'];
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favList = prefs.getStringList('favorite_products') ?? [];
    setState(() {
      _favoriteIds = favList.map((e) => int.tryParse(e) ?? -1).toSet();
    });
  }

  Future<void> _toggleFavorite(dynamic product) async {
    final productId = _getId(product);
    if (productId == null) return;

    setState(() {
      if (_favoriteIds.contains(productId)) {
        _favoriteIds.remove(productId);
        _favorites.removeWhere((p) => _getId(p) == productId);
      } else {
        _favoriteIds.add(productId);
        if (!_favorites.any((p) => _getId(p) == productId)) {
          _favorites.add(product);
        }
      }
    });

    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(
      'favorite_products',
      _favoriteIds.map((e) => e.toString()).toList(),
    );
  }

  static List<dynamic>? _globalCachedProducts;
  static List<dynamic>? _globalCachedCategories;

  bool _isProductsLoading = false;

  Future<void> _loadData({bool isCategoryChange = false}) async {
    setState(() {
      if (isCategoryChange) {
        _isProductsLoading = true;
      } else {
        _isLoading = true;
      }
    });

    if (_globalCachedCategories == null) {
      _globalCachedCategories = await fetchProductCategory();
    }

    if (_globalCachedProducts == null) {
      _globalCachedProducts = await fetchProductInPriceList(
        context: context,
        categoryID: null,
        searchTerm: '',
        priceListID: widget.priceListID,
      );
    }

    List<dynamic> productsToDisplay;

    if (_selectedCategoryIds.isNotEmpty) {
      // Fallback to API filtering to guarantee correct results
      productsToDisplay = await fetchProductInPriceList(
        context: context,
        categoryID: _selectedCategoryIds.toList(),
        searchTerm: '',
        priceListID: widget.priceListID,
      );
    } else {
      productsToDisplay = List.from(_globalCachedProducts!);
    }

    // Sort alphabetically
    productsToDisplay.sort(
      (a, b) => (a['name'] ?? '').toString().toLowerCase().compareTo(
        (b['name'] ?? '').toString().toLowerCase(),
      ),
    );

    // Favorites
    final favoritesList = productsToDisplay
        .where((p) => _favoriteIds.contains(_getId(p)))
        .toList();

    // Grouping for main view
    productsToDisplay.sort((a, b) {
      final isAFav = _favoriteIds.contains(_getId(a)) ? 0 : 1;
      final isBFav = _favoriteIds.contains(_getId(b)) ? 0 : 1;
      if (isAFav != isBFav) return isAFav.compareTo(isBFav);
      return (a['name'] ?? '').toString().toLowerCase().compareTo(
        (b['name'] ?? '').toString().toLowerCase(),
      );
    });

    setState(() {
      _categories = _globalCachedCategories!;
      _products = productsToDisplay;
      _favorites = favoritesList;
      _isLoading = false;
      _isProductsLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Selección de Productos",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              tabs: const [
                Tab(icon: Icon(Icons.grid_view), text: "Productos"),
                Tab(icon: Icon(Icons.favorite), text: "Favoritos"),
                Tab(icon: Icon(Icons.folder), text: "Categorías"),
              ],
            ),
            const SizedBox(height: 16),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildProductGrid(_products, isMainView: true),
                        _buildProductGrid(_favorites, isMainView: false),
                        _buildCategoryGrid(),
                      ],
                    ),
            ),

            const SizedBox(height: 16),
            Column(
              children: [
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${_selectedProducts.length} seleccionados",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedProducts.clear();
                        });
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text("Limpiar"),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text(
                      "Añadir a la orden",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: _selectedProducts.isEmpty
                        ? null
                        : () {
                            Navigator.pop(
                              context,
                              _selectedProducts.values.toList(),
                            );
                          },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid(List<dynamic> items, {bool isMainView = false}) {
    if (_isProductsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No se encontraron productos",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Group items
    final Map<String, List<dynamic>> groupedItems = {};
    if (isMainView) {
      for (final item in items) {
        if (_favoriteIds.contains(_getId(item))) {
          groupedItems.putIfAbsent("Favoritos", () => []).add(item);
        } else {
          final name = (item['name'] ?? '').toString().trim();
          final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : '#';
          groupedItems.putIfAbsent(firstLetter, () => []).add(item);
        }
      }
    } else {
      groupedItems[""] = items;
    }

    return CustomScrollView(
      slivers: [
        if (isMainView && _selectedCategoryIds.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedCategoryIds.map((id) {
                  final cat = _categories.firstWhere(
                    (c) => _getId(c) == id,
                    orElse: () => {'name': '...'},
                  );
                  return InputChip(
                    label: Text(
                      cat['name'] ?? '',
                      style: const TextStyle(fontSize: 12),
                    ),
                    padding: EdgeInsets.zero,
                    deleteIconColor: Theme.of(context).primaryColor,
                    onDeleted: () {
                      setState(() {
                        _selectedCategoryIds.remove(id);
                        _loadData(isCategoryChange: true);
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        for (final group in groupedItems.entries) ...[
          if (group.key.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  group.key,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                return _buildProductCard(group.value[index]);
              }, childCount: group.value.length),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProductCard(dynamic product) {
    final id = _getId(product);
    if (id == null) return const SizedBox.shrink();

    final isSelected = _selectedProducts.containsKey(id);
    final isFav = _favoriteIds.contains(id);

    return Card(
      elevation: isSelected ? 8 : 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedProducts.remove(id);
            } else {
              _selectedProducts[id] = product;
            }
          });
        },
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    color: Theme.of(context).primaryColor.withOpacity(0.05),
                    child: const Icon(
                      Icons.inventory_2,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        product['name'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "\$${product['price'] ?? '0.00'}",
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : Colors.grey,
                  shadows: const [Shadow(color: Colors.white, blurRadius: 4)],
                ),
                onPressed: () => _toggleFavorite(product),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    if (_categories.isEmpty) {
      return const Center(
        child: Text("No hay categorías", style: TextStyle(color: Colors.grey)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        final id = cat['id'] ?? cat['M_Product_Category_ID'];
        final isSelected = _selectedCategoryIds.contains(id);

        return Card(
          elevation: isSelected ? 6 : 2,
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                if (_selectedCategoryIds.contains(id)) {
                  _selectedCategoryIds.remove(id);
                } else {
                  _selectedCategoryIds.add(id);
                }
                _loadData(isCategoryChange: true);
              });
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? Icons.folder_open : Icons.folder,
                  size: 48,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    cat['name'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Theme.of(context).primaryColor : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
