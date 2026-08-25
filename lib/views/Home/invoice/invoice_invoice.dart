import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:primware/API/endpoint.dart';
import 'package:primware/API/token.api.dart';
import 'package:primware/views/Auth/auth_funtions.dart';

class InvoicePaymentConfiguration {
  const InvoicePaymentConfiguration({
    required this.paymentDocTypeId,
    required this.allocationDocTypeId,
    required this.currencyId,
  });

  final int paymentDocTypeId;
  final int allocationDocTypeId;
  final int currencyId;
}

String? _invoicePaymentConfigurationCacheKey;
InvoicePaymentConfiguration? _invoicePaymentConfigurationCache;

bool invoicePaymentAmountsMatch(num allocatedAmount, num paymentAmount) {
  return (_roundMoney(allocatedAmount) - _roundMoney(paymentAmount)).abs() <
      0.001;
}

double calculateRemainingInvoicePayment(
  num allocatedAmount,
  Iterable<num> otherPaymentAmounts,
) {
  final maximum = allocatedAmount.toDouble().clamp(0.0, double.infinity);
  final otherTotal = otherPaymentAmounts.fold<double>(
    0.0,
    (sum, amount) => sum + amount.toDouble(),
  );
  return _roundMoney((maximum - otherTotal).clamp(0.0, maximum));
}

Map<String, dynamic> buildInvoicePaymentPayload({
  required int bankAccountId,
  required int organizationId,
  required int currencyId,
  required int paymentDocTypeId,
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
    'AD_Org_ID': organizationId,
    'C_BankAccount_ID': bankAccountId,
    'TenderType': {'id': tenderTypeId},
    'C_Currency_ID': currencyId,
    'C_POSTenderType_ID': posTenderTypeId,
    'C_DocType_ID': paymentDocTypeId,
    'PayAmt': _roundMoney(amount),
    'C_BPartner_ID': bPartnerId,
    'DateTrx': dateText,
    'DateAcct': dateText,
    'doc-action': 'CO',
  };
}

List<Map<String, dynamic>> buildFifoAllocationLines({
  required List<Map<String, dynamic>> payments,
  required List<Map<String, dynamic>> invoices,
  required int organizationId,
  required int bPartnerId,
}) {
  final paymentQueue = payments.map((payment) {
    final id = _asInt(payment['id']);
    if (id == null || id <= 0) {
      throw ArgumentError('Un método de pago no tiene un ID válido.');
    }
    final cents = _moneyToCents(payment['amount']);
    if (cents <= 0) {
      throw ArgumentError('Los montos de pago deben ser mayores que cero.');
    }
    return {'id': id, 'remaining': cents};
  }).toList();
  final invoiceQueue = invoices.map((invoice) {
    final id = _asInt(invoice['id']);
    if (id == null || id <= 0) {
      throw ArgumentError('Una factura no tiene un ID válido.');
    }
    final cents = _moneyToCents(invoice['amountToPay']);
    final outstandingCents = _moneyToCents(invoice['outstandingDebt']);
    if (cents <= 0 || cents > outstandingCents) {
      throw ArgumentError('El monto asignado excede el saldo de una factura.');
    }
    return {'id': id, 'remaining': cents};
  }).toList();

  final paymentTotal = paymentQueue.fold<int>(
    0,
    (sum, item) => sum + (item['remaining'] as int),
  );
  final invoiceTotal = invoiceQueue.fold<int>(
    0,
    (sum, item) => sum + (item['remaining'] as int),
  );
  if (paymentTotal != invoiceTotal) {
    throw ArgumentError(
      'Los métodos de pago deben coincidir con el monto asignado a facturas.',
    );
  }

  final lines = <Map<String, dynamic>>[];
  var paymentIndex = 0;
  var invoiceIndex = 0;
  while (paymentIndex < paymentQueue.length &&
      invoiceIndex < invoiceQueue.length) {
    final payment = paymentQueue[paymentIndex];
    final invoice = invoiceQueue[invoiceIndex];
    final paymentRemaining = payment['remaining'] as int;
    final invoiceRemaining = invoice['remaining'] as int;
    final allocatedCents = paymentRemaining < invoiceRemaining
        ? paymentRemaining
        : invoiceRemaining;
    final methodId = payment['id'] as int;

    lines.add({
      'AD_Org_ID': organizationId,
      'C_Payment_ID': '@payment_$methodId\$.id@',
      'C_Invoice_ID': invoice['id'],
      'C_BPartner_ID': bPartnerId,
      'Amount': allocatedCents / 100,
      'DiscountAmt': 0,
      'WriteOffAmt': 0,
      'OverUnderAmt': 0,
    });

    payment['remaining'] = paymentRemaining - allocatedCents;
    invoice['remaining'] = invoiceRemaining - allocatedCents;
    if (payment['remaining'] == 0) paymentIndex++;
    if (invoice['remaining'] == 0) invoiceIndex++;
  }
  return lines;
}

