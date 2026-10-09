import 'package:primware/shared/format_amount.dart';
import 'dart:convert';
import 'package:primware/localization/app_locale.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter/services.dart';
import '../../../API/fe.api.dart';
import '../../../shared/format_date.dart';
import '../../../shared/document_number_barcode.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../../API/endpoint.dart';
import '../../../API/pos.api.dart';
import '../../../API/token.api.dart';
import 'order_line_helper.dart';

bool hasPrintableFE(Map<String, dynamic>? info) => FESession.hasFEConfig && (info?['url']?.toString().trim().isNotEmpty ?? false);

bool _hasHeaderValue(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isNotEmpty && text != '?';
}

class GiftInvoiceLabels {
  const GiftInvoiceLabels({
    required this.title,
    required this.orderNumber,
    required this.date,
    required this.servedBy,
    required this.identification,
    required this.customer,
    required this.address,
    required this.phone,
    required this.product,
    required this.quantity,
  });

  final String title;
  final String orderNumber;
  final String date;
  final String servedBy;
  final String identification;
  final String customer;
  final String address;
  final String phone;
  final String product;
  final String quantity;
}

Future<Uint8List> generateGiftOrderTicket(Map<String, dynamic> order, {required GiftInvoiceLabels labels}) =>
    _generateGiftInvoice(order, labels: labels, isPOS: false);

Future<Uint8List> generateGiftPOSTicket(Map<String, dynamic> order, {required GiftInvoiceLabels labels}) =>
    _generateGiftInvoice(order, labels: labels, isPOS: true);

