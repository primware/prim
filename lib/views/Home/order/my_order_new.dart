import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/localization/app_locale.dart';
import 'dart:async';
import 'package:primware/shared/custom_container.dart';
import 'package:primware/shared/custom_dropdown.dart';
import 'package:primware/shared/logo.dart';
import '../../../API/pos.api.dart';
import '../../../shared/button.widget.dart';
import '../../../shared/custom_app_menu.dart';
import '../../../shared/custom_searchfield.dart';
import '../../../shared/custom_spacer.dart';
import '../../../shared/custom_textfield.dart';
import '../../../theme/colors.dart';
import '../bpartner/bpartner_new.dart';
import '../product/product_new.dart';
import 'order_funtions.dart';
import 'package:shimmer/shimmer.dart';

import 'my_order.dart';

import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';

class OrderNewPage extends StatefulWidget {
  final bool isRefund;
  final int? doctypeID;
  final String? orderName;

  const OrderNewPage(
      {super.key, this.isRefund = false, this.doctypeID, this.orderName});

  @override
  State<OrderNewPage> createState() => _OrderNewPageState();
}

class _OrderNewPageState extends State<OrderNewPage> {
  Timer? _debounce;
  double calculatedChange = 0.0;
  TextEditingController clienteController = TextEditingController();
  TextEditingController qtyProductController = TextEditingController();
  TextEditingController productController = TextEditingController();
  TextEditingController taxController = TextEditingController();
  bool isSending = false;
  bool isBPartnerLoading = true;
  bool isProductLoading = true;
  bool isProductSearchLoading = false;
  bool isCustomerSearchLoading = false;
  bool isProductCategoryLoading = true;
  bool isTaxLoading = true;

  List<Map<String, dynamic>> bPartnerOptions = [];
  List<Map<String, dynamic>> productOptions = [];
  List<Map<String, dynamic>> categpryOptions = [];
  List<Map<String, dynamic>> taxOptions = [];
  List<Map<String, dynamic>> invoiceLines = [];

  // Estado para categorías seleccionadas
  Set<int> selectedCategories = {};

  // Payment methods state
  List<Map<String, dynamic>> paymentMethods = [];
  Map<int, TextEditingController> paymentControllers = {};
  bool isPaymentMethodsLoading = true;
  bool isFormValid = false;
  bool _isInvoiceValid = false;

  int? selectedBPartnerID;
  String? selectedDocActionCode;
  Map<String, dynamic>? selectedTax;

  double subtotal = 0.0;
  double iva = 0.0;
  double total = 0.0;

