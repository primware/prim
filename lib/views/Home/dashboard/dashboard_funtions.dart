import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../../../API/endpoint.api.dart';
import '../../../API/pos.api.dart';
import '../../../API/token.api.dart';
import '../../Auth/auth_funtions.dart';

Future<Map<String, double>> fetchSalesChartData({
  required BuildContext context,
}) async {
  try {
    await usuarioAuth(context: context);

    final response = await get(
      Uri.parse(EndPoints.salesYTDMonthly),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode != 200) {
      debugPrint(
          'Error al obtener datos del gráfico mensual (status ${response.statusCode}): ${response.body}');
      return {};
    }

    final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
    final List data = (jsonResponse['data'] as List?) ?? [];

    // Abreviaturas de meses "como hasta ahora" (ajusta si usabas otro idioma/formato)
    const monthNames = <String>[
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];

    final Map<String, double> groupedTotals = {};

    for (final item in data) {
      final String? x = item['x']?.toString();
      final num? yNum = item['y'] is num
          ? item['y'] as num
          : num.tryParse(item['y']?.toString() ?? '');
      if (x == null || yNum == null) continue;

      DateTime? date;
      try {
        // Permite "YYYY-MM-DD HH:mm:ss"
        date = DateTime.parse(x.replaceFirst(' ', 'T'));
      } catch (_) {
        // Intento alterno: solo fecha
        try {
          date = DateTime.parse(x.split(' ').first);
        } catch (e) {
          debugPrint('No se pudo parsear fecha x="$x": $e');
          continue;
        }
      }

      final monthIndex = date.month - 1;
      final String key = monthIndex >= 0 && monthIndex < 12
          ? monthNames[monthIndex]
          : '${date.month}';

      final double val = yNum.toDouble();
      groupedTotals[key] = (groupedTotals[key] ?? 0) + val;
    }

    return groupedTotals;
  } catch (e) {
    debugPrint('Error en fetchSalesChartData (mensual): $e');
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
