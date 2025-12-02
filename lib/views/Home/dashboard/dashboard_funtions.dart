import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../../../API/endpoint.api.dart';
import '../../../API/pos.api.dart';
import '../../../API/token.api.dart';
import '../../Auth/auth_funtions.dart';

Future<Map<String, double>> fetchSalesYTDData({
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
        'Error al obtener datos del gráfico mensual (status ${response.statusCode}): ${response.body}',
      );
      return {};
    }

    final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
    final List data = (jsonResponse['data'] as List?) ?? [];

    // Nombres de meses abreviados
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
      'Dic',
    ];

    // Agrupar totales por año+mes
    final Map<String, double> groupedTotals = {};

    for (final item in data) {
      final String? x = item['x']?.toString();
      final num? yNum = item['y'] is num
          ? item['y'] as num
          : num.tryParse(item['y']?.toString() ?? '');
      if (x == null || yNum == null) continue;

      DateTime? date;
      try {
        date = DateTime.parse(x.replaceFirst(' ', 'T'));
      } catch (_) {
        try {
          date = DateTime.parse(x.split(' ').first);
        } catch (e) {
          debugPrint('No se pudo parsear fecha x="$x": $e');
          continue;
        }
      }

      final int year = date.year;
      final int month = date.month;
      final double val = yNum.toDouble();

      // clave única por año y mes
      final key = '${year.toString()}-${month.toString().padLeft(2, '0')}';
      groupedTotals[key] = (groupedTotals[key] ?? 0) + val;
    }

    // Ordenar cronológicamente (por año y mes)
    final sortedKeys = groupedTotals.keys.toList()
      ..sort((a, b) {
        final aParts = a.split('-');
        final bParts = b.split('-');
        final aDate = DateTime(int.parse(aParts[0]), int.parse(aParts[1]));
        final bDate = DateTime(int.parse(bParts[0]), int.parse(bParts[1]));
        return aDate.compareTo(bDate);
      });

    // Construir resultado final con etiquetas "Mes aa"
    final Map<String, double> orderedTotals = {};
    for (final key in sortedKeys) {
      final parts = key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final label = '${monthNames[month - 1]} ${year.toString().substring(2)}';
      orderedTotals[label] = groupedTotals[key]!;
    }

    return orderedTotals;
  } catch (e) {
    debugPrint('Error en fetchSalesYTDData: $e');
    return {};
  }
}

Future<Map<String, double>> fetchSalesPerDay({
  required BuildContext context,
}) async {
  try {
    await usuarioAuth(context: context);

    final response = await get(
      Uri.parse(EndPoints.salesPerDay),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode != 200) {
      debugPrint(
        'Error al obtener datos del gráfico por día (status ${response.statusCode}): ${response.body}',
      );
      return {};
    }

    final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
    final List data = (jsonResponse['data'] as List?) ?? [];

    // yyyy-MM-dd -> total
    final Map<String, double> totalsByDate = {};

    for (final item in data) {
      final String? xStr = item['x']?.toString();
      final num? yNum = item['y'] is num
          ? item['y'] as num
          : num.tryParse(item['y']?.toString() ?? '');
      if (xStr == null || yNum == null) continue;

      DateTime? dt;
      try {
        // Intenta "YYYY-MM-DD HH:mm:ss"
        dt = DateTime.parse(xStr.replaceFirst(' ', 'T'));
      } catch (_) {
        try {
          // Alternativa: solo fecha "YYYY-MM-DD"
          dt = DateTime.parse(xStr.split(' ').first);
        } catch (e) {
          debugPrint('No se pudo parsear fecha x="$xStr": $e');
          continue;
        }
      }

      // Normaliza a solo la fecha
      final dOnly = DateTime(dt.year, dt.month, dt.day);
      final storageKey =
          '${dOnly.year.toString().padLeft(4, '0')}-'
          '${dOnly.month.toString().padLeft(2, '0')}-'
          '${dOnly.day.toString().padLeft(2, '0')}';

      totalsByDate[storageKey] =
          (totalsByDate[storageKey] ?? 0) + yNum.toDouble();
    }

    // Nombres de meses para la etiqueta
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
      'Dic',
    ];

    // Ordena TODAS las fechas disponibles de menor a mayor
    final List<DateTime> sortedDates =
        totalsByDate.keys
            .map((k) {
              try {
                final parts = k.split('-');
                return DateTime(
                  int.parse(parts[0]),
                  int.parse(parts[1]),
                  int.parse(parts[2]),
                );
              } catch (_) {
                return null;
              }
            })
            .whereType<DateTime>()
            .toList()
          ..sort((a, b) => a.compareTo(b));

    // Construye el mapa ordenado sin limitar cantidad
    final Map<String, double> ordered = {};
    for (final d in sortedDates) {
      final storageKey =
          '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
      final label =
          '${d.day.toString().padLeft(2, '0')} ${monthNames[d.month - 1]}';
      ordered[label] = totalsByDate[storageKey] ?? 0.0;
    }

    return ordered;
  } catch (e) {
    debugPrint('Error en fetchSalesPerDay: $e');
    return {};
  }
}

Future<bool> updateOrgLogo(Uint8List fileBytes, BuildContext context) async {
  try {
    final getResp = await get(
      Uri.parse(
        '${EndPoints.adOrgInfo}?\$filter=AD_Org_ID eq ${Token.organitation}',
      ),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.auth!,
      },
    );
    if (getResp.statusCode != 200) {
      CurrentLogMessage.add(
        'updateOrgLogo GET OrgInfo: ${getResp.statusCode}, ${getResp.body}',
        level: 'ERROR',
        tag: 'updateOrgLogo',
      );
      return false;
    }
    final getJson = json.decode(utf8.decode(getResp.bodyBytes));
    if (getJson['records'] == null || (getJson['records'] as List).isEmpty) {
      CurrentLogMessage.add(
        'updateOrgLogo: OrgInfo no encontrado',
        level: 'ERROR',
        tag: 'updateOrgLogo',
      );
      return false;
    }
    final int orgInfoId = getJson['records'][0]['id'] ?? Token.organitation;

    // 2) Hacer PUT con el Logo_ID en base64 (mismo formato que recibimos)
    final String b64 = base64Encode(fileBytes);
    final body = jsonEncode({
      'Logo_ID': {'data': b64},
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
        tag: 'updateOrgLogo',
      );
    }
  } catch (e) {
    CurrentLogMessage.add(
      'Excepción en updateOrgLogo: $e',
      level: 'ERROR',
      tag: 'updateOrgLogo',
    );
    if (e is ClientException) {
      handle401(context);
    }
  }
  return false;
}
