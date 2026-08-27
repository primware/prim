import 'package:flutter_test/flutter_test.dart';
import 'package:primware/views/Home/invoice/invoice_funtions.dart';

void main() {
  const configuration = InvoicePaymentConfiguration(
    paymentDocTypeId: 1000049,
    allocationDocTypeId: 1000050,
    currencyId: 197,
  );
  final payments = <Map<String, dynamic>>[
    {'id': 1000004, 'tenderTypeID': 'X', 'amount': 100.0},
    {'id': 1000005, 'tenderTypeID': 'A', 'amount': 40.0},
  ];
  final invoices = <Map<String, dynamic>>[
    {'id': 2000001, 'amountToPay': 110.0, 'outstandingDebt': 110.0},
    {'id': 2000002, 'amountToPay': 30.0, 'outstandingDebt': 30.0},
  ];

  test('selects the current user only when available as sales rep', () {
    final reps = <Map<String, dynamic>>[
      {'id': 10, 'name': 'Uno'},
      {'id': 20, 'name': 'Dos'},
    ];

    expect(selectDefaultSalesRepId(reps, 20), 20);
    expect(selectDefaultSalesRepId(reps, 30), isNull);
    expect(selectDefaultSalesRepId(reps, null), isNull);
  });

  test('creates one trace per payment with selected sales rep and POS', () {
    final batch = buildInvoicePaymentBatch(
      bankAccountId: 1000004,
      organizationId: 1000000,
      bPartnerId: 1000123,
      salesRepId: 1009252,
      posId: 1000000,
      configuration: configuration,
      payments: payments,
      invoices: invoices,
      date: DateTime(2026, 8, 27),
    );

    expect(batch, hasLength(5));
    for (var paymentIndex = 0; paymentIndex < payments.length; paymentIndex++) {
      final methodId = payments[paymentIndex]['id'];
      final paymentRequest = batch[paymentIndex * 2];
      final traceRequest = batch[paymentIndex * 2 + 1];
      expect(paymentRequest['responseAlias'], 'payment_$methodId');
      expect(traceRequest['path'], 'v1/models/CDS_POSPaymentTrace');
      expect(traceRequest['responseAlias'], 'payment_trace_$methodId');
      expect(traceRequest['body'], {
        'AD_Org_ID': 1000000,
        'C_Payment_ID': '@payment_$methodId\$.id@',
        'SalesRep_ID': 1009252,
        'C_POS_ID': 1000000,
      });
      expect((traceRequest['body'] as Map).containsKey('DocumentNo'), isFalse);
    }
  });

  test('omits C_POS_ID when there is no POS', () {
    final batch = buildInvoicePaymentBatch(
      bankAccountId: 1000004,
      organizationId: 1000000,
      bPartnerId: 1000123,
      salesRepId: 1009252,
      configuration: configuration,
      payments: [payments.first],
      invoices: [
        {'id': 2000001, 'amountToPay': 100.0, 'outstandingDebt': 100.0},
      ],
      date: DateTime(2026, 8, 27),
    );

    final traceBody = batch[1]['body'] as Map;
    expect(traceBody.containsKey('C_POS_ID'), isFalse);
    expect(traceBody.containsKey('DocumentNo'), isFalse);
  });

  test('accepts traces without DocStatus and completed documents', () {
    final response = [
      {
        'statusCode': 201,
        'body': {
          'id': 1,
          'DocStatus': {'id': 'CO'},
        },
      },
      {
        'statusCode': 201,
        'body': {'id': 2},
      },
      {
        'statusCode': 201,
        'body': {
          'id': 3,
          'DocStatus': {'id': 'CO'},
        },
      },
      {
        'statusCode': 201,
        'body': {'id': 4},
      },
      {
        'statusCode': 201,
        'body': {
          'id': 5,
          'DocStatus': {'id': 'CO'},
        },
      },
    ];

    expect(
      validateInvoicePaymentBatchResponse(response, paymentCount: 2),
      isNull,
    );
  });

  test('identifies trace failures and invalid response counts', () {
    final response = [
      {
        'statusCode': 201,
        'body': {
          'id': 1,
          'DocStatus': {'id': 'CO'},
        },
      },
      {
        'statusCode': 400,
        'body': {'message': 'duplicate payment'},
      },
      {
        'statusCode': 201,
        'body': {
          'id': 3,
          'DocStatus': {'id': 'CO'},
        },
      },
    ];

    expect(
      validateInvoicePaymentBatchResponse(response, paymentCount: 1),
      contains('traza del pago 1'),
    );
    expect(
      validateInvoicePaymentBatchResponse(
        response.take(2).toList(),
        paymentCount: 1,
      ),
      contains('se esperaban 3'),
    );
  });
}
