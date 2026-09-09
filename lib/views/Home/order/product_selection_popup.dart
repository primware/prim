import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../localization/app_locale.dart';
import '../product/product_repository.dart';
import 'order_funtions.dart';

class ProductSelectionResult {
  const ProductSelectionResult({required this.products, required this.categoryIDs});
  final List<Map<String, dynamic>> products;
  final Set<int> categoryIDs;
}

class ProductSelectionPopup extends StatefulWidget {
  const ProductSelectionPopup({super.key, this.priceListID, this.initialSearch = '', this.initialCategoryIDs = const {}});

  final int? priceListID;
  final String initialSearch;
  final Set<int> initialCategoryIDs;

  static void clearGlobalCache() => ProductRepository.instance.clearMemory();

  static Future<ProductSelectionResult?> show(
    BuildContext context, {
    int? priceListID,
    String initialSearch = '',
    Set<int> initialCategoryIDs = const {},
    ValueChanged<Set<int>>? onCategoriesChanged,
  }) async {
    final result = await showGeneralDialog<ProductSelectionResult?>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).closeButtonTooltip,
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, _, _) =>
          ProductSelectionPopup(priceListID: priceListID, initialSearch: initialSearch, initialCategoryIDs: initialCategoryIDs),
      transitionBuilder: (_, animation, _, child) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: Tween(begin: 0.97, end: 1.0).animate(animation), child: child),
      ),
    );
    if (result != null) {
      onCategoriesChanged?.call({...result.categoryIDs});
    }
    return result;
  }

  @override
  State<ProductSelectionPopup> createState() => _ProductSelectionPopupState();
}

