import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../../../API/endpoint.api.dart';
import '../../../API/pos.api.dart';
import '../../../API/token.api.dart';
import '../../../API/user.api.dart';
import '../../Auth/auth_funtions.dart';

Future<Map<String, double>> fetchSalesChartData({
  required BuildContext context,
  String groupBy = 'month',
  bool onlyMyOrders = true,
}) async {
  try {
    List<Map<String, dynamic>> allRecords = [];
    int skip = 0;
    int totalCount = 0;

    const int pageSize = 100;

    // Fechas de filtro
    final DateTime now = DateTime.now();
    final DateTime oneYearAgo = now.subtract(const Duration(days: 365));

    await usuarioAuth(context: context);

    do {
      final uri = Uri.parse(
        '${EndPoints.cOrder}?'
        // Filtra por vendedor, documentos completados/cerrados y último año
        '\$filter=${onlyMyOrders ? 'SalesRep_ID eq ${UserData.id} and ' : ''}(DocStatus eq \'CO\' or DocStatus eq \'CL\') and DateOrdered gt \'$oneYearAgo\''
        // Ordenar por fecha para consistencia
        '&\$orderby=DateOrdered'
        // Traer solo los campos necesarios para agrupar y sumar
        '&\$select=DateOrdered,GrandTotal'
        // Paginación
        '&\$skip=$skip',
      );

      final response = await get(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': Token.auth!,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        final List records = (jsonResponse['records'] as List?) ?? [];
        totalCount = jsonResponse['row-count'] ?? 0;

        // Normaliza/asegura el shape de cada registro que usaremos luego
        for (final r in records) {
          allRecords.add({
            'DateOrdered': r['DateOrdered'],
            'GrandTotal': (r['GrandTotal'] ?? 0),
          });
        }

        skip += pageSize;
        print('Fetched ${allRecords.length}/$totalCount sales records...');
      } else {
        debugPrint(
            'Error al obtener datos de ventas (status ${response.statusCode}): ${response.body}');
        return {};
      }
    } while (skip < totalCount);

    // Agrupar totales según `groupBy`
    final Map<String, double> groupedTotals = {};
    for (final record in allRecords) {
      final date = DateTime.parse(record['DateOrdered']);

      // Filtro adicional por periodo visible (mes/año actual si aplica)
      if (groupBy == 'month') {
        if (date.year != now.year) continue;
      } else if (groupBy == 'day') {
        if (date.year != now.year || date.month != now.month) continue;
      }

      final key = groupBy == 'day'
          ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
          : '${date.year}-${date.month.toString().padLeft(2, '0')}';

      final double amount = (record['GrandTotal'] is num)
          ? (record['GrandTotal'] as num).toDouble()
          : 0.0;

      groupedTotals[key] = (groupedTotals[key] ?? 0) + amount;
    }

    return groupedTotals;
  } catch (e) {
    debugPrint('Error de red en fetchSalesChartData: $e');
    return {};
  }
}

Future<bool> updateOrgLogo(Uint8List fileBytes, BuildContext context) async {
  try {
    final getResp = await get(
      Uri.parse(
          '${EndPoints.adOrgInfo}?\$filter=AD_Org_ID eq ${Token.organitation}'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.auth!,
      },
    );
    if (getResp.statusCode != 200) {
      CurrentLogMessage.add(
          'updateOrgLogo GET OrgInfo: ${getResp.statusCode}, ${getResp.body}',
          level: 'ERROR',
          tag: 'updateOrgLogo');
      return false;
    }
    final getJson = json.decode(utf8.decode(getResp.bodyBytes));
    if (getJson['records'] == null || (getJson['records'] as List).isEmpty) {
      CurrentLogMessage.add('updateOrgLogo: OrgInfo no encontrado',
          level: 'ERROR', tag: 'updateOrgLogo');
      return false;
    }
    final int orgInfoId = getJson['records'][0]['id'];

    // 2) Hacer PUT con el Logo_ID en base64 (mismo formato que recibimos)
    final String b64 = base64Encode(fileBytes);
    final body = jsonEncode({
      'Logo_ID': {'data': b64}
    });
    final putResp = await put(
      Uri.parse('${EndPoints.adOrgInfo}/$orgInfoId'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.auth!,
      },
      body: body,
    );
    if (putResp.statusCode == 200 || putResp.statusCode == 204) {
      POSPrinter.isLogoSet = true;
      return true;
    } else {
      CurrentLogMessage.add(
          'updateOrgLogo PUT: ${putResp.statusCode}, ${putResp.body}',
          level: 'ERROR',
          tag: 'updateOrgLogo');
    }
  } catch (e) {
    CurrentLogMessage.add('Excepción en updateOrgLogo: $e',
        level: 'ERROR', tag: 'updateOrgLogo');
    if (e is ClientException) {
      handle401(context);
    }
  }
  return false;
}
