import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart';

import '../../../API/endpoint.dart';
import '../../../API/pos.api.dart';
import '../../../API/token.api.dart';
import '../../Auth/auth_funtions.dart';

Map<String, String> _headers() => {
  'Content-Type': 'application/json; charset=UTF-8',
  'Authorization': Token.auth!,
};

Map<String, String> _writeHeaders() => {
  'Content-Type': 'application/json',
  'Authorization': Token.auth!,
};

Map<String, dynamic> _normalizeLookup(Map<String, dynamic> record) {
  return {
    'id': record['id'],
    'name':
        record['Name']?.toString() ?? record['identifier']?.toString() ?? '',
    if (record['CountryCode'] != null) 'CountryCode': record['CountryCode'],
  };
}

Future<List<Map<String, dynamic>>> fetchCountries({
  required BuildContext context,
}) async {
  try {
    await usuarioAuth(context: context);

    const pageSize = 100;
    var skip = 0;
    var totalCount = 0;
    final countries = <Map<String, dynamic>>[];

    do {
      final response = await get(
        Uri.parse(
          '${EndPoints.cCountry}?\$skip=$skip&\$select=Name,CountryCode&\$orderby=Name',
        ),
        headers: _headers(),
      );

      if (response.statusCode != 200) {
        CurrentLogMessage.add(
          'fetchCountries: ${response.statusCode}, ${response.body}',
          level: 'ERROR',
          tag: 'fetchCountries',
        );
        return countries;
      }

      final data = json.decode(utf8.decode(response.bodyBytes));
      final records = (data['records'] as List?) ?? [];
      totalCount = data['row-count'] is int
          ? data['row-count'] as int
          : int.tryParse(data['row-count']?.toString() ?? '') ?? 0;

      countries.addAll(
        records.whereType<Map<String, dynamic>>().map(_normalizeLookup),
      );

      if (records.isEmpty) break;
      skip += pageSize;
    } while (skip < totalCount);

    return countries;
  } catch (e) {
    CurrentLogMessage.add(
      'Excepcion en fetchCountries: $e',
      level: 'ERROR',
      tag: 'fetchCountries',
    );
  }

  return [];
}

Future<List<Map<String, dynamic>>> fetchCities({
  required BuildContext context,
  required int countryId,
}) async {
  try {
    await usuarioAuth(context: context);

    const pageSize = 100;
    var skip = 0;
    var totalCount = 0;
    final cities = <Map<String, dynamic>>[];

    do {
      final response = await get(
        Uri.parse(
          '${EndPoints.cCity}?\$skip=$skip&\$filter=C_Country_ID eq $countryId&\$select=Name&\$orderby=Name',
        ),
        headers: _headers(),
      );

      if (response.statusCode != 200) {
        CurrentLogMessage.add(
          'fetchCities: ${response.statusCode}, ${response.body}',
          level: 'ERROR',
          tag: 'fetchCities',
        );
        return cities;
      }

      final data = json.decode(utf8.decode(response.bodyBytes));
      final records = (data['records'] as List?) ?? [];
      totalCount = data['row-count'] is int
          ? data['row-count'] as int
          : int.tryParse(data['row-count']?.toString() ?? '') ?? 0;

      cities.addAll(
        records.whereType<Map<String, dynamic>>().map(_normalizeLookup),
      );

      if (records.isEmpty) break;
      skip += pageSize;
    } while (skip < totalCount);

    return cities;
  } catch (e) {
    CurrentLogMessage.add(
      'Excepcion en fetchCities: $e',
      level: 'ERROR',
      tag: 'fetchCities',
    );
  }

  return [];
}