Future<Uint8List> _generateGiftInvoice(Map<String, dynamic> order, {required GiftInvoiceLabels labels, required bool isPOS}) async {
  final pdf = pw.Document();
  final lines = (order['C_OrderLine'] as List?) ?? const [];
  String str(dynamic value) => value?.toString() ?? '';
  final docNo = str(order['DocumentNo']);
  final date = formatIdempiereDateUI(str(order['DateOrdered']));
  final servedBy = str(order['SalesRep_ID']?['name']);
  final taxID = str(order['bpartner']?['taxID']);
  final phone = str(order['bpartner']?['phone']);
  final customerName = str(order['bpartner']?['name']);
  final customerLocation = str(order['bpartner']?['location']);
  final baseTextStyle = pw.TextStyle(fontSize: isPOS ? 8 : 10);

  List<pw.Widget> merchantHeader() => [
    if (POSPrinter.logo != null)
      pw.Center(
        child: pw.Image(pw.MemoryImage(POSPrinter.logo!), width: isPOS ? 60 : 100, height: isPOS ? 60 : 100, fit: pw.BoxFit.contain),
      ),
    if (_hasHeaderValue(POSPrinter.headerName)) pw.Text(POSPrinter.headerName!, textAlign: pw.TextAlign.center),
    if (_hasHeaderValue(POSPrinter.headerAddress)) pw.Text(POSPrinter.headerAddress!, textAlign: pw.TextAlign.center),
    if (_hasHeaderValue(POSPrinter.headerTaxID)) pw.Text('RUC: ${POSPrinter.headerTaxID}', textAlign: pw.TextAlign.center),
    if (_hasHeaderValue(POSPrinter.headerDV)) pw.Text('DV: ${POSPrinter.headerDV}', textAlign: pw.TextAlign.center),
    if (_hasHeaderValue(POSPrinter.headerPhone)) pw.Text('${labels.phone}: ${POSPrinter.headerPhone}', textAlign: pw.TextAlign.center),
    if (_hasHeaderValue(POSPrinter.headerEmail)) pw.Text(POSPrinter.headerEmail!, textAlign: pw.TextAlign.center),
    if (_hasHeaderValue(POSPrinter.header1)) pw.Text(POSPrinter.header1!, textAlign: pw.TextAlign.center),
    if (_hasHeaderValue(POSPrinter.header2)) pw.Text(POSPrinter.header2!, textAlign: pw.TextAlign.center),
    if (_hasHeaderValue(POSPrinter.header3)) pw.Text(POSPrinter.header3!, textAlign: pw.TextAlign.center),
    if (_hasHeaderValue(POSPrinter.header4)) pw.Text(POSPrinter.header4!, textAlign: pw.TextAlign.center),
  ];

  List<pw.Widget> customerDetails() => [
    pw.Text('${labels.orderNumber}: $docNo'),
    pw.Text('${labels.date}: $date'),
    if (servedBy.isNotEmpty) pw.Text('${labels.servedBy}: $servedBy'),
    if (taxID.isNotEmpty) pw.Text('${labels.identification}: $taxID'),
    if (customerName.isNotEmpty) pw.Text('${labels.customer}: $customerName'),
    if (customerLocation.isNotEmpty) pw.Text('${labels.address}: $customerLocation'),
    if (phone.isNotEmpty) pw.Text('${labels.phone}: $phone'),
  ];

  List<pw.Widget> footer() => [
    if (_hasHeaderValue(POSPrinter.footer1)) pw.Text(POSPrinter.footer1!, textAlign: pw.TextAlign.center),
    if (_hasHeaderValue(POSPrinter.footer2)) pw.Text(POSPrinter.footer2!, textAlign: pw.TextAlign.center),
    if (_hasHeaderValue(POSPrinter.footer3)) pw.Text(POSPrinter.footer3!, textAlign: pw.TextAlign.center),
    if (_hasHeaderValue(POSPrinter.footer4)) pw.Text(POSPrinter.footer4!, textAlign: pw.TextAlign.center),
  ];

  final content = <pw.Widget>[
    ...merchantHeader(),
    pw.SizedBox(height: 12),
    pw.Text(
      labels.title,
      textAlign: pw.TextAlign.center,
      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: isPOS ? 12 : 16),
    ),
    pw.SizedBox(height: 14),
    ...customerDetails(),
    pw.SizedBox(height: 12),
    if (lines.isNotEmpty)
      pw.Table.fromTextArray(
        headers: [labels.product, labels.quantity],
        data: lines.map((rawLine) {
          final line = rawLine as Map;
          final name = orderLineDisplayName(line);
          final rawQuantity = line['QtyOrdered'] ?? line['QtyEntered'] ?? 0;
          final quantity = rawQuantity is num ? rawQuantity.toDouble() : double.tryParse(rawQuantity.toString()) ?? 0.0;
          return [name, quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 2)];
        }).toList(),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: isPOS ? 8 : 11),
        cellStyle: pw.TextStyle(fontSize: isPOS ? 7 : 10),
        columnWidths: {0: const pw.FlexColumnWidth(5), 1: pw.FixedColumnWidth(isPOS ? 32 : 55)},
        cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerRight},
      ),
    pw.SizedBox(height: 14),
    documentNumberBarcode(docNo, isPOS: isPOS),
    ...footer(),
    if (isPOS) pw.SizedBox(height: 56),
  ];

  final theme = pw.ThemeData.withFont(base: pw.Font.helvetica(), bold: pw.Font.helveticaBold()).copyWith(defaultTextStyle: baseTextStyle);

  if (isPOS) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80.copyWith(marginTop: 8, marginBottom: 8, width: 75 * PdfPageFormat.mm),
        theme: theme,
        build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: content),
      ),
    );
  } else {
    pdf.addPage(pw.MultiPage(theme: theme, build: (_) => content));
  }
  return pdf.save();
}

