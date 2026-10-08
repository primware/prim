import 'dart:convert';
import 'package:http/http.dart' as http;
import 'endpoint.dart';
import 'token.api.dart';

int? feReferenceId(dynamic value) {
  final raw = value is Map ? value['id'] : value;
  return raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '');
}

Map<String, dynamic>? selectFEConfig(List<dynamic> records, int organization) {
  final applicable = records.where((r) {
    final org = feReferenceId(r['AD_Org_ID']);
    return org == organization || org == 0;
  }).toList();
  applicable.sort((a, b) {
    final ao = feReferenceId(a['AD_Org_ID']) == organization ? 0 : 1;
    final bo = feReferenceId(b['AD_Org_ID']) == organization ? 0 : 1;
    final priority = ao.compareTo(bo);
    return priority != 0 ? priority : (feReferenceId(a['id']) ?? 0).compareTo(feReferenceId(b['id']) ?? 0);
  });
  if (applicable.isEmpty) return null;
  final selectedOrg = feReferenceId(applicable.first['AD_Org_ID']);
  if (applicable.where((r) => feReferenceId(r['AD_Org_ID']) == selectedOrg).length > 1) {
    CurrentLogMessage.add('Multiple FE configurations for organization $selectedOrg; selecting lowest ID.', level: 'WARNING', tag: 'FE');
  }
  return Map<String, dynamic>.from(applicable.first);
}

class FESession {
  static bool hasFEConfig = false;
  static int? configId, organizationId, pacId;
  static String? legalName, taxId, resolution;
  static DateTime? resolutionDate;
  static int _generation = 0;
  static void reset() {
    _generation++;
    hasFEConfig = false;
    configId = organizationId = pacId = null;
    legalName = taxId = resolution = null;
    resolutionDate = null;
  }
}

Future<void> loadFESession({http.Client? client}) async {
  FESession.reset();
  final generation = FESession._generation;
  final org = Token.organitation;
  final token = Token.auth;
  if (org == null || token == null) return;
  final transport = client ?? http.Client();
  final headers = {'Authorization': token, 'Content-Type': 'application/json; charset=UTF-8'};
  try {
    final configs = <dynamic>[];
    var skip = 0;
    while (true) {
      final response = await transport
          .get(
            Uri.parse(
              '${EndPoints.fePACConfig}?\$filter=AD_Org_ID eq $org OR AD_Org_ID eq 0&\$select=AD_Org_ID,FE_PAC_ID&\$orderby=FE_PAC_Config_ID&\$top=100&\$skip=$skip',
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) throw StateError('FE config HTTP ${response.statusCode}');
      final data = json.decode(utf8.decode(response.bodyBytes));
      final page = (data['records'] as List?) ?? [];
      configs.addAll(page);
      if (page.isEmpty || configs.length >= (data['row-count'] as num? ?? configs.length)) break;
      skip += page.length;
    }
    final config = selectFEConfig(configs, org);
    if (config == null) return;
    final pacId = feReferenceId(config['FE_PAC_ID']);
    Map<String, dynamic> pac = {};
    if (pacId != null) {
      final response = await transport
          .get(
            Uri.parse('${EndPoints.fePAC}?\$filter=FE_PAC_ID eq $pacId&\$select=FE_LegalName,TaxID,FE_Resolution,FE_ResolutionDate'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) throw StateError('FE PAC HTTP ${response.statusCode}');
      final records = json.decode(utf8.decode(response.bodyBytes))['records'] as List?;
      if (records != null && records.isNotEmpty) pac = Map<String, dynamic>.from(records.first);
    }
    if (generation != FESession._generation || token != Token.auth || org != Token.organitation) return;
    String? text(dynamic value) {
      final result = value?.toString().trim() ?? '';
      return result.isEmpty ? null : result;
    }

    FESession.hasFEConfig = true;
    FESession.configId = feReferenceId(config['id']);
    FESession.organizationId = feReferenceId(config['AD_Org_ID']);
    FESession.pacId = pacId;
    FESession.legalName = text(pac['FE_LegalName']);
    FESession.taxId = text(pac['TaxID']);
    FESession.resolution = text(pac['FE_Resolution']);
    FESession.resolutionDate = DateTime.tryParse(pac['FE_ResolutionDate']?.toString() ?? '');
  } catch (e) {
    CurrentLogMessage.add('$e', level: 'WARNING', tag: 'FE');
  } finally {
    if (client == null) transport.close();
  }
}
