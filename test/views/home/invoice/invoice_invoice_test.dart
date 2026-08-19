import 'package:flutter_test/flutter_test.dart';
import 'package:primware/API/endpoint.dart';
import 'package:primware/views/Home/invoice/invoice_invoice.dart';

void main() {
  test('uses the payment and receipt window endpoint', () {
    final previousBaseUrl = Base.baseURL;
    Base.baseURL = 'https://example.test';

    expect(
      EndPoints.paymentAndReceipt,
      'https://example.test/api/v1/windows/payment-and-receipt',
    );

    Base.baseURL = previousBaseUrl;
  });

  test('builds the C_Payment payload with fixed accounting values', () {
    final payload = buildInvoicePaymentPayload(
      bankAccountId: 1000000,
      tenderTypeId: 'X',
      posTenderTypeId: 1000062,
      amount: 20,
      bPartnerId: 1000049,
      date: DateTime(2026, 8, 19),
    );

    expect(payload, {
      'C_BankAccount_ID': 1000000,
      'TaxAmt': 0,
      'TenderType': {'id': 'X'},
      'C_Currency_ID': 100,
      'C_POSTenderType_ID': 1000062,
      'C_DocType_ID': 1000578,
      'PayAmt': 20.0,
      'C_BPartner_ID': 1000049,
      'DateTrx': '2026-08-19',
      'DateAcct': '2026-08-19',
      'doc-action': 'CO',
    });
  });

  test('compares allocated and payment totals at two decimals', () {
    expect(invoicePaymentAmountsMatch(20, 20.004), isTrue);
    expect(invoicePaymentAmountsMatch(20, 20.01), isFalse);
  });

  test('calculates the amount remaining after other payment methods', () {
    expect(calculateRemainingInvoicePayment(100, const []), 100);
    expect(calculateRemainingInvoicePayment(100, const [35, 15]), 50);
    expect(calculateRemainingInvoicePayment(100, const [110]), 0);
  });

  group('normalizeCompletedCustomerInvoice', () {
    test('uses the full total as debt when there are no allocations', () {
      final invoice = normalizeCompletedCustomerInvoice({
        'id': 1,
        'DocumentNo': '100001',
        'GrandTotal': 100,
      });

      expect(invoice['totalPaid'], 0);
      expect(invoice['outstandingDebt'], 100);
      expect(invoice['paymentProgress'], 0);
    });

    test('normalizes AD_Client_ID from lookup, scalar and missing values', () {
      expect(
        normalizeCompletedCustomerInvoice({
          'GrandTotal': 10,
          'AD_Client_ID': {'id': 1000012},
        })['clientId'],
        1000012,
      );
      expect(
        normalizeCompletedCustomerInvoice({
          'GrandTotal': 10,
          'AD_Client_ID': '1000013',
        })['clientId'],
        1000013,
      );
      expect(
        normalizeCompletedCustomerInvoice({
          'GrandTotal': 10,
          'AD_Client_ID': 1000014,
        })['clientId'],
        1000014,
      );
      expect(
        normalizeCompletedCustomerInvoice({'GrandTotal': 10})['clientId'],
        isNull,
      );
    });

    test('adds positive and negative allocations with their sign', () {
      final invoice = normalizeCompletedCustomerInvoice({
        'id': 1,
        'GrandTotal': '100.00',
        'C_AllocationLine': [
          {'Amount': 30},
          {'Amount': '20'},
          {'Amount': -10},
        ],
      });

      expect(invoice['totalPaid'], 40);
      expect(invoice['outstandingDebt'], 60);
      expect(invoice['paymentProgress'], 0.4);
    });

    test('clamps overpaid debt to zero and progress to one', () {
      final invoice = normalizeCompletedCustomerInvoice({
        'id': 1,
        'GrandTotal': 100,
        'C_AllocationLine': [
          {'Amount': 120},
        ],
      });

      expect(invoice['totalPaid'], 120);
      expect(invoice['outstandingDebt'], 0);
      expect(invoice['paymentProgress'], 1);
    });

    test('allows reversals to increase debt while progress stays at zero', () {
      final invoice = normalizeCompletedCustomerInvoice({
        'id': 1,
        'GrandTotal': 100,
        'C_AllocationLine': [
          {'Amount': -20},
        ],
      });

      expect(invoice['totalPaid'], -20);
      expect(invoice['outstandingDebt'], 120);
      expect(invoice['paymentProgress'], 0);
    });

    test('removes fully paid invoices from the selectable collection', () {
      final invoices = normalizeOutstandingCustomerInvoices([
        {
          'id': 1,
          'GrandTotal': 100,
          'C_AllocationLine': [
            {'Amount': 100},
          ],
        },
        {'id': 2, 'GrandTotal': 50},
      ]);

      expect(invoices, hasLength(1));
      expect(invoices.single['id'], 2);
    });
  });
}