Future<Uint8List> generateOrderTicket(
  Map<String, dynamic> order, {
  required BuildContext context,
  Map<String, dynamic>? electronicInvoiceInfo,
}) async {
  // Currency formatter
  final NumberFormat nf = NumberFormat.currency(locale: 'en_US', symbol: 'B/.', decimalDigits: 2);

  // Fetch FE info if order['id'] exists
  Map<String, dynamic>? feInfo = electronicInvoiceInfo;
  if (feInfo == null && order['id'] != null) {
    feInfo = await fetchElectronicInvoiceInfo(orderId: order['id']);
  }

  final showFE = hasPrintableFE(feInfo);
  final dgi = showFE ? (await rootBundle.load('assets/img/dgi.png')).buffer.asUint8List() : null;
  final pdf = pw.Document();
  final List lines = (order['C_OrderLine'] as List?) ?? const [];

  // Header fields (as in generatePOSTicket)
  String str(dynamic v) => v?.toString() ?? '';
  bool hasHeaderValue(dynamic value) => _hasHeaderValue(value);
  String docTypename = order['doctypetarget']?['name'] ?? '';
  final docNo = str(order['DocumentNo']);
  final date = formatIdempiereDateUI(str(order['DateOrdered']));
  final servedBy = str(order['SalesRep_ID']?['name'] ?? '');
  final taxID = str(order['bpartner']?['taxID'] ?? '');
  final phone = str(order['bpartner']?['phone'] ?? '');
  final customerName = str(order['bpartner']?['name'] ?? AppLocale.ticketCashCustomerLabel.getString(context));
  final customeLocation = str(order['bpartner']?['location'] ?? '');

  pdf.addPage(
    pw.MultiPage(
      build: (pdfContext) => <pw.Widget>[
        if (dgi != null) ...[
          pw.Center(child: pw.Image(pw.MemoryImage(dgi), width: 50, fit: pw.BoxFit.contain)),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              AppLocale.es[AppLocale.ticketElectronicInvoiceAuxiliaryTitle] as String,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ),
          if (Localizations.localeOf(context).languageCode == 'en')
            pw.Center(
              child: pw.Text(
                AppLocale.ticketElectronicInvoiceAuxiliaryTitle.getString(context),
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 9),
              ),
            ),
          pw.SizedBox(height: 10),
        ],
        // Header + General info with QR at top-right (if FE exists)
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 3,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  POSPrinter.logo != null
                      ? pw.Center(child: pw.Image(pw.MemoryImage(POSPrinter.logo!), width: 100, height: 100, fit: pw.BoxFit.contain))
                      : pw.SizedBox(),
                  pw.SizedBox(height: 4),
                  if (hasHeaderValue(POSPrinter.headerName)) pw.Text(POSPrinter.headerName!, textAlign: pw.TextAlign.center),
                  if (hasHeaderValue(POSPrinter.headerAddress)) pw.Text(POSPrinter.headerAddress!, textAlign: pw.TextAlign.center),
                  if (hasHeaderValue(POSPrinter.headerTaxID)) pw.Text('RUC: ${POSPrinter.headerTaxID}', textAlign: pw.TextAlign.center),
                  if (hasHeaderValue(POSPrinter.headerDV)) pw.Text('DV: ${POSPrinter.headerDV}', textAlign: pw.TextAlign.center),
                  if (hasHeaderValue(POSPrinter.headerPhone))
                    pw.Text(
                      '${AppLocale.ticketPhoneShortLabel.getString(context)}: ${POSPrinter.headerPhone}',
                      textAlign: pw.TextAlign.center,
                    ),
                  if (hasHeaderValue(POSPrinter.headerEmail)) pw.Text(POSPrinter.headerEmail!, textAlign: pw.TextAlign.center),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    docTypename,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
                  ),
                  pw.SizedBox(height: 18),

                  // Order details
                  pw.Text('${AppLocale.ticketOrderNumberLabel.getString(context)}: $docNo'),
                  pw.Text('${AppLocale.ticketDateLabel.getString(context)}: $date'),
                  if (servedBy.isNotEmpty) pw.Text('${AppLocale.ticketSalesRepresentativeLabel.getString(context)}: $servedBy'),
                  if (taxID.isNotEmpty) pw.Text('${AppLocale.ticketIdentificationNumberLabel.getString(context)}: $taxID'),
                  pw.Text('${AppLocale.ticketCustomerLabel.getString(context)}: $customerName'),
                  if (customeLocation.isNotEmpty) pw.Text('${AppLocale.ticketAddressLabel.getString(context)}: $customeLocation'),
                  if (phone.isNotEmpty) pw.Text('${AppLocale.ticketPhoneLabel.getString(context)}: $phone'),
                ],
              ),
            ),
            if (hasPrintableFE(feInfo)) pw.SizedBox(width: 10),
            if (hasPrintableFE(feInfo))
              pw.Expanded(
                flex: 2,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.BarcodeWidget(
                      data: feInfo?['url'] ?? '',
                      barcode: pw.Barcode.qrCode(errorCorrectLevel: pw.BarcodeQRCorrectionLevel.medium),
                      width: 120,
                      height: 120,
                    ),
                  ],
                ),
              ),
          ],
        ),

        pw.SizedBox(height: 12),
        // Products table
        if (lines.isNotEmpty) ...[
          pw.Table.fromTextArray(
            headers: [
              AppLocale.ticketProductLabel.getString(context),
              AppLocale.ticketDescriptionLabel.getString(context),
              AppLocale.ticketQuantityTimesPriceLabel.getString(context),
              AppLocale.ticketTaxLabel.getString(context),
              AppLocale.ticketSubtotalLabel.getString(context),
              AppLocale.ticketTotalLabel.getString(context),
            ],
            data: lines.map((line) {
              final name = orderLineDisplayName(line as Map);
              final qty = (line['QtyOrdered'] ?? 0);
              final price = (line['PriceActual'] as num?)?.toDouble() ?? 0.0;
              final rate = (line['C_Tax_ID']?['Rate'] as num?)?.toDouble() ?? 0.0;
              final net = (line['LineNetAmt'] as num?) ?? 0;
              final tax = (net * rate / 100);
              final total = net + tax;
              final description = line['Description']?.toString() ?? '';
              return [name, description, "$qty x ${nf.format(price)}", "${rate.toStringAsFixed(0)}%", nf.format(net), nf.format(total)];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            cellStyle: pw.TextStyle(fontSize: 10),
            columnWidths: {
              0: pw.FixedColumnWidth(95), // Producto
              1: pw.FlexColumnWidth(3), // Descripción
              2: pw.FixedColumnWidth(90), // Cant. x Precio
              3: pw.FixedColumnWidth(40), // Impuesto
              4: pw.FixedColumnWidth(65), // Subtotal
              5: pw.FixedColumnWidth(65), // Total
            },
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
            },
          ),
          pw.SizedBox(height: 20),
        ],
        // Totals section
        pw.Text(
          "${AppLocale.ticketNetTotalLabel.getString(context)}: ${nf.format(order['TotalLines'])}",
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          "${AppLocale.ticketGrandTotalLabel.getString(context)}: ${nf.format(order['GrandTotal'])}",
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
        ),
        pw.SizedBox(height: 16),
        // FE footer note (QR is shown at top-right)
        if (hasPrintableFE(feInfo)) ...[
          pw.Divider(),
          pw.SizedBox(height: 6),
          pw.Text(
            AppLocale.ticketElectronicInvoiceTitle.getString(context),
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
          pw.SizedBox(height: 4),
          if (_hasHeaderValue(feInfo?['protocolo']))
            pw.Text(
              '${AppLocale.ticketAuthorizationProtocolLabel.getString(context)}: ${feInfo?['protocolo']}',
              style: pw.TextStyle(fontSize: 8),
            ),
          pw.Text(AppLocale.ticketInvoiceAccessKeyConsultation.getString(context), style: pw.TextStyle(fontSize: 8)),
          pw.Text('https://dgi-fep.mef.gob.pa/Consultas/FacturasPorCUFE', style: pw.TextStyle(fontSize: 8)),
          if (electronicInvoiceCUFE(feInfo!).isNotEmpty) ...[
            pw.Text(AppLocale.ticketUsingCUFE.getString(context), style: pw.TextStyle(fontSize: 8)),
            pw.Text(electronicInvoiceCUFE(feInfo), style: pw.TextStyle(fontSize: 8)),
          ],
          pw.SizedBox(height: 6),
        ],
        documentNumberBarcode(docNo, isPOS: false),
        if (hasHeaderValue(POSPrinter.footer1)) pw.Text(POSPrinter.footer1!, textAlign: pw.TextAlign.center),
        if (hasHeaderValue(POSPrinter.footer2)) pw.Text(POSPrinter.footer2!, textAlign: pw.TextAlign.center),
        if (hasHeaderValue(POSPrinter.footer3)) pw.Text(POSPrinter.footer3!, textAlign: pw.TextAlign.center),
        if (hasHeaderValue(POSPrinter.footer4)) pw.Text(POSPrinter.footer4!, textAlign: pw.TextAlign.center),
      ],
    ),
  );
  return pdf.save();
}

