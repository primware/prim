import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import '../../../API/endpoint.dart';
import 'close_cash_dates.dart';
import '../../../API/token.api.dart';
import '../../../API/user.api.dart';
import '../../Auth/auth_funtions.dart';

Future<List<Map<String, dynamic>>> fetchRecords({required BuildContext context, String? filter, bool onlyMyRecords = true}) async {
  try {
    await usuarioAuth(context: context);

    filter = onlyMyRecords == true ? 'SalesRep_ID eq ${UserData.id}' : '';

    final response = await get(
      Uri.parse('${EndPoints.cdsCloseCash}?\$filter=$filter&\$orderby=DateTrx desc&\$expand=CDS_CloseCash_Line'),
      headers: {'Content-Type': 'application/json; charset=UTF-8', 'Authorization': Token.auth!},
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      final List records = jsonResponse['records'];

      return records.map((record) {
        return {
          'id': record['id'],
          'Created': record['Created'],
          'DateFrom': record['DateFrom'],
          'DateTrx': record['DateTrx'],
          'GrandTotal': record['GrandTotal'],
          'TotalOrders': record['CDS_QtyOrder'] + record['CDS_QtyRefund'],

          'C_POS_ID': {'id': record['C_POS_ID']?['id'], 'name': record['C_POS_ID']?['identifier']},
          'SalesRep_ID': {'id': record['SalesRep_ID']?['id'], 'name': record['SalesRep_ID']?['identifier']},
          'CDS_CloseCash_Line': record['CDS_CloseCash_Line'] ?? [],
          'DocStatus': record['DocStatus']['id'],
        };
      }).toList();
    } else {
      debugPrint('Error al obtener Cierre de cajas: ${response.body}');
      return [];
    }
  } catch (e) {
    debugPrint('Error de red en fetchRecords: $e');
    return [];
  }
}

Future<Map<String, dynamic>?> fetchCloseCash({required BuildContext context, required int closeCashId}) async {
  try {
    await usuarioAuth(context: context);

    final response = await get(
      Uri.parse('${EndPoints.cdsCloseCash}?\$filter=id eq $closeCashId&\$orderby=DateTrx desc&\$expand=CDS_CloseCash_Line'),
      headers: {'Content-Type': 'application/json; charset=UTF-8', 'Authorization': Token.auth!},
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      final List records = jsonResponse['records'] ?? [];

      if (records.isEmpty) {
        return null;
      }

      final record = records.first as Map<String, dynamic>;

      // Fallback de vendedor: si no viene SalesRep_ID, usamos CreatedBy
      final Map<String, dynamic>? salesRep =
          (record['SalesRep_ID'] as Map<String, dynamic>?) ?? (record['CreatedBy'] as Map<String, dynamic>?);

      final List<dynamic> lines = (record['CDS_CloseCash_Line'] ?? []) as List;

      final payments = lines.map((l) {
        final line = l as Map<String, dynamic>;
        return {
          'C_POSTenderType_ID': {'id': line['C_POSTenderType_ID']?['id'], 'identifier': line['C_POSTenderType_ID']?['identifier']},
          'PayAmt': line['PayAmt'] ?? 0,
          'C_DocType_ID': {'id': line['C_DocType_ID']?['id'], 'identifier': line['C_DocType_ID']?['identifier']},
        };
      }).toList();

      final int qtyOrder = (record['CDS_QtyOrder'] ?? 0) as int;
      final int qtyRefund = (record['CDS_QtyRefund'] ?? 0) as int;

      return {
        'id': record['id'],
        'Created': record['Created'],
        'DateFrom': record['DateFrom'],
        'DateTrx': record['DateTrx'],
        'IsActive': record['IsActive'] ?? true,
        'Processed': record['Processed'] ?? false,
        'GrandTotal': record['GrandTotal'] ?? 0,

        // Cantidades
        'QtyOrders': qtyOrder,
        'QtyReturns': qtyRefund,
        'TotalOrders': qtyOrder + qtyRefund,

        // Órdenes
        'TaxBaseAmt': record['CDS_TaxBaseAmt'] ?? 0,
        'TaxAmt': record['CDS_TaxAmt'] ?? 0,
        'ExemptAmt': record['CDS_TotalExemptOrders'] ?? 0,
        'TotalOrdersAmt': record['CDS_TotalOrders'] ?? record['GrandTotal'] ?? 0,

        // Devoluciones
        'ReturnTaxBaseAmt': record['CDS_TaxBaseAmtRefund'] ?? 0,
        'ReturnTaxAmt': record['CDS_TaxAmtRefund'] ?? 0,
        'ReturnExemptAmt': record['CDS_TotalExemptRefund'] ?? 0,
        'TotalReturnsAmt': record['CDS_TotalRefund'] ?? 0,

        // Referencias
        'C_POS_ID': {'id': record['C_POS_ID']?['id'], 'name': record['C_POS_ID']?['identifier']},
        'SalesRep_ID': {'id': salesRep?['id'], 'name': salesRep?['identifier']},
        'DocStatus': record['DocStatus']?['id'],

        // Líneas (raw)
        'CDS_CloseCash_Line': lines,

        // Líneas normalizadas para UI
        'payments': payments,
      };
    } else {
      debugPrint('Error al obtener detalle Cierre de caja: ${response.body}');
      return null;
    }
  } catch (e) {
    debugPrint('Error de red en fetchCloseCashDetailById: $e');
    return null;
  }
}

