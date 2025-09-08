import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/API/user.api.dart';
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
import '../../../shared/formater.dart';
import '../../../shared/toast_message.dart';
import '../../../theme/colors.dart';
import '../bpartner/bpartner_new.dart';
import '../product/product_new.dart';
import 'order_funtions.dart';
import 'package:shimmer/shimmer.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'my_order.dart';
import 'package:printing/printing.dart';

class OrderNewPage extends StatefulWidget {
  final bool isRefund;
  final int? doctypeID;
  final String? orderName;
  final int? sourceOrderId;

  const OrderNewPage({
    super.key,
    this.isRefund = false,
    this.doctypeID,
    this.orderName,
    this.sourceOrderId,
  });

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
  TextEditingController docActionController = TextEditingController();
  bool isSending = false,
      isTaxLoading = true,
      isProductCategoryLoading = true,
      isCustomerSearchLoading = false,
      isProductSearchLoading = false,
      isProductLoading = true,
      isYappyLoading = false,
      isYappyConfigAvailable = false;

  final Set<int> _lockedPayments = {};
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

  int? selectedBPartnerID, docNoSequenceID; 
  String? selectedDocActionCode, yappyTransactionId, docNoSequenceNumber;
  Map<String, dynamic>? selectedTax;

  double subtotal = 0.0;
  double iva = 0.0;
  double total = 0.0;

  // ==== Helpers for monetary rounding and comparisons ====
  static const double eps = 0.01; // tolerancia de 1 centavo
  double _r2(num v) => (v * 100).round() / 100.0; // redondea a 2 decimales
  // ==== Helpers for monetary rounding and comparisons ====

  void clearInvoiceFields() {
    clienteController.clear();
    qtyProductController.clear();
    productController.clear();
    taxController.clear();
    yappyTransactionId = null;
    selectedBPartnerID = null;
    _lockedPayments.clear();
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

    if (Yappy.apiKey != null && Yappy.secretKey != null) {
      isYappyConfigAvailable = true;
    }

    _loadSequence();
    if (widget.sourceOrderId != null) {
      _prefillFromExistingOrder();
    }
  }

