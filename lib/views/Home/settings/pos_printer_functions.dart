import 'dart:convert';
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

Future<Map<String, dynamic>?> fetchPOSPrinterConfig({
  required BuildContext context,
  required int posId,
}) async {
  try {
    await usuarioAuth(context: context);

    final response = await get(
      Uri.parse('${EndPoints.cdsPOSPrinterConfig}?\$filter=C_POS_ID eq $posId'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      final records = (data['records'] as List?) ?? [];
      if (records.isNotEmpty && records.first is Map<String, dynamic>) {
        return records.first as Map<String, dynamic>;
      }
    } else {
      CurrentLogMessage.add(
        'fetchPOSPrinterConfig: ${response.statusCode}, ${response.body}',
        level: 'ERROR',
        tag: 'fetchPOSPrinterConfig',
      );
    }
  } catch (e) {
    CurrentLogMessage.add(
      'Excepcion en fetchPOSPrinterConfig: $e',
      level: 'ERROR',
      tag: 'fetchPOSPrinterConfig',
    );
  }

  return null;
}

Future<bool> savePOSPrinterConfig({
  required BuildContext context,
  required int posId,
  int? configId,
  String? header1,
  String? header2,
  String? header3,
  String? header4,
  String? footer1,
  String? footer2,
  String? footer3,
  String? footer4,
}) async {
  try {
    await usuarioAuth(context: context);

    final bodyData = {
      'C_POS_ID': {'id': posId},
      if (header1 != null) 'Header1': header1,
      if (header2 != null) 'Header2': header2,
      if (header3 != null) 'Header3': header3,
      if (header4 != null) 'Header4': header4,
      if (footer1 != null) 'Footer1': footer1,
      if (footer2 != null) 'Footer2': footer2,
      if (footer3 != null) 'Footer3': footer3,
      if (footer4 != null) 'Footer4': footer4,
    };

    Response response;

    if (configId != null && configId > 0) {
      // Actualizar registro existente
      response = await put(
        Uri.parse('${EndPoints.cdsPOSPrinterConfig}/$configId'),
        headers: _writeHeaders(),
        body: jsonEncode(bodyData),
      );
    } else {
      // Crear nuevo registro
      response = await post(
        Uri.parse(EndPoints.cdsPOSPrinterConfig),
        headers: _writeHeaders(),
        body: jsonEncode(bodyData),
      );
    }

    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
      return true;
    } else {
      CurrentLogMessage.add(
        'savePOSPrinterConfig Error: ${response.statusCode}, ${response.body}',
        level: 'ERROR',
        tag: 'savePOSPrinterConfig',
      );
    }
  } catch (e) {
    CurrentLogMessage.add(
      'Excepcion en savePOSPrinterConfig: $e',
      level: 'ERROR',
      tag: 'savePOSPrinterConfig',
    );
  }

  return false;
}