Future<Map<String, dynamic>?> fetchElectronicInvoiceInfo({required int orderId}) async {
  try {
    final uri = Uri.parse('${EndPoints.cInvoice}?\$filter=C_Order_ID eq $orderId&\$expand=FE_InvoiceResponseLog');
    final response = await get(uri, headers: {'Content-Type': 'application/json; charset=UTF-8', 'Authorization': Token.auth!});

    if (response.statusCode != 200) {
      CurrentLogMessage.add('FE query HTTP ${response.statusCode}', level: 'WARNING', tag: 'FE');
      return null;
    }

    final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
    final List records = (jsonResponse['records'] as List?) ?? const [];
    if (records.isEmpty) return null;

    final invoice = records.firstWhere((record) {
      final logs = (record['FE_InvoiceResponseLog'] as List?) ?? const [];
      return record['RelatedInvoice_ID'] == null && logs.isNotEmpty;
    }, orElse: () => records.firstWhere((record) => record['RelatedInvoice_ID'] == null, orElse: () => records.first));
    final List logs = (invoice['FE_InvoiceResponseLog'] as List?) ?? const [];
    if (logs.isEmpty) return null;

    final logsSorted = [...logs]
      ..sort((a, b) {
        final aId = (a['id'] as num?)?.toInt() ?? 0;
        final bId = (b['id'] as num?)?.toInt() ?? 0;
        return bId.compareTo(aId);
      });

    final latest = logsSorted.first;

    final responseCode = latest['FE_ResponseCode']?.toString() ?? '';
    final responseMessage = latest['FE_ResponseMessage']?.toString() ?? '';
    final cufe = _hasHeaderValue(latest['FE_ResponseCUFE'])
        ? latest['FE_ResponseCUFE'].toString()
        : invoice['FE_FiscalInvoiceNumber']?.toString() ?? '';
    final protocolo = latest['FE_NroProtocoloAutorizacion']?.toString() ?? '';
    final url = latest['FE_ResponseQR']?.toString() ?? '';

    return {
      'responseCode': responseCode,
      'responseMessage': responseMessage,
      'cufe': cufe,
      'protocolo': protocolo,
      'url': url,
      'cInvoiceID': invoice['id'],
      'invoice': invoice,
    };
  } catch (e) {
    CurrentLogMessage.add('FE_InvoiceResponseLog: $e', level: 'WARNING', tag: 'FE');
    return null;
  }
}

