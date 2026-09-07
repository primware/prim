import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:primware/API/endpoint.dart';
import 'package:primware/API/token.api.dart';
import 'package:primware/API/user.api.dart';
import 'package:primware/views/Auth/auth_funtions.dart';
import 'package:primware/views/Home/order/history_search_criteria.dart';

import 'invoice_payment_receipt.dart';

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

int? selectDefaultSalesRepId(
  List<Map<String, dynamic>> salesReps,
  int? userId,
) {
  if (userId == null) return null;
  return salesReps.any((rep) => _asInt(rep['id']) == userId) ? userId : null;
}

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
  required int salesRepId,
  int? posId,
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
    requests.add({
      'method': 'POST',
      'path': 'v1/models/CDS_POSPaymentTrace',
      'responseAlias': 'payment_trace_$methodId',
      'body': {
        'AD_Org_ID': organizationId,
        'C_Payment_ID': '@payment_$methodId\$.id@',
        'SalesRep_ID': salesRepId,
        if (posId != null) 'C_POS_ID': posId,
      },
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
  required String bPartnerName,
  String bPartnerTaxId = '',
  String bPartnerAddress = '',
  String bPartnerPhone = '',
  required int salesRepId,
  required String salesRepName,
  int? posId,
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
      salesRepId: salesRepId,
      posId: posId,
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
    final validationError = validateInvoicePaymentBatchResponse(
      decoded,
      paymentCount: payments.length,
    );
    if (response.statusCode == 200 && validationError == null) {
      final receipt = buildInvoicePaymentReceiptFromBatch(
        decoded: decoded,
        bPartnerId: bPartnerId,
        bPartnerName: bPartnerName,
        bPartnerTaxId: bPartnerTaxId,
        bPartnerAddress: bPartnerAddress,
        bPartnerPhone: bPartnerPhone,
        salesRepId: salesRepId,
        salesRepName: salesRepName,
        posId: posId,
        date: date ?? DateTime.now(),
        payments: payments,
        invoices: invoices,
      );
      return {
        'success': true,
        'response': decoded,
        'allocationId': receipt.allocationId,
        'allocationDocumentNo': receipt.documentNo,
        'payments': receipt.payments,
        'receipt': receipt,
      };
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

InvoicePaymentReceipt buildInvoicePaymentReceiptFromBatch({
  required dynamic decoded,
  required int bPartnerId,
  required String bPartnerName,
  String bPartnerTaxId = '',
  String bPartnerAddress = '',
  String bPartnerPhone = '',
  required int salesRepId,
  required String salesRepName,
  required int? posId,
  required DateTime date,
  required List<Map<String, dynamic>> payments,
  required List<Map<String, dynamic>> invoices,
}) {
  if (decoded is! List || decoded.length != payments.length * 2 + 1) {
    throw ArgumentError(
      'No se puede construir el recibo desde una respuesta batch inválida.',
    );
  }
  final allocationBody = Map<String, dynamic>.from(decoded.last['body'] as Map);
  final receiptPayments = <InvoicePaymentReceiptPayment>[];
  for (var index = 0; index < payments.length; index++) {
    final payment = payments[index];
    final body = Map<String, dynamic>.from(decoded[index * 2]['body'] as Map);
    receiptPayments.add(
      InvoicePaymentReceiptPayment(
        id: _asInt(body['id'])!,
        documentNo: (body['DocumentNo'] ?? body['documentNo'] ?? body['id'])
            .toString(),
        methodName:
            (payment['name'] ??
                    payment['Name'] ??
                    payment['identifier'] ??
                    'Pago')
                .toString(),
        amount: _roundMoney(_asDouble(payment['amount'])),
      ),
    );
  }
  final receiptInvoices = invoices
      .map(
        (invoice) => InvoicePaymentReceiptInvoice(
          id: _asInt(invoice['id'])!,
          documentNo:
              (invoice['documentNo'] ?? invoice['DocumentNo'] ?? invoice['id'])
                  .toString(),
          originalAmount: _roundMoney(
            _asDouble(invoice['grandTotal'] ?? invoice['GrandTotal']),
          ),
          appliedAmount: _roundMoney(_asDouble(invoice['amountToPay'])),
        ),
      )
      .toList();
  return InvoicePaymentReceipt(
    allocationId: _asInt(allocationBody['id'])!,
    documentNo: _optionalText(
      allocationBody['DocumentNo'] ?? allocationBody['documentNo'],
    ),
    date: date,
    customerId: bPartnerId,
    customerName: bPartnerName,
    customerTaxId: bPartnerTaxId,
    customerAddress: bPartnerAddress,
    customerPhone: bPartnerPhone,
    salesRepId: salesRepId,
    salesRepName: salesRepName,
    posId: posId,
    invoices: receiptInvoices,
    payments: receiptPayments,
  );
}

Future<PagedResult<InvoicePaymentReceipt>> fetchInvoicePaymentReceiptsPage({
  required BuildContext context,
  HistorySearchCriteria criteria = const HistorySearchCriteria(),
  int top = 50,
  int skip = 0,
}) async {
  await usuarioAuth(context: context);
  if (criteria.docStatus != null && criteria.docStatus != 'CO') {
    return PagedResult(
      records: const [],
      rowCount: 0,
      recordsSize: 0,
      skipRecords: skip,
    );
  }
  final allocationDocTypeId = await _fetchUniqueDocTypeId(
    "DocBaseType eq 'CMA'",
  );
  final records = <Map>[];
  var totalCount = 0;
  var recordsSize = 0;
  var skipRecords = skip;
  {
    final organizationFilter = criteria.organizationId == null
        ? ''
        : ' and AD_Org_ID eq ${criteria.organizationId}';
    final uri = Uri.parse(
      '${EndPoints.cAllocationHdr}?\$top=$top&\$skip=$skip'
      '&\$filter=DocStatus eq \'CO\' and IsManual eq true '
      'and C_DocType_ID eq $allocationDocTypeId'
      '$organizationFilter'
      '&\$orderby=DateTrx desc'
      '&\$expand=C_AllocationLine',
    );
    final response = await get(uri, headers: _headers());
    if (response.statusCode != 200) {
      throw Exception(
        'No se pudo cargar el historial de pagos (${response.statusCode}).',
      );
    }
    final decoded = json.decode(utf8.decode(response.bodyBytes));
    final page =
        (decoded['records'] as List?)?.whereType<Map>().toList() ??
        const <Map>[];
    records.addAll(page);
    recordsSize =
        int.tryParse((decoded['records-size'] ?? page.length).toString()) ??
        page.length;
    skipRecords =
        int.tryParse((decoded['skip-records'] ?? skip).toString()) ?? skip;
    totalCount =
        int.tryParse((decoded['row-count'] ?? page.length).toString()) ??
        page.length;
  }
  final paymentIds = records
      .expand((record) => ((record['C_AllocationLine'] as List?) ?? const []))
      .whereType<Map>()
      .map((line) => _lookupInt(line['C_Payment_ID']))
      .whereType<int>()
      .toSet()
      .toList();
  if (paymentIds.isEmpty) {
    return PagedResult(
      records: const [],
      rowCount: totalCount,
      recordsSize: recordsSize,
      skipRecords: skipRecords,
    );
  }

  final invoiceIds = records
      .expand((record) => ((record['C_AllocationLine'] as List?) ?? const []))
      .whereType<Map>()
      .map((line) => _lookupInt(line['C_Invoice_ID']))
      .whereType<int>()
      .toSet()
      .toList();
  final partnerIds = records
      .expand((record) => ((record['C_AllocationLine'] as List?) ?? const []))
      .whereType<Map>()
      .map((line) => _lookupInt(line['C_BPartner_ID']))
      .whereType<int>()
      .toSet()
      .toList();

  final invoicesById = await _fetchRecordsByIds(
    endpoint: EndPoints.cInvoice,
    idColumn: 'C_Invoice_ID',
    ids: invoiceIds,
    select: 'DocumentNo,GrandTotal,C_BPartner_ID',
  );
  final paymentsById = await _fetchRecordsByIds(
    endpoint: EndPoints.cPayment,
    idColumn: 'C_Payment_ID',
    ids: paymentIds,
    select: 'DocumentNo,PayAmt,TenderType,C_POSTenderType_ID,C_BPartner_ID',
    expand: 'C_POSTenderType_ID',
  );
  final partnersById = await _fetchRecordsByIds(
    endpoint: EndPoints.cBPartner,
    idColumn: 'C_BPartner_ID',
    ids: partnerIds,
    select: 'Name,TaxID',
  );

  final traces = <Map>[];
  for (var start = 0; start < paymentIds.length; start += 75) {
    final end = (start + 75).clamp(0, paymentIds.length);
    final chunk = paymentIds.sublist(start, end);
    final traceUri = Uri.parse(
      '${EndPoints.cdsPOSPaymentTrace}?\$filter=C_Payment_ID in (${chunk.join(',')})'
      '&\$expand=C_Payment_ID,SalesRep_ID,C_POS_ID',
    );
    final traceResponse = await get(traceUri, headers: _headers());
    if (traceResponse.statusCode == 404) {
      return PagedResult(
        records: const [],
        rowCount: 0,
        recordsSize: 0,
        skipRecords: skip,
      );
    }
    if (traceResponse.statusCode != 200) {
      throw Exception(
        'No se pudieron cargar las trazas de pagos (${traceResponse.statusCode}).',
      );
    }
    final traceDecoded = json.decode(utf8.decode(traceResponse.bodyBytes));
    traces.addAll(
      (traceDecoded['records'] as List?)?.whereType<Map>() ?? const <Map>[],
    );
  }
  final tracesByPayment = <int, Map>{};
  for (final trace in traces) {
    final paymentId = _lookupInt(trace['C_Payment_ID']);
    if (paymentId != null) tracesByPayment[paymentId] = trace;
  }
  final enrichedRecords = records.map((record) {
    final copy = Map<String, dynamic>.from(record);
    copy['C_AllocationLine'] =
        ((record['C_AllocationLine'] as List?) ?? const [])
            .whereType<Map>()
            .map((line) {
              final enrichedLine = Map<String, dynamic>.from(line);
              final invoiceId = _lookupInt(line['C_Invoice_ID']);
              final paymentId = _lookupInt(line['C_Payment_ID']);
              final partnerId = _lookupInt(line['C_BPartner_ID']);
              if (invoiceId != null && invoicesById[invoiceId] != null) {
                enrichedLine['C_Invoice_ID'] = invoicesById[invoiceId];
              }
              if (paymentId != null && paymentsById[paymentId] != null) {
                enrichedLine['C_Payment_ID'] = paymentsById[paymentId];
              }
              if (partnerId != null && partnersById[partnerId] != null) {
                enrichedLine['C_BPartner_ID'] = partnersById[partnerId];
              }
              return enrichedLine;
            })
            .toList();
    return copy;
  }).toList();
  final normalized = enrichedRecords
      .map((record) => _normalizeHistoricalReceipt(record, tracesByPayment))
      .whereType<InvoicePaymentReceipt>()
      .toList();
  final customerQuery = criteria.customerText.trim().toLowerCase();
  final documentQuery = criteria.documentText.trim().toLowerCase();
  final filtered = normalized.where((receipt) {
    final matchesCustomer =
        customerQuery.isEmpty ||
        receipt.customerName.toLowerCase().contains(customerQuery) ||
        receipt.customerTaxId.toLowerCase().contains(customerQuery);
    final matchesDocument =
        documentQuery.isEmpty ||
        receipt.displayDocumentNo.toLowerCase().contains(documentQuery) ||
        receipt.invoices.any(
          (invoice) => invoice.documentNo.toLowerCase().contains(documentQuery),
        );
    final matchesOwner =
        !criteria.onlyMyMovements || receipt.salesRepId == UserData.id;
    return matchesCustomer && matchesDocument && matchesOwner;
  }).toList();
  return PagedResult(
    records: filtered,
    rowCount: totalCount,
    recordsSize: recordsSize,
    skipRecords: skipRecords,
  );
}

Future<Map<int, Map>> _fetchRecordsByIds({
  required String endpoint,
  required String idColumn,
  required List<int> ids,
  required String select,
  String? expand,
}) async {
  if (ids.isEmpty) return {};
  final result = <int, Map>{};
  for (var start = 0; start < ids.length; start += 75) {
    final end = (start + 75).clamp(0, ids.length);
    final chunk = ids.sublist(start, end);
    final uri = Uri.parse(
      '$endpoint?\$filter=$idColumn in (${chunk.join(',')})'
      '&\$select=$select'
      '${expand == null ? '' : '&\$expand=$expand'}',
    );
    final response = await get(uri, headers: _headers());
    if (response.statusCode != 200) {
      throw Exception(
        'No se pudieron cargar registros relacionados de $idColumn (${response.statusCode}).',
      );
    }
    final decoded = json.decode(utf8.decode(response.bodyBytes));
    final records =
        (decoded['records'] as List?)?.whereType<Map>() ??
        const Iterable<Map>.empty();
    for (final record in records) {
      final id = _asInt(record['id']);
      if (id != null) result[id] = record;
    }
  }
  return result;
}

InvoicePaymentReceipt? _normalizeHistoricalReceipt(
  Map record,
  Map<int, Map> tracesByPayment,
) {
  final rawLines = ((record['C_AllocationLine'] as List?) ?? const [])
      .whereType<Map>()
      .toList();
  final lines = rawLines.where((line) {
    final paymentId = _lookupInt(line['C_Payment_ID']);
    return paymentId != null && tracesByPayment.containsKey(paymentId);
  }).toList();
  if (lines.isEmpty) return null;

  final invoiceMap = <int, InvoicePaymentReceiptInvoice>{};
  final paymentMap = <int, InvoicePaymentReceiptPayment>{};
  final salesRepIds = <int>{};
  final posIds = <int>{};
  var customerId = 0;
  var customerName = '';
  var customerTaxId = '';
  var salesRepName = '';
  var posName = '';
  for (final line in lines) {
    final invoice = line['C_Invoice_ID'];
    final invoiceId = _lookupInt(invoice);
    if (invoiceId != null) {
      final current = invoiceMap[invoiceId];
      invoiceMap[invoiceId] = InvoicePaymentReceiptInvoice(
        id: invoiceId,
        documentNo: _lookupLabel(invoice, fallback: invoiceId.toString()),
        originalAmount: _lookupDouble(invoice, 'GrandTotal'),
        appliedAmount: _roundMoney(
          (current?.appliedAmount ?? 0) + _asDouble(line['Amount']),
        ),
      );
    }
    final partner = line['C_BPartner_ID'];
    customerId = _lookupInt(partner) ?? customerId;
    customerName = _lookupLabel(partner, fallback: customerName);
    if (partner is Map) {
      customerTaxId = (partner['TaxID'] ?? customerTaxId).toString();
    }
    final payment = line['C_Payment_ID'];
    final paymentId = _lookupInt(payment);
    if (paymentId == null || paymentMap.containsKey(paymentId)) continue;
    final trace = tracesByPayment[paymentId]!;
    final salesRep = trace['SalesRep_ID'];
    final salesRepId = _lookupInt(salesRep);
    if (salesRepId != null) salesRepIds.add(salesRepId);
    salesRepName = _lookupLabel(salesRep, fallback: salesRepName);
    final pos = trace['C_POS_ID'];
    final posId = _lookupInt(pos);
    if (posId != null) posIds.add(posId);
    posName = _lookupLabel(pos, fallback: posName);
    final tender = payment is Map ? payment['C_POSTenderType_ID'] : null;
    paymentMap[paymentId] = InvoicePaymentReceiptPayment(
      id: paymentId,
      documentNo: _lookupLabel(payment, fallback: paymentId.toString()),
      methodName: _lookupLabel(
        tender,
        fallback: payment is Map
            ? (payment['TenderType']?['identifier'] ?? 'Pago').toString()
            : 'Pago',
      ),
      amount: _lookupDouble(payment, 'PayAmt'),
    );
  }
  if (invoiceMap.isEmpty || paymentMap.isEmpty) return null;
  return InvoicePaymentReceipt(
    allocationId: _asInt(record['id']) ?? 0,
    documentNo: _optionalText(record['DocumentNo']),
    date:
        DateTime.tryParse(
          (record['DateTrx'] ?? record['Created'] ?? '').toString(),
        ) ??
        DateTime.now(),
    customerId: customerId,
    customerName: customerName.isEmpty ? 'Cliente' : customerName,
    customerTaxId: customerTaxId,
    salesRepId: salesRepIds.isEmpty ? 0 : salesRepIds.first,
    salesRepName: salesRepName.isEmpty ? 'Sin representante' : salesRepName,
    posId: posIds.isEmpty ? null : posIds.first,
    posName: posName,
    invoices: invoiceMap.values.toList(),
    payments: paymentMap.values.toList(),
    hasTraceConflict: salesRepIds.length > 1 || posIds.length > 1,
  );
}

String _lookupLabel(dynamic value, {required String fallback}) {
  if (value is Map) {
    return (value['Name'] ??
            value['name'] ??
            value['identifier'] ??
            value['DocumentNo'] ??
            fallback)
        .toString();
  }
  return fallback;
}

double _lookupDouble(dynamic value, String key) =>
    value is Map ? _asDouble(value[key]) : 0;

String? validateInvoicePaymentBatchResponse(
  dynamic decoded, {
  required int paymentCount,
}) {
  if (decoded is! List || decoded.isEmpty) {
    return 'El servidor no devolvió una respuesta batch válida; puede no soportar batch/responseAlias.';
  }
  final expectedOperations = paymentCount * 2 + 1;
  for (var index = 0; index < decoded.length; index++) {
    final isAllocation = index == expectedOperations - 1;
    final isPaymentTrace = !isAllocation && index.isOdd;
    final operationName = isAllocation
        ? 'la asignación'
        : isPaymentTrace
        ? 'la traza del pago ${(index ~/ 2) + 1}'
        : 'el pago ${(index ~/ 2) + 1}';
    final item = decoded[index];
    if (item is! Map) return 'Respuesta inválida para $operationName.';
    final statusCode = _asInt(item['statusCode']);
    if (statusCode == null || !{200, 201, 202}.contains(statusCode)) {
      final detail = _extractBatchError(item['body']);
      return 'Falló $operationName${detail.isEmpty ? '' : ': $detail'}';
    }
    final body = item['body'];
    if (body is! Map) {
      return '$operationName no devolvió un registro verificable.';
    }
    final recordId = _asInt(body['id']);
    if (recordId == null || recordId <= 0) {
      return '$operationName no devolvió un ID válido.';
    }
    if (isPaymentTrace) continue;
    final docStatus = _lookupString(body['DocStatus'] ?? body['doc-status']);
    if (docStatus != 'CO') {
      return '$operationName no completó el documento (estado: ${docStatus ?? 'desconocido'}).';
    }
  }
  if (decoded.length != expectedOperations) {
    return 'El servidor devolvió ${decoded.length} operaciones exitosas; se esperaban $expectedOperations. El batch se detuvo antes de completar todas las operaciones.';
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
      '&\$select=DocumentNo,Description,GrandTotal,AD_Client_ID,AD_Org_ID,C_Currency_ID',
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
    'description': (record['Description'] ?? '').toString().trim(),
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

String? _optionalText(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
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
