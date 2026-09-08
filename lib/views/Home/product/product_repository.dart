import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import '../../../API/endpoint.dart';
import '../../../API/pos.api.dart';
import '../../../API/token.api.dart';
import '../../Auth/auth_funtions.dart';
import 'product_cache_file_size.dart';

const int productPageSize = 100;

class ProductPage {
  const ProductPage({
    required this.records,
    required this.rowCount,
    required this.pageIndex,
    required this.pageSize,
    required this.fromCache,
  });

  final List<Map<String, dynamic>> records;
  final int rowCount;
  final int pageIndex;
  final int pageSize;
  final bool fromCache;

  bool get hasMore => (pageIndex + 1) * pageSize < rowCount;
  ProductPage copyWith({
    List<Map<String, dynamic>>? records,
    bool? fromCache,
  }) => ProductPage(
    records: records ?? this.records,
    rowCount: rowCount,
    pageIndex: pageIndex,
    pageSize: pageSize,
    fromCache: fromCache ?? this.fromCache,
  );
}

class ProductRepository extends ChangeNotifier {
  ProductRepository._();
  static final ProductRepository instance = ProductRepository._();

  static const _boxName = 'product_cache_v1';
  static const _schemaVersion = 1;
  static const _stockSemanticsMigrationKey =
      'meta:rv_pos_product_search_stock_v1';
  Box<dynamic>? _box;
  final Map<String, Future<ProductPage>> _inFlight = {};
  final Map<String, ProductPage> _memoryPages = {};
  final Map<String, int?> _priceListVersionCache = {};
  String? _viewCapabilityScope;
  bool? _viewAvailable;
  int _cacheGeneration = 0;

  Future<void> initialize() async {
    if (_box != null) return;
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(_boxName);
    await _migrateCachedStock();
    await _cleanupExpired();
  }

  Future<int?> cacheSizeBytes() async {
    await initialize();
    await _box?.flush();
    return productCacheFileSize(_box?.path);
  }

  Future<void> clearCache() async {
    await initialize();
    _cacheGeneration++;
    _memoryPages.clear();
    _inFlight.clear();
    await _box?.clear();
    await _box?.compact();
    await _box?.flush();
  }

  String get _catalogScope => '${Base.baseURL ?? ''}|${Token.client ?? 0}';
  int get _warehouseID => POS.warehouseID ?? Token.warehouseID ?? 0;
  String get catalogCacheNamespace =>
      base64Url.encode(utf8.encode(_catalogScope));

  Future<int?> effectivePriceListVersion(int? partnerPriceListID) async {
    if (POS.isPOS ||
        partnerPriceListID == null ||
        partnerPriceListID == POS.priceListID) {
      return POS.priceListVersionID;
    }
    final key = '$_catalogScope|pl:$partnerPriceListID';
    if (_priceListVersionCache.containsKey(key)) {
      return _priceListVersionCache[key];
    }
    final versionID = await getMPriceListVersion(partnerPriceListID);
    if (versionID != null) {
      _priceListVersionCache[key] = versionID;
    }
    return versionID;
  }

  Future<String> syncContextKey(int? partnerPriceListID) async =>
      '$_catalogScope|plv:${await effectivePriceListVersion(partnerPriceListID) ?? 0}'
      '|wh:$_warehouseID';

  String _queryKey({
    required int priceListVersionID,
    required String searchTerm,
    required List<int> categoryIDs,
    required int pageIndex,
  }) {
    final categories = [...categoryIDs]..sort();
    return '$_catalogScope|plv:$priceListVersionID|wh:$_warehouseID'
        '|q:${searchTerm.trim().toLowerCase()}|c:${categories.join(',')}|p:$pageIndex';
  }

  String _pageStorageKey(String queryKey) =>
      'page:${base64Url.encode(utf8.encode(queryKey))}';
  String _productStorageKey(
    int id,
    int versionID, {
    String? catalogScope,
    int? warehouseID,
  }) =>
      'product:${base64Url.encode(utf8.encode(catalogScope ?? _catalogScope))}:$versionID:${warehouseID ?? _warehouseID}:$id';