Future<Uint8List> generatePOSTicket(
  Map<String, dynamic> order, {
  required BuildContext context,
  Map<String, dynamic>? electronicInvoiceInfo,
}) async {
  // Consultar datos de Factura Electrónica (FE)
  final int? orderId = (order['id'] as int?);
  final feInfo = electronicInvoiceInfo ?? (orderId != null ? await fetchElectronicInvoiceInfo(orderId: orderId) : null);

  final showFE = hasPrintableFE(feInfo);
  final dgi = showFE ? (await rootBundle.load('assets/img/dgi.png')).buffer.asUint8List() : null;
  final pacFooter = showFE ? buildPACFooter(context) : <String>[];
  final pdf = pw.Document();
  final pageFormat = PdfPageFormat.roll80;

  // Helpers
  String str(dynamic v) => v?.toString() ?? '';
  bool hasHeaderValue(dynamic value) => _hasHeaderValue(value);
  String money(num? v) => 'B/.${formatAmount(v)}';

  String docTypename = order['doctypetarget']?['name'] ?? '';

  // Order fields (safe access)
  final docNo = str(order['DocumentNo']);
  final date = formatIdempiereDateUI(str(order['DateOrdered']));
  final servedBy = str(order['SalesRep_ID']?['name'] ?? '');
  final taxID = str(order['bpartner']?['taxID'] ?? '');
  final phone = str(order['bpartner']?['phone'] ?? '');
  final customerName = str(order['bpartner']?['name'] ?? AppLocale.ticketCashCustomerLabel.getString(context));
  final customeLocation = str(order['bpartner']?['location'] ?? '');

  // Lines & taxes
  final List lines = (order['C_OrderLine'] as List?) ?? const [];
  final payments = (order['payments'] as List?) ?? const [];
  final taxSummary = _calculateTaxSummary([order]);

  final double taxTotal = taxSummary.values.map((e) => e['tax'] as double).fold(0.0, (a, b) => a + b);
  final double grandTotal = (order['GrandTotal'] as num?)?.toDouble() ?? 0.0;

  // Taxes summary (net + taxes)
  final netSum = taxSummary.values.map((e) => e['net'] as double).fold(0.0, (a, b) => a + b);

  final baseTextStyle = pw.TextStyle(fontSize: 8);
  final smallTextStyle = pw.TextStyle(fontSize: 6);

  final theme = pw.ThemeData.withFont(base: pw.Font.helvetica(), bold: pw.Font.helveticaBold()).copyWith(defaultTextStyle: baseTextStyle);

  // Render PDF
  pdf.addPage(
    pw.Page(
      pageFormat: pageFormat.copyWith(marginTop: 8, marginBottom: 8, width: 75 * PdfPageFormat.mm),
      theme: theme,
      build: (pdfContext) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            if (dgi != null) ...[
              pw.Center(child: pw.Image(pw.MemoryImage(dgi), width: 32, fit: pw.BoxFit.contain)),
              pw.SizedBox(height: 3),
              pw.Text(
                AppLocale.es[AppLocale.ticketElectronicInvoiceAuxiliaryTitle] as String,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6),
              ),
              if (Localizations.localeOf(context).languageCode == 'en')
                pw.Text(
                  AppLocale.ticketElectronicInvoiceAuxiliaryTitle.getString(context),
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 6),
                ),
            ],
            POSPrinter.logo != null
                ? pw.Center(child: pw.Image(pw.MemoryImage(POSPrinter.logo!), width: 60, height: 60, fit: pw.BoxFit.contain))
                : pw.SizedBox(),
            pw.SizedBox(height: 4),
            if (hasHeaderValue(POSPrinter.headerName)) pw.Text(POSPrinter.headerName!, textAlign: pw.TextAlign.center),
            if (hasHeaderValue(POSPrinter.headerAddress)) pw.Text(POSPrinter.headerAddress!, textAlign: pw.TextAlign.center),
            if (hasHeaderValue(POSPrinter.headerTaxID)) pw.Text('RUC: ${POSPrinter.headerTaxID}', textAlign: pw.TextAlign.center),
            if (hasHeaderValue(POSPrinter.headerDV)) pw.Text('DV: ${POSPrinter.headerDV}', textAlign: pw.TextAlign.center),
            if (hasHeaderValue(POSPrinter.headerPhone))
              pw.Text('${AppLocale.ticketPhoneShortLabel.getString(context)}: ${POSPrinter.headerPhone}', textAlign: pw.TextAlign.center),
            if (hasHeaderValue(POSPrinter.headerEmail)) pw.Text(POSPrinter.headerEmail!, textAlign: pw.TextAlign.center),

            if (hasHeaderValue(POSPrinter.header1)) pw.Text(POSPrinter.header1!, textAlign: pw.TextAlign.center),
            if (hasHeaderValue(POSPrinter.header2)) pw.Text(POSPrinter.header2!, textAlign: pw.TextAlign.center),
            if (hasHeaderValue(POSPrinter.header3)) pw.Text(POSPrinter.header3!, textAlign: pw.TextAlign.center),
            if (hasHeaderValue(POSPrinter.header4)) pw.Text(POSPrinter.header4!, textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 12),
            pw.Text(
              docTypename,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),

            pw.SizedBox(height: 18),

            // Detalles (alineados a la izquierda)
            pw.Text('${AppLocale.ticketReceiptNumberLabel.getString(context)}: $docNo'),
            pw.Text('${AppLocale.ticketDateLabel.getString(context)}: $date'),
            if (servedBy.isNotEmpty) pw.Text('${AppLocale.ticketServedByLabel.getString(context)}: $servedBy'),
            pw.Text('${AppLocale.ticketIdentificationLabel.getString(context)}: $taxID'),
            pw.Text('${AppLocale.ticketCustomerLabel.getString(context)}: $customerName'),
            pw.Text('${AppLocale.ticketAddressLabel.getString(context)}: $customeLocation'),
            if (phone.isNotEmpty) pw.Text('${AppLocale.ticketPhoneLabel.getString(context)}: $phone'),
            pw.SizedBox(height: 12),

            if (lines.isNotEmpty) ...[
              // Tabla de ítems (alineada en 4 columnas)
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 20,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(AppLocale.ticketItemLabel.getString(context), maxLines: 1),
                        pw.Text(AppLocale.ticketPriceTimesQuantityLabel.getString(context), maxLines: 1, style: smallTextStyle),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    flex: 15,
                    child: pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(AppLocale.ticketSubtotalLabel.getString(context), maxLines: 1),
                    ),
                  ),
                ],
              ),
              pw.Divider(),
              pw.SizedBox(height: 6),
              ...lines.map((line) {
                final name = orderLineDisplayName(line as Map);
                final qty = (line['QtyOrdered'] as num?)?.toDouble() ?? 0.0;
                final price = (line['PriceActual'] as num?)?.toDouble() ?? 0.0;
                final net = (line['LineNetAmt'] as num?)?.toDouble() ?? 0.0;
                final rate = (line['C_Tax_ID']?['Rate'] as num?)?.toDouble() ?? 0.0;
                final tax = double.parse((net * (rate / 100)).toStringAsFixed(2));
                final value = net + tax;
                final description = line['Description']?.toString() ?? '';
                final discount = (line['Discount'] as num?)?.toDouble() ?? 0.0;

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          flex: 20,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(name, overflow: pw.TextOverflow.span),
                              pw.Text('${money(price)} x ${qty.toStringAsFixed(qty % 1 == 0 ? 0 : 2)}', maxLines: 1, style: smallTextStyle),
                              if (discount > 0)
                                pw.Text(
                                  '${AppLocale.ticketDiscountLabel.getString(context)}: ${discount.toStringAsFixed(2)}%',
                                  maxLines: 1,
                                  style: smallTextStyle.copyWith(fontStyle: pw.FontStyle.italic),
                                ),
                              if (description.isNotEmpty && description != name)
                                pw.Text(description, maxLines: 1, style: smallTextStyle.copyWith(fontStyle: pw.FontStyle.italic)),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          flex: 15,
                          child: pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text(money(value), maxLines: 1)),
                        ),
                      ],
                    ),
                  ],
                );
              }),
              pw.SizedBox(height: 6),
              pw.Divider(),
              // Totales por items
              pw.Text('${AppLocale.ticketItemCountLabel.getString(context)}: ${lines.length}'),
              pw.SizedBox(height: 12),
            ],
            // Formas de pago
            if (payments.isNotEmpty) ...[
              pw.Text(AppLocale.ticketPaymentMethodsLabel.getString(context), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ...payments.map<pw.Widget>((payment) {
                final payType = payment['C_POSTenderType_ID']?['identifier'] ?? AppLocale.ticketOtherPaymentMethod.getString(context);
                final amount = (payment['PayAmt'] as num?)?.toDouble() ?? 0.0;
                return pw.Text('- $payType: ${money(amount)}');
              }),
              pw.SizedBox(height: 10),
            ],

            // Impuestos
            pw.Text(
              '${AppLocale.ticketNetBeforeITBMSLabel.getString(context)}: ${money(netSum)}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('ITBMS: ${money(taxTotal)}'),
            pw.SizedBox(height: 12),

            pw.Text(
              '${AppLocale.ticketTotalLabel.getString(context)}: ${money(grandTotal)}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
            ),
            pw.SizedBox(height: 10),

            // Electronic invoice data
            if (hasPrintableFE(feInfo)) ...[
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Text(
                AppLocale.ticketElectronicInvoiceTitle.getString(context),
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
              ),
              pw.SizedBox(height: 6),
              if (_hasHeaderValue(feInfo?['protocolo']))
                pw.Text(
                  '${AppLocale.ticketAuthorizationProtocolLabel.getString(context)}: ${feInfo?['protocolo']}',
                  style: pw.TextStyle(fontSize: 6),
                ),
              pw.Text(AppLocale.ticketInvoiceAccessKeyConsultation.getString(context), style: pw.TextStyle(fontSize: 6)),
              pw.Text('https://dgi-fep.mef.gob.pa/Consultas/FacturasPorCUFE', style: pw.TextStyle(fontSize: 6)),
              if (electronicInvoiceCUFE(feInfo!).isNotEmpty) ...[
                pw.Text(AppLocale.ticketUsingCUFE.getString(context), style: pw.TextStyle(fontSize: 6)),
                pw.Text(electronicInvoiceCUFE(feInfo), style: pw.TextStyle(fontSize: 6)),
              ],
              pw.SizedBox(height: 6),
              pw.Text(AppLocale.ticketScanInvoiceQRCode.getString(context), style: pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.BarcodeWidget(
                  data: feInfo['url'] ?? '',
                  barcode: pw.Barcode.qrCode(errorCorrectLevel: pw.BarcodeQRCorrectionLevel.medium),
                  width: 120,
                  height: 120,
                ),
              ),
              pw.SizedBox(height: 10),
            ],

            documentNumberBarcode(docNo, isPOS: true),

            for (final text in pacFooter) pw.Text(text, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 7)),
            // Footer
            if (hasHeaderValue(POSPrinter.footer1)) pw.Text(POSPrinter.footer1!, textAlign: pw.TextAlign.center),
            if (hasHeaderValue(POSPrinter.footer2)) pw.Text(POSPrinter.footer2!, textAlign: pw.TextAlign.center),
            if (hasHeaderValue(POSPrinter.footer3)) pw.Text(POSPrinter.footer3!, textAlign: pw.TextAlign.center),
            if (hasHeaderValue(POSPrinter.footer4)) pw.Text(POSPrinter.footer4!, textAlign: pw.TextAlign.center),

            pw.SizedBox(height: 56),
          ],
        );
      },
    ),
  );

  return pdf.save();
}