Future<Map<String, dynamic>> postNewCloseCash({
  int? salesRepID,
  required int terminalID,
  required String dateTrx,
  required BuildContext context,
}) async {
  try {
    await usuarioAuth(context: context);
    final String dateTrxIso = formatCloseCashDateForApi(dateTrx);

    final Map<String, dynamic> data = {
      if (salesRepID != null) "SalesRep_ID": {"id": salesRepID},
      "C_POS_ID": {"id": terminalID},
      "DateTrx": dateTrxIso,
    };

    final response = await post(
      Uri.parse(EndPoints.cdsCloseCash),
      headers: {'Content-Type': 'application/json', 'Authorization': Token.auth!},
      body: jsonEncode(data),
    );

    if (response.statusCode != 201) {
      CurrentLogMessage.add('Error al crear y completar el cierre de caja: ${response.body}', level: 'ERROR', tag: 'postInvoice');

      return {'success': false, 'message': 'Error al crear y completar el cierre de caja.'};
    }

    final Map<String, dynamic> jsonData = jsonDecode(utf8.decode(response.bodyBytes));
    final int? closeCashId = jsonData['id'] as int?;
    if (closeCashId == null) {
      return {'success': false, 'message': 'El servidor creó el cierre sin devolver su identificador.'};
    }

    final processResult = await refreshCloseCash(cdsCloseCashID: closeCashId);
    if (processResult['success'] != true) {
      return {
        'success': false,
        'Record_ID': closeCashId,
        'message': processResult['message'] ?? 'El cierre fue creado, pero no se pudo calcular.',
      };
    }

    return {'success': true, 'Record_ID': closeCashId};
  } catch (e) {
    CurrentLogMessage.add('Excepción general: $e', level: 'ERROR', tag: 'postNewCloseCash');
    return {'success': false, 'message': 'Excepción inesperada: $e'};
  }
}