  void _ensureContext(
    String catalogScope,
    int warehouseID,
    int cacheGeneration,
  ) {
    if (_catalogScope != catalogScope ||
        _warehouseID != warehouseID ||
        _cacheGeneration != cacheGeneration) {
      throw StateError('Product context changed while loading');
    }
  }

  Future<ProductPage> getPage({
    int pageIndex = 0,
    String searchTerm = '',
    List<int> categoryIDs = const [],
    int? partnerPriceListID,
    bool preferCache = true,
    bool includeStock = true,
    bool waitForStock = false,
  }) async {
    await initialize();
    final versionID = await effectivePriceListVersion(partnerPriceListID);
    if (versionID == null) {
      return ProductPage(
        records: const [],
        rowCount: 0,
        pageIndex: pageIndex,
        pageSize: productPageSize,
        fromCache: false,
      );
    }
    final key = _queryKey(
      priceListVersionID: versionID,
      searchTerm: searchTerm,
      categoryIDs: categoryIDs,
      pageIndex: pageIndex,
    );
    if (preferCache) {
      final memory = _memoryPages[key];
      if (memory != null) return memory;
      final cached = _readCachedPage(key, versionID);
      if (cached != null) {
        _memoryPages[key] = cached;
        unawaited(
          refreshPage(
            pageIndex: pageIndex,
            searchTerm: searchTerm,
            categoryIDs: categoryIDs,
            partnerPriceListID: partnerPriceListID,
            includeStock: includeStock,
          ).then<void>((_) {}).catchError((_) {}),
        );
        return cached;
      }
    }
    return refreshPage(
      pageIndex: pageIndex,
      searchTerm: searchTerm,
      categoryIDs: categoryIDs,
      partnerPriceListID: partnerPriceListID,
      includeStock: includeStock,
      waitForStock: waitForStock,
    );
  }

  Future<ProductPage> refreshPage({
    int pageIndex = 0,
    String searchTerm = '',
    List<int> categoryIDs = const [],
    int? partnerPriceListID,
    bool includeStock = true,
    bool waitForStock = false,
  }) async {
    await initialize();
    final versionID = await effectivePriceListVersion(partnerPriceListID);
    if (versionID == null) {
      return ProductPage(
        records: const [],
        rowCount: 0,
        pageIndex: pageIndex,
        pageSize: productPageSize,
        fromCache: false,
      );
    }
    final key = _queryKey(
      priceListVersionID: versionID,
      searchTerm: searchTerm,
      categoryIDs: categoryIDs,
      pageIndex: pageIndex,
    );
    final catalogScope = _catalogScope;
    final warehouseID = _warehouseID;
    final cacheGeneration = _cacheGeneration;
    final inFlightKey = '$key|generation:$cacheGeneration';
    return _inFlight.putIfAbsent(inFlightKey, () async {
      try {
        final remote = await _fetchPreferredRemotePage(
          versionID: versionID,
          pageIndex: pageIndex,
          searchTerm: searchTerm,
          categoryIDs: categoryIDs,
          warehouseID: warehouseID,
        );
        var page = remote.page;
        _ensureContext(catalogScope, warehouseID, cacheGeneration);
        if (!remote.usesView) {
          page = _mergeLastKnownStock(
            page,
            versionID,
            catalogScope: catalogScope,
            warehouseID: warehouseID,
          );
        }
        _memoryPages[key] = page;
        await _writePage(
          key,
          versionID,
          page,
          persistPage: searchTerm.trim().isEmpty,
          catalogScope: catalogScope,
          warehouseID: warehouseID,
        );
        notifyListeners();
        if (!remote.usesView && includeStock && POS.isPOS) {
          final stockFuture = _refreshPageStock(
            key: key,
            versionID: versionID,
            pageIndex: pageIndex,
            searchTerm: searchTerm,
            categoryIDs: categoryIDs,
            persistPage: searchTerm.trim().isEmpty,
            catalogScope: catalogScope,
            warehouseID: warehouseID,
            cacheGeneration: cacheGeneration,
          );
          if (waitForStock) {
            page = await stockFuture;
          } else {
            unawaited(stockFuture.then<void>((_) {}).catchError((_) {}));
          }
        }
        return page;
      } finally {
        _inFlight.remove(inFlightKey);
      }
    });
  }