Map<String, Map<String, double>> _calculateTaxSummary(List<dynamic> records) {
  final Map<String, Map<String, double>> taxSummary = {};

  for (var order in records) {
    if (order.containsKey("C_OrderLine")) {
      for (var line in order["C_OrderLine"]) {
        final tax = line["C_Tax_ID"];
        final String taxName = tax?["Name"]?.toString() ?? '';
        final double taxRate = (tax?["Rate"] as num?)?.toDouble() ?? 0;
        final double lineNetAmt = (line["LineNetAmt"] as num?)?.toDouble() ?? 0;

        final taxKey = "$taxName (${taxRate.toStringAsFixed(0)}%)";

        taxSummary.putIfAbsent(taxKey, () => {"net": 0.0, "tax": 0.0, "total": 0.0});

        final double taxAmount = double.parse((lineNetAmt * (taxRate / 100)).toStringAsFixed(2));
        taxSummary[taxKey]!["net"] = taxSummary[taxKey]!["net"]! + lineNetAmt;
        taxSummary[taxKey]!["tax"] = taxSummary[taxKey]!["tax"]! + taxAmount;
        taxSummary[taxKey]!["total"] = taxSummary[taxKey]!["total"]! + lineNetAmt + taxAmount;
      }
    }
  }

  return taxSummary;
}