Future<Map<String, dynamic>> refreshCloseCash({required int cdsCloseCashID}) async {
  try {
    // CloseCash.java carga el encabezado mediante CDS_CloseCash_ID y obtiene
    // desde ese registro C_POS_ID, SalesRep_ID, DateTrx y los demás datos.
    final Map<String, dynamic> data = {'CDS_CloseCash_ID': cdsCloseCashID};

    final response = await post(
      Uri.parse(Processes.cdsCloseCashProcess),
      headers: {'Content-Type': 'application/json', 'Authorization': Token.auth!},
      body: jsonEncode(data),
    );

    Map<String, dynamic>? responseData;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) responseData = decoded;
    } catch (_) {
      // El status HTTP todavía permite informar una respuesta no JSON.
    }

    final bool processFailed = responseData?['isError'] == true;
    if (response.statusCode != 200 || processFailed) {
      final message = _processErrorMessage(
        responseData,
        fallback: response.statusCode == 200
            ? 'El proceso no pudo calcular el cierre de caja.'
            : 'Error al ejecutar el proceso de cierre de caja (HTTP ${response.statusCode}).',
      );
      CurrentLogMessage.add('Error al actualizar el cierre de caja: ${response.body}', level: 'ERROR', tag: 'refreshCloseCash');

      return {'success': false, 'message': message};
    }

    return {'success': true, 'message': responseData?['summary']};
  } catch (e) {
    CurrentLogMessage.add('Excepción general: $e', level: 'ERROR', tag: 'refreshCloseCash');
    return {'success': false, 'message': 'Excepción inesperada: $e'};
  }
}

String _processErrorMessage(Map<String, dynamic>? data, {required String fallback}) {
  if (data == null) return fallback;

  for (final key in ['summary', 'message', 'error']) {
    final value = data[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }

  final logs = data['logs'];
  if (logs is List) {
    for (final rawLog in logs.reversed) {
      if (rawLog is Map) {
        for (final key in ['message', 'msg', 'summary']) {
          final value = rawLog[key]?.toString().trim();
          if (value != null && value.isNotEmpty) return value;
        }
      }
    }
  }

  return fallback;
}

Future<Map<String, dynamic>> updateCloseCashStatus({required int cdsCloseCashID}) async {
  try {
    final Map<String, dynamic> data = {"DocStatus": 'CO', "Processed": true};

    final response = await put(
      Uri.parse('${EndPoints.cdsCloseCash}/$cdsCloseCashID'),
      headers: {'Content-Type': 'application/json', 'Authorization': Token.auth!},
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      CurrentLogMessage.add('Error al cerrar el cierre de caja: ${response.body}', level: 'ERROR', tag: 'updateCloseCashStatus');

      return {'success': false, 'message': 'Error al cerrar el cierre de caja.'};
    }

    return {'success': true};
  } catch (e) {
    CurrentLogMessage.add('Excepción general: $e', level: 'ERROR', tag: 'updateCloseCashStatus');
    return {'success': false, 'message': 'Excepción inesperada: $e'};
  }
}

Future<Map<String, dynamic>> updateCloseCashDateTrx({required int cdsCloseCashID}) async {
  try {
    final String nowText = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final String dateTrxIso = formatCloseCashDateForApi(nowText);
    final Map<String, dynamic> data = {"DateTrx": dateTrxIso};

    final response = await put(
      Uri.parse('${EndPoints.cdsCloseCash}/$cdsCloseCashID'),
      headers: {'Content-Type': 'application/json', 'Authorization': Token.auth!},
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      CurrentLogMessage.add('Error al cerrar el cierre de caja: ${response.body}', level: 'ERROR', tag: 'updateCloseCashStatus');

      return {'success': false, 'message': 'Error al cerrar el cierre de caja.'};
    }

    return {'success': true};
  } catch (e) {
    CurrentLogMessage.add('Excepción general: $e', level: 'ERROR', tag: 'updateCloseCashStatus');
    return {'success': false, 'message': 'Excepción inesperada: $e'};
  }
}

Future<int?> currentCloseCash() async {
  final response = await get(
    Uri.parse("${EndPoints.cdsCloseCash}?\$filter=DocStatus eq 'DR' and SalesRep_ID eq ${UserData.id}"),
    headers: {'Content-Type': 'application/json', 'Authorization': Token.auth!},
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final List records = data['records'] ?? [];

    if (records.isEmpty) {
      return null;
    }

    return records.first['id'] as int;
  } else {
    debugPrint('Error al verificar usuario: ${response.statusCode}, ${response.body}');
    return null;
  }
}