List<Map<String, dynamic>> buildInvoicePaymentBatch({
  required int bankAccountId,
  required int organizationId,
  required int bPartnerId,
  required InvoicePaymentConfiguration configuration,
  required List<Map<String, dynamic>> payments,
  required List<Map<String, dynamic>> invoices,
  required DateTime date,
}) {
  final lines = buildFifoAllocationLines(
    payments: payments,
    invoices: invoices,
    organizationId: organizationId,
    bPartnerId: bPartnerId,
  );
  final requests = <Map<String, dynamic>>[];
  for (final payment in payments) {
    final methodId = _asInt(payment['id'])!;
    final tenderTypeId = payment['tenderTypeID']?.toString().trim() ?? '';
    if (tenderTypeId.isEmpty) {
      throw ArgumentError('Un método de pago no tiene TenderType configurado.');
    }
    requests.add({
      'method': 'POST',
      'path': 'v1/windows/payment-and-receipt',
      'responseAlias': 'payment_$methodId',
      'body': buildInvoicePaymentPayload(
        bankAccountId: bankAccountId,
        organizationId: organizationId,
        currencyId: configuration.currencyId,
        paymentDocTypeId: configuration.paymentDocTypeId,
        tenderTypeId: tenderTypeId,
        posTenderTypeId: methodId,
        amount: _asDouble(payment['amount']),
        bPartnerId: bPartnerId,
        date: date,
      ),
    });
  }
  final dateText = _formatDate(date);
  requests.add({
    'method': 'POST',
    'path': 'v1/models/C_AllocationHdr',
    'responseAlias': 'allocation',
    'body': {
      'AD_Org_ID': organizationId,
      'C_DocType_ID': configuration.allocationDocTypeId,
      'C_Currency_ID': configuration.currencyId,
      'DateTrx': dateText,
      'DateAcct': dateText,
      'IsManual': true,
      'ApprovalAmt': 0,
      'C_AllocationLine': lines,
      'doc-action': 'CO',
    },
  });
  return requests;
}

Future<InvoicePaymentConfiguration> resolveInvoicePaymentConfiguration({
  required BuildContext context,
  required int bankAccountId,
}) async {
  await usuarioAuth(context: context);
  final cacheKey =
      '${Token.auth.hashCode}:${Token.client}:${Token.organitation}:$bankAccountId';
  if (_invoicePaymentConfigurationCacheKey == cacheKey &&
      _invoicePaymentConfigurationCache != null) {
    return _invoicePaymentConfigurationCache!;
  }
  final paymentDocTypeId = await _fetchUniqueDocTypeId(
    "DocBaseType eq 'ARR' and IsSOTrx eq true",
  );
  final allocationDocTypeId = await _fetchUniqueDocTypeId(
    "DocBaseType eq 'CMA'",
  );
  final bankResponse = await get(
    Uri.parse('${EndPoints.cBankAccount}/$bankAccountId'),
    headers: _headers(),
  );
  if (bankResponse.statusCode != 200) {
    throw Exception(
      'No se pudo consultar la moneda de la cuenta bancaria (${bankResponse.statusCode}).',
    );
  }
  final bank = json.decode(utf8.decode(bankResponse.bodyBytes));
  final currencyId = _lookupInt(bank['C_Currency_ID']);
  if (currencyId == null) {
    throw Exception('La cuenta bancaria no tiene una moneda configurada.');
  }
  final configuration = InvoicePaymentConfiguration(
    paymentDocTypeId: paymentDocTypeId,
    allocationDocTypeId: allocationDocTypeId,
    currencyId: currencyId,
  );
  _invoicePaymentConfigurationCacheKey = cacheKey;
  _invoicePaymentConfigurationCache = configuration;
  return configuration;
}

