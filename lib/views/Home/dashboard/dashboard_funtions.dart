import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../../../API/endpoint.api.dart';
import '../../../API/token.api.dart';
import '../../../API/user.api.dart';
import '../../Auth/auth_funtions.dart';

Future<Map<String, double>> fetchSalesChartData({
  required BuildContext context,
  String groupBy = 'month',
}) async {
  try {
    await usuarioAuth(context: context);
    final response = await get(
      Uri.parse(
          '${EndPoints.cOrder}?\$filter=SalesRep_ID eq ${UserData.id} and DocStatus eq \'CO\'&\$orderby=DateOrdered desc'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      final List records = jsonResponse['records'];

      final now = DateTime.now();

      final Map<String, double> groupedTotals = {};
      for (var record in records) {
        final date = DateTime.parse(record['DateOrdered']);

        if (groupBy == 'month' && date.year != now.year) {
          continue;
        }
        if (groupBy == 'day' &&
            (date.year != now.year || date.month != now.month)) {
          continue;
        }

        final key = groupBy == 'day'
            ? '${date.year}-${date.month}-${date.day}'
            : '${date.year}-${date.month}';

        groupedTotals[key] =
            (groupedTotals[key] ?? 0) + (record['GrandTotal'] ?? 0);
      }
      return groupedTotals;
    } else {
      debugPrint('Error al obtener datos de ventas: ${response.body}');
      return {};
    }
  } catch (e) {
    debugPrint('Error de red en fetchSalesChartData: $e');
    return {};
  }
}