Future<Map<String, dynamic>?> fetchOrganizationSettings({
  required BuildContext context,
}) async {
  try {
    await usuarioAuth(context: context);

    final organizationId = Token.organitation;
    if (organizationId == null) {
      CurrentLogMessage.add(
        'fetchOrganizationSettings: organizacion no definida',
        level: 'ERROR',
        tag: 'fetchOrganizationSettings',
      );
      return null;
    }

    final orgResp = await get(
      Uri.parse('${EndPoints.adOrg}?\$filter=AD_Org_ID eq $organizationId'),
      headers: _headers(),
    );
    if (orgResp.statusCode != 200) {
      CurrentLogMessage.add(
        'fetchOrganizationSettings AD_Org: ${orgResp.statusCode}, ${orgResp.body}',
        level: 'ERROR',
        tag: 'fetchOrganizationSettings',
      );
      return null;
    }

    final orgData = json.decode(utf8.decode(orgResp.bodyBytes));
    final orgRecords = (orgData['records'] as List?) ?? [];
    if (orgRecords.isEmpty || orgRecords.first is! Map<String, dynamic>) {
      CurrentLogMessage.add(
        'fetchOrganizationSettings: AD_Org no encontrado',
        level: 'ERROR',
        tag: 'fetchOrganizationSettings',
      );
      return null;
    }

    final orgRecord = orgRecords.first as Map<String, dynamic>;
    final infoRecord = await _fetchOrgInfoByOrgId(organizationId);
    Token.adOrgInfoUU = infoRecord?['uid']?.toString() ?? Token.adOrgInfoUU;

    Map<String, dynamic>? locationRecord;
    final locationId = infoRecord?['C_Location_ID']?['id'];
    if (locationId != null) {
      final locResp = await get(
        Uri.parse('${EndPoints.cLocation}/$locationId'),
        headers: _headers(),
      );
      if (locResp.statusCode == 200) {
        locationRecord =
            json.decode(utf8.decode(locResp.bodyBytes)) as Map<String, dynamic>;
      } else {
        CurrentLogMessage.add(
          'fetchOrganizationSettings C_Location: ${locResp.statusCode}, ${locResp.body}',
          level: 'ERROR',
          tag: 'fetchOrganizationSettings',
        );
      }
    }

    final visualAddress =
        locationRecord?['identifier']?.toString() ??
        locationRecord?['Address1']?.toString() ??
        '';

    return {
      'adOrgId': orgRecord['id'],
      'cLocationId': locationRecord?['id'] ?? locationId,
      'name': orgRecord['Name']?.toString() ?? '',
      'taxId': infoRecord?['TaxID']?.toString() ?? '',
      'dv': infoRecord?['dv']?.toString() ?? '',
      'phone': infoRecord?['Phone2']?.toString() ?? '',
      'email': infoRecord?['EMail']?.toString() ?? '',
      'countryId': locationRecord?['C_Country_ID']?['id'],
      'cityId': locationRecord?['C_City_ID']?['id'],
      'cityName': locationRecord?['City']?.toString() ?? '',
      'address1': locationRecord?['Address1']?.toString() ?? '',
      'visualAddress': visualAddress.trim().replaceAll(',', '').isEmpty
          ? (locationRecord?['Address1']?.toString() ?? '')
          : visualAddress,
    };
  } catch (e) {
    CurrentLogMessage.add(
      'Excepcion en fetchOrganizationSettings: $e',
      level: 'ERROR',
      tag: 'fetchOrganizationSettings',
    );
  }

  return null;
}

Future<Map<String, dynamic>?> _fetchOrgInfoByOrgId(int organizationId) async {
  final infoResp = await get(
    Uri.parse('${EndPoints.adOrgInfo}?\$filter=AD_Org_ID eq $organizationId'),
    headers: _headers(),
  );

  if (infoResp.statusCode == 200) {
    final infoData = json.decode(utf8.decode(infoResp.bodyBytes));
    final infoRecords = (infoData['records'] as List?) ?? [];
    if (infoRecords.isNotEmpty && infoRecords.first is Map<String, dynamic>) {
      return infoRecords.first as Map<String, dynamic>;
    }
  } else {
    CurrentLogMessage.add(
      'fetchOrganizationSettings AD_OrgInfo: ${infoResp.statusCode}, ${infoResp.body}',
      level: 'ERROR',
      tag: 'fetchOrganizationSettings',
    );
  }

  return null;
}

Future<String?> _resolveOrgInfoUU() async {
  if (Token.adOrgInfoUU != null && Token.adOrgInfoUU!.trim().isNotEmpty) {
    return Token.adOrgInfoUU;
  }

  final organizationId = Token.organitation;
  if (organizationId == null || organizationId == 0) return null;

  final infoRecord = await _fetchOrgInfoByOrgId(organizationId);
  Token.adOrgInfoUU = infoRecord?['uid']?.toString();
  return Token.adOrgInfoUU;
}