  Future<ProductPage> _refreshPageStock({
    required String key,
    required int versionID,
    required int pageIndex,
    required String searchTerm,
    required List<int> categoryIDs,
    required bool persistPage,
    required String catalogScope,
    required int warehouseID,
    required int cacheGeneration,
  }) async {
    final page = await _fetchLegacyRemotePage(
      versionID: versionID,
      pageIndex: pageIndex,
      searchTerm: searchTerm,
      categoryIDs: categoryIDs,
      includeStock: true,
      warehouseID: warehouseID,
    );
    _ensureContext(catalogScope, warehouseID, cacheGeneration);
    _memoryPages[key] = page;
    await _writePage(
      key,
      versionID,
      page,
      persistPage: persistPage,
      catalogScope: catalogScope,
      warehouseID: warehouseID,
    );
    notifyListeners();
    return page;
  }

  ProductPage _mergeLastKnownStock(
    ProductPage page,
    int versionID, {
    required String catalogScope,
    required int warehouseID,
  }) {
    if (!POS.isPOS) return page;
    final records = page.records.map((product) {
      final id = product['id'];
      if (id is! int) return product;
      final stored = _box?.get(
        _productStorageKey(
          id,
          versionID,
          catalogScope: catalogScope,
          warehouseID: warehouseID,
        ),
      );
      if (stored is Map && stored['QtyAvailable'] != null) {
        return <String, dynamic>{
          ...product,
          'QtyAvailable': stored['QtyAvailable'],
          'stockValidatedAt': stored['stockValidatedAt'],
          'stockLoading': true,
        };
      }
      return product;
    }).toList();
    return page.copyWith(records: records);
  }

  Future<Map<String, dynamic>?> refreshProduct({
    required int productID,
    int? partnerPriceListID,
  }) async {
    final versionID = await effectivePriceListVersion(partnerPriceListID);
    if (versionID == null) return null;
    final catalogScope = _catalogScope;
    final warehouseID = _warehouseID;
    final cacheGeneration = _cacheGeneration;
    final remote = await _fetchPreferredRemotePage(
      versionID: versionID,
      pageIndex: 0,
      searchTerm: '',
      categoryIDs: const [],
      productID: productID,
      warehouseID: warehouseID,
    );
    var page = remote.page;
    if (!remote.usesView && POS.isPOS) {
      page = await _fetchLegacyRemotePage(
        versionID: versionID,
        pageIndex: 0,
        searchTerm: '',
        categoryIDs: const [],
        includeStock: true,
        productID: productID,
        warehouseID: warehouseID,
      );
    }
    _ensureContext(catalogScope, warehouseID, cacheGeneration);
    if (page.records.isEmpty) return null;
    final product = page.records.first;
    await _writeProduct(
      product,
      versionID,
      catalogScope: catalogScope,
      warehouseID: warehouseID,
    );
    _replaceProductInMemory(product);
    notifyListeners();
    return product;
  }