class _ProductSelectionPopupState extends State<ProductSelectionPopup> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _searchController;
  final ScrollController _scrollController = ScrollController();
  final Map<int, Map<String, dynamic>> _selectedProducts = {};
  final Set<int> _favoriteIDs = {};
  final List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _categories = [];
  late Set<int> _selectedCategoryIDs;
  Timer? _searchDebounce;
  int _pageIndex = 0;
  int _rowCount = 0;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  bool _applyingRepositoryUpdate = false;
  bool _repositoryUpdatePending = false;
  bool _categoryFilterDirty = false;
  int _queryGeneration = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _searchController = TextEditingController(text: widget.initialSearch);
    _selectedCategoryIDs = {...widget.initialCategoryIDs};
    _scrollController.addListener(_onScroll);
    ProductRepository.instance.addListener(_onRepositoryChanged);
    _initialize();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging || _tabController.index != 0 || !_categoryFilterDirty) {
      return;
    }
    _categoryFilterDirty = false;
    unawaited(_loadFirstPage());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    ProductRepository.instance.removeListener(_onRepositoryChanged);
    super.dispose();
  }

  Future<void> _onRepositoryChanged() async {
    if (!mounted) return;
    if (_applyingRepositoryUpdate) {
      _repositoryUpdatePending = true;
      return;
    }
    _applyingRepositoryUpdate = true;
    final generation = _queryGeneration;
    final searchTerm = _searchController.text.trim();
    final categoryIDs = [..._selectedCategoryIDs];
    final lastPage = _pageIndex;
    try {
      final refreshed = <Map<String, dynamic>>[];
      var total = _rowCount;
      var hasMore = _hasMore;
      for (var pageIndex = 0; pageIndex <= lastPage; pageIndex++) {
        final page = await fetchProductPage(
          pageIndex: pageIndex,
          categoryID: categoryIDs,
          searchTerm: searchTerm,
          priceListID: widget.priceListID,
        );
        refreshed.addAll(page.records);
        total = page.rowCount;
        hasMore = page.hasMore;
      }
      if (!mounted || generation != _queryGeneration) return;
      final selectedIDs = _selectedProducts.keys.toSet();
      setState(() {
        _products
          ..clear()
          ..addAll(refreshed);
        _rowCount = total;
        _hasMore = hasMore;
        for (final item in refreshed.where((item) => selectedIDs.contains(item['id']))) {
          _selectedProducts[item['id'] as int] = item;
        }
      });
    } finally {
      _applyingRepositoryUpdate = false;
      if (_repositoryUpdatePending && mounted) {
        _repositoryUpdatePending = false;
        unawaited(_onRepositoryChanged());
      }
    }
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteKey = 'favorite_products_${ProductRepository.instance.catalogCacheNamespace}_${widget.priceListID ?? 0}';
    final favorites = prefs.getStringList(favoriteKey) ?? prefs.getStringList('favorite_products') ?? const [];
    _favoriteIDs.addAll(favorites.map(int.tryParse).whereType<int>());
    _categories = await fetchProductCategory();
    await _loadFirstPage();
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteKey = 'favorite_products_${ProductRepository.instance.catalogCacheNamespace}_${widget.priceListID ?? 0}';
    await prefs.setStringList(favoriteKey, _favoriteIDs.map((id) => id.toString()).toList());
  }

  Future<void> _loadFirstPage() async {
    final generation = ++_queryGeneration;
    final searchTerm = _searchController.text.trim();
    final categoryIDs = [..._selectedCategoryIDs];
    if (mounted) {
      setState(() {
        _loading = true;
        _loadingMore = false;
        _error = null;
      });
    }
    try {
      final filtered = searchTerm.isNotEmpty || categoryIDs.isNotEmpty;
      final page = await fetchProductPage(
        categoryID: categoryIDs,
        searchTerm: searchTerm,
        priceListID: widget.priceListID,
        preferCache: !filtered,
        waitForStock: filtered,
      );
      if (!mounted || generation != _queryGeneration) return;
      setState(() {
        _products
          ..clear()
          ..addAll(page.records);
        _pageIndex = 0;
        _rowCount = page.rowCount;
        _hasMore = page.hasMore;
      });
    } catch (exception) {
      if (mounted && generation == _queryGeneration) {
        setState(() => _error = exception.toString());
      }
    } finally {
      if (mounted && generation == _queryGeneration) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final generation = _queryGeneration;
    final searchTerm = _searchController.text.trim();
    final categoryIDs = [..._selectedCategoryIDs];
    setState(() => _loadingMore = true);
    try {
      final nextPage = _pageIndex + 1;
      final page = await fetchProductPage(
        pageIndex: nextPage,
        categoryID: categoryIDs,
        searchTerm: searchTerm,
        priceListID: widget.priceListID,
        preferCache: searchTerm.isEmpty && categoryIDs.isEmpty,
        waitForStock: searchTerm.isNotEmpty || categoryIDs.isNotEmpty,
      );
      if (!mounted || generation != _queryGeneration) return;
      final known = _products.map((item) => item['id']).toSet();
      setState(() {
        _products.addAll(page.records.where((item) => known.add(item['id'])));
        _pageIndex = nextPage;
        _rowCount = page.rowCount;
        _hasMore = page.hasMore;
      });
    } catch (exception) {
      if (mounted && generation == _queryGeneration) {
        setState(() => _error = exception.toString());
      }
    } finally {
      if (mounted && generation == _queryGeneration) {
        setState(() => _loadingMore = false);
      }
    }
  }

  void _onScroll() {
    if (_scrollController.hasClients && _scrollController.position.extentAfter < 500) {
      _loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _queryGeneration++;
    final term = value.trim();
    setState(() {
      _loading = true;
      _loadingMore = false;
      _error = null;
      if (term.isNotEmpty && term.length < 2) {
        _products.clear();
        _loading = false;
      }
    });
    if (term.isNotEmpty && term.length < 2) return;
    _searchDebounce = Timer(const Duration(milliseconds: 300), _loadFirstPage);
  }

  void _toggleCategory(int id) {
    setState(() {
      if (!_selectedCategoryIDs.remove(id)) _selectedCategoryIDs.add(id);
      _categoryFilterDirty = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 850),
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width * 0.9,
          height: MediaQuery.sizeOf(context).height * 0.88,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocale.selectProducts.getString(context),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  onSubmitted: (_) => _loadFirstPage(),
                  style: const TextStyle(color: Colors.black87),
                  cursorColor: Theme.of(context).colorScheme.primary,
                  decoration: InputDecoration(
                    hintText: AppLocale.filterProduct.getString(context),
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.primary),
                    suffixIcon: IconButton(
                      tooltip: AppLocale.clear.getString(context),
                      onPressed: () {
                        _searchController.clear();
                        _loadFirstPage();
                      },
                      icon: const Icon(Icons.close_rounded, color: Colors.black54),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.6),
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(11)),
                  labelColor: Theme.of(context).colorScheme.onPrimary,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: [
                    _buildTab(Icons.grid_view_rounded, AppLocale.products.getString(context)),
                    _buildTab(Icons.favorite_outline_rounded, AppLocale.favorites.getString(context)),
                    _buildTab(Icons.folder_outlined, AppLocale.categories.getString(context)),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProductGrid(_products, loadMore: true),
                    _buildProductGrid(_products.where((item) => _favoriteIDs.contains(item['id'])).toList()),
                    _buildCategoryGrid(),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocale.selectedProductsCount.getString(context).replaceAll('{count}', _selectedProducts.length.toString()),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton(
                      onPressed: _selectedProducts.isEmpty ? null : () => setState(_selectedProducts.clear),
                      child: Text(AppLocale.clear.getString(context)),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _selectedProducts.isEmpty
                          ? null
                          : () => Navigator.pop(
                              context,
                              ProductSelectionResult(products: _selectedProducts.values.toList(), categoryIDs: _selectedCategoryIDs),
                            ),
                      icon: const Icon(Icons.add_shopping_cart),
                      label: Text(AppLocale.addToOrder.getString(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Tab _buildTab(IconData icon, String label) => Tab(
    height: 48,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 19),
        const SizedBox(width: 7),
        Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    ),
  );

  Widget _buildProductGrid(List<Map<String, dynamic>> items, {bool loadMore = false}) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null && items.isEmpty) {
      return Center(
        child: FilledButton.tonalIcon(
          onPressed: _loadFirstPage,
          icon: const Icon(Icons.refresh),
          label: Text(AppLocale.retry.getString(context)),
        ),
      );
    }
    if (items.isEmpty) {
      return Center(child: Text(AppLocale.noProductsFound.getString(context)));
    }
    return GridView.builder(
      controller: loadMore ? _scrollController : null,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        childAspectRatio: 0.86,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: items.length + (loadMore && _loadingMore ? 1 : 0),
      itemBuilder: (context, index) =>
          index == items.length ? const Center(child: CircularProgressIndicator()) : _buildProductCard(items[index]),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final id = product['id'] as int?;
    if (id == null) return const SizedBox.shrink();
    final selected = _selectedProducts.containsKey(id);
    final favorite = _favoriteIDs.contains(id);
    final colors = Theme.of(context).colorScheme;
    final stockLoading = product['stockLoading'] == true;
    final stock = product['QtyAvailable'];
    final stockNumber = stock is num ? stock.toDouble() : double.tryParse(stock?.toString() ?? '');
    final hasStock = stockNumber != null && stockNumber > 0;
    final code = (product['value'] ?? product['sku'] ?? '').toString().trim();

    return Semantics(
      button: true,
      selected: selected,
      label: product['name']?.toString() ?? '',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? colors.primary : colors.outlineVariant, width: selected ? 3 : 1),
          boxShadow: [
            BoxShadow(color: colors.shadow.withOpacity(selected ? 0.12 : 0.06), blurRadius: selected ? 12 : 8, offset: const Offset(0, 3)),
          ],
        ),
        child: InkWell(
          onTap: () => setState(() {
            if (selected) {
              _selectedProducts.remove(id);
            } else {
              _selectedProducts[id] = product;
            }
          }),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (selected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(20)),
                        child: Icon(Icons.check_rounded, color: colors.onPrimary, size: 16),
                      ),
                    const Spacer(),
                    SizedBox(
                      width: 38,
                      height: 38,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        tooltip: AppLocale.favorites.getString(context),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          hoverColor: colors.primary.withOpacity(0.08),
                          highlightColor: colors.primary.withOpacity(0.12),
                        ),
                        onPressed: () {
                          setState(() {
                            if (!_favoriteIDs.remove(id)) _favoriteIDs.add(id);
                          });
                          _saveFavorites();
                        },
                        icon: Icon(
                          favorite ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: favorite ? colors.error : colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Center(
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: selected ? colors.primary.withOpacity(0.14) : colors.secondaryContainer.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.inventory_2_outlined, size: 31, color: selected ? colors.primary : colors.onSecondaryContainer),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product['name']?.toString() ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, height: 1.2),
                ),
                if (code.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant, fontSize: 11),
                  ),
                ],
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '\$${product['price'] ?? '0.00'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colors.primary, fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (stockLoading)
                      SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary))
                    else if (stock != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: hasStock ? colors.tertiaryContainer : colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${AppLocale.exist.getString(context)}: $stock',
                          maxLines: 1,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: hasStock ? colors.onTertiaryContainer : colors.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    if (_categories.isEmpty) {
      return Center(child: Text(AppLocale.noCategories.getString(context)));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 170,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final id = category['id'] as int?;
        final selected = id != null && _selectedCategoryIDs.contains(id);
        final colors = Theme.of(context).colorScheme;
        return Card(
          color: selected ? colors.primary : null,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: id == null ? null : () => _toggleCategory(id),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(selected ? Icons.folder_open : Icons.folder_outlined, size: 38, color: selected ? colors.onPrimary : null),
                  const SizedBox(height: 8),
                  Text(
                    category['name']?.toString() ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: selected ? colors.onPrimary : null, fontWeight: selected ? FontWeight.w700 : null),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