Future<bool> updateOrgLogo({
  required Uint8List fileBytes,
  required BuildContext context,
}) async {
  try {
    await usuarioAuth(context: context);

    if (Token.organitation == null || Token.organitation == 0) {
      CurrentLogMessage.add(
        'updateOrgLogo: intento de guardar en Org 0 o token nulo',
        level: 'ERROR',
        tag: 'updateOrgLogo',
      );
      return false;
    }

    final orgInfoUU = await _resolveOrgInfoUU();
    if (orgInfoUU == null || orgInfoUU.trim().isEmpty) {
      CurrentLogMessage.add(
        'updateOrgLogo: OrgInfo uid no encontrado',
        level: 'ERROR',
        tag: 'updateOrgLogo',
      );
      return false;
    }

    final body = jsonEncode({
      'Logo_ID': {'data': base64Encode(fileBytes)},
    });

    final putResp = await put(
      Uri.parse('${EndPoints.adOrgInfo}/$orgInfoUU'),
      headers: _writeHeaders(),
      body: body,
    );
    if (putResp.statusCode == 200 || putResp.statusCode == 204) {
      POSPrinter.isLogoSet = true;
      return true;
    }

    CurrentLogMessage.add(
      'updateOrgLogo PUT: ${putResp.statusCode}, ${putResp.body}',
      level: 'ERROR',
      tag: 'updateOrgLogo',
    );
  } catch (e) {
    CurrentLogMessage.add(
      'Excepcion en updateOrgLogo: $e',
      level: 'ERROR',
      tag: 'updateOrgLogo',
    );
  }

  return false;
}

Future<bool> saveOrganizationSettings({
  required BuildContext context,
  required int? adOrgId,
  required int? cLocationId,
  required String name,
  required String taxId,
  String? dv,
  String? phone,
  String? email,
  required int? countryId,
  required int? cityId,
  required String cityName,
  required String address1,
}) async {
  try {
    await usuarioAuth(context: context);

    var success = true;

    final targetOrgId = adOrgId ?? Token.organitation;
    if (targetOrgId != null) {
      final response = await put(
        Uri.parse('${EndPoints.adOrg}/$targetOrgId'),
        headers: _writeHeaders(),
        body: jsonEncode({'Name': name.trim()}),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        success = false;
        CurrentLogMessage.add(
          'saveOrganizationSettings AD_Org: ${response.statusCode}, ${response.body}',
          level: 'ERROR',
          tag: 'saveOrganizationSettings',
        );
      } else {
        CurrentLogMessage.add(
          'saveOrganizationSettings AD_Org OK: ${response.statusCode}, id=$targetOrgId',
          tag: 'saveOrganizationSettings',
        );
      }
    } else {
      success = false;
      CurrentLogMessage.add(
        'saveOrganizationSettings AD_Org: id nulo, no se actualizo Name',
        level: 'ERROR',
        tag: 'saveOrganizationSettings',
      );
    }

    final orgInfoUU = await _resolveOrgInfoUU();
    if (orgInfoUU != null && orgInfoUU.trim().isNotEmpty) {
      final response = await put(
        Uri.parse('${EndPoints.adOrgInfo}/$orgInfoUU'),
        headers: _writeHeaders(),
        body: jsonEncode({
          'TaxID': taxId.trim(),
          if (dv != null && dv.trim().isNotEmpty) 'dv': dv.trim(),
          if (phone != null && phone.trim().isNotEmpty) 'Phone2': phone.trim(),
          if (email != null && email.trim().isNotEmpty) 'EMail': email.trim(),
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        success = false;
        CurrentLogMessage.add(
          'saveOrganizationSettings AD_OrgInfo: ${response.statusCode}, ${response.body}',
          level: 'ERROR',
          tag: 'saveOrganizationSettings',
        );
      } else {
        CurrentLogMessage.add(
          'saveOrganizationSettings AD_OrgInfo OK: ${response.statusCode}, uid=$orgInfoUU',
          tag: 'saveOrganizationSettings',
        );
      }
    } else {
      success = false;
      CurrentLogMessage.add(
        'saveOrganizationSettings AD_OrgInfo: uid nulo, no se actualizaron datos fiscales/contacto',
        level: 'ERROR',
        tag: 'saveOrganizationSettings',
      );
    }

    if (cLocationId != null) {
      final response = await put(
        Uri.parse('${EndPoints.cLocation}/$cLocationId'),
        headers: _writeHeaders(),
        body: jsonEncode({
          if (countryId != null) 'C_Country_ID': {'id': countryId},
          if (cityId != null) 'C_City_ID': {'id': cityId},
          'City': cityName.trim(),
          'Address1': address1.trim(),
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        success = false;
        CurrentLogMessage.add(
          'saveOrganizationSettings C_Location: ${response.statusCode}, ${response.body}',
          level: 'ERROR',
          tag: 'saveOrganizationSettings',
        );
      }
    }

    return success;
  } catch (e) {
    CurrentLogMessage.add(
      'Excepcion en saveOrganizationSettings: $e',
      level: 'ERROR',
      tag: 'saveOrganizationSettings',
    );
    return false;
  }
}
