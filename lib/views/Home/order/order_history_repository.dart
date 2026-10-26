import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../../API/token.api.dart';
import '../../../API/user.api.dart';
import '../invoice/invoice_payment_receipt.dart';
import '../product/product_cache_file_size.dart';
import 'history_search_criteria.dart';
import '../../../shared/local_cache_storage.dart';

class CachedOrderHistoryPage {
  const CachedOrderHistoryPage({required this.orders, required this.receipts, required this.totalCount, required this.pageIndex});

  final List<Map<String, dynamic>> orders;
  final List<InvoicePaymentReceipt> receipts;
  final int totalCount;
  final int pageIndex;
}

/// Progressive cache for the history pages the user has actually opened.
///
/// The namespace intentionally depends only on AD_Client_ID. Roles, users and
/// organizations belonging to the same client share the same cached history.
class OrderHistoryRepository extends ChangeNotifier {
  OrderHistoryRepository._();

  static final OrderHistoryRepository instance = OrderHistoryRepository._();
  static const String _boxName = 'order_history_cache_v1';

  Box<dynamic>? _box;

  Future<void>? _initialization;
  Future<void> initialize() => _initialization ??= _initialize().timeout(const Duration(seconds: 30));

  Future<void> _initialize() async {
    _box = await LocalCacheStorage.instance.openBox(_boxName);
  }

  Future<int?> cacheSizeBytes() async {
    await initialize();
    await _box?.flush();
    return productCacheFileSize(_box?.path);
  }

  Future<void> clearCache() async {
    await initialize();
    await _box?.clear();
    await _box?.compact();
    await _box?.flush();
    notifyListeners();
  }

  String get _clientNamespace => 'client:${Token.client ?? 0}';

  String _criteriaKey(HistorySearchCriteria criteria) {
    final json = jsonEncode(criteria.toJson());
    return base64Url.encode(utf8.encode(json));
  }

  String _pageKey(HistorySearchCriteria criteria, int pageIndex) => 'page:$_clientNamespace:${_criteriaKey(criteria)}:$pageIndex';
  String _orderKey(int id) => 'order:$_clientNamespace:$id';
  String _receiptKey(int id) => 'receipt:$_clientNamespace:$id';

