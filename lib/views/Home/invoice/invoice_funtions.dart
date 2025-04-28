import 'package:flutter/material.dart';
import 'package:primware/views/Auth/login_view.dart';
import '../../../API/endpoint.api.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../API/token.api.dart';
import '../../Auth/auth_funtions.dart';

Future<List<Map<String, dynamic>>> fetchBPartner(
    {required BuildContext context}) async {
  try {
    await usuarioAuth(
      usuario: usuarioController.text.trim(),
      clave: claveController.text.trim(),
      context: context,
    );
    final response = await http.get(
      Uri.parse('${EndPoints.partner}?\$filter=IsCustomer eq true'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.auth!,
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
      throw Exception('Error al cargar los terceros: ${response.statusCode}');
    }
  } catch (e) {
    print('Excepción al obtener terceros: $e');
    return [];
  }
}

Future<List<Map<String, dynamic>>> fetchProduct(
    {required BuildContext context}) async {
  try {
    await usuarioAuth(
      usuario: usuarioController.text.trim(),
      clave: claveController.text.trim(),
      context: context,
    );
    final response = await http.get(
      Uri.parse(
          '${EndPoints.product}?\$select=Name,SKU&\$expand=M_ProductPrice(\$select=PriceStd)'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      final records = jsonResponse['records'] as List;
      return records.map((record) {
        return {
          'id': record['id'],
          'name': record['Name'],
          'sku': record['SKU'],
          'price': record['M_ProductPrice'] != null &&
                  record['M_ProductPrice'].isNotEmpty
              ? record['M_ProductPrice'][0]['PriceStd']
              : null,
        };
      }).toList();
    } else {
      throw Exception('Error al cargar los productos: ${response.statusCode}');
    }
  } catch (e) {
    print('Excepción al obtener productos: $e');
    return [];
  }
}
