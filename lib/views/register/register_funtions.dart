// ignore_for_file: avoid_print, use_build_context_synchronously, depend_on_referenced_packages

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../API/endpoint.api.dart';
import '../../API/token.api.dart';

Future<List<Map<String, dynamic>>> fetchCurrency() async {
  try {
    final response = await http.get(
      Uri.parse(EndPoints.currency),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.tokenRegister,
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      final records = jsonResponse['records'] as List;
      return records.map((record) {
        return {
          'id': record['id'],
          'name': record['ISO_Code'],
        };
      }).toList();
    } else {
      throw Exception('Error al cargar las monedas');
    }
  } catch (e) {
    print('Excepción al obtener monedas: $e');
    return [];
  }
}

Future<List<Map<String, dynamic>>> fetchCountry() async {
  try {
    final response = await http.get(
      Uri.parse(EndPoints.country),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.tokenRegister,
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      final records = jsonResponse['records'] as List;
      return records.map((record) {
        return {
          'id': record['id'],
          'name': record['Name'],
        };
      }).toList();
    } else {
      throw Exception('Error al cargar los paises');
    }
  } catch (e) {
    print('Excepción al obtener paises: $e');
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