  Future<CachedOrderHistoryPage?> readPage({required HistorySearchCriteria criteria, required int pageIndex}) async {
    await initialize();
    final raw = _box?.get(_pageKey(criteria, pageIndex));
    if (raw is! Map) return null;
    try {
      final data = Map<String, dynamic>.from(raw);
      final orderIds = ((data['orderIds'] as List?) ?? const []).map(_asInt).whereType<int>().toList();
      final receiptIds = ((data['receiptIds'] as List?) ?? const []).map(_asInt).whereType<int>().toList();
      return CachedOrderHistoryPage(
        orders: orderIds.isNotEmpty
            ? orderIds.map((id) => _box?.get(_orderKey(id))).whereType<Map>().map(_deepMap).toList()
            : ((data['orders'] as List?) ?? const []).whereType<Map>().map(_deepMap).toList(),
        receipts: receiptIds.isNotEmpty
            ? receiptIds
                  .map((id) => _box?.get(_receiptKey(id)))
                  .whereType<Map>()
                  .map((item) => _receiptFromJson(Map<String, dynamic>.from(item)))
                  .toList()
            : ((data['receipts'] as List?) ?? const [])
                  .whereType<Map>()
                  .map((item) => _receiptFromJson(Map<String, dynamic>.from(item)))
                  .toList(),
        totalCount: _asInt(data['totalCount']) ?? 0,
        pageIndex: _asInt(data['pageIndex']) ?? pageIndex,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> writePage({
    required HistorySearchCriteria criteria,
    required int pageIndex,
    required List<Map<String, dynamic>> orders,
    required List<InvoicePaymentReceipt> receipts,
    required int totalCount,
  }) async {
    await initialize();
    var changed = false;
    final existingPage = _box?.get(_pageKey(criteria, pageIndex));
    final needsCompaction = existingPage is Map && (existingPage.containsKey('orders') || existingPage.containsKey('receipts'));
    final orderIds = <int>[];
    for (final order in orders) {
      final id = _asInt(order['id'] ?? order['C_Order_ID']);
      if (id == null) continue;
      orderIds.add(id);
      changed = await _putIfChanged(_orderKey(id), _deepMap(order)) || changed;
    }
    final receiptIds = <int>[];
    for (final receipt in receipts) {
      receiptIds.add(receipt.allocationId);
      changed = await _putIfChanged(_receiptKey(receipt.allocationId), _receiptToJson(receipt)) || changed;
    }
    changed = await _putIfChanged(_pageKey(criteria, pageIndex), <String, dynamic>{
      'criteria': criteria.toJson(),
      'pageIndex': pageIndex,
      'totalCount': totalCount,
      'orderIds': orderIds,
      'receiptIds': receiptIds,
    }) || changed;
    if (needsCompaction) await _box?.compact();
    if (changed) notifyListeners();
  }

  Future<void> upsertOrder(Map<String, dynamic> order) async {
    await initialize();
    final orderId = _asInt(order['id'] ?? order['C_Order_ID']);
    if (orderId == null) return;

    var changed = await _putIfChanged(_orderKey(orderId), _deepMap(order));
    final prefix = 'page:$_clientNamespace:';
    for (final key in _box!.keys.whereType<String>().where((key) => key.startsWith(prefix)).toList()) {
      final raw = _box!.get(key);
      if (raw is! Map) continue;
      final page = Map<String, dynamic>.from(raw);
      final legacyOrders = ((page['orders'] as List?) ?? const []).whereType<Map>().map(_deepMap).toList();
      if (!page.containsKey('orderIds') && legacyOrders.isNotEmpty) {
        final legacyIndex = legacyOrders.indexWhere((item) => _asInt(item['id'] ?? item['C_Order_ID']) == orderId);
        if (legacyIndex >= 0) {
          legacyOrders[legacyIndex] = _deepMap(order);
          page['orders'] = legacyOrders;
          page.remove('updatedAt');
          changed = await _putIfChanged(key, page) || changed;
          continue;
        }
      }
      final orderIds = ((page['orderIds'] as List?) ?? const []).map(_asInt).whereType<int>().toList();
      if (orderIds.isEmpty) {
        orderIds.addAll(
          ((page['orders'] as List?) ?? const [])
              .whereType<Map>()
              .map((item) => _asInt(item['id'] ?? item['C_Order_ID']))
              .whereType<int>(),
        );
      }
      if (!orderIds.contains(orderId)) {
        final criteriaRaw = page['criteria'];
        final criteria = criteriaRaw is Map
            ? HistorySearchCriteria.fromJson(Map<String, dynamic>.from(criteriaRaw))
            : const HistorySearchCriteria();
        final pageIndex = _asInt(page['pageIndex']) ?? -1;
        if (pageIndex != 0 || !_matches(order, criteria)) continue;
        orderIds.insert(0, orderId);
        if (orderIds.length > 50) orderIds.removeLast();
        page['totalCount'] = (_asInt(page['totalCount']) ?? 0) + 1;
        page['orderIds'] = orderIds;
        page.remove('orders');
        changed = await _putIfChanged(key, page) || changed;
      }
    }
    if (changed) notifyListeners();
  }

  Future<void> upsertReceipt(InvoicePaymentReceipt receipt, {required int organizationId}) async {
    await initialize();
    final receiptId = receipt.allocationId;
    if (receiptId <= 0) return;

    var changed = await _putIfChanged(_receiptKey(receiptId), _receiptToJson(receipt));
    final prefix = 'page:$_clientNamespace:';
    for (final key in _box!.keys.whereType<String>().where((key) => key.startsWith(prefix)).toList()) {
      final raw = _box!.get(key);
      if (raw is! Map) continue;
      final page = Map<String, dynamic>.from(raw);
      final criteriaRaw = page['criteria'];
      final criteria = criteriaRaw is Map
          ? HistorySearchCriteria.fromJson(Map<String, dynamic>.from(criteriaRaw))
          : const HistorySearchCriteria();
      final pageIndex = _asInt(page['pageIndex']) ?? -1;
      if (pageIndex != 0 || !_receiptMatches(receipt, organizationId, criteria)) continue;

      final receiptIds = ((page['receiptIds'] as List?) ?? const []).map(_asInt).whereType<int>().toList();
      if (receiptIds.isEmpty) {
        receiptIds.addAll(
          ((page['receipts'] as List?) ?? const []).whereType<Map>().map((item) => _asInt(item['allocationId'])).whereType<int>(),
        );
      }
      final alreadyIncluded = receiptIds.remove(receiptId);
      receiptIds.insert(0, receiptId);
      if (receiptIds.length > 50) receiptIds.removeLast();
      if (!alreadyIncluded) {
        page['totalCount'] = (_asInt(page['totalCount']) ?? 0) + 1;
      }
      page['receiptIds'] = receiptIds;
      page.remove('receipts');
      page.remove('updatedAt');
      changed = await _putIfChanged(key, page) || changed;
    }
    if (changed) notifyListeners();
  }

  Future<bool> _putIfChanged(String key, Map<String, dynamic> value) async {
    final current = _box?.get(key);
    if (current is Map && jsonEncode(current) == jsonEncode(value)) return false;
    await _box?.put(key, value);
    return true;
  }

  bool _matches(Map<String, dynamic> order, HistorySearchCriteria criteria) {
    final document = (order['DocumentNo'] ?? '').toString().toLowerCase();
    final partner = order['bpartner'] is Map ? order['bpartner'] as Map : const {};
    final customer = '${partner['name'] ?? ''} ${partner['taxID'] ?? ''}'.toLowerCase();
    final status = order['DocStatus'] is Map ? order['DocStatus']['id'] : order['DocStatus'];
    final salesRep = order['SalesRep_ID'] is Map ? order['SalesRep_ID']['id'] : order['SalesRep_ID'];
    return (criteria.documentText.trim().isEmpty || document.contains(criteria.documentText.trim().toLowerCase())) &&
        (criteria.customerText.trim().isEmpty || customer.contains(criteria.customerText.trim().toLowerCase())) &&
        (criteria.docStatus == null || status?.toString() == criteria.docStatus) &&
        (!criteria.onlyMyMovements || _asInt(salesRep) == UserData.id) &&
        (criteria.organizationId == null || _asInt(order['AD_Org_ID']) == criteria.organizationId);
  }

  bool _receiptMatches(InvoicePaymentReceipt receipt, int organizationId, HistorySearchCriteria criteria) {
    final customerQuery = criteria.customerText.trim().toLowerCase();
    final documentQuery = criteria.documentText.trim().toLowerCase();
    final customer = '${receipt.customerName} ${receipt.customerTaxId}'.toLowerCase();
    final document = '${receipt.displayDocumentNo} ${receipt.invoices.map((item) => item.documentNo).join(' ')}'.toLowerCase();
    return (customerQuery.isEmpty || customer.contains(customerQuery)) &&
        (documentQuery.isEmpty || document.contains(documentQuery)) &&
        (criteria.docStatus == null || criteria.docStatus == 'CO') &&
        (!criteria.onlyMyMovements || receipt.salesRepId == UserData.id) &&
        (criteria.organizationId == null || criteria.organizationId == organizationId);
  }

  static Map<String, dynamic> _deepMap(Map<dynamic, dynamic> value) => Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is Map) return _asInt(value['id']);
    return int.tryParse(value?.toString() ?? '');
  }

  static Map<String, dynamic> _receiptToJson(InvoicePaymentReceipt receipt) => {
    'allocationId': receipt.allocationId,
    'documentNo': receipt.documentNo,
    'date': receipt.date.toIso8601String(),
    'customerId': receipt.customerId,
    'customerName': receipt.customerName,
    'customerTaxId': receipt.customerTaxId,
    'customerAddress': receipt.customerAddress,
    'customerPhone': receipt.customerPhone,
    'salesRepId': receipt.salesRepId,
    'salesRepName': receipt.salesRepName,
    'posId': receipt.posId,
    'posName': receipt.posName,
    'hasTraceConflict': receipt.hasTraceConflict,
    'invoices': receipt.invoices
        .map(
          (item) => {
            'id': item.id,
            'documentNo': item.documentNo,
            'originalAmount': item.originalAmount,
            'appliedAmount': item.appliedAmount,
          },
        )
        .toList(),
    'payments': receipt.payments
        .map((item) => {'id': item.id, 'documentNo': item.documentNo, 'methodName': item.methodName, 'amount': item.amount})
        .toList(),
  };

  static InvoicePaymentReceipt _receiptFromJson(Map<String, dynamic> json) => InvoicePaymentReceipt(
    allocationId: _asInt(json['allocationId']) ?? 0,
    documentNo: json['documentNo']?.toString(),
    date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
    customerId: _asInt(json['customerId']) ?? 0,
    customerName: (json['customerName'] ?? '').toString(),
    customerTaxId: (json['customerTaxId'] ?? '').toString(),
    customerAddress: (json['customerAddress'] ?? '').toString(),
    customerPhone: (json['customerPhone'] ?? '').toString(),
    salesRepId: _asInt(json['salesRepId']) ?? 0,
    salesRepName: (json['salesRepName'] ?? '').toString(),
    posId: _asInt(json['posId']),
    posName: (json['posName'] ?? '').toString(),
    hasTraceConflict: json['hasTraceConflict'] == true,
    invoices: ((json['invoices'] as List?) ?? const [])
        .whereType<Map>()
        .map(
          (item) => InvoicePaymentReceiptInvoice(
            id: _asInt(item['id']) ?? 0,
            documentNo: (item['documentNo'] ?? '').toString(),
            originalAmount: (item['originalAmount'] as num?)?.toDouble() ?? 0,
            appliedAmount: (item['appliedAmount'] as num?)?.toDouble() ?? 0,
          ),
        )
        .toList(),
    payments: ((json['payments'] as List?) ?? const [])
        .whereType<Map>()
        .map(
          (item) => InvoicePaymentReceiptPayment(
            id: _asInt(item['id']) ?? 0,
            documentNo: (item['documentNo'] ?? '').toString(),
            methodName: (item['methodName'] ?? '').toString(),
            amount: (item['amount'] as num?)?.toDouble() ?? 0,
          ),
        )
        .toList(),
  );
}
