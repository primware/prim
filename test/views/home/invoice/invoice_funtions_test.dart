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

  test('keeps invoice description when normalizing outstanding invoices', () {
    final invoice = normalizeCompletedCustomerInvoice({
      'id': 1,
      'DocumentNo': 'FAC-1',
      'Description': 'Matrícula del segundo semestre',
      'GrandTotal': 91,
      'AD_Org_ID': {'id': 1000000},
      'C_Currency_ID': {'id': 197},
      'C_AllocationLine': const [],
      'C_InvoiceLine': const [],
    });

    expect(invoice['description'], 'Matrícula del segundo semestre');
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
        response.take(1).toList(),
        paymentCount: 1,
      ),
      contains('se esperaban 3'),
    );
  });

  test('shows the first batch error before reporting a truncated response', () {
    final response = [
      {
        'statusCode': 500,
        'body': {'summary': 'No se pudo completar el pago'},
      },
    ];

    expect(
      validateInvoicePaymentBatchResponse(response, paymentCount: 1),
      'Falló el pago 1: No se pudo completar el pago',
    );
  });

  test('builds a receipt snapshot from all payments and invoices', () {
    final response = [
      {
        'statusCode': 201,
        'body': {
          'id': 501,
          'DocumentNo': 'PAY-501',
          'DocStatus': {'id': 'CO'},
        },
      },
      {
        'statusCode': 201,
        'body': {'id': 601},
      },
      {
        'statusCode': 201,
        'body': {
          'id': 502,
          'DocumentNo': 'PAY-502',
          'DocStatus': {'id': 'CO'},
        },
      },
      {
        'statusCode': 201,
        'body': {'id': 602},
      },
      {
        'statusCode': 201,
        'body': {
          'id': 701,
          'DocumentNo': 'REC-701',
          'DocStatus': {'id': 'CO'},
        },
      },
    ];
    final receipt = buildInvoicePaymentReceiptFromBatch(
      decoded: response,
      bPartnerId: 10,
      bPartnerName: 'Cliente de prueba',
      salesRepId: 20,
      salesRepName: 'Vendedor',
      posId: 30,
      date: DateTime(2026, 8, 27),
      payments: [
        {...payments[0], 'name': 'Efectivo'},
        {...payments[1], 'name': 'ACH'},
      ],
      invoices: [
        {...invoices[0], 'documentNo': 'FAC-1', 'grandTotal': 200.0},
        {...invoices[1], 'documentNo': 'FAC-2', 'grandTotal': 30.0},
      ],
    );

    expect(receipt.allocationId, 701);
    expect(receipt.documentNo, 'REC-701');
    expect(receipt.payments.map((item) => item.documentNo), [
      'PAY-501',
      'PAY-502',
    ]);
    expect(receipt.invoices.map((item) => item.appliedAmount), [110.0, 30.0]);
    expect(receipt.totalApplied, 140.0);
    expect(receipt.totalReceived, 140.0);
    expect(receipt.searchableText, contains('fac-2'));
    expect(receipt.searchableText, contains('cliente de prueba'));
  });
}
