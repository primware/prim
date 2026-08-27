import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:primware/API/pos.api.dart';
import 'package:primware/shared/footer.dart';

import 'invoice_payment_print_generator.dart';
import 'invoice_payment_receipt.dart';

class InvoicePaymentDetailsPage extends StatelessWidget {
  const InvoicePaymentDetailsPage({super.key, required this.receipt});

  final InvoicePaymentReceipt receipt;

  String _money(num value) => 'B/.${value.toStringAsFixed(2)}';

  Future<Uint8List> _pdf() => POS.isPOS
      ? generateInvoicePaymentPOSTicket(receipt)
      : generateInvoicePaymentReceipt(receipt);

  Future<bool?> _printConfirmation(BuildContext context) => showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Theme.of(dialogContext).cardColor,
      title: Column(
        children: [
          Icon(
            Icons.print_rounded,
            size: 45,
            color: Theme.of(dialogContext).colorScheme.primary,
          ),
          const SizedBox(height: 10),
          const Text(
            'Confirmar imprimir',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: const Text(
        '¿Desea imprimir?',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('No'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Sí'),
        ),
      ],
    ),
  );

  Future<void> _print(BuildContext context) async {
    if (await _printConfirmation(context) != true) return;
    try {
      final pdfBytes = await _pdf();
      try {
        final printers = await Printing.listPrinters();
        final defaultPrinter = printers.firstWhere(
          (printer) => printer.isDefault,
          orElse: () => printers.isNotEmpty
              ? printers.first
              : throw Exception('No hay impresoras disponibles'),
        );
        await Printing.directPrintPdf(
          printer: defaultPrinter,
          usePrinterSettings: true,
          dynamicLayout: true,
          onLayout: (_) => pdfBytes,
        );
      } catch (_) {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'Recibo_Pago_${receipt.displayDocumentNo}.pdf',
        );
      }
    } catch (_) {}
  }

  Future<void> _share(BuildContext context) async {
    try {
      await Printing.sharePdf(
        bytes: await _pdf(),
        filename: 'Recibo_Pago_${receipt.displayDocumentNo}.pdf',
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo compartir el recibo: $error')),
        );
      }
    }
  }

  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Row(
      children: List.generate(
        28,
        (_) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 1,
            color: Colors.grey.shade300,
          ),
        ),
      ),
    ),
  );

  Widget _sectionTitle(String title) => Text(
    title.toUpperCase(),
    style: TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.grey.shade600,
      letterSpacing: 1.2,
      fontSize: 12,
    ),
  );

  Widget _statusChip(String label, IconData icon, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(50),
      border: Border.all(color: color),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _infoRow(String label, String value, {bool emphasized = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 145,
              child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontWeight: emphasized ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ticketColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;
    final textColor = isDark ? Colors.grey.shade300 : Colors.black87;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Pago a facturas #${receipt.displayDocumentNo}'),
        actions: [
          IconButton(
            tooltip: 'Compartir',
            onPressed: () => _share(context),
            icon: const Icon(Icons.share_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Imprimir',
              onPressed: () => _print(context),
              icon: const Icon(Icons.print_rounded),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomFooter(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              decoration: BoxDecoration(
                color: ticketColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: DefaultTextStyle(
                style: TextStyle(color: textColor, fontSize: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          if (POSPrinter.logo != null) ...[
                            Image.memory(
                              POSPrinter.logo!,
                              height: 60,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 12),
                          ],
                          Text(
                            POSPrinter.headerName ??
                                'Recibo de pago a facturas',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                          ),
                          if (POSPrinter.headerTaxID != null)
                            Text(
                              'RUC: ${POSPrinter.headerTaxID}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    _infoRow(
                      'Recibo',
                      receipt.displayDocumentNo,
                      emphasized: true,
                    ),
                    _infoRow('Cliente', receipt.customerName),
                    if (receipt.customerTaxId.isNotEmpty)
                      _infoRow('Identificación', receipt.customerTaxId),
                    _infoRow('Representante', receipt.salesRepName),
                    if (receipt.posId != null)
                      _infoRow(
                        'POS',
                        receipt.posName.isEmpty
                            ? receipt.posId.toString()
                            : receipt.posName,
                      ),
                    if (receipt.hasTraceConflict) ...[
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Esta operación contiene trazas con vendedores o POS diferentes.',
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _statusChip(
                          'Pago a facturas',
                          Icons.receipt_long_outlined,
                          Theme.of(context).primaryColor,
                        ),
                        _statusChip(
                          'Completado',
                          Icons.check_circle_outline,
                          Colors.green,
                        ),
                      ],
                    ),
                    _divider(),
                    _sectionTitle('Facturas aplicadas'),
                    const SizedBox(height: 10),
                    ...receipt.invoices.map(
                      (invoice) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Factura ${invoice.documentNo}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Valor: ${_money(invoice.originalAmount)}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _money(invoice.appliedAmount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _divider(),
                    _sectionTitle('Métodos de pago'),
                    const SizedBox(height: 10),
                    ...receipt.payments.map(
                      (payment) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    payment.methodName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Pago ${payment.documentNo}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _money(payment.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _divider(),
                    _infoRow(
                      'Total aplicado',
                      _money(receipt.totalApplied),
                      emphasized: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
