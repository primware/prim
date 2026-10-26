import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import '../../../API/endpoint.dart';
import '../../../API/token.api.dart';
import '../../Auth/auth_funtions.dart';
import '../product/product_cache_file_size.dart';
import '../../../shared/local_cache_storage.dart';

const int bPartnerPageSize = 100;
const String _bPartnerSelect =
    'C_BPartner_ID,Name,TaxID,dv,M_PriceList_ID,TipoClienteFE,LCO_TaxIdType_ID,C_BP_Group_ID';
const String _bPartnerExpand =
    'AD_User(\$select=AD_User_ID,Name,EMail),'
    'C_BPartner_Location(\$select=C_BPartner_Location_ID,Name,C_Location_ID;'
    '\$expand=C_Location_ID(\$select=C_Location_ID,Address1))';

class BPartnerPage {
  const BPartnerPage({
    required this.records,
    required this.rowCount,
    required this.pageIndex,
    required this.fromCache,
  });

  final List<Map<String, dynamic>> records;
  final int rowCount;
  final int pageIndex;
  final bool fromCache;

  bool get hasMore => (pageIndex + 1) * bPartnerPageSize < rowCount;
}

class BPartnerRepository extends ChangeNotifier {
  BPartnerRepository._();

  static final BPartnerRepository instance = BPartnerRepository._();
  static const String _boxName = 'bpartner_cache_v1';
  static const int _schemaVersion = 1;

  Box<dynamic>? _box;
  final Map<String, Future<BPartnerPage>> _inFlight = {};

  Future<void>? _initialization;
  Future<void> initialize() => _initialization ??= _initialize().timeout(const Duration(seconds: 30));

  Future<void> _initialize() async {
    _box = await LocalCacheStorage.instance.openBox(_boxName);
  }

  String get _clientNamespace => 'client:${Token.client ?? 0}';
  String _recordKey(int id) => 'bpartner:$_clientNamespace:$id';
  String get _recordPrefix => 'bpartner:$_clientNamespace:';
  String get _totalKey => 'meta:$_clientNamespace:total';
  String _pageKey(String searchTerm, int pageIndex) =>
      'page:$_clientNamespace:${base64Url.encode(utf8.encode(searchTerm.trim().toLowerCase()))}:$pageIndex';

  Future<int?> cacheSizeBytes() async {
    await initialize();
    await _box?.flush();
    return productCacheFileSize(_box?.path);
  }

  Future<void> clearCache() async {
    await initialize();
    _inFlight.clear();
    await _box?.clear();
    await _box?.compact();
    await _box?.flush();
    notifyListeners();
  }

