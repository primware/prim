import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../../../API/endpoint.dart';
import '../../../API/token.api.dart';
import '../../Auth/auth_funtions.dart';

Future<Map<String, double>> fetchSalesYTDData({
  required BuildContext context,
}) async {
  try {
    await usuarioAuth(context: context);

    final chartUrl = Charts.salesYTD;
    if (chartUrl == null) {
      return {};
    }

    final response = await get(
      Uri.parse(chartUrl),
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

      final key =
          '${date.year.toString()}-${date.month.toString().padLeft(2, '0')}';
      groupedTotals[key] = (groupedTotals[key] ?? 0) + yNum.toDouble();
    }

    final sortedKeys = groupedTotals.keys.toList()
      ..sort((a, b) {
        final aParts = a.split('-');
        final bParts = b.split('-');
        final aDate = DateTime(int.parse(aParts[0]), int.parse(aParts[1]));
        final bDate = DateTime(int.parse(bParts[0]), int.parse(bParts[1]));
        return aDate.compareTo(bDate);
      });

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
  int monthOffset = 0,
}) async {
  try {
    await usuarioAuth(context: context);

    final chartUrl = Charts.salesPerDay;
    if (chartUrl == null) {
      return {};
    }

    final response = await get(
      Uri.parse(chartUrl),
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

    final now = DateTime.now();
    final targetDate = DateTime(now.year, now.month + monthOffset, 1);
    final targetMonthKey =
        '${targetDate.year.toString().padLeft(4, '0')}-${targetDate.month.toString().padLeft(2, '0')}';

    final Map<String, double> totalsByDate = {};

    for (final item in data) {
      final String? xStr = item['x']?.toString();
      final num? yNum = item['y'] is num
          ? item['y'] as num
          : num.tryParse(item['y']?.toString() ?? '');
      final String? series = item['series']?.toString();
      if (xStr == null ||
          yNum == null ||
          series == null ||
          series.trim().isEmpty) {
        continue;
      }

      DateTime? dt;
      try {
        dt = DateTime.parse(xStr.replaceFirst(' ', 'T'));
      } catch (_) {
        try {
          dt = DateTime.parse(xStr.split(' ').first);
        } catch (e) {
          debugPrint('No se pudo parsear fecha x="$xStr": $e');
          continue;
        }
      }

      final itemMonthKey =
          '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}';
      if (itemMonthKey != targetMonthKey) continue;

      final dOnly = DateTime(dt.year, dt.month, dt.day);
      final storageKey =
          '${dOnly.year.toString().padLeft(4, '0')}-'
          '${dOnly.month.toString().padLeft(2, '0')}-'
          '${dOnly.day.toString().padLeft(2, '0')}';

      totalsByDate[storageKey] =
          (totalsByDate[storageKey] ?? 0) + yNum.toDouble();
    }

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

Future<Map<String, double>> fetchSalesYTDBySalesRepCurrentMonth({
  required BuildContext context,
  int monthOffset = 0,
}) async {
  try {
    await usuarioAuth(context: context);

    final chartUrl = Charts.salesYTDBySalesRep;
    if (chartUrl == null) {
      return {};
    }

    final response = await get(
      Uri.parse(chartUrl),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode != 200) {
      debugPrint(
        'Error al obtener datos del gráfico Sales YTD By SalesRep (status ${response.statusCode}): ${response.body}',
      );
      return {};
    }

    final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
    final List data = (jsonResponse['data'] as List?) ?? [];

    final now = DateTime.now();
    final targetDate = DateTime(now.year, now.month + monthOffset, 1);
    final currentMonthKey =
        '${targetDate.year.toString().padLeft(4, '0')}-${targetDate.month.toString().padLeft(2, '0')}';

    final Map<String, double> salesByRep = {};

    for (final item in data) {
      final String? salesRep = item['row']?.toString();
      final String? columnDate = item['column']?.toString();
      final dynamic rawValue = item['value'];

      if (salesRep == null ||
          salesRep.trim().isEmpty ||
          columnDate == null ||
          columnDate.trim().isEmpty ||
          rawValue == null) {
        continue;
      }

      final num? value = rawValue is num
          ? rawValue
          : num.tryParse(rawValue.toString());
      if (value == null) continue;

      DateTime? parsedDate;
      try {
        parsedDate = DateTime.parse(columnDate.replaceFirst(' ', 'T'));
      } catch (_) {
        try {
          parsedDate = DateTime.parse(columnDate.split(' ').first);
        } catch (e) {
          debugPrint('No se pudo parsear fecha column="$columnDate": $e');
          continue;
        }
      }

      final itemMonthKey =
          '${parsedDate.year.toString().padLeft(4, '0')}-${parsedDate.month.toString().padLeft(2, '0')}';
      if (itemMonthKey != currentMonthKey) continue;

      salesByRep[salesRep] = (salesByRep[salesRep] ?? 0) + value.toDouble();
    }

    final orderedEntries = salesByRep.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {for (final entry in orderedEntries) entry.key: entry.value};
  } catch (e) {
    debugPrint('Error en fetchSalesYTDBySalesRepCurrentMonth: $e');
    return {};
  }
}

Future<Map<String, double>> fetchSalesPerDayByProductCategory({
  required BuildContext context,
  int dayOffset = 0,
}) async {
  try {
    await usuarioAuth(context: context);

    final chartUrl = Charts.salesPerDayByProductCategory;
    if (chartUrl == null) {
      return {};
    }

    final response = await get(
      Uri.parse(chartUrl),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode != 200) {
      CurrentLogMessage.add(
        'Error fetchSalesPerDayByProductCategory: ${response.statusCode}, ${response.body}',
        level: 'ERROR',
        tag: 'fetchSalesPerDayByProductCategory',
      );
      debugPrint(
        'Error al obtener datos del gráfico Sales Per Day By Product Category '
        '(status ${response.statusCode}): ${response.body}',
      );
      return {};
    }

    final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
    final List data = (jsonResponse['data'] as List?) ?? [];

    final now = DateTime.now();
    final targetDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: dayOffset));

    final Map<String, double> salesByCategory = {};

    for (final item in data) {
      final String? categoryName = item['row']?.toString();
      final String? columnDate = item['column']?.toString();
      final dynamic rawValue = item['value'];

      if (categoryName == null ||
          categoryName.trim().isEmpty ||
          columnDate == null ||
          columnDate.trim().isEmpty ||
          rawValue == null) {
        continue;
      }

      final num? value = rawValue is num
          ? rawValue
          : num.tryParse(rawValue.toString());
      if (value == null) continue;

      DateTime? parsedDate;
      try {
        parsedDate = DateTime.parse(columnDate.replaceFirst(' ', 'T'));
      } catch (_) {
        try {
          parsedDate = DateTime.parse(columnDate.split('').first);
        } catch (e) {
          debugPrint('No se pudo parsear fecha column="$columnDate": $e');
          continue;
        }
      }

      final itemDate = DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
      );

      if (itemDate.year != targetDate.year ||
          itemDate.month != targetDate.month ||
          itemDate.day != targetDate.day) {
        continue;
      }

      salesByCategory[categoryName] =
          (salesByCategory[categoryName] ?? 0) + value.toDouble();
    }

    final orderedEntries = salesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {for (final entry in orderedEntries) entry.key: entry.value};
  } catch (e) {
    CurrentLogMessage.add(
      'Excepción en fetchSalesPerDayByProductCategory: $e',
      level: 'ERROR',
      tag: 'fetchSalesPerDayByProductCategory',
    );
    debugPrint('Error en fetchSalesPerDayByProductCategory: $e');
    return {};
  }
}