List<String> buildPACFooter(BuildContext context) {
  final missing = <String>[
    if (FESession.legalName == null) 'FE_LegalName',
    if (FESession.taxId == null) 'TaxID',
    if (FESession.resolution == null) 'FE_Resolution',
    if (FESession.resolutionDate == null) 'FE_ResolutionDate',
  ];
  if (missing.isNotEmpty) CurrentLogMessage.add('PAC missing: ${missing.join(', ')}', level: 'WARNING', tag: 'FE');
  final name = FESession.legalName;
  final tax = FESession.taxId;
  final resolution = FESession.resolution;
  final date = FESession.resolutionDate == null ? null : DateFormat('dd/MM/yyyy').format(FESession.resolutionDate!);
  if (name == null && tax == null && resolution == null && date == null) return [];
  String fill(String template) => template
      .replaceAll('{name}', name ?? '')
      .replaceAll('{taxId}', tax ?? '')
      .replaceAll('{resolution}', resolution ?? '')
      .replaceAll('{date}', date ?? '');
  String legend({required bool spanish}) {
    if (name != null && tax != null && resolution != null && date != null) {
      return fill(spanish ? AppLocale.es[AppLocale.pacValidationLegend] as String : AppLocale.pacValidationLegend.getString(context));
    }
    return '${[if (name != null) fill(spanish ? AppLocale.es[AppLocale.pacValidatedBy] as String : AppLocale.pacValidatedBy.getString(context)), if (tax != null) fill(spanish ? AppLocale.es[AppLocale.pacTaxId] as String : AppLocale.pacTaxId.getString(context)), spanish ? AppLocale.es[AppLocale.pacQualifiedProvider] as String : AppLocale.pacQualifiedProvider.getString(context), if (resolution != null) fill(spanish ? AppLocale.es[AppLocale.pacResolutionNumber] as String : AppLocale.pacResolutionNumber.getString(context)), if (date != null) fill(spanish ? AppLocale.es[AppLocale.pacResolutionDate] as String : AppLocale.pacResolutionDate.getString(context))].join(', ')}.';
  }

  return [legend(spanish: true), if (Localizations.localeOf(context).languageCode == 'en') legend(spanish: false)];
}

String electronicInvoiceCUFE(Map<String, dynamic> info) {
  final invoice = info['invoice'] as Map?;
  final value = _hasHeaderValue(info['cufe']) ? info['cufe'] : invoice?['FE_FiscalInvoiceNumber'];
  return _hasHeaderValue(value) ? value.toString() : '';
}