  void clearMemory() {
    _inFlight.clear();
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> readCached({String searchTerm = ''}) async {
    await initialize();
    final query = searchTerm.trim().toLowerCase();
    final records = <Map<String, dynamic>>[];
    for (final key in _box!.keys.whereType<String>().where((key) => key.startsWith(_recordPrefix))) {
      final value = _box!.get(key);
      if (value is! Map) continue;
      final record = _deepMap(value);
      final searchable = '${record['name'] ?? ''} ${record['Name'] ?? ''} ${record['TaxID'] ?? ''}'.toLowerCase();
      if (query.isEmpty || searchable.contains(query)) records.add(record);
    }
    records.sort((a, b) => (a['name'] ?? '').toString().toLowerCase().compareTo((b['name'] ?? '').toString().toLowerCase()));
    return records;
  }

  Future<Map<String, dynamic>?> readById(int id) async {
    await initialize();
    final value = _box?.get(_recordKey(id));
    return value is Map ? _deepMap(value) : null;
  }

  Future<BPartnerPage?> readCachedPage({String searchTerm = '', int pageIndex = 0}) async {
    await initialize();
    final raw = _box?.get(_pageKey(searchTerm, pageIndex));
    if (raw is! Map) return null;
    final ids = ((raw['ids'] as List?) ?? const []).map(_asInt).whereType<int>();
    final records = ids.map((id) => _box?.get(_recordKey(id))).whereType<Map>().map(_deepMap).toList();
    return BPartnerPage(
      records: records,
      rowCount: _asInt(raw['rowCount']) ?? records.length,
      pageIndex: pageIndex,
      fromCache: true,
    );
  }

  Future<BPartnerPage> searchCustomers({required BuildContext context, String searchTerm = ''}) async {
    final cached = await readCached(searchTerm: searchTerm);
    if (cached.isNotEmpty) {
      unawaited(refreshPage(context: context, searchTerm: searchTerm).then<void>((_) {}).catchError((_) {}));
      return BPartnerPage(
        records: cached,
        rowCount: cached.length,
        pageIndex: 0,
        fromCache: true,
      );
    }
    return refreshPage(context: context, searchTerm: searchTerm);
  }

  Future<BPartnerPage> getCustomers({
    required BuildContext context,
    String searchTerm = '',
    int pageIndex = 0,
    bool preferCache = true,
  }) async {
    final cached = preferCache ? await readCachedPage(searchTerm: searchTerm, pageIndex: pageIndex) : null;
    if (cached != null) {
      unawaited(
        refreshPage(context: context, searchTerm: searchTerm, pageIndex: pageIndex).then<void>((_) {}).catchError((_) {}),
      );
      return cached;
    }
    return refreshPage(context: context, searchTerm: searchTerm, pageIndex: pageIndex);
  }

  Future<BPartnerPage> refreshPage({
    required BuildContext context,
    String searchTerm = '',
    int pageIndex = 0,
  }) async {
    await initialize();
    final client = Token.client ?? 0;
    final requestKey = '$client|${searchTerm.trim().toLowerCase()}|$pageIndex';
    return _inFlight.putIfAbsent(requestKey, () async {
      try {
        await usuarioAuth(context: context);
        final filters = <String>['IsCustomer eq true'];
        if (searchTerm.trim().isNotEmpty) {
          final query = searchTerm.trim().toLowerCase().replaceAll("'", "''");
          filters.add("(contains(tolower(Name), '$query') or contains(tolower(TaxID), '$query'))");
        }
        final response = await http.get(
          Uri.parse(
            '${EndPoints.cBPartner}?\$top=$bPartnerPageSize&\$skip=${pageIndex * bPartnerPageSize}'
            '&\$filter=${filters.join(' and ')}&\$orderby=Name'
            '&\$select=$_bPartnerSelect&\$expand=$_bPartnerExpand',
          ),
          headers: {'Content-Type': 'application/json; charset=UTF-8', 'Authorization': Token.auth!},
        );
        if (response.statusCode != 200) {
          throw Exception('Error al cargar los terceros: ${response.statusCode}');
        }
        if (Token.client != client) throw StateError('BPartner context changed while loading');
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        final rawRecords = (decoded['records'] as List?)?.whereType<Map>().toList() ?? const <Map>[];
        var changed = false;
        final normalized = <Map<String, dynamic>>[];
        for (final raw in rawRecords) {
          final partner = _normalize(raw);
          normalized.add(partner);
          changed = await upsert(partner, notify: false) || changed;
        }
        final rowCount = _asInt(decoded['row-count']) ?? rawRecords.length;
        if (searchTerm.trim().isEmpty) {
          changed = await _putIfChanged(_totalKey, rowCount) || changed;
        }
        changed =
            await _putIfChanged(_pageKey(searchTerm, pageIndex), {
              'ids': normalized.map((item) => item['id']).whereType<int>().toList(),
              'rowCount': rowCount,
              'pageIndex': pageIndex,
            }) ||
            changed;
        if (changed) notifyListeners();
        return BPartnerPage(records: normalized, rowCount: rowCount, pageIndex: pageIndex, fromCache: false);
      } finally {
        _inFlight.remove(requestKey);
      }
    });
  }

  Future<Map<String, dynamic>?> refreshById({required BuildContext context, required int id}) async {
    await usuarioAuth(context: context);
    final response = await http.get(
      Uri.parse(
        '${EndPoints.cBPartner}?\$filter=IsCustomer eq true and C_BPartner_ID eq $id'
        '&\$select=$_bPartnerSelect&\$expand=$_bPartnerExpand',
      ),
      headers: {'Content-Type': 'application/json; charset=UTF-8', 'Authorization': Token.auth!},
    );
    if (response.statusCode != 200) return null;
    final decoded = json.decode(utf8.decode(response.bodyBytes));
    final records = (decoded['records'] as List?)?.whereType<Map>().toList() ?? const <Map>[];
    if (records.isEmpty) return null;
    final partner = _normalize(records.first);
    await upsert(partner);
    return partner;
  }

  Future<bool> upsert(Map<String, dynamic> partner, {bool notify = true}) async {
    await initialize();
    final id = _asInt(partner['id'] ?? partner['C_BPartner_ID']);
    if (id == null) return false;
    // AD_Client_ID + C_BPartner_ID is the identity of a cached customer.
    // Reusing this exact key guarantees that an existing customer is updated
    // in place instead of being inserted as another cache entry.
    final key = _recordKey(id);
    final changed = await _putIfChanged(key, _deepMap(partner));
    if (changed && notify) notifyListeners();
    return changed;
  }

  Map<String, dynamic> _normalize(Map<dynamic, dynamic> raw) {
    final record = _deepMap(raw);
    final users = (record['AD_User'] as List?)?.whereType<Map>().map(_deepMap).toList() ?? <Map<String, dynamic>>[];
    final locations =
        (record['C_BPartner_Location'] as List?)?.whereType<Map>().map(_deepMap).toList() ?? <Map<String, dynamic>>[];
    final firstUser = users.isEmpty ? null : users.first;
    final firstLocation = locations.isEmpty ? null : locations.first;
    final location = firstLocation?['C_Location_ID'] is Map ? firstLocation!['C_Location_ID'] as Map : null;
    return <String, dynamic>{
      ...record,
      'schema': _schemaVersion,
      'id': _asInt(record['id'] ?? record['C_BPartner_ID']),
      'name': record['Name'] ?? '',
      'TaxID': record['TaxID'],
      'dv': record['dv'],
      'M_PriceList_ID': _asInt(record['M_PriceList_ID']),
      'TipoClienteFE': _referenceValue(record['TipoClienteFE']),
      'LCO_TaxIdType_ID': _asInt(record['LCO_TaxIdType_ID']),
      'LCO_TaxIdTypeName': _referenceName(record['LCO_TaxIdType_ID']),
      'C_BP_Group_ID': _asInt(record['C_BP_Group_ID']),
      'AD_User': users,
      'AD_User_ID': _asInt(firstUser?['id']),
      'email': firstUser?['EMail'],
      'C_BPartner_Location': locations,
      'C_BPartner_Location_ID': _asInt(firstLocation?['id']),
      'locationName': firstLocation?['Name'] ?? location?['identifier'] ?? location?['Address1'],
      'location': location?['Address1'] ?? location?['identifier'] ?? firstLocation?['Name'],
      'hasLocation': locations.any((item) => _asInt(item['id']) != null),
    };
  }

  Future<bool> _putIfChanged(dynamic key, dynamic value) async {
    final current = _box?.get(key);
    if (jsonEncode(current) == jsonEncode(value)) return false;
    await _box?.put(key, value);
    return true;
  }

  static Map<String, dynamic> _deepMap(Map<dynamic, dynamic> value) =>
      Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is Map) return _asInt(value['id']);
    return int.tryParse(value?.toString() ?? '');
  }

  static dynamic _referenceValue(dynamic value) => value is Map ? value['id'] : value;
  static String? _referenceName(dynamic value) =>
      value is Map ? (value['identifier'] ?? value['Name'] ?? value['name'])?.toString() : null;
}
