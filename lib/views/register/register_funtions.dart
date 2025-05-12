// ignore_for_file: avoid_print, use_build_context_synchronously, depend_on_referenced_packages

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../API/endpoint.api.dart';
import '../../API/token.api.dart';

Future<List<Map<String, dynamic>>> fetchCurrency() async {
  List<Map<String, dynamic>> allCurrencys = [];
  int skip = 0;
  int totalCount = 0;

  const int pageSize = 100;

  try {
    do {
      final response = await http.get(
        Uri.parse(
            '${EndPoints.cCurrency}?\$skip=$skip&\$select=ISO_Code&\$orderby=Name'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': Token.tokenRegister,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        final records = jsonResponse['records'] as List;
        totalCount = jsonResponse['row-count'] ?? 0;

        final mapped = records.map((record) {
          return {
            'id': record['id'],
            'name': record['ISO_Code'],
          };
        }).toList();

        allCurrencys.addAll(mapped);
        skip += pageSize;
      } else {
        throw Exception(
            'Error al cargar las monedas (status ${response.statusCode})');
      }
    } while (skip < totalCount);

    return allCurrencys;
  } catch (e) {
    print('Excepción al obtener monedas: $e');
    return [];
  }
}

Future<List<Map<String, dynamic>>> fetchCountry() async {
  List<Map<String, dynamic>> allCountries = [];
  int skip = 0;
  int totalCount = 0;

  const int pageSize = 100;

  try {
    do {
      final response = await http.get(
        Uri.parse(
            '${EndPoints.cCountry}?\$skip=$skip&\$select=Name,CountryCode&\$orderby=Name'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': Token.tokenRegister,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        final records = jsonResponse['records'] as List;
        totalCount = jsonResponse['row-count'] ?? 0;

        final mapped = records.map((record) {
          return {
            'id': record['id'],
            'name': record['Name'],
            'CountryCode': record['CountryCode'],
          };
        }).toList();

        allCountries.addAll(mapped);
        skip += pageSize;
      } else {
        throw Exception(
            'Error al cargar los países (status ${response.statusCode})');
      }
    } while (skip < totalCount);

    return allCountries;
  } catch (e) {
    print('Excepción al obtener países: $e');
    return [];
  }
}

Future<Map<String, dynamic>> postNewTenant({
  required String clientName,
  required String orgValue,
  required String orgName,
  required String adminUserName,
  required String adminUserEmail,
  required String normalUserName,
  required int currencyID,
  required int countryID,
}) async {
  try {
    final Map<String, dynamic> data = {
      "ClientName": clientName,
      "OrgValue": orgValue,
      "OrgName": orgName,
      "AdminUserName": adminUserName,
      "AdminUserEmail": adminUserEmail,
      "NormalUserName": normalUserName,
      "IsSetInitialPassword": true,
      "C_Currency_ID": currencyID,
      "C_Country_ID": countryID,
      "UseDefaultCoA": true
    };

    final response = await http.post(
      Uri.parse(EndPoints.initialclientsetup),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.tokenRegister,
      },
      body: jsonEncode(data),
    );

    print(data.toString());

    if (response.statusCode != 200) {
      print('Error: ${response.statusCode}, ${response.body}');
    }
    final jsonResponse = json.decode(response.body);

    return {
      'status': response.statusCode,
      'summary': jsonResponse['summary'] ?? 'No se pudo obtener el resumen',
      'isError': jsonResponse['isError'],
    };
  } catch (e) {
    if (e is http.ClientException) {
      print('Error de cliente: ${e.message}');
      return {
        'status': 500,
        'summary': 'Error: ${e.toString()}',
        'isError': true,
      };
    } else {
      print('Error general: $e');
      return {
        'status': 500,
        'summary': 'Error: ${e.toString()}',
        'isError': true,
      };
    }
  }
}