  Future<void> _loadDocumentActions() async {
    await fetchDocumentActions(docTypeID: widget.doctypeID!);

    if (POS.documentActions.isNotEmpty) {
      setState(() {
        selectedDocActionCode = POS.documentActions.first['code'];
        docActionController.text = POS.documentActions.first['name'] ?? '';
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
    _debounce = Timer(const Duration(milliseconds: 3000), () {
      _loadProduct(showLoadingIndicator: true);
    });
  }

  void debouncedLoadCustomer() {
    if (clienteController.text.trim().isEmpty) {
      setState(() {
        selectedBPartnerID = null;
        _validateForm();
      });
      return;
    }

    if (_debounce?.isActive ?? false) _debounce?.cancel();
    final searchText = clienteController.text.trim();
    if (searchText.length < 4 && searchText.isNotEmpty) {
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 5000), () {
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

  Future<void> _prefillFromExistingOrder() async {
    if (widget.sourceOrderId == null) return;

    try {
      // Asegurar que impuestos y métodos de pago estén cargados
      if (isTaxLoading) {
        // esperar a que termine _loadTax que se llama en initState
        while (isTaxLoading) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
      if (POSTenderType.isMultiPayment && isPaymentMethodsLoading) {
        while (isPaymentMethodsLoading) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      final src = await fetchOrderById(orderId: widget.sourceOrderId!);
      if (src == null) return;

      // Prefill cliente
      final bpId = src['bpartner']?['id'] ?? src['C_BPartner_ID']?['id'];
      final bpName =
          src['bpartner']?['name'] ?? src['C_BPartner_ID']?['identifier'] ?? '';

      setState(() {
        if (bpId != null) selectedBPartnerID = bpId;
        clienteController.text = bpName.toString();
      });

      // Prefill productos/lineas
      final List<dynamic> lines = (src['lines'] ??
          src['C_OrderLine'] ??
          src['orderLines'] ??
          []) as List<dynamic>;

      final List<Map<String, dynamic>> mapped = [];
      for (final raw in lines) {
        final Map<String, dynamic> line = Map<String, dynamic>.from(raw as Map);
        final name = line['Name'] ??
            (line['M_Product_ID']?['identifier']
                    ?.toString()
                    .split('_')
                    .skip(1)
                    .join(' ') ??
                'Producto');
        final price =
            (line['PriceActual'] ?? line['Price'] ?? line['price'] ?? 0) as num;
        final qty = (line['QtyOrdered'] ??
            line['QtyEntered'] ??
            line['quantity'] ??
            1) as num;
        final dynamic taxField = line['C_Tax_ID'];
        final taxId = (taxField is Map)
            ? taxField['id']
            : (taxField ?? selectedTax?['id']);
        final dynamic productField = line['M_Product_ID'];
        final dynamic categoryField = line['M_Product_Category_ID'];
        final dynamic categoryValue = line['Category'] ??
            (categoryField is Map ? categoryField['identifier'] : null);
        mapped.add({
          'id': (productField is Map)
              ? productField['id']
              : (productField ?? line['id']),
          'sku': line['SKU'] ?? line['Value'] ?? '',
          'upc': line['upc'] ?? '',
          'category': categoryValue,
          'name': name,
          'price': (price).toDouble(),
          'quantity': (qty).toInt(),
          'C_Tax_ID': taxId,
          'Description': line['Description'] ?? '',
        });
      }

      if (mapped.isNotEmpty) {
        setState(() {
          invoiceLines = mapped;
          _recalculateSummary();
        });
      }

      // Prefill pagos
      final List<dynamic> pays =
          (src['payments'] ?? src['C_POSPayment'] ?? []) as List<dynamic>;
      if (pays.isNotEmpty && POSTenderType.isMultiPayment) {
        for (final raw in pays) {
          final Map<String, dynamic> p = Map<String, dynamic>.from(raw as Map);
          final dynamic tenderField = p['C_POSTenderType_ID'];
          final tenderId =
              (tenderField is Map) ? tenderField['id'] : tenderField;
          final amt = (p['PayAmt'] ?? p['Amount'] ?? 0).toString();
          if (tenderId != null && paymentControllers.containsKey(tenderId)) {
            paymentControllers[tenderId]!.text = amt;
          }
        }
      }

      _validateForm();
    } catch (e) {
      // Silencioso, solo log
      // ignore: avoid_print
      print('Prefill error: $e');
    }
  }

  Future<void> _loadSequence() async {
    //TODO cargar secuencia con el fortmato, buscar si hay un proceso que lo traiga
    docNoSequenceID = await getDocNoSequenceID(recordID: widget.doctypeID!);

    if (docNoSequenceID != null) {
      getDocNoSequence(docNoSequenceID: docNoSequenceID!).then((value) {
        setState(() {
          docNoSequenceNumber = value;
        });
      });
    }
  }

  @override
  void dispose() {
    //todo si me voy a otra pantalla que no sea la de ordenes o la de despues de procesar entnces si cancelar
    // Cancela Yappy si quedó pendiente al cerrar esta pantalla
    //  _cancelPendingYappy(silent: true);

    for (final controller in paymentControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  bool get clientSelected => selectedBPartnerID != null;
  List<Map<String, dynamic>> get products => invoiceLines;
  double get totalAmount => total;

  void _validateForm() {
    final totalPayment = _r2(
      paymentControllers.values
          .map(
              (c) => _r2(double.tryParse((c.text).replaceAll(',', '.')) ?? 0.0))
          .fold(0.0, (sum, val) => sum + val),
    );

    final totalCash = _r2(
      paymentControllers.entries
          .where((entry) {
            final method = paymentMethods.firstWhere(
              (m) => m['id'] == entry.key,
              orElse: () => {},
            );
            return method['isCash'] == true;
          })
          .map((entry) => _r2(
              double.tryParse((entry.value.text).replaceAll(',', '.')) ?? 0.0))
          .fold(0.0, (sum, val) => sum + val),
    );

    final amount = _r2(totalAmount);

    final overpay = _r2(totalPayment - amount);
    final change =
        overpay > 0 ? _r2(totalCash >= overpay ? overpay : totalCash) : 0.0;

    setState(() {
      if (paymentMethods.isEmpty) {
        _isInvoiceValid = clientSelected && products.isNotEmpty;
      } else {
        _isInvoiceValid = clientSelected &&
            products.isNotEmpty &&
            (totalPayment + eps) >= amount;
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

    setState(() {
      bPartnerOptions = partner;
      isCustomerSearchLoading = false;
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

      newSubtotal += (price * quantity);

      final tax = taxOptions.firstWhere(
        (t) => t['id'] == taxID,
        orElse: () => {},
      );
      final taxPercent = double.tryParse('${tax['rate'] ?? '0'}') ?? 0.0;

      newIVA += (price * quantity) * (taxPercent / 100);
    }

    setState(() {
      subtotal = _r2(newSubtotal);
      iva = _r2(newIVA);
      total = _r2(subtotal + iva);
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

  //? para mostrar el dialogo de Yappy
  Future<void> _showYappyQRDialog({
    required double subTotal,
    required double totalTax,
    required double total,
    required int methodId,
  }) async {
    setState(() {
      isYappyLoading = true;
    });

    // 1) Solicitar el QR dinámico (hash + transactionId)
    final result = await showYappyQR(
      subTotal: double.parse(subTotal.toStringAsFixed(2)),
      totalTax: double.parse(totalTax.toStringAsFixed(2)),
      total: double.parse(total.toStringAsFixed(2)),
      docNoSequence: docNoSequenceNumber,
      context: context,
    );

    if (result['success'] != true) {
      ToastMessage.show(
        context: context,
        message: result['message'] ?? 'No se pudo generar el QR',
        type: ToastType.failure,
      );
      setState(() {
        isYappyLoading = false;
      });
      return;
    }

    final String hash = result['hash'] as String;
    yappyTransactionId = result['transactionId'] as String;

    int secondsLeft = 300;
    Timer? ticker;
    bool closed = false;

    setState(() {
      isYappyLoading = false;
    });

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            // Iniciar el ticker una sola vez
            ticker ??= Timer.periodic(const Duration(seconds: 1), (t) async {
              if (closed) return;

              // Reducir contador
              if (secondsLeft > 0) {
                setModalState(() {
                  secondsLeft -= 1;
                });
              }

              // Polling de estado
              try {
                final paid = await checkYappyStatus(yappyTransactionId!);
                if (paid) {
                  if (mounted) {
                    setState(() {
                      _lockedPayments.add(methodId); // bloquear campo de pago
                    });
                  }
                  closed = true;
                  t.cancel();
                  ToastMessage.show(
                    context: context,
                    message: 'Pago recibido correctamente',
                    type: ToastType.success,
                  );
                  if (Navigator.of(dialogContext).canPop()) {
                    Navigator.of(dialogContext).pop(true);
                  }
                  return;
                }
              } catch (_) {
                // Ignorar errores de polling por ahora
              }

              // Tiempo agotado => cancelar
              if (secondsLeft == 0) {
                closed = true;
                t.cancel();
                await cancelYappyTransaction(
                    transactionId: yappyTransactionId!);
                setState(() {
                  yappyTransactionId = null;
                });

                ToastMessage.show(
                  context: context,
                  message: 'Pago cancelado o tiempo agotado',
                  type: ToastType.failure,
                );
                if (Navigator.of(dialogContext).canPop()) {
                  Navigator.of(dialogContext).pop(false);
                }
              }
            });

            final mm = (secondsLeft ~/ 60).toString().padLeft(2, '0');
            final ss = (secondsLeft % 60).toString().padLeft(2, '0');

            return WillPopScope(
              onWillPop: () async => false,
              child: AlertDialog(
                backgroundColor: Color(0xFF1996E6),
                contentPadding: const EdgeInsets.all(0),
                content: SizedBox(
                  width: 640,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                          color: Colors.white,
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/img/yappyLogo.png',
                            width: 240,
                          ),
                        ),
                      ),
                      const SizedBox(height: CustomSpacer.xlarge),

                      // QR grande centrado
                      Container(
                        padding: const EdgeInsets.all(8),
                        width: 280,
                        // height: 280,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              QrImageView(
                                data: hash,
                                version: QrVersions.auto,
                                size: 260,
                              ),
                              // Contador
                              Text(
                                'Tiempo restante: $mm:$ss',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              // Id de transacción (pequeño)
                              Text(
                                'Transacción: $yappyTransactionId',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              const SizedBox(height: CustomSpacer.medium),
                              TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor:
                                      ColorTheme.error.withOpacity(0.2),
                                ),
                                onPressed: () {
                                  closed = true;
                                  ticker?.cancel();
                                  cancelYappyTransaction(
                                      transactionId: yappyTransactionId!);
                                  setState(() {
                                    yappyTransactionId = null;
                                  });

                                  ToastMessage.show(
                                    context: context,
                                    message: 'Pago cancelado o tiempo agotado',
                                    type: ToastType.failure,
                                  );
                                  Navigator.of(dialogContext).pop(false);
                                },
                                child: Text(
                                  AppLocale.cancel.getString(context),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: CustomSpacer.xlarge),
                      Text(
                          'Escanéalo desde Yappy App o desde Yappy en el App de tu banco',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                color: Colors.white,
                              ),
                          textAlign: TextAlign.center),
                      const SizedBox(height: CustomSpacer.xlarge),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    ticker?.cancel();
  }

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
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocale.yes.getString(context)),
          ),
        ],
      ),
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
        // Considerar entradas con algún monto numérico
        .where((entry) {
          final txt = entry.value.text.trim();
          final amt = double.tryParse(txt.replaceAll(',', '.')) ?? 0.0;
          return amt > 0;
        })
        .map((entry) {
          final txt = entry.value.text.trim();
          final originalAmt = double.tryParse(txt.replaceAll(',', '.')) ?? 0.0;

          final method = paymentMethods.firstWhere(
            (m) => m['id'] == entry.key,
            orElse: () => const <String, dynamic>{},
          );

          final bool isYappy =
              (method['name']?.toString().toLowerCase().contains('yappy') ==
                  true);
          final bool isCash = (method['isCash'] == true);

          // Si es efectivo, restar el vuelto disponible (sin quedar negativo)
          double adjustedAmt = originalAmt;
          if (isCash && calculatedChange > 0) {
            adjustedAmt = adjustedAmt - calculatedChange;
          }

          final Map<String, dynamic> data = {
            'PayAmt': double.parse(adjustedAmt.toStringAsFixed(2)),
            'C_POSTenderType_ID': entry.key,
          };

          // Si es Yappy y hay transacción, incluirla como RoutingNo
          if (isYappy &&
              yappyTransactionId != null &&
              yappyTransactionId!.isNotEmpty) {
            data['RoutingNo'] = yappyTransactionId;
          }

          return data;
        })
        // Excluir pagos que quedaron en 0 luego del ajuste
        .where((p) => (p['PayAmt'] ?? 0) > 0)
        .toList();

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
          orderId: int.parse(result['Record_ID'].toString()));

      if (order != null) {
        final confirmPrintTicket = await _printTicketConfirmation(context);

        if (confirmPrintTicket == true) {
          final pdfBytes = await generateTicketPdf(order);

          try {
            final printers = await Printing.listPrinters();
            final defaultPrinter = printers.firstWhere(
              (p) => p.isDefault,
              orElse: () => printers.isNotEmpty
                  ? printers.first
                  : throw Exception('No hay impresoras disponibles'),
            );

            await Printing.directPrintPdf(
              printer: defaultPrinter,
              onLayout: (_) => pdfBytes,
            );
          } catch (e) {
            await Printing.layoutPdf(
              onLayout: (_) => pdfBytes,
            );
          }
        }
      }
      ToastMessage.show(
        context: context,
        message: widget.isRefund
            ? AppLocale.creditNote.getString(context)
            : AppLocale.newOrder.getString(context),
        type: ToastType.success,
      );

      clearInvoiceFields();
      _loadSequence();
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
      ToastMessage.show(
        context: context,
        message: result['message'] ??
            AppLocale.errorCompleteOrder.getString(context),
        type: ToastType.failure,
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
    return _r2(taxes.values.fold(0.0, (sum, amount) => sum + amount));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        //TODO manejar lo de cancelar el yappy si me salgo
        // await _cancelPendingYappy(silent: false);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${AppLocale.user.getString(context)}: ${UserData.name} -'),
              const SizedBox(width: 4),
              Text(
                widget.orderName != null
                    ? '${widget.orderName!} : ${docNoSequenceNumber ?? ""}'
                    : widget.isRefund
                        ? '${AppLocale.creditNote.getString(context)} : ${docNoSequenceNumber ?? ""}'
                        : '${AppLocale.newOrder.getString(context)} : ${docNoSequenceNumber ?? ""}',
              ),
            ],
          ),
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
                  width: 60,
                ),
              ),
            )
          ],
        ),
        drawer: MenuDrawer(),
        bottomNavigationBar: Text(
          'www.primware.net',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.end,
              children: [
                CustomContainer(
                  maxWidthContainer: 320,
                  margin: EdgeInsets.only(top: 24),
                  child: Column(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: CustomSpacer.medium),
                          if (isCustomerSearchLoading) ...[
                            const SizedBox(height: 4),
                            const LinearProgressIndicator(),
                            const SizedBox(height: 8),
                          ],
                          CustomSearchField(
                            key: ValueKey('customer_${bPartnerOptions.length}'),
                            options: bPartnerOptions,
                            labelText: AppLocale.customer.getString(context),
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
                              if (result != null && result['created'] == true) {
                                await _loadBPartner();
                                setState(() {
                                  selectedBPartnerID = result['bpartner']['id'];
                                });
                              }
                            },
                            onItemSelected: (item) {
                              setState(() {
                                selectedBPartnerID = item['id'];
                                _validateForm();
                              });
                            },
                            itemBuilder: (item) => Text(
                              '${item['TaxID'] ?? ''} - ${item['name'] ?? ''}',
                              style: Theme.of(context).textTheme.bodyMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (selectedBPartnerID == null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                AppLocale.clientMustBeSelected
                                    .getString(context),
                                style: TextStyle(
                                    color: ColorTheme.error, fontSize: 13),
                              ),
                            ),
                          const SizedBox(height: CustomSpacer.medium),
                          isProductLoading
                              ? _buildShimmerField()
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Segmento de selección de categorías con botón y modal
                                    if (!isProductCategoryLoading)
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
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
                                                    builder: (context,
                                                        setModalState) {
                                                      return SafeArea(
                                                        child: Padding(
                                                          padding:
                                                              MediaQuery.of(
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
                                                                            ? const Icon(Icons.check,
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
                                              padding: const EdgeInsets.only(
                                                  top: 8.0),
                                              child: Wrap(
                                                spacing: 6,
                                                runSpacing: 6,
                                                children: selectedCategories
                                                    .map((catId) {
                                                  final cat = categpryOptions
                                                      .firstWhere(
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
                                      searchBy: 'UPC',
                                      showCreateButtonIfNotFound: true,
                                      onItemSelected: (item) {
                                        _showQuantityDialog(item);
                                      },
                                      onChanged: (_) => debouncedLoadProduct(),
                                      onCreate: (value) async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ProductNewPage(
                                                productName: value),
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                              children:
                                  invoiceLines.asMap().entries.map((entry) {
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
                                    backgroundColor:
                                        Theme.of(context).cardColor,
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
                    maxWidthContainer: 320,
                    margin: EdgeInsets.only(top: 24),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextfieldTheme(
                                              controlador: paymentControllers[
                                                  method['id']],
                                              texto: method['name'],
                                              inputType: TextInputType.number,
                                              inputFormatters: [
                                                NumericTextFormatterWithDecimal()
                                              ],
                                              readOnly: _lockedPayments
                                                  .contains(method['id']),
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
                                                      .fold(
                                                          0.0, (a, b) => a + b);

                                              final remaining = _r2(
                                                  (totalAmount - currentSum)
                                                      .clamp(0.0, totalAmount));
                                              paymentControllers[method['id']]
                                                      ?.text =
                                                  remaining.toStringAsFixed(2);
                                              _validateForm();
                                            },
                                          ),
                                          if (method['name']
                                                  .toString()
                                                  .toLowerCase()
                                                  .contains('yappy') &&
                                              isYappyConfigAvailable &&
                                              paymentControllers[method['id']]
                                                      ?.text !=
                                                  null &&
                                              (double.tryParse(
                                                          paymentControllers[
                                                                      method[
                                                                          'id']]
                                                                  ?.text ??
                                                              '0') ??
                                                      0) >
                                                  0 &&
                                              yappyTransactionId == null)
                                            isYappyLoading
                                                ? SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child:
                                                        CircularProgressIndicator())
                                                : IconButton(
                                                    icon: const Icon(
                                                        Icons.qr_code),
                                                    tooltip:
                                                        'Mostrar código QR',
                                                    onPressed: () {
                                                      _showYappyQRDialog(
                                                        subTotal: double.parse(
                                                            paymentControllers[
                                                                        method[
                                                                            'id']]
                                                                    ?.text
                                                                    .toString() ??
                                                                '0'),
                                                        totalTax: 0,
                                                        total: double.parse(
                                                            paymentControllers[
                                                                        method[
                                                                            'id']]
                                                                    ?.text
                                                                    .toString() ??
                                                                '0'),
                                                        methodId: method['id'],
                                                      );
                                                    },
                                                  ),
                                          if (yappyTransactionId != null &&
                                              method['name']
                                                  .toString()
                                                  .toLowerCase()
                                                  .contains('yappy') &&
                                              paymentControllers[method['id']]
                                                      ?.text !=
                                                  null &&
                                              (paymentControllers[method['id']]
                                                          ?.text ??
                                                      '0.0') !=
                                                  '0.0')
                                            if (yappyTransactionId != null)
                                              IconButton(
                                                  icon: Icon(Icons.cancel),
                                                  color: ColorTheme.error,
                                                  tooltip:
                                                      'Anular transacción Yappy',
                                                  onPressed: () async {
                                                    final confirm =
                                                        await showDialog(
                                                      context: context,
                                                      builder: (context) {
                                                        return AlertDialog(
                                                          backgroundColor:
                                                              Theme.of(context)
                                                                  .cardColor,
                                                          title: Text(AppLocale
                                                              .cancelYappyTransaction
                                                              .getString(
                                                                  context)),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      context,
                                                                      false),
                                                              child: Text(AppLocale
                                                                  .cancel
                                                                  .getString(
                                                                      context)),
                                                            ),
                                                            ElevatedButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      context,
                                                                      true),
                                                              child: Text(
                                                                AppLocale
                                                                    .confirm
                                                                    .getString(
                                                                        context),
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .bodySmall
                                                                    ?.copyWith(
                                                                        color: Theme.of(context)
                                                                            .colorScheme
                                                                            .surface),
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    );

                                                    if (confirm != true) return;

                                                    final paid =
                                                        await cancelYappyTransaction(
                                                            transactionId:
                                                                yappyTransactionId!);
                                                    if (paid) {
                                                      if (mounted) {
                                                        paymentControllers[
                                                                method['id']]
                                                            ?.text = '0.0';
                                                        yappyTransactionId =
                                                            null;
                                                        _validateForm();
                                                        ToastMessage.show(
                                                          context: context,
                                                          message:
                                                              'Pago anulado correctamente',
                                                          type: ToastType.help,
                                                        );
                                                      }
                                                    }
                                                  }),
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
                  maxWidthContainer: 320,
                  margin: EdgeInsets.only(top: 24),
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
                      if (invoiceLines.isNotEmpty &&
                          getTotalTaxAmount() > 0) ...[
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
                                      Text(
                                          '\$${entry.value.toStringAsFixed(2)}',
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
                        controller: docActionController,
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
      ),
    );
  }
}
