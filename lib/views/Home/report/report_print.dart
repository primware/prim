import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../../API/token.api.dart';
import '../../../shared/toast_message.dart';

/* Para que funcione tiene que estar marcado el IsCanReport 'Puede hacer informes' en el rol del usuario
   tambien tiene que tener acceso a la ventana, y al proceso del informe */

Future<void> shareReportProcessPdf({
  required BuildContext context,
  required String process,
  Map<String, dynamic>? params,
  String fallbackFileName = 'reporte.pdf',
}) async {
  final String token = Token.auth!;

  try {
    final response = await post(
      Uri.parse(process),
      headers: {'Content-Type': 'application/json', 'Authorization': token},
      body: jsonEncode(params ?? <String, dynamic>{}),
    );

    debugPrint(
      'Process call (share): $process | params: ${jsonEncode(params ?? {})}',
    );

    if (response.statusCode != 200) {
      ToastMessage.show(
        context: context,
        message: "Error al obtener el archivo (${response.statusCode})",
        type: ToastType.failure,
      );
      return;
    }

    final jsonResponse = json.decode(utf8.decode(response.bodyBytes));

    final String? base64Data =
        (jsonResponse['exportFile'] ?? jsonResponse['reportFile']) as String?;

    final String fileName =
        (jsonResponse['exportFileName'] ??
                jsonResponse['reportFileName'] ??
                fallbackFileName)
            as String;

    if (base64Data == null || base64Data.isEmpty) {
      ToastMessage.show(
        context: context,
        message: 'El response no trae exportFile/reportFile',
        type: ToastType.failure,
      );
      return;
    }

    // Base64 -> bytes
    final Uint8List decodedBytes = base64Decode(base64Data);

    // Asegurar extensión .pdf para que los share targets lo reconozcan bien.
    final String safeFileName = fileName.toLowerCase().endsWith('.pdf')
        ? fileName
        : '$fileName.pdf';

    await Printing.sharePdf(bytes: decodedBytes, filename: safeFileName);
  } catch (e) {
    ToastMessage.show(
      context: context,
      message: 'Error al compartir el PDF',
      type: ToastType.failure,
    );
    debugPrint('Error shareReportPdf: $e');
  }
}

Future<void> shareReportPrintFormatPdf({
  required BuildContext context,
  required String table,
  required int recordID,
  String fileName = 'reporte.pdf',
}) async {
  final String token = Token.auth!;

  try {
    final response = await get(
      Uri.parse('$table/$recordID/print?\$report_type=PDF'),
      headers: {'Content-Type': 'application/json', 'Authorization': token},
    );

    debugPrint('Print Format call (share): $table | ID: $recordID');

    if (response.statusCode != 200) {
      ToastMessage.show(
        context: context,
        message: "Error al obtener el archivo (${response.statusCode})",
        type: ToastType.failure,
      );
      return;
    }

    final jsonResponse = json.decode(utf8.decode(response.bodyBytes));

    final String? base64Data =
        (jsonResponse['exportFile'] ?? jsonResponse['reportFile']) as String?;

    if (base64Data == null || base64Data.isEmpty) {
      ToastMessage.show(
        context: context,
        message: 'El response no trae exportFile/reportFile',
        type: ToastType.failure,
      );
      return;
    }

    // Base64 -> bytes
    final Uint8List decodedBytes = base64Decode(base64Data);

    await Printing.sharePdf(bytes: decodedBytes, filename: fileName);
  } catch (e) {
    ToastMessage.show(
      context: context,
      message: 'Error al compartir el PDF',
      type: ToastType.failure,
    );
    debugPrint('Error shareReportPdf: $e');
  }
}
