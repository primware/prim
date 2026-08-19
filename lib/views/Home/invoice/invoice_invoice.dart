import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:primware/API/endpoint.dart';
import 'package:primware/API/token.api.dart';
import 'package:primware/views/Auth/auth_funtions.dart';

const int invoicePaymentCurrencyId = 100;
const int invoicePaymentDocTypeId = 1000578;

bool invoicePaymentAmountsMatch(num allocatedAmount, num paymentAmount) {
  return (_roundMoney(allocatedAmount) - _roundMoney(paymentAmount)).abs() < 0.001;
}

double calculateRemainingInvoicePayment(num allocatedAmount, Iterable<num> otherPaymentAmounts) {
  final maximum = allocatedAmount.toDouble().clamp(0.0, double.infinity);
  final otherTotal = otherPaymentAmounts.fold<double>(0.0, (sum, amount) => sum + amount.toDouble());
  return _roundMoney((maximum - otherTotal).clamp(0.0, maximum));
}

Map<String, dynamic> buildInvoicePaymentPayload({
  required int bankAccountId,
  required String tenderTypeId,
  required int posTenderTypeId,
  required double amount,
  required int bPartnerId,
  required DateTime date,
}) {
  final dateText =
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
  return {
    'C_BankAccount_ID': bankAccountId,
    // 'TaxAmt': 0,
    'TenderType': {'id': tenderTypeId},
    'C_Currency_ID': invoicePaymentCurrencyId,
    'C_POSTenderType_ID': posTenderTypeId,
    'C_DocType_ID': invoicePaymentDocTypeId,
    'PayAmt': _roundMoney(amount),
    'C_BPartner_ID': bPartnerId,
    'DateTrx': dateText,
    'DateAcct': dateText,
    'doc-action': 'CO',
  };
}

Future<Map<String, dynamic>> postInvoicePayment({
  required BuildContext context,
  required int bankAccountId,
  required String tenderTypeId,
  required int posTenderTypeId,
  required double amount,
  required int bPartnerId,
  DateTime? date,
}) async {
  try {
    await usuarioAuth(context: context);
    final payload = buildInvoicePaymentPayload(
      bankAccountId: bankAccountId,
      tenderTypeId: tenderTypeId,
      posTenderTypeId: posTenderTypeId,
      amount: amount,
      bPartnerId: bPartnerId,
      date: date ?? DateTime.now(),
    );
    final response = await post(
      Uri.parse(EndPoints.paymentAndReceipt),
      headers: {'Content-Type': 'application/json; charset=UTF-8', 'Authorization': Token.auth!},
      body: jsonEncode(payload),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final dynamic rawDecoded = response.bodyBytes.isEmpty ? <String, dynamic>{} : json.decode(utf8.decode(response.bodyBytes));
      final decoded = rawDecoded is Map ? Map<String, dynamic>.from(rawDecoded) : <String, dynamic>{'data': rawDecoded};
      return {'success': true, 'id': decoded['id'], 'response': decoded};
    }
    final message =
        'Error al crear o completar el pago (${response.statusCode}): '
        '${utf8.decode(response.bodyBytes)}';
    CurrentLogMessage.add(message, level: 'ERROR', tag: 'postInvoicePayment');
    return {'success': false, 'message': message};
  } catch (error) {
    CurrentLogMessage.add('Excepción al crear o completar C_Payment: $error', level: 'ERROR', tag: 'postInvoicePayment');
    return {'success': false, 'message': error.toString()};
  }
}

/// Obtiene las facturas de venta completadas de un tercero y normaliza la
/// respuesta para que la vista no dependa de la forma exacta de los lookups.
Future<List<Map<String, dynamic>>> fetchCompletedCustomerInvoices({required BuildContext context, required int bPartnerId}) async {
  try {
    await usuarioAuth(context: context);
    final filter = "IsSOTrx eq true and C_BPartner_ID eq $bPartnerId and DocStatus eq 'CO'";
    final url = Uri.parse(
      '${EndPoints.cInvoice}?\$filter=$filter'
      '&\$expand=C_InvoiceLine(\$select=M_Product_ID,QtyEntered,PriceEntered),'
      'C_AllocationLine(\$select=Amount)'
      '&\$select=DocumentNo,GrandTotal,AD_Client_ID',
    );

    final response = await get(url, headers: {'Content-Type': 'application/json; charset=UTF-8', 'Authorization': Token.auth!});

    if (response.statusCode != 200) {
      throw Exception('Error al cargar facturas: ${response.statusCode}');
    }

    final decoded = json.decode(utf8.decode(response.bodyBytes));
    final records = (decoded['records'] as List?) ?? const [];
    return normalizeOutstandingCustomerInvoices(records);
  } catch (error) {
    CurrentLogMessage.add('Excepción al obtener facturas del tercero: $error', level: 'ERROR', tag: 'fetchCompletedCustomerInvoices');
    rethrow;
  }
}

List<Map<String, dynamic>> normalizeOutstandingCustomerInvoices(List records) {
  return records
      .whereType<Map>()
      .map(normalizeCompletedCustomerInvoice)
      .where((invoice) => (invoice['outstandingDebt'] as double) > 0)
      .toList();
}

Map<String, dynamic> normalizeCompletedCustomerInvoice(Map rawRecord) {
  final record = Map<String, dynamic>.from(rawRecord);
  final dynamic clientField = record['AD_Client_ID'];
  final dynamic rawClientId = clientField is Map ? clientField['id'] : clientField;
  final int? clientId = rawClientId is num ? rawClientId.toInt() : int.tryParse(rawClientId?.toString() ?? '');
  final grandTotal = _roundMoney(_asDouble(record['GrandTotal']));
  final rawAllocations = (record['C_AllocationLine'] as List?) ?? const [];
  final totalPaid = _roundMoney(
    rawAllocations.fold<double>(0.0, (sum, rawAllocation) {
      if (rawAllocation is! Map) return sum;
      return sum + _asDouble(rawAllocation['Amount']);
    }),
  );
  final outstandingDebt = _roundMoney((grandTotal - totalPaid).clamp(0.0, double.infinity));
  final paymentProgress = grandTotal <= 0 ? 0.0 : (totalPaid / grandTotal).clamp(0.0, 1.0).toDouble();
  final rawLines = (record['C_InvoiceLine'] as List?) ?? const [];
  final lines = rawLines.whereType<Map>().map<Map<String, dynamic>>((rawLine) {
    final line = Map<String, dynamic>.from(rawLine);
    final product = line['M_Product_ID'];
    final productId = product is Map ? product['id'] : product;
    final identifier = product is Map ? (product['identifier'] ?? product['Name'] ?? product['name']) : null;
    return {
      'id': line['id'],
      'productId': productId,
      'productName': _cleanIdentifier(identifier),
      'quantity': _asDouble(line['QtyEntered']),
      'price': _asDouble(line['PriceEntered']),
    };
  }).toList();

  return {
    'id': record['id'],
    'clientId': clientId,
    'documentNo': (record['DocumentNo'] ?? record['id'] ?? '').toString(),
    'grandTotal': grandTotal,
    'totalPaid': totalPaid,
    'outstandingDebt': outstandingDebt,
    'paymentProgress': paymentProgress,
    'lines': lines,
  };
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double _roundMoney(num value) {
  final scaled = value * 100;
  final adjustment = value >= 0 ? 1e-9 : -1e-9;
  return (scaled + adjustment).round() / 100;
}

String _cleanIdentifier(dynamic value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return 'Producto';
  final parts = text.split('_');
  return parts.length > 1 ? parts.skip(1).join(' ') : text;
}
