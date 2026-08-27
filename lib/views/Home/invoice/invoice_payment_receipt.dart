class InvoicePaymentReceipt {
  const InvoicePaymentReceipt({
    required this.allocationId,
    required this.documentNo,
    required this.date,
    required this.customerId,
    required this.customerName,
    required this.salesRepId,
    required this.salesRepName,
    required this.invoices,
    required this.payments,
    this.customerTaxId = '',
    this.customerAddress = '',
    this.customerPhone = '',
    this.posId,
    this.posName = '',
    this.hasTraceConflict = false,
  });

  final int allocationId;
  final String? documentNo;
  final DateTime date;
  final int customerId;
  final String customerName;
  final String customerTaxId;
  final String customerAddress;
  final String customerPhone;
  final int salesRepId;
  final String salesRepName;
  final int? posId;
  final String posName;
  final List<InvoicePaymentReceiptInvoice> invoices;
  final List<InvoicePaymentReceiptPayment> payments;
  final bool hasTraceConflict;

  double get totalApplied => invoices.fold(0, (sum, item) => sum + item.appliedAmount);
  double get totalReceived => payments.fold(0, (sum, item) => sum + item.amount);

  String get displayDocumentNo {
    final value = documentNo?.trim() ?? '';
    return value.isEmpty ? allocationId.toString() : value;
  }

  String get searchableText => [displayDocumentNo, customerName, ...invoices.map((item) => item.documentNo)].join(' ').toLowerCase();
}

class InvoicePaymentReceiptInvoice {
  const InvoicePaymentReceiptInvoice({
    required this.id,
    required this.documentNo,
    required this.originalAmount,
    required this.appliedAmount,
  });

  final int id;
  final String documentNo;
  final double originalAmount;
  final double appliedAmount;
}

class InvoicePaymentReceiptPayment {
  const InvoicePaymentReceiptPayment({required this.id, required this.documentNo, required this.methodName, required this.amount});

  final int id;
  final String documentNo;
  final String methodName;
  final double amount;
}