  void clearInvoiceFields() {
    clienteController.clear();
    qtyProductController.clear();
    productController.clear();
    taxController.clear();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBPartner();
      _loadDocumentActions();
      initialLoadProduct();
      _loadTax();
      _loadProductCategory();
      if (POSTenderType.isMultiPayment) {
        _loadPayment();
      }
    });

    if (POS.documentActions.isNotEmpty) {
      selectedDocActionCode = POS.documentActions.first['code'];
    }
  }

  Future<void> _loadDocumentActions() async {
    await fetchDocumentActions(docTypeID: widget.doctypeID!);
    if (mounted &&
        POS.documentActions.isNotEmpty &&
        selectedDocActionCode == null) {
      setState(() {
        selectedDocActionCode = POS.documentActions.first['code'];
      });
    }
  }

  Future<void> initialLoadProduct() async {
    setState(() {
      isProductLoading = true;
    });
    final product = await fetchProductInPriceList(
      context: context,
    );
    setState(() {
      productOptions = product;
      isProductLoading = false;
    });
  }

  void debouncedLoadProduct() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    final searchText = productController.text.trim();
    if (searchText.length < 4 && searchText.isNotEmpty) {
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      _loadProduct(showLoadingIndicator: true);
    });
  }

  void debouncedLoadCustomer() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    final searchText = clienteController.text.trim();
    if (searchText.length < 4 && searchText.isNotEmpty) {
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      _loadBPartner(showLoadingIndicator: true);
    });
  }

  Future<void> _loadPayment() async {
    setState(() {
      isPaymentMethodsLoading = true;
    });
    try {
      final result = await fetchPaymentMethods();
      setState(() {
        paymentMethods = result;
        for (var method in result) {
          paymentControllers.putIfAbsent(
              method['id'], () => TextEditingController());
        }
        isPaymentMethodsLoading = false;
      });
    } catch (e) {
      setState(() {
        isPaymentMethodsLoading = false;
      });
      print('Error al cargar métodos de pago: $e');
    }
  }

  @override
  void dispose() {
    for (final controller in paymentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get clientSelected => selectedBPartnerID != null;
  List<Map<String, dynamic>> get products => invoiceLines;
  double get totalAmount => total;

  void _validateForm() {
    final totalPayment = paymentControllers.values
        .map((c) => double.tryParse(c.text) ?? 0.0)
        .fold(0.0, (sum, val) => sum + val);

    final totalCash = paymentControllers.entries
        .where((entry) {
          final method = paymentMethods.firstWhere(
            (m) => m['id'] == entry.key,
            orElse: () => {},
          );
          return method['isCash'] == true;
        })
        .map((entry) => double.tryParse(entry.value.text) ?? 0.0)
        .fold(0.0, (sum, val) => sum + val);

    final change = (totalPayment > totalAmount)
        ? (totalCash - (totalAmount - (totalPayment - totalCash)))
        : 0.0;

    setState(() {
      if (paymentMethods.isEmpty) {
        _isInvoiceValid = clientSelected && products.isNotEmpty;
      } else {
        _isInvoiceValid = clientSelected &&
            products.isNotEmpty &&
            totalPayment >= totalAmount;
      }
      calculatedChange = change > 0 ? change : 0.0;
    });
  }

  Future<void> _loadBPartner({bool showLoadingIndicator = false}) async {
    if (showLoadingIndicator) {
      setState(() {
        isCustomerSearchLoading = true;
      });
    }
    final partner = await fetchBPartner(
      context: context,
      searchTerm: clienteController.text.trim(),
    );

    //? Busca el cliente por defecto según el ID en POS
    final defaultPartner = partner.firstWhere(
      (p) => p['id'] == POS.templatePartnerID,
      orElse: () => {},
    );

    setState(() {
      bPartnerOptions = partner;
      isBPartnerLoading = false;
      isCustomerSearchLoading = false;
      if (defaultPartner.isNotEmpty) {
        selectedBPartnerID = defaultPartner['id'];
        clienteController.text =
            '${defaultPartner['TaxID'] ?? ''} - ${defaultPartner['name'] ?? ''}';
      }
    });
  }

  Future<void> _loadProduct({bool showLoadingIndicator = false}) async {
    if (showLoadingIndicator) {
      setState(() {
        isProductSearchLoading = true;
      });
    }
    final product = await fetchProductInPriceList(
      context: context,
      categoryID:
          selectedCategories.isNotEmpty ? selectedCategories.toList() : null,
      searchTerm: productController.text.trim(),
    );
    setState(() {
      productOptions = product;
      isProductSearchLoading = false;
    });
  }

  Future<void> _loadProductCategory() async {
    final category = await fetchProductCategory();
    setState(() {
      categpryOptions = category;
      isProductCategoryLoading = false;
    });
  }

  Future<void> _loadTax() async {
    final tax = await fetchTax();
    final defaultTax = tax.isNotEmpty
        ? tax.firstWhere((t) => t['isdefault'] == true, orElse: () => tax.first)
        : null;
    setState(() {
      taxOptions = tax;
      if (defaultTax != null) {
        selectedTax = defaultTax;
        taxController.text = defaultTax['name'];
        _recalculateSummary();
        _validateForm();
      }
      isTaxLoading = false;
    });
  }

  void _recalculateSummary() {
    double newSubtotal = 0.0;
    double newIVA = 0.0;

    for (var line in invoiceLines) {
      final price = (line['price'] ?? 0) as num;
      final quantity = (line['quantity'] ?? 1) as num;
      final taxID = line['C_Tax_ID'];

      newSubtotal += price * quantity;

      final tax = taxOptions.firstWhere(
        (t) => t['id'] == taxID,
        orElse: () => {},
      );
      final taxPercent = double.tryParse('${tax['rate'] ?? '0'}') ?? 0.0;

      newIVA += price * quantity * (taxPercent / 100);
    }

    setState(() {
      subtotal = newSubtotal;
      iva = newIVA;
      total = subtotal + iva;
    });
  }

  Widget _buildShimmerField() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _showQuantityDialog(Map<String, dynamic> product,
      {int? index}) async {
    int? selectedTaxID = index != null
        ? (product['C_Tax_ID'] ?? product['tax']?['id'])
        : (product['tax']?['id'] ?? selectedTax?['id']);
    final quantityController = TextEditingController(
      text: index != null && product['quantity'] != null
          ? product['quantity'].toString()
          : "1",
    );

    final priceController = TextEditingController(
        text: product['price'] == 0 ? '' : product['price'].toString());
    final descriptionController = TextEditingController(
      text: index != null && product['Description'] != null
          ? product['Description'].toString()
          : '',
    );

    void onSubmitted(BuildContext dialogContext) {
      final qty = int.tryParse(quantityController.text) ?? 1;
      final price =
          double.tryParse(priceController.text) ?? (product['price'] ?? 0);
      final description = descriptionController.text;

      if (index != null) {
        invoiceLines.removeAt(index);
      }

      setState(() {
        invoiceLines.add({
          ...product,
          'quantity': qty,
          'price': price,
          'C_Tax_ID': selectedTaxID ?? selectedTax?['id'],
          'Description': description,
        });
      });

      _recalculateSummary();
      productController.clear();
      _validateForm();
      Navigator.pop(dialogContext, true);
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return WillPopScope(
          onWillPop: () async {
            productController.clear();
            return true;
          },
          child: AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: Text(product['name'] ?? 'Producto',
                style: Theme.of(context).textTheme.bodyMedium),
            content: SingleChildScrollView(
              child: Padding(
                padding: MediaQuery.of(context).viewInsets,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Divider(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: CustomSpacer.medium),
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: IconButton(
                            icon: Icon(Icons.remove),
                            color: ColorTheme.error,
                            onPressed: () {
                              int current =
                                  int.tryParse(quantityController.text) ?? 1;
                              if (current > 1) {
                                quantityController.text =
                                    (current - 1).toString();
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: TextfieldTheme(
                            controlador: quantityController,
                            texto: AppLocale.quantity.getString(context),
                            inputType: TextInputType.number,
                            onSubmitted: (_) => onSubmitted(dialogContext),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: IconButton(
                            icon: Icon(Icons.add),
                            color: ColorTheme.success,
                            onPressed: () {
                              int current =
                                  int.tryParse(quantityController.text) ?? 1;
                              quantityController.text =
                                  (current + 1).toString();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: CustomSpacer.medium),
                    TextfieldTheme(
                      controlador: priceController,
                      pista: product['price'] == 0
                          ? product['price'].toString()
                          : null,
                      texto: AppLocale.price.getString(context),
                      inputType: TextInputType.number,
                      onSubmitted: (_) => onSubmitted,
                    ),
                    const SizedBox(height: CustomSpacer.medium),
                    SearchableDropdown<int>(
                      labelText: AppLocale.taxType.getString(context),
                      showSearchBox: false,
                      options: taxOptions,
                      value: selectedTaxID,
                      onChanged: (value) {
                        setState(() {
                          selectedTaxID = value;
                        });
                      },
                      displayItem: (item) =>
                          '${item['name']} (${item['rate']}%)',
                    ),
                    const SizedBox(height: CustomSpacer.medium),
                    TextFieldComments(
                      controlador: descriptionController,
                      texto: AppLocale.descriptionOptional.getString(context),
                      onSubmitted: (_) => onSubmitted,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  productController.clear();
                  Navigator.pop(dialogContext, false);
                },
                child: Text(AppLocale.cancel.getString(context)),
              ),
              ElevatedButton(
                onPressed: () => onSubmitted(dialogContext),
                child: Text(
                  AppLocale.add.getString(context),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.surface,
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (result != true) {
      productController.clear();
    }
  }

  // void _onProductCreated(Map<String, dynamic> newProduct) async {
  //   await _loadProduct();
  //   final createdProduct = productOptions.firstWhere(
  //     (p) => p['id'] == newProduct['id'],
  //     orElse: () => {},
  //   );
  //   if (createdProduct.isNotEmpty) {
  //     _showQuantityDialog(createdProduct);
  //   }
  // }

  void _deleteLine(int index) {
    setState(() {
      invoiceLines.removeAt(index);
      _recalculateSummary();

      final totalPayment = paymentControllers.values
          .map((c) => double.tryParse(c.text) ?? 0.0)
          .fold(0.0, (sum, val) => sum + val);

      if (totalPayment > totalAmount) {
        for (var controller in paymentControllers.values) {
          controller.text = '0';
        }
      }

      _validateForm();
    });
  }

  // Función para mostrar la confirmación de imprimir ticket
  Future<bool?> _printTicketConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocale.confirmPrintTicket.getString(context)),
        content: Text(AppLocale.printTicketMessage.getString(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocale.no.getString(context)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocale.yes.getString(context)),
          ),
        ],
      ),
    );
  }

  Future<Uint8List> _generateTicketPdf(Map<String, dynamic> order) async {
    final pdf = pw.Document();

    // Obtener líneas del pedido
    final lines = (order['C_OrderLine'] as List?) ?? [];
    //final taxSummary = _calculateTaxSummary([order]);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Pedido #${order['DocumentNo']}',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text('Cliente: ${order['bpartner']['name']}'),
            pw.Text('Fecha: ${order['DateOrdered']}'),
            pw.Divider(),
            pw.Text('Resumen de productos', style: pw.TextStyle(fontSize: 16)),
            /*pw.SizedBox(height: 10),
            ...lines.map((line) {
              final name = (line['M_Product_ID']?['identifier']?.toString() ??
                      'Sin nombre')
                  .split('_')
                  .skip(1)
                  .join(' ');
              final qty = (line['QtyOrdered'] as num).toDouble();
              final price = (line['PriceActual'] as num).toDouble();
              final net = (line['LineNetAmt'] as num).toDouble();
              final rate = (line['C_Tax_ID']['Rate'] as num).toDouble();
              final tax = net * (rate / 100);
              final total = net + tax;

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Cantidad: $qty | Precio: \$${price.toStringAsFixed(2)}'),
                  pw.Text('Impuesto: \$${tax.toStringAsFixed(2)}'),
                  pw.Text('Total: \$${total.toStringAsFixed(2)}'),
                  pw.Divider(),
                ],
              );
            }),
            pw.Divider(),
            pw.Text('Resumen final', style: pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 10),
            pw.Text('Subtotal: \$${(order['GrandTotal'] as num).toDouble().toStringAsFixed(2)}'),
            ...taxSummary.entries.map((entry) => pw.Text(
                '${entry.key}: \$${entry.value['tax']!.toStringAsFixed(2)}')),
            pw.Text(
                'Total impuestos: \$${taxSummary.values.map((e) => e['tax']!).reduce((a, b) => a + b).toStringAsFixed(2)}'),
            pw.Text(
                'Total final: \$${(order['GrandTotal'] as num).toDouble().toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),*/
          ],
        ),
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
          final String taxName = tax["Name"];
          final double taxRate = (tax["Rate"] as num).toDouble();
          final double lineNetAmt = (line["LineNetAmt"] as num).toDouble();

          final taxKey = "$taxName (${taxRate.toStringAsFixed(0)}%)";

          taxSummary.putIfAbsent(
              taxKey,
              () => {
                    "net": 0.0,
                    "tax": 0.0,
                    "total": 0.0,
                  });

          final double taxAmount =
              double.parse((lineNetAmt * (taxRate / 100)).toStringAsFixed(2));
          taxSummary[taxKey]!["net"] = taxSummary[taxKey]!["net"]! + lineNetAmt;
          taxSummary[taxKey]!["tax"] = taxSummary[taxKey]!["tax"]! + taxAmount;
          taxSummary[taxKey]!["total"] =
              taxSummary[taxKey]!["total"]! + lineNetAmt + taxAmount;
        }
      }
    }

    return taxSummary;
  }

  // Agrega este método a tu clase OrderDetailPage
  Future<void> _showPdfPreview(BuildContext context, Uint8List pdfBytes) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          //title: Text(AppLocale.previewTicket.getString(context)),
          title: Text('asdadsdad'),
          content: Container(
            width: double.maxFinite,
            height: 500,
            child: PdfPreview(
              build: (format) => pdfBytes,
              allowSharing: true,
              allowPrinting: true,
              canChangePageFormat: false,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocale.close.getString(context)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              //child: Text(AppLocale.print.getString(context)),
              child: Text('asdadaddd'),
              onPressed: () {
                Printing.layoutPdf(onLayout: (_) => pdfBytes);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _createInvoice({
    required List<Map<String, dynamic>> product,
    required int bPartner,
  }) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(AppLocale.complete.getString(context)),
          content: Text(
            widget.isRefund
                ? AppLocale.confirmCompleteCreditNote.getString(context)
                : AppLocale.confirmCompleteOrder.getString(context),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocale.cancel.getString(context)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                AppLocale.confirm.getString(context),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.surface),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => isSending = true);
    final List<Map<String, dynamic>> invoiceLine = product.map((item) {
      return {
        'M_Product_ID': item['id'],
        'SKU': item['sku'],
        'upc': item['upc'],
        'Category': item['category'],
        'Name': item['name'],
        'Price': item['price'],
        'Quantity': item['quantity'],
        'C_Tax_ID': item['C_Tax_ID'],
        'Description': item['Description'] ?? '',
      };
    }).toList();

    final paymentData = paymentControllers.entries
        .where((entry) =>
            double.tryParse(entry.value.text) != null &&
            double.parse(entry.value.text) > 0)
        .map((entry) {
      return {
        'PayAmt': double.parse(entry.value.text),
        'C_POSTenderType_ID': entry.key,
      };
    }).toList();

    final result = await postInvoice(
      cBPartnerID: bPartner,
      invoiceLines: invoiceLine,
      payments: paymentData,
      context: context,
      docAction: selectedDocActionCode ?? 'DR',
      isRefund: widget.isRefund,
      doctypeID: widget.doctypeID,
    );

    if (result['success'] == true) {
      if (calculatedChange > 0) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: Text(
              AppLocale.change.getString(context),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            content: Text(
              '\$${calculatedChange.toStringAsFixed(2)}',
              style: Theme.of(context)
                  .textTheme
                  .headlineLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocale.close.getString(context)),
              ),
            ],
          ),
        );
      }

      final Map<String, dynamic>? order = await fetchOrderById(
        context: context, 
        orderId: int.parse(result['Record_ID'].toString())
      );

      if (order != null) {
        // Mostrar diálogo de confirmación de imprimir ticket después de guardar exitosamente
        final confirmPrintTicket = await _printTicketConfirmation(context);

        if (confirmPrintTicket == true) {
          // Generar el PDF
          //final pdfDocument = await generateOrderSummaryPdf(order);
          final pdfBytes = await _generateTicketPdf(order);
          //final pdfBytes = await pdfDocument.save();

          // Mostrar la vista previa del PDF
          //await _showPdfPreview(context, pdfBytes);
          
          // Mostrar la vista previa del PDF
          await Printing.layoutPdf(
            onLayout: (_) => pdfBytes,
          );
          
          /*ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              //content: Text(AppLocale.logoutSuccess.getString(context)),
              content: Text('Imprimir Ticket'),
              backgroundColor: Colors.green,
            ),
          );*/
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isRefund
              ? AppLocale.creditNote.getString(context)
              : AppLocale.newOrder.getString(context)),
          backgroundColor: Colors.green,
        ),
      );
      clearInvoiceFields();
      setState(() {
        invoiceLines.clear();
        subtotal = 0.0;
        iva = 0.0;
        total = 0.0;
        paymentControllers.forEach((key, controller) => controller.clear());
        selectedDocActionCode = POS.documentActions.first['code'];
        _validateForm();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ??
              AppLocale.errorCompleteOrder.getString(context)),
          backgroundColor: ColorTheme.error,
        ),
      );
    }
    setState(() => isSending = false);
  }

  Map<String, double> getGroupedTaxTotals() {
    final Map<String, double> groupedTaxes = {};

    for (var line in invoiceLines) {
      final price = (line['price'] ?? 0) as num;
      final quantity = (line['quantity'] ?? 1) as num;
      final taxID = line['C_Tax_ID'];
      final tax =
          taxOptions.firstWhere((t) => t['id'] == taxID, orElse: () => {});
      final rate = (tax['rate'] ?? 0).toDouble();
      final name = tax['name'] ?? AppLocale.noTax.getString(context);

      final taxAmount = price * quantity * (rate / 100);
      groupedTaxes['$name (${rate.toStringAsFixed(2)}%)'] =
          (groupedTaxes['$name (${rate.toStringAsFixed(2)}%)'] ?? 0) +
              taxAmount;
    }

    return groupedTaxes;
  }

  double getTotalTaxAmount() {
    final taxes = getGroupedTaxTotals();
    return taxes.values.fold(0.0, (sum, amount) => sum + amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.orderName != null
            ? widget.orderName!
            : widget.isRefund
                ? AppLocale.creditNote.getString(context)
                : AppLocale.newOrder.getString(context)),
        backgroundColor:
            widget.isRefund ? Theme.of(context).colorScheme.error : null,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: CustomSpacer.medium),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(CustomSpacer.medium),
                color: Colors.white,
              ),
              padding: EdgeInsets.all(CustomSpacer.small),
              child: Logo(
                width: 40,
              ),
            ),
          )
        ],
      ),
      drawer: MenuDrawer(),
      body: SingleChildScrollView(
        child: Center(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.end,
            children: [
              CustomContainer(
                maxWidthContainer: 360,
                child: Column(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isCustomerSearchLoading) ...[
                          const SizedBox(height: 4),
                          const LinearProgressIndicator(),
                          const SizedBox(height: 8),
                        ],
                        isBPartnerLoading
                            ? _buildShimmerField()
                            : CustomSearchField(
                                options: bPartnerOptions,
                                labelText:
                                    AppLocale.customer.getString(context),
                                searchBy: "TaxID",
                                controller: clienteController,
                                showCreateButtonIfNotFound: true,
                                onChanged: (_) => debouncedLoadCustomer(),
                                onCreate: (value) async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          BPartnerNewPage(bpartnerName: value),
                                    ),
                                  );
                                  if (result != null &&
                                      result['created'] == true) {
                                    await _loadBPartner();
                                    setState(() {
                                      selectedBPartnerID =
                                          result['bpartner']['id'];
                                    });
                                  }
                                },
                                onItemSelected: (item) {
                                  setState(() {
                                    selectedBPartnerID = item['id'];
                                  });
                                },
                                itemBuilder: (item) => Text(
                                  '${item['TaxID'] ?? ''} - ${item['name'] ?? ''}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                        const SizedBox(height: CustomSpacer.medium),
                        isProductLoading
                            ? _buildShimmerField()
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Segmento de selección de categorías con botón y modal
                                  if (!isProductCategoryLoading)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        TextButton.icon(
                                          style: ButtonStyle(
                                            textStyle:
                                                MaterialStateProperty.all(
                                                    Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium),
                                            backgroundColor:
                                                MaterialStateProperty.all(
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .secondary),
                                            foregroundColor:
                                                MaterialStateProperty.all(
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .onSecondary),
                                          ),
                                          icon: const Icon(Icons.category),
                                          label: Text(AppLocale.categories
                                              .getString(context)),
                                          onPressed: () async {
                                            Set<int> tempSelected =
                                                Set<int>.from(
                                                    selectedCategories);
                                            await showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              builder: (context) {
                                                return StatefulBuilder(
                                                  builder:
                                                      (context, setModalState) {
                                                    return SafeArea(
                                                      child: Padding(
                                                        padding: MediaQuery.of(
                                                                context)
                                                            .viewInsets,
                                                        child: Container(
                                                          constraints:
                                                              const BoxConstraints(
                                                                  maxHeight:
                                                                      400),
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        16.0),
                                                                child: Text(
                                                                  AppLocale
                                                                      .selectCategories
                                                                      .getString(
                                                                          context),
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .bodyLarge,
                                                                ),
                                                              ),
                                                              Expanded(
                                                                child: ListView
                                                                    .builder(
                                                                  shrinkWrap:
                                                                      true,
                                                                  itemCount:
                                                                      categpryOptions
                                                                          .length,
                                                                  itemBuilder:
                                                                      (context,
                                                                          idx) {
                                                                    final cat =
                                                                        categpryOptions[
                                                                            idx];
                                                                    final isSelected =
                                                                        tempSelected
                                                                            .contains(cat['id']);
                                                                    return ListTile(
                                                                      title: Text(
                                                                          cat['name']),
                                                                      selected:
                                                                          isSelected,
                                                                      onTap:
                                                                          () {
                                                                        setModalState(
                                                                            () {
                                                                          if (isSelected) {
                                                                            tempSelected.remove(cat['id']);
                                                                          } else {
                                                                            tempSelected.add(cat['id']);
                                                                          }
                                                                        });
                                                                      },
                                                                      trailing: isSelected
                                                                          ? const Icon(
                                                                              Icons.check,
                                                                              color: Colors.blue)
                                                                          : null,
                                                                    );
                                                                  },
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        16.0),
                                                                child: Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .end,
                                                                  children: [
                                                                    TextButton(
                                                                      onPressed:
                                                                          () {
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child:
                                                                          Text(
                                                                        AppLocale
                                                                            .cancel
                                                                            .getString(context),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                        width:
                                                                            8),
                                                                    ElevatedButton(
                                                                      onPressed:
                                                                          () {
                                                                        Navigator.pop(
                                                                            context,
                                                                            tempSelected);
                                                                      },
                                                                      child:
                                                                          Text(
                                                                        AppLocale
                                                                            .apply
                                                                            .getString(context),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            ).then((result) {
                                              if (result != null &&
                                                  result is Set<int>) {
                                                setState(() {
                                                  selectedCategories =
                                                      Set<int>.from(result);
                                                });
                                                debouncedLoadProduct();
                                              }
                                            });
                                          },
                                        ),
                                        // Chips de categorías seleccionadas
                                        if (selectedCategories.isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8.0),
                                            child: Wrap(
                                              spacing: 6,
                                              runSpacing: 6,
                                              children: selectedCategories
                                                  .map((catId) {
                                                final cat =
                                                    categpryOptions.firstWhere(
                                                  (c) => c['id'] == catId,
                                                  orElse: () =>
                                                      <String, dynamic>{},
                                                );
                                                final catName = cat.isNotEmpty
                                                    ? cat['name']
                                                    : 'Categoría';
                                                return Chip(
                                                  label: Text(catName),
                                                  onDeleted: () {
                                                    setState(() {
                                                      selectedCategories
                                                          .remove(catId);
                                                    });
                                                    debouncedLoadProduct();
                                                  },
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        const SizedBox(
                                            height: CustomSpacer.medium),
                                      ],
                                    ),
                                  // Campo de producto
                                  if (isProductSearchLoading) ...[
                                    const SizedBox(height: 4),
                                    const LinearProgressIndicator(),
                                    const SizedBox(height: 8),
                                  ],
                                  CustomSearchField(
                                    options: productOptions,
                                    controller: productController,
                                    labelText:
                                        AppLocale.product.getString(context),
                                    searchBy: AppLocale.code.getString(context),
                                    showCreateButtonIfNotFound: true,
                                    onItemSelected: (item) {
                                      _showQuantityDialog(item);
                                    },
                                    onChanged: (_) => debouncedLoadProduct(),
                                    onCreate: (value) async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ProductNewPage(productName: value),
                                        ),
                                      );
                                      if (result != null &&
                                          result['created'] == true) {
                                        debouncedLoadProduct();
                                      }
                                    },
                                    itemBuilder: (item) => Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${item['name'] ?? ''}',
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                              if (item['value'] != null)
                                                Text(
                                                  'Cod: ${item['value'] ?? ''}',
                                                  maxLines: 2,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '\$${item['price'] ?? '0.00'}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // //? crear producto si no existe
                                  /*if (productOptions.isEmpty &&
                                      productController.text
                                          .trim()
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.add),
                                      label: Text(
                                          'Crear "${productController.text.trim()}"'),
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ProductNewPage(
                                                productName: productController
                                                    .text
                                                    .trim()),
                                          ),
                                        );
                                        if (result != null &&
                                            result['created'] == true) {
                                          debouncedLoadProduct();
                                        }
                                      },
                                    ),
                                  ],*/
                                ],
                              ),
                        if (invoiceLines.isNotEmpty) ...[
                          const SizedBox(height: CustomSpacer.large),
                          Text(AppLocale.productSummary.getString(context),
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: CustomSpacer.medium),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: invoiceLines.asMap().entries.map((entry) {
                              final index = entry.key;
                              final line = entry.value;
                              final tax = taxOptions.firstWhere(
                                (t) => t['id'] == line['C_Tax_ID'],
                                orElse: () => {},
                              );
                              final taxRate = tax['rate'] != null
                                  ? '${tax['rate']}%'
                                  : AppLocale.noTax.getString(context);
                              return Tooltip(
                                message: line['name'],
                                child: InputChip(
                                  onPressed: () =>
                                      _showQuantityDialog(line, index: index),
                                  deleteIcon: const Icon(Icons.close),
                                  onDeleted: () => _deleteLine(index),
                                  deleteIconColor: ColorTheme.error,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  label: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        line['name'],
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      if (line['Description'] != null &&
                                          line['Description']
                                              .toString()
                                              .isNotEmpty)
                                        Text(
                                          '${line['Description']}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall,
                                        ),
                                      Text(
                                        '${line['quantity']} x \$${line['price']} + $taxRate',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Theme.of(context).cardColor,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (POSTenderType.isMultiPayment)
                CustomContainer(
                  maxWidthContainer: 360,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocale.paymentMethods.getString(context),
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          if (isPaymentMethodsLoading)
                            _buildShimmerField()
                          else ...[
                            ...paymentMethods.map((method) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextfieldTheme(
                                            controlador: paymentControllers[
                                                method['id']],
                                            texto: method['name'],
                                            inputType: TextInputType.number,
                                            onChanged: (_) => _validateForm(),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.attach_money_rounded),
                                          tooltip:
                                              'Llenar con el máximo disponible',
                                          onPressed: () {
                                            final currentSum =
                                                paymentControllers.entries
                                                    .where((e) =>
                                                        e.key != method['id'])
                                                    .map((e) =>
                                                        double.tryParse(
                                                            e.value.text) ??
                                                        0.0)
                                                    .fold(0.0, (a, b) => a + b);

                                            final remaining =
                                                (totalAmount - currentSum)
                                                    .clamp(0.0, totalAmount);
                                            paymentControllers[method['id']]
                                                    ?.text =
                                                remaining.toStringAsFixed(2);
                                            _validateForm();
                                          },
                                        ),
                                      ],
                                    ),
                                    if (calculatedChange > 0 &&
                                        method['isCash'])
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 2, bottom: 4),
                                        child: Text(
                                          'Vuelto: \$${calculatedChange.toStringAsFixed(2)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                      if (!_isInvoiceValid &&
                          clientSelected &&
                          products.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            AppLocale.paymentSumMustEqualTotal
                                .getString(context),
                            style: TextStyle(
                                color: ColorTheme.error, fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                ),

              //? Resumen de la factura
              CustomContainer(
                maxWidthContainer: 360,
                child: Column(
                  children: [
                    Center(
                      child: Text(AppLocale.summary.getString(context),
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                    const SizedBox(height: CustomSpacer.medium),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppLocale.subtotal.getString(context),
                            style: Theme.of(context).textTheme.bodyMedium),
                        Text('\$${subtotal.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                    const SizedBox(height: CustomSpacer.medium),
                    if (invoiceLines.isNotEmpty && getTotalTaxAmount() > 0) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocale.taxes.getString(context),
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: CustomSpacer.small),
                          ...getGroupedTaxTotals().entries.map(
                                (entry) => Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(entry.key,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium),
                                    Text('\$${entry.value.toStringAsFixed(2)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium),
                                  ],
                                ),
                              ),
                          const SizedBox(height: CustomSpacer.small),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(AppLocale.totalTaxes.getString(context),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      )),
                              Text(
                                  '\$${getTotalTaxAmount().toStringAsFixed(2)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      )),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: CustomSpacer.medium),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppLocale.total.getString(context),
                            style: Theme.of(context).textTheme.titleLarge),
                        Text('\$${total.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleLarge),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: CustomSpacer.xlarge),
                    CustomSearchField(
                      options: POS.documentActions,
                      labelText: AppLocale.documentAction.getString(context),
                      searchBy: "name",
                      showCreateButtonIfNotFound: false,
                      controller: TextEditingController(
                        text: POS.documentActions.first['name'],
                      ),
                      onItemSelected: (item) {
                        setState(() {
                          selectedDocActionCode = item['code'];
                        });
                      },
                      itemBuilder: (item) => Text(
                        '${item['name']}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: CustomSpacer.small),
                    Container(
                      child: isSending
                          ? ButtonLoading(fullWidth: true)
                          : ButtonPrimary(
                              fullWidth: true,
                              texto: AppLocale.process.getString(context),
                              enable: _isInvoiceValid,
                              onPressed: () => _isInvoiceValid
                                  ? _createInvoice(
                                      product: invoiceLines,
                                      bPartner: selectedBPartnerID ?? 0,
                                    )
                                  : null,
                            ),
                    ),
                    const SizedBox(height: CustomSpacer.medium),
                    if (!isSending)
                      ButtonSecondary(
                        fullWidth: true,
                        texto: AppLocale.cancel.getString(context),
                        onPressed: () {
                          clearInvoiceFields();
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => OrderListPage()));
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