  Future<_RemoteProductPage> _fetchPreferredRemotePage({
    required int versionID,
    required int pageIndex,
    required String searchTerm,
    required List<int> categoryIDs,
    int? productID,
    required int warehouseID,
  }) async {
    _syncViewCapabilityScope();
    if (_viewAvailable != false) {
      try {
        final page = await _fetchViewPage(
          versionID: versionID,
          pageIndex: pageIndex,
          searchTerm: searchTerm,
          categoryIDs: categoryIDs,
          productID: productID,
          warehouseID: warehouseID,
        );
        _viewAvailable = true;
        return _RemoteProductPage(page: page, usesView: true);
      } on _ProductViewUnavailable {
        _viewAvailable = false;
      }
    }
    final page = await _fetchLegacyRemotePage(
      versionID: versionID,
      pageIndex: pageIndex,
      searchTerm: searchTerm,
      categoryIDs: categoryIDs,
      includeStock: false,
      productID: productID,
      warehouseID: warehouseID,
    );
    return _RemoteProductPage(page: page, usesView: false);
  }

  Future<ProductPage> _fetchViewPage({
    required int versionID,
    required int pageIndex,
    required String searchTerm,
    required List<int> categoryIDs,
    int? productID,
    required int warehouseID,
  }) async {
    final filters = <String>['M_PriceList_Version_ID eq $versionID'];
    if (productID != null) {
      filters.add('M_Product_ID eq $productID');
    } else if (searchTerm.trim().isNotEmpty) {
      final escaped = searchTerm.trim().toLowerCase().replaceAll("'", "''");
      filters.add(
        "(tolower(UPC) eq '$escaped' or tolower(SKU) eq '$escaped' or tolower(Value) eq '$escaped' or "
        "contains(tolower(Name), '$escaped') or contains(tolower(SKU), '$escaped') or contains(tolower(Value), '$escaped'))",
      );
    }
    if (categoryIDs.isNotEmpty) {
      filters.add(
        '(${categoryIDs.map((id) => 'M_Product_Category_ID eq $id').join(' or ')})',
      );
    }
    final top = productID == null ? productPageSize : 1;
    final skip = productID == null ? pageIndex * productPageSize : 0;
    final uri = Uri.parse(
      '${EndPoints.rvPosProductSearch}?\$top=$top&\$skip=$skip'
      '&\$filter=${filters.join(' and ')}&\$orderby=Name,M_Product_ID'
      '&\$select=M_ProductPrice_ID,M_Product_ID,M_PriceList_Version_ID,Value,Name,SKU,UPC,ProductType,M_Product_Category_ID,C_TaxCategory_ID,PriceStd,PriceList,qtyavailablebywarehouse',
    );
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      if (_isMissingProductView(response)) {
        throw const _ProductViewUnavailable();
      }
      throw Exception('Product view query failed (${response.statusCode})');
    }
    final decoded =
        json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final rawRecords = (decoded['records'] as List?) ?? const [];
    final products = rawRecords
        .whereType<Map>()
        .map((record) => _normalizeViewProduct(record, versionID, warehouseID))
        .whereType<Map<String, dynamic>>()
        .toList();
    final rowCount =
        int.tryParse((decoded['row-count'] ?? products.length).toString()) ??
        products.length;
    return ProductPage(
      records: products,
      rowCount: productID == null ? rowCount : products.length,
      pageIndex: pageIndex,
      pageSize: productPageSize,
      fromCache: false,
    );
  }

  Future<ProductPage> _fetchLegacyRemotePage({
    required int versionID,
    required int pageIndex,
    required String searchTerm,
    required List<int> categoryIDs,
    required bool includeStock,
    int? productID,
    required int warehouseID,
  }) async {
    final filters = <String>['IsSold eq true'];
    if (productID != null) {
      filters.add('M_Product_ID eq $productID');
    } else if (searchTerm.trim().isNotEmpty) {
      final escaped = searchTerm.trim().toLowerCase().replaceAll("'", "''");
      filters.add(
        "(tolower(UPC) eq '$escaped' or tolower(SKU) eq '$escaped' or tolower(Value) eq '$escaped' or "
        "contains(tolower(Name), '$escaped') or contains(tolower(SKU), '$escaped') or contains(tolower(Value), '$escaped'))",
      );
    }
    if (categoryIDs.isNotEmpty) {
      filters.add(
        '(${categoryIDs.map((id) => 'M_Product_Category_ID eq $id').join(' or ')})',
      );
    }
    final stockExpand = includeStock && POS.isPOS
        ? ',M_Storage(\$select=QtyOnHand,QtyReserved,M_Locator_ID;\$expand=M_Locator_ID(\$select=M_Warehouse_ID))'
        : '';
    final uri = Uri.parse(
      '${EndPoints.mProduct}?\$top=$productPageSize&\$skip=${pageIndex * productPageSize}'
      '&\$filter=${filters.join(' and ')}&\$orderby=Name,M_Product_ID'
      '&\$select=Value,Name,C_TaxCategory_ID,SKU,UPC,ProductType,M_Product_Category_ID'
      '&\$expand=M_ProductPrice(\$select=PriceStd,PriceList,M_PriceList_Version_ID;\$filter=M_PriceList_Version_ID eq $versionID)$stockExpand',
    );
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Product query failed (${response.statusCode})');
    }
    final decoded =
        json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final rawRecords = (decoded['records'] as List?) ?? const [];
    final products = rawRecords
        .whereType<Map>()
        .map(
          (record) =>
              _normalizeProduct(record, versionID, includeStock, warehouseID),
        )
        .whereType<Map<String, dynamic>>()
        .toList();
    final rowCount =
        int.tryParse((decoded['row-count'] ?? products.length).toString()) ??
        products.length;
    return ProductPage(
      records: products,
      rowCount: productID == null ? rowCount : products.length,
      pageIndex: pageIndex,
      pageSize: productPageSize,
      fromCache: false,
    );
  }

  Map<String, dynamic>? _normalizeProduct(
    Map record,
    int versionID,
    bool stockLoaded,
    int warehouseID,
  ) {
    final prices =
        (record['M_ProductPrice'] as List?)?.whereType<Map>().toList() ??
        const [];
    if (prices.isEmpty) return null;
    final taxCategoryID = _referenceID(record['C_TaxCategory_ID']);
    if (taxCategoryID == null) return null;
    double? quantity;
    if (POS.isPOS && stockLoaded) {
      quantity = 0;
      for (final storage
          in (record['M_Storage'] as List?)?.whereType<Map>() ??
              const Iterable<Map>.empty()) {
        final locator = storage['M_Locator_ID'];
        final locatorWarehouseID = locator is Map
            ? _referenceID(locator['M_Warehouse_ID'])
            : null;
        if (locatorWarehouseID == warehouseID) {
          quantity =
              quantity! +
              _number(storage['QtyOnHand']) -
              _number(storage['QtyReserved']);
        }
      }
    }
    final price = prices.first;
    return <String, dynamic>{
      'id': (record['id'] as num?)?.toInt(),
      'name': record['Name']?.toString() ?? '',
      'value': record['Value']?.toString(),
      'sku': record['SKU']?.toString(),
      'upc': record['UPC']?.toString(),
      'category': _referenceID(record['M_Product_Category_ID']),
      'price': _number(price['PriceStd']),
      'priceList': _number(price['PriceList']),
      'C_TaxCategory_ID': taxCategoryID,
      'tax': POS.principalTaxs[taxCategoryID],
      'ProductType': _referenceValue(record['ProductType']),
      'QtyAvailable': quantity,
      'stockLoading': POS.isPOS && !stockLoaded,
      'priceValidatedAt': DateTime.now().toIso8601String(),
      'stockValidatedAt': stockLoaded ? DateTime.now().toIso8601String() : null,
      'priceListVersionID': versionID,
      'fromCache': false,
    };
  }

  Map<String, dynamic>? _normalizeViewProduct(
    Map record,
    int versionID,
    int warehouseID,
  ) {
    final productID = _referenceID(record['M_Product_ID']);
    final recordVersionID = _referenceID(record['M_PriceList_Version_ID']);
    final taxCategoryID = _referenceID(record['C_TaxCategory_ID']);
    if (productID == null ||
        taxCategoryID == null ||
        (recordVersionID != null && recordVersionID != versionID)) {
      return null;
    }
    final now = DateTime.now().toIso8601String();
    final stockByWarehouse = _stockByWarehouse(
      record['qtyavailablebywarehouse'] ?? record['QtyAvailableByWarehouse'],
    );
    return <String, dynamic>{
      'id': productID,
      'productPriceID': _referenceID(record['M_ProductPrice_ID']),
      'name': record['Name']?.toString() ?? '',
      'value': record['Value']?.toString(),
      'sku': record['SKU']?.toString(),
      'upc': record['UPC']?.toString(),
      'category': _referenceID(record['M_Product_Category_ID']),
      'price': _number(record['PriceStd']),
      'priceList': _number(record['PriceList']),
      'C_TaxCategory_ID': taxCategoryID,
      'tax': POS.principalTaxs[taxCategoryID],
      'ProductType': _referenceValue(record['ProductType']),
      'QtyAvailable': _number(
        stockByWarehouse[warehouseID.toString()] ??
            stockByWarehouse[warehouseID],
      ),
      'stockByWarehouse': stockByWarehouse,
      'stockLoading': false,
      'priceValidatedAt': now,
      'stockValidatedAt': now,
      'priceListVersionID': versionID,
      'fromCache': false,
    };
  }

  Map<dynamic, dynamic> _stockByWarehouse(dynamic raw) {
    if (raw is Map) return Map<dynamic, dynamic>.from(raw);
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = json.decode(raw);
        if (decoded is Map) return Map<dynamic, dynamic>.from(decoded);
      } catch (_) {
        // Invalid inventory JSON is treated as an empty warehouse map.
      }
    }
    return <dynamic, dynamic>{};
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Authorization': Token.auth!,
  };

  void _syncViewCapabilityScope() {
    if (_viewCapabilityScope == _catalogScope) return;
    _viewCapabilityScope = _catalogScope;
    _viewAvailable = null;
  }

  bool _isMissingProductView(http.Response response) {
    if (response.statusCode == 404) return true;
    if (response.statusCode != 500) return false;
    final body = utf8.decode(response.bodyBytes).toLowerCase();
    if (!body.contains('rv_pos_product_search')) return false;
    return body.contains('not found') ||
        body.contains('does not exist') ||
        body.contains('unknown table') ||
        body.contains('no table') ||
        body.contains('not registered');
  }

  ProductPage? _readCachedPage(String key, int versionID) {
    final raw = _box?.get(_pageStorageKey(key));
    if (raw is! Map || raw['schema'] != _schemaVersion) return null;
    final ids =
        (raw['ids'] as List?)
            ?.map((id) => int.tryParse(id.toString()))
            .whereType<int>()
            .toList() ??
        const [];
    final products = <Map<String, dynamic>>[];
    for (final id in ids) {
      final stored = _box?.get(_productStorageKey(id, versionID));
      if (stored is Map) {
        products.add({
          ...Map<String, dynamic>.from(stored),
          'fromCache': true,
          'stockLoading': POS.isPOS,
        });
      }
    }
    if (products.isEmpty) return null;
    return ProductPage(
      records: products,
      rowCount: int.tryParse(raw['rowCount'].toString()) ?? products.length,
      pageIndex: int.tryParse(raw['pageIndex'].toString()) ?? 0,
      pageSize: productPageSize,
      fromCache: true,
    );
  }

  Future<void> _writePage(
    String key,
    int versionID,
    ProductPage page, {
    required bool persistPage,
    required String catalogScope,
    required int warehouseID,
  }) async {
    for (final product in page.records) {
      await _writeProduct(
        product,
        versionID,
        catalogScope: catalogScope,
        warehouseID: warehouseID,
      );
    }
    if (persistPage) {
      await _box?.put(_pageStorageKey(key), {
        'schema': _schemaVersion,
        'ids': page.records.map((item) => item['id']).whereType<int>().toList(),
        'rowCount': page.rowCount,
        'pageIndex': page.pageIndex,
        'catalogScope': catalogScope,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _writeProduct(
    Map<String, dynamic> product,
    int versionID, {
    required String catalogScope,
    required int warehouseID,
  }) async {
    final id = product['id'];
    if (id is! int) return;
    await _box?.put(
      _productStorageKey(
        id,
        versionID,
        catalogScope: catalogScope,
        warehouseID: warehouseID,
      ),
      {
        ...product,
        'tax': product['tax'] is Map
            ? Map<String, dynamic>.from(product['tax'] as Map)
            : product['tax'],
        'fromCache': false,
        'stockLoading': false,
        'lastAccessedAt': DateTime.now().toIso8601String(),
        'schema': _schemaVersion,
      },
    );
  }

  void _replaceProductInMemory(Map<String, dynamic> product) {
    final id = product['id'];
    for (final entry in _memoryPages.entries.toList()) {
      final records = entry.value.records
          .map((item) => item['id'] == id ? product : item)
          .toList();
      _memoryPages[entry.key] = entry.value.copyWith(
        records: records,
        fromCache: false,
      );
    }
  }

  Future<void> invalidateProduct(int productID) async {
    await initialize();
    final scope = base64Url.encode(utf8.encode(_catalogScope));
    final keys = _box!.keys
        .where(
          (key) =>
              key.toString().startsWith('product:$scope:') &&
              key.toString().endsWith(':$productID'),
        )
        .toList();
    await _box!.deleteAll(keys);
    final pageKeys = _box!.keys.where((key) {
      if (!key.toString().startsWith('page:')) return false;
      final value = _box!.get(key);
      return value is Map && value['catalogScope'] == _catalogScope;
    }).toList();
    await _box!.deleteAll(pageKeys);
    _memoryPages.clear();
    notifyListeners();
  }

  void clearMemory() {
    _memoryPages.clear();
    _inFlight.clear();
    _priceListVersionCache.clear();
    _viewCapabilityScope = null;
    _viewAvailable = null;
    notifyListeners();
  }

  Future<void> _migrateCachedStock() async {
    if (_box?.get(_stockSemanticsMigrationKey) == true) return;
    final updates = <dynamic, dynamic>{};
    for (final key in _box!.keys) {
      if (!key.toString().startsWith('product:')) continue;
      final value = _box!.get(key);
      if (value is! Map) continue;
      final product = Map<String, dynamic>.from(value);
      product
        ..remove('QtyAvailable')
        ..remove('stockByWarehouse')
        ..remove('stockValidatedAt')
        ..['stockLoading'] = true;
      updates[key] = product;
    }
    if (updates.isNotEmpty) await _box!.putAll(updates);
    await _box!.put(_stockSemanticsMigrationKey, true);
  }

  Future<void> _cleanupExpired() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final stale = <dynamic>[];
    for (final key in _box!.keys) {
      final value = _box!.get(key);
      if (value is! Map) continue;
      final date = DateTime.tryParse(
        (value['lastAccessedAt'] ?? value['updatedAt'] ?? '').toString(),
      );
      if (date != null && date.isBefore(cutoff)) stale.add(key);
    }
    if (stale.isNotEmpty) await _box!.deleteAll(stale);
  }

  int? _referenceID(dynamic value) {
    if (value is num) return value.toInt();
    if (value is Map && value['id'] is num) return (value['id'] as num).toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  dynamic _referenceValue(dynamic value) => value is Map ? value['id'] : value;
  double _number(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;
}

class _RemoteProductPage {
  const _RemoteProductPage({required this.page, required this.usesView});

  final ProductPage page;
  final bool usesView;
}

class _ProductViewUnavailable implements Exception {
  const _ProductViewUnavailable();
}