Future<Map<String, dynamic>> postInvoicePaymentBatch({
  required BuildContext context,
  required int bankAccountId,
  required int organizationId,
  required int bPartnerId,
  required List<Map<String, dynamic>> payments,
  required List<Map<String, dynamic>> invoices,
  DateTime? date,
}) async {
  try {
    await usuarioAuth(context: context);
    final configuration = await resolveInvoicePaymentConfiguration(
      context: context,
      bankAccountId: bankAccountId,
    );
    _validateInvoiceContext(
      invoices: invoices,
      organizationId: organizationId,
      currencyId: configuration.currencyId,
    );
    final payload = buildInvoicePaymentBatch(
      bankAccountId: bankAccountId,
      organizationId: organizationId,
      bPartnerId: bPartnerId,
      configuration: configuration,
      payments: payments,
      invoices: invoices,
      date: date ?? DateTime.now(),
    );
    final response = await post(
      Uri.parse(EndPoints.batch),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    final dynamic decoded = response.bodyBytes.isEmpty
        ? null
        : json.decode(utf8.decode(response.bodyBytes));
    final validationError = validateInvoicePaymentBatchResponse(decoded);
    if (response.statusCode == 200 && validationError == null) {
      return {'success': true, 'response': decoded};
    }
    final message =
        validationError ??
        'Error en el batch (${response.statusCode}): ${utf8.decode(response.bodyBytes)}';
    CurrentLogMessage.add(
      message,
      level: 'ERROR',
      tag: 'postInvoicePaymentBatch',
    );
    return {'success': false, 'message': message};
  } catch (error) {
    CurrentLogMessage.add(
      'Excepción en pago y asignación: $error',
      level: 'ERROR',
      tag: 'postInvoicePaymentBatch',
    );
    return {'success': false, 'message': error.toString()};
  }
}

String? validateInvoicePaymentBatchResponse(dynamic decoded) {
  if (decoded is! List || decoded.isEmpty) {
    return 'El servidor no devolvió una respuesta batch válida; puede no soportar batch/responseAlias.';
  }
  for (var index = 0; index < decoded.length; index++) {
    final item = decoded[index];
    if (item is! Map) return 'Respuesta inválida en la operación ${index + 1}.';
    final statusCode = _asInt(item['statusCode']);
    if (statusCode == null || !{200, 201, 202}.contains(statusCode)) {
      final detail = _extractBatchError(item['body']);
      return 'Falló la operación ${index + 1}${detail.isEmpty ? '' : ': $detail'}';
    }
    final body = item['body'];
    if (body is! Map) {
      return 'La operación ${index + 1} no devolvió un documento verificable.';
    }
    final docStatus = _lookupString(body['DocStatus'] ?? body['doc-status']);
    if (docStatus != 'CO') {
      return 'La operación ${index + 1} no completó el documento (estado: ${docStatus ?? 'desconocido'}).';
    }
  }
  return null;
}

/// Obtiene las facturas de venta completadas de un tercero y normaliza la
/// respuesta para que la vista no dependa de la forma exacta de los lookups.
Future<List<Map<String, dynamic>>> fetchCompletedCustomerInvoices({
  required BuildContext context,
  required int bPartnerId,
}) async {
  try {
    await usuarioAuth(context: context);
    final filter =
        "IsSOTrx eq true and C_BPartner_ID eq $bPartnerId and DocStatus eq 'CO'";
    final url = Uri.parse(
      '${EndPoints.cInvoice}?\$filter=$filter'
      '&\$expand=C_InvoiceLine(\$select=M_Product_ID,QtyEntered,PriceEntered),'
      'C_AllocationLine(\$select=Amount)'
      '&\$select=DocumentNo,GrandTotal,AD_Client_ID,AD_Org_ID,C_Currency_ID',
    );

    final response = await get(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error al cargar facturas: ${response.statusCode}');
    }

    final decoded = json.decode(utf8.decode(response.bodyBytes));
    final records = (decoded['records'] as List?) ?? const [];
    return normalizeOutstandingCustomerInvoices(records);
  } catch (error) {
    CurrentLogMessage.add(
      'Excepción al obtener facturas del tercero: $error',
      level: 'ERROR',
      tag: 'fetchCompletedCustomerInvoices',
    );
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
  final dynamic rawClientId = clientField is Map
      ? clientField['id']
      : clientField;
  final int? clientId = rawClientId is num
      ? rawClientId.toInt()
      : int.tryParse(rawClientId?.toString() ?? '');
  final organizationId = _lookupInt(record['AD_Org_ID']);
  final currencyId = _lookupInt(record['C_Currency_ID']);
  final grandTotal = _roundMoney(_asDouble(record['GrandTotal']));
  final rawAllocations = (record['C_AllocationLine'] as List?) ?? const [];
  final totalPaid = _roundMoney(
    rawAllocations.fold<double>(0.0, (sum, rawAllocation) {
      if (rawAllocation is! Map) return sum;
      return sum + _asDouble(rawAllocation['Amount']);
    }),
  );
  final outstandingDebt = _roundMoney(
    (grandTotal - totalPaid).clamp(0.0, double.infinity),
  );
  final paymentProgress = grandTotal <= 0
      ? 0.0
      : (totalPaid / grandTotal).clamp(0.0, 1.0).toDouble();
  final rawLines = (record['C_InvoiceLine'] as List?) ?? const [];
  final lines = rawLines.whereType<Map>().map<Map<String, dynamic>>((rawLine) {
    final line = Map<String, dynamic>.from(rawLine);
    final product = line['M_Product_ID'];
    final productId = product is Map ? product['id'] : product;
    final identifier = product is Map
        ? (product['identifier'] ?? product['Name'] ?? product['name'])
        : null;
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
    'organizationId': organizationId,
    'currencyId': currencyId,
    'documentNo': (record['DocumentNo'] ?? record['id'] ?? '').toString(),
    'grandTotal': grandTotal,
    'totalPaid': totalPaid,
    'outstandingDebt': outstandingDebt,
    'paymentProgress': paymentProgress,
    'lines': lines,
  };
}

Future<int> _fetchUniqueDocTypeId(String filter) async {
  final response = await get(
    Uri.parse(
      '${EndPoints.cDocType}?\$filter=$filter&\$select=Name,DocBaseType,IsSOTrx',
    ),
    headers: _headers(),
  );
  if (response.statusCode != 200) {
    throw Exception(
      'No se pudo resolver el tipo de documento (${response.statusCode}).',
    );
  }
  final decoded = json.decode(utf8.decode(response.bodyBytes));
  final records = (decoded['records'] as List?) ?? const [];
  if (records.length != 1) {
    throw Exception(
      'Se esperaba un único tipo de documento para "$filter" y se encontraron ${records.length}.',
    );
  }
  final id = records.first is Map ? _asInt((records.first as Map)['id']) : null;
  if (id == null) {
    throw Exception('El tipo de documento encontrado no tiene un ID válido.');
  }
  return id;
}

void _validateInvoiceContext({
  required List<Map<String, dynamic>> invoices,
  required int organizationId,
  required int currencyId,
}) {
  if (invoices.isEmpty) {
    throw ArgumentError('Debe seleccionar al menos una factura.');
  }
  for (final invoice in invoices) {
    final invoiceOrgId = _asInt(invoice['organizationId']);
    final invoiceCurrencyId = _asInt(invoice['currencyId']);
    if (invoiceOrgId == null || invoiceOrgId != organizationId) {
      throw ArgumentError(
        'Todas las facturas deben pertenecer a la organización activa.',
      );
    }
    if (invoiceCurrencyId == null || invoiceCurrencyId != currencyId) {
      throw ArgumentError(
        'Todas las facturas deben usar la moneda de la cuenta bancaria del POS.',
      );
    }
  }
}

Map<String, String> _headers() => {
  'Content-Type': 'application/json; charset=UTF-8',
  'Authorization': Token.auth!,
};

String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

int _moneyToCents(dynamic value) => (_asDouble(value) * 100 + 1e-7).round();

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

int? _lookupInt(dynamic value) => _asInt(value is Map ? value['id'] : value);

String? _lookupString(dynamic value) {
  final raw = value is Map ? value['id'] : value;
  final text = raw?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

String _extractBatchError(dynamic body) {
  if (body is Map) {
    for (final key in const ['detail', 'summary', 'title', 'message']) {
      final value = body[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return jsonEncode(body);
  }
  return body?.toString().trim() ?? '';
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
