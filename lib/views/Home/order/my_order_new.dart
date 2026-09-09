import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../shared/footer.dart';
import '../../../shared/formater.dart';
import '../../../shared/toast_message.dart';
import '../../../theme/colors.dart';
import '../bpartner/bpartner_new.dart';
import 'my_order_print_generator.dart';
import 'my_order_detail.dart';
import 'order_funtions.dart';
import 'package:shimmer/shimmer.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:printing/printing.dart';
import '../product/product_new.dart';
import 'package:primware/shared/shimmer_list.dart';
import 'product_selection_popup.dart';
import 'held_ticket.dart';
import '../product/product_repository.dart';

class OrderNewPage extends StatefulWidget {
  final bool isRefund;
  final int? doctypeID;
  final String? orderName;
  final int? sourceOrderId;
  final String? docSubTypeSO;
  final HeldTicket? heldTicket;

  const OrderNewPage({
    super.key,
    this.isRefund = false,
    this.doctypeID,
    this.orderName,
    this.sourceOrderId,
    this.docSubTypeSO,
    this.heldTicket,
  });

  @override
  State<OrderNewPage> createState() => _OrderNewPageState();
}

class _OrderNewPageState extends State<OrderNewPage> {
  late final Future<void> Function() _activeOrderSaver;
  String? _resumedTicketId;
  DateTime? _resumedTicketCreatedAt;
  final CustomSearchFieldController customerFieldController = CustomSearchFieldController(),
      productFieldController = CustomSearchFieldController();

  String? createAnchorCustomerTerm;
  String? createAnchorProductTerm;

  double calculatedChange = 0.0;
  TextEditingController clienteController = TextEditingController();
  TextEditingController qtyProductController = TextEditingController();
  TextEditingController productController = TextEditingController();
  TextEditingController taxController = TextEditingController();
  bool isSending = false,
      isTaxLoading = true,
      isProductCategoryLoading = true,
      isCustomerSearchLoading = false,
      isProductSearchLoading = false,
      isProductLoading = true,
      isYappyLoading = false,
      isSalesRepLoading = true,
      isYappyConfigAvailable = false,
      canShowCreateCustomerButton = false,
      firtsLoad = false,
      canShowCreateProductButton = false,
      isDocActionsLoading = true;

  final Set<int> _lockedPayments = {};
  final Map<int, Future<void>> _priceValidations = {};
  bool _applyingProductRepositoryUpdate = false;
  bool _productRepositoryUpdatePending = false;
  List<Map<String, dynamic>> bPartnerOptions = [];
  List<Map<String, dynamic>> productOptions = [];
  List<Map<String, dynamic>> categpryOptions = [];
  List<Map<String, dynamic>> taxOptions = [];
  List<Map<String, dynamic>> invoiceLines = [];
  List<Map<String, dynamic>> salesRep = [];
  Set<int> selectedCategories = {};

  // Payment methods state
  List<Map<String, dynamic>> paymentMethods = [];
  Map<int, TextEditingController> paymentControllers = {};
  bool isPaymentMethodsLoading = true;
  bool isFormValid = false;
  bool _isInvoiceValid = false, hasLocationBPartner = false;

  int? selectedBPartnerID, docNoSequenceID, selectedSalesRepID, bpartnerPriceListID;
  String? selectedDocActionCode, yappyTransactionId, docNoSequenceNumber;
  Map<String, dynamic>? selectedTax;

  double subtotal = 0.0;
  double iva = 0.0;
  double total = 0.0;

  // ==== Helpers for monetary rounding and comparisons ====
  // Redondeo HALF-UP estable a 2 decimales (evita 8.414999 => 8.41)
  double _r2(num v) {
    final x = v * 100.0;
    final adj = v >= 0 ? 1e-9 : -1e-9; // empuja .4999999 a .5
    return ((x + adj).round()) / 100.0;
  }
  // ==== Helpers for monetary rounding and comparisons ====

  void clearInvoiceFields() {
    clienteController.clear();
    qtyProductController.clear();
    productController.clear();
    taxController.clear();
    yappyTransactionId = null;
    selectedBPartnerID = null;
    _lockedPayments.clear();
    selectedBPartnerID = null;
  }

  @override
  void initState() {
    super.initState();

    _resumedTicketId = widget.heldTicket?.id;
    _resumedTicketCreatedAt = widget.heldTicket?.createdAt;
    HeldTicketStore.instance.activeTicketId = _resumedTicketId;

    _activeOrderSaver = () => _putOnHold(showConfirmation: false);
    HeldTicketStore.instance.activeOrderSaver = _activeOrderSaver;
    ProductRepository.instance.addListener(_onProductRepositoryChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBPartner(showLoadingIndicator: true);
      _loadSalesRep();
      _loadDocumentActions();
      _loadProduct();
      _loadTax();
      _loadProductCategory();
      if (POSTenderType.isMultiPayment) {
        _loadPayment();
      }
      if (widget.heldTicket == null) _initialPartner();
      if (widget.heldTicket != null) _restoreHeldTicket(widget.heldTicket!);
    });

    if (Yappy.apiKey != null && Yappy.secretKey != null) {
      isYappyConfigAvailable = true;
    }

    if (widget.doctypeID != null) {
      _loadSequence();
    }
    if (widget.sourceOrderId != null && widget.heldTicket == null) {
      _prefillFromExistingOrder();
    }
  }

  bool get _hasMeaningfulContent {
    if (invoiceLines.isNotEmpty) return true;
    return paymentControllers.values.any((controller) => (double.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0) != 0);
  }

  Map<String, dynamic> _heldTicketData() => {
    'isRefund': widget.isRefund,
    'doctypeID': widget.doctypeID,
    'orderName': widget.orderName,
    'sourceOrderId': widget.sourceOrderId,
    'docSubTypeSO': widget.docSubTypeSO,
    'customerId': selectedBPartnerID,
    'customerName': clienteController.text,
    'hasLocationBPartner': hasLocationBPartner,
    'bpartnerPriceListID': bpartnerPriceListID,
    'salesRepID': selectedSalesRepID,
    'docActionCode': selectedDocActionCode,
    'invoiceLines': invoiceLines,
    'selectedCategories': selectedCategories.toList(),
    'selectedTax': selectedTax,
    'payments': {for (final entry in paymentControllers.entries) entry.key.toString(): entry.value.text},
    'paymentDetails': paymentControllers.entries
        .where((entry) => (double.tryParse(entry.value.text.trim().replaceAll(',', '.')) ?? 0) != 0)
        .map(
          (entry) => {
            'id': entry.key,
            'name': _paymentMethod(entry.key)['name'] ?? _paymentMethod(entry.key)['identifier'],
            'amount': entry.value.text,
          },
        )
        .toList(),
    'lockedPayments': _lockedPayments.toList(),
    'subtotal': subtotal,
    'iva': iva,
    'total': netTotalAmount,
  };

  Future<void> _putOnHold({bool showConfirmation = true}) async {
    if (!_hasMeaningfulContent || isSending) return;
    final now = DateTime.now();
    final ticket = HeldTicket(
      id: _resumedTicketId ?? '${now.microsecondsSinceEpoch}_${UserData.id ?? 0}',
      createdAt: _resumedTicketCreatedAt ?? now,
      updatedAt: now,
      data: _heldTicketData(),
    );
    await HeldTicketStore.instance.save(ticket);
    if (!mounted) return;
    _resumedTicketId = null;
    _resumedTicketCreatedAt = null;
    HeldTicketStore.instance.activeTicketId = null;
    _resetForNewOrder();
    if (showConfirmation) {
      ToastMessage.show(context: context, message: AppLocale.heldTicketSaved.getString(context), type: ToastType.success);
    }
  }

  void _resetForNewOrder() {
    setState(() {
      clearInvoiceFields();
      invoiceLines.clear();
      selectedCategories.clear();
      bpartnerPriceListID = null;
      selectedTax = taxOptions.isEmpty ? null : taxOptions.firstWhere((tax) => tax['isdefault'] == true, orElse: () => taxOptions.first);
      taxController.text = selectedTax?['name']?.toString() ?? '';
      subtotal = 0;
      iva = 0;
      total = 0;
      calculatedChange = 0;
      for (final controller in paymentControllers.values) {
        controller.clear();
      }
      _lockedPayments.clear();
      selectedDocActionCode = POS.documentActions.isEmpty ? null : POS.documentActions.first['code'];
      selectedSalesRepID = UserData.id;
    });
    _validateForm();
    if (widget.doctypeID != null) _loadSequence();
    _initialPartner();
  }

  Future<void> _restoreHeldTicket(HeldTicket ticket) async {
    while (mounted &&
        (isTaxLoading || isSalesRepLoading || isDocActionsLoading || (POSTenderType.isMultiPayment && isPaymentMethodsLoading))) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    if (!mounted) return;
    final data = ticket.data;
    final rawLines = data['invoiceLines'];
    final rawPayments = data['payments'];
    setState(() {
      selectedBPartnerID = data['customerId'] as int?;
      clienteController.text = data['customerName']?.toString() ?? '';
      hasLocationBPartner = data['hasLocationBPartner'] == true;
      bpartnerPriceListID = data['bpartnerPriceListID'] as int?;
      selectedSalesRepID = data['salesRepID'] as int? ?? UserData.id;
      selectedDocActionCode = data['docActionCode']?.toString();
      invoiceLines = rawLines is List ? rawLines.whereType<Map>().map((line) => Map<String, dynamic>.from(line)).toList() : [];
      selectedCategories = data['selectedCategories'] is List
          ? (data['selectedCategories'] as List).whereType<num>().map((id) => id.toInt()).toSet()
          : <int>{};
      if (data['selectedTax'] is Map) {
        final savedTax = Map<String, dynamic>.from(data['selectedTax'] as Map);
        final savedTaxId = savedTax['id'];
        selectedTax = taxOptions.firstWhere((tax) => tax['id'] == savedTaxId, orElse: () => savedTax);
        taxController.text = selectedTax?['name']?.toString() ?? '';
      }
      if (rawPayments is Map) {
        for (final entry in rawPayments.entries) {
          final methodId = int.tryParse(entry.key.toString());
          if (methodId != null && paymentControllers.containsKey(methodId)) {
            paymentControllers[methodId]!.text = entry.value?.toString() ?? '';
          }
        }
      }
      _lockedPayments
        ..clear()
        ..addAll(
          data['lockedPayments'] is List ? (data['lockedPayments'] as List).whereType<num>().map((id) => id.toInt()) : const <int>[],
        );
    });
    _recalculateSummary();
    _validateForm();
  }

  Future<void> _loadSalesRep() async {
    final fetchedSalesRep = await fetctSalesRep();
    if (fetchedSalesRep.isNotEmpty) {
      setState(() {
        salesRep = fetchedSalesRep;
        selectedSalesRepID = UserData.id;
      });
    }

    setState(() => isSalesRepLoading = false);
  }

  Future<void> _loadDocumentActions() async {
    setState(() => isDocActionsLoading = true);

    if (widget.doctypeID != null) {
      await fetchDocumentActions(docTypeID: widget.doctypeID!);
    }

    setState(() {
      isDocActionsLoading = false;
      if (POS.documentActions.isNotEmpty) {
        selectedDocActionCode = POS.documentActions.first['code'];
      }
    });
  }

  Future<void> _initialPartner() async {
    if (POS.templatePartnerID != null) {
      final hasLocation = await fetchBPartnerHasLocation(context: context, partnerId: POS.templatePartnerID);

      setState(() {
        selectedBPartnerID = POS.templatePartnerID;
        clienteController.text = POS.templatePartnerName ?? '';
        hasLocationBPartner = hasLocation;
      });
      _validateForm();
    }
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
          paymentControllers.putIfAbsent(method['id'], () => TextEditingController());
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

      final src = await fetchOrderById(orderId: widget.sourceOrderId!, context: context);
      if (src == null) return;

      // Prefill cliente
      final bpId = src['bpartner']?['id'] ?? src['C_BPartner_ID']?['id'];
      final bpName = src['bpartner']?['name'] ?? src['C_BPartner_ID']?['identifier'] ?? '';

      if (bpId != null) {
        final hasLocation = await fetchBPartnerHasLocation(context: context, partnerId: bpId);
        setState(() {
          selectedBPartnerID = bpId;
          clienteController.text = bpName.toString();
          hasLocationBPartner = hasLocation;
        });
      } else {
        setState(() {
          clienteController.text = bpName.toString();
        });
      }

      // Prefill productos/lineas
      final List<dynamic> lines = (src['lines'] ?? src['C_OrderLine'] ?? src['orderLines'] ?? []) as List<dynamic>;

      final List<Map<String, dynamic>> mapped = [];
      for (final raw in lines) {
        final Map<String, dynamic> line = Map<String, dynamic>.from(raw as Map);
        // Omitir líneas de descuento genérico (qty == -1)
        final qty = (line['QtyOrdered'] ?? line['QtyEntered'] ?? line['quantity'] ?? 1) as num;
        if (qty.toInt() == -1) continue;

        final name = line['Name'] ?? (line['M_Product_ID']?['identifier']?.toString().split('_').skip(1).join(' ') ?? 'Producto');
        final price = (line['PriceActual'] ?? line['Price'] ?? line['price'] ?? 0) as num;
        final dynamic taxField = line['C_Tax_ID'];
        final taxId = (taxField is Map) ? taxField['id'] : (taxField ?? selectedTax?['id']);
        final dynamic productField = line['M_Product_ID'];
        final dynamic categoryField = line['M_Product_Category_ID'];
        final dynamic categoryValue = line['Category'] ?? (categoryField is Map ? categoryField['identifier'] : null);
        // Compute PriceList and Discount
        final priceList = (line['PriceList'] ?? line['priceList'] ?? line['Price'] ?? line['price'] ?? 0);
        final discount = (line['Discount'] ?? 0);
        mapped.add({
          'id': (productField is Map) ? productField['id'] : (productField ?? line['id']),
          'sku': line['SKU'] ?? line['Value'] ?? '',
          'upc': line['upc'] ?? '',
          'category': categoryValue,
          'name': name,
          'price': (price).toDouble(),
          'quantity': (qty).toInt(),
          'C_Tax_ID': taxId,
          'Description': line['Description'] ?? '',
          'PriceList': (priceList is num ? priceList.toDouble() : double.tryParse(priceList.toString()) ?? 0.0),
          'Discount': (discount is num ? discount.toDouble() : double.tryParse(discount.toString()) ?? 0.0),
        });
      }

      if (mapped.isNotEmpty) {
        setState(() {
          invoiceLines = mapped;
          _recalculateSummary();
        });
      }

      // Prefill pagos
      final List<dynamic> pays = (src['payments'] ?? src['C_POSPayment'] ?? []) as List<dynamic>;
      if (pays.isNotEmpty && POSTenderType.isMultiPayment) {
        for (final raw in pays) {
          final Map<String, dynamic> p = Map<String, dynamic>.from(raw as Map);
          final dynamic tenderField = p['C_POSTenderType_ID'];
          final tenderId = (tenderField is Map) ? tenderField['id'] : tenderField;
          final amt = (p['PayAmt'] ?? p['Amount'] ?? 0).toString();
          if (tenderId != null && paymentControllers.containsKey(tenderId)) {
            paymentControllers[tenderId]!.text = amt;
          }
        }
      }

      _validateForm();
    } catch (e) {
      debugPrint('Prefill error: $e');
    }
  }

  Future<void> _loadSequence() async {
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
    ProductRepository.instance.removeListener(_onProductRepositoryChanged);
    if (identical(HeldTicketStore.instance.activeOrderSaver, _activeOrderSaver)) {
      HeldTicketStore.instance.activeOrderSaver = null;
      HeldTicketStore.instance.activeTicketId = null;
    }
    for (final controller in paymentControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _onProductRepositoryChanged() async {
    if (!mounted || productOptions.isEmpty) {
      return;
    }
    if (_applyingProductRepositoryUpdate) {
      _productRepositoryUpdatePending = true;
      return;
    }
    _applyingProductRepositoryUpdate = true;
    try {
      final page = await fetchProductPage(
        categoryID: selectedCategories.toList(),
        searchTerm: productController.text.trim(),
        priceListID: bpartnerPriceListID,
      );
      if (mounted) setState(() => productOptions = page.records);
    } finally {
      _applyingProductRepositoryUpdate = false;
      if (_productRepositoryUpdatePending && mounted) {
        _productRepositoryUpdatePending = false;
        unawaited(_onProductRepositoryChanged());
      }
    }
  }

  bool get clientSelected => selectedBPartnerID != null;
  List<Map<String, dynamic>> get products => invoiceLines;
  double get totalAmount => total;

  Map<String, dynamic> _paymentMethod(int methodId) {
    return paymentMethods.firstWhere((method) => method['id'] == methodId, orElse: () => const <String, dynamic>{});
  }

  bool _isDiscountMethod(Map<String, dynamic> method) => method['isDiscount'] == true;

  List<Map<String, dynamic>> get _orderedDiscountMethods => [
    ...paymentMethods.where((method) => method['isRetireDiscount'] == true),
    ...paymentMethods.where((method) => method['isGlobalDiscount'] == true),
  ];

  double _controllerAmount(int methodId) {
    return _r2(double.tryParse(paymentControllers[methodId]?.text.trim().replaceAll(',', '.') ?? '') ?? 0.0);
  }

  bool get _hasDiscountConfig => POS.discountChargeID != null && POS.discountTaxID != null && POS.discountTaxRate != null;

  Map<int, Map<String, double>> _productTaxGroups() {
    final groups = <int, Map<String, double>>{};
    for (final line in invoiceLines) {
      final dynamic taxIdValue = line['C_Tax_ID'];
      if (taxIdValue is! num) continue;
      final taxId = taxIdValue.toInt();
      final tax = taxOptions.firstWhere((item) => item['id'] == taxId, orElse: () => const <String, dynamic>{});
      final dynamic rawRate = tax['rate'];
      final rate = rawRate is num ? rawRate.toDouble() : double.tryParse('${rawRate ?? 0}') ?? 0.0;
      final base = _r2(((line['price'] ?? 0) as num) * ((line['quantity'] ?? 1) as num));
      final group = groups.putIfAbsent(taxId, () => <String, double>{'Base': 0.0, 'Rate': rate});
      group['Base'] = _r2((group['Base'] ?? 0.0) + base);
    }
    return groups;
  }

  double _simulatedTotalForDiscountBase(double discountBase) {
    final groups = _productTaxGroups().map((taxId, group) => MapEntry(taxId, <String, double>{...group}));
    final discountTaxId = POS.discountTaxID;
    if (discountTaxId != null) {
      final group = groups.putIfAbsent(discountTaxId, () => <String, double>{'Base': 0.0, 'Rate': POS.discountTaxRate ?? 0.0});
      group['Base'] = _r2((group['Base'] ?? 0.0) - discountBase);
      group['Rate'] = POS.discountTaxRate ?? group['Rate'] ?? 0.0;
    }
    final tax = _r2(
      groups.values.map((group) => _r2((group['Base'] ?? 0.0) * (group['Rate'] ?? 0.0) / 100)).fold(0.0, (sum, amount) => sum + amount),
    );
    return _r2(subtotal - discountBase + tax);
  }

  double _effectiveDiscountForBase(double base, double previousBase) {
    return _r2(_simulatedTotalForDiscountBase(previousBase) - _simulatedTotalForDiscountBase(previousBase + base));
  }

  double _baseDiscountForGross(double gross, double previousBase) {
    if (gross <= 0 || POS.discountTaxRate == null) return 0.0;
    final approximateCents = (gross / (1 + POS.discountTaxRate! / 100) * 100).floor();
    double best = 0.0;
    double bestEffective = 0.0;
    for (var cents = approximateCents - 10; cents <= approximateCents + 10; cents++) {
      if (cents < 0) continue;
      final candidate = _r2(cents / 100);
      final candidateEffective = _effectiveDiscountForBase(candidate, previousBase);
      if (candidateEffective <= gross && candidateEffective > bestEffective) {
        best = candidate;
        bestEffective = candidateEffective;
      }
    }
    return best;
  }

  double _normalizedDiscountAmount(double requested, {double previousBase = 0.0}) {
    if (!_hasDiscountConfig || requested <= 0) return 0.0;
    final base = _baseDiscountForGross(requested, previousBase);
    return _effectiveDiscountForBase(base, previousBase);
  }

  List<Map<String, dynamic>> _buildDiscountLines() {
    if (!_hasDiscountConfig || invoiceLines.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final lines = <Map<String, dynamic>>[];
    var cumulativeBase = 0.0;
    for (final method in _orderedDiscountMethods) {
      final methodId = method['id'] as int;
      final requested = _controllerAmount(methodId);
      if (requested <= 0) continue;
      final base = _baseDiscountForGross(requested, cumulativeBase);
      if (base <= 0) continue;
      final effective = _effectiveDiscountForBase(base, cumulativeBase);
      lines.add({
        'Amount': base,
        'C_Tax_ID': POS.discountTaxID,
        'TaxAmount': _r2(effective - base),
        'EffectiveAmount': effective,
        'MethodId': methodId,
      });
      cumulativeBase = _r2(cumulativeBase + base);
    }
    return lines;
  }

  double get totalDiscount =>
      _r2(_buildDiscountLines().map((line) => (line['EffectiveAmount'] as num).toDouble()).fold(0.0, (sum, amount) => sum + amount));

  double get netTotalAmount {
    final discountBase = _buildDiscountLines().map((line) => (line['Amount'] as num).toDouble()).fold(0.0, (sum, amount) => sum + amount);
    return _r2(_simulatedTotalForDiscountBase(discountBase).clamp(0.0, totalAmount));
  }

  double get listSubtotal => _r2(
    invoiceLines
        .map((line) => _r2(((line['PriceList'] ?? line['price'] ?? 0) as num) * ((line['quantity'] ?? 1) as num)))
        .fold(0.0, (sum, amount) => sum + amount),
  );

  double get lineDiscountTotal => _r2(
    invoiceLines
        .map((line) {
          final priceList = ((line['PriceList'] ?? line['price'] ?? 0) as num).toDouble();
          final priceActual = ((line['price'] ?? 0) as num).toDouble();
          final quantity = ((line['quantity'] ?? 1) as num).toDouble();
          return _r2(((priceList - priceActual).clamp(0.0, priceList)) * quantity);
        })
        .fold(0.0, (sum, amount) => sum + amount),
  );

  List<Map<String, dynamic>> get specialDiscountSummary {
    return _orderedDiscountMethods
        .map((method) {
          final methodId = method['id'] as int;
          final amount = _r2(
            _buildDiscountLines()
                .where((line) => line['MethodId'] == methodId)
                .map((line) => (line['EffectiveAmount'] as num).toDouble())
                .fold(0.0, (sum, value) => sum + value),
          );
          return <String, dynamic>{'Name': method['name'] ?? AppLocale.discount.getString(context), 'Amount': amount};
        })
        .where((item) => (item['Amount'] as double) > 0)
        .toList();
  }

  double get retireDiscountAmount => _normalizedDiscountAmount(_r2(totalAmount * 0.25));

  void _clampGlobalDiscount(int methodId, String rawValue) {
    final otherDiscounts = _r2(
      paymentMethods
          .where((method) => _isDiscountMethod(method) && method['id'] != methodId)
          .map((method) => _controllerAmount(method['id'] as int))
          .fold(0.0, (sum, amount) => sum + amount),
    );
    final maximum = _r2((totalAmount - otherDiscounts).clamp(0.0, totalAmount));
    final current = _controllerAmount(methodId);
    if (current > maximum) {
      paymentControllers[methodId]?.text = maximum.toStringAsFixed(2);
      paymentControllers[methodId]?.selection = TextSelection.collapsed(offset: paymentControllers[methodId]!.text.length);
    }
    final decimals = rawValue.replaceAll(',', '.').split('.');
    if (decimals.length == 2 && decimals.last.length >= 2 && _controllerAmount(methodId) > 0) {
      final effective = _r2(
        _buildDiscountLines()
            .where((line) => line['MethodId'] == methodId)
            .map((line) => (line['EffectiveAmount'] as num).toDouble())
            .fold(0.0, (sum, amount) => sum + amount),
      );
      if (effective != _controllerAmount(methodId)) {
        paymentControllers[methodId]?.text = effective.toStringAsFixed(2);
        paymentControllers[methodId]?.selection = TextSelection.collapsed(offset: paymentControllers[methodId]!.text.length);
      }
    }
    _validateForm();
  }

  Future<bool> _resetPaymentsForProductChange() async {
    final transactionId = yappyTransactionId;
    if (transactionId != null) {
      final wasCancelled = await cancelYappyTransaction(transactionId: transactionId);
      if (!wasCancelled) {
        if (mounted) {
          ToastMessage.show(
            context: context,
            message: 'No se pudo anular el pago Yappy. Los productos no fueron modificados.',
            type: ToastType.failure,
          );
        }
        return false;
      }
    }

    if (!mounted) return false;

    setState(() {
      for (final controller in paymentControllers.values) {
        controller.text = '0.00';
      }
      _lockedPayments.clear();
      yappyTransactionId = null;
    });
    _validateForm();
    return true;
  }

  Future<void> _applyRetireDiscount(int methodId) async {
    final discount = retireDiscountAmount;
    final otherDiscounts = _r2(
      paymentMethods
          .where((method) => _isDiscountMethod(method) && method['id'] != methodId)
          .map((method) => _controllerAmount(method['id'] as int))
          .fold(0.0, (sum, amount) => sum + amount),
    );
    final normalPayments = _r2(
      paymentControllers.entries
          .where((entry) => !_isDiscountMethod(_paymentMethod(entry.key)))
          .map((entry) => _controllerAmount(entry.key))
          .fold(0.0, (sum, amount) => sum + amount),
    );
    final projectedDiscount = _r2((discount + otherDiscounts).clamp(0.0, totalAmount));
    final exceedsNetTotal = normalPayments > _r2(totalAmount - projectedDiscount);

    if (exceedsNetTotal && yappyTransactionId != null) {
      final transactionId = yappyTransactionId!;
      final wasCancelled = await cancelYappyTransaction(transactionId: transactionId);
      if (!wasCancelled) {
        if (mounted) {
          ToastMessage.show(
            context: context,
            message: 'No se pudo anular el pago Yappy. El descuento no fue aplicado.',
            type: ToastType.failure,
          );
        }
        return;
      }
    }

    if (!mounted) return;

    setState(() {
      paymentControllers[methodId]?.text = discount.toStringAsFixed(2);

      // R siempre conserva su 25%; si G ya tenía un valor, se limita al saldo disponible.
      final retireTotal = _r2(
        paymentMethods
            .where((method) => method['isRetireDiscount'] == true)
            .map((method) => _controllerAmount(method['id'] as int))
            .fold(0.0, (sum, amount) => sum + amount),
      );
      var globalRemaining = _r2((totalAmount - retireTotal).clamp(0.0, totalAmount));
      for (final method in paymentMethods.where((method) => method['isGlobalDiscount'] == true)) {
        final globalId = method['id'] as int;
        final amount = _controllerAmount(globalId);
        if (amount > globalRemaining) {
          paymentControllers[globalId]?.text = globalRemaining.toStringAsFixed(2);
        }
        globalRemaining = _r2((globalRemaining - _controllerAmount(globalId)).clamp(0.0, globalRemaining));
      }

      if (exceedsNetTotal) {
        for (final entry in paymentControllers.entries) {
          final method = _paymentMethod(entry.key);
          if (!_isDiscountMethod(method)) {
            entry.value.text = '0.00';
            _lockedPayments.remove(entry.key);
          }
        }
        yappyTransactionId = null;
      }

      _lockedPayments.add(methodId);
    });
    _validateForm();
  }

  void _clearRetireDiscount(int methodId) {
    setState(() {
      paymentControllers[methodId]?.text = '0.00';
      _lockedPayments.remove(methodId);
    });
    _validateForm();
  }

  void _validateForm() {
    final totalPayment = _r2(
      paymentControllers.entries
          .where((entry) => !_isDiscountMethod(_paymentMethod(entry.key)))
          .map((entry) => _controllerAmount(entry.key))
          .fold(0.0, (sum, val) => sum + val),
    );

    final totalCash = _r2(
      paymentControllers.entries
          .where((entry) {
            final method = paymentMethods.firstWhere((m) => m['id'] == entry.key, orElse: () => {});
            return method['isCash'] == true;
          })
          .map((entry) => _r2(double.tryParse((entry.value.text).replaceAll(',', '.')) ?? 0.0))
          .fold(0.0, (sum, val) => sum + val),
    );

    final amount = netTotalAmount;

    final overpay = _r2(totalPayment - amount);
    final hasEnoughPayment = totalPayment >= amount;
    final cashCoversOverpay = overpay <= 0 || totalCash >= overpay;
    final change = hasEnoughPayment && cashCoversOverpay && overpay > 0 ? overpay : 0.0;

    setState(() {
      final hasPriceConflict = invoiceLines.any((line) => line['priceSyncState'] == 'changed');
      if (POS.isPOS && paymentMethods.isNotEmpty) {
        _isInvoiceValid = clientSelected && products.isNotEmpty && hasEnoughPayment && cashCoversOverpay && !hasPriceConflict;
      } else {
        _isInvoiceValid = clientSelected && products.isNotEmpty && !hasPriceConflict;
      }
      calculatedChange = change > 0 ? change : 0.0;
    });
  }

  void _startPriceValidation(Map<String, dynamic> line) {
    final id = line['id'] as int?;
    if (id == null || line['fromCache'] != true) {
      line['priceSyncState'] = 'valid';
      return;
    }
    line['priceSyncState'] = 'pending';
    final validation = _validateProductPrice(id);
    _priceValidations[id] = validation;
    validation.whenComplete(() => _priceValidations.remove(id));
  }

  Future<void> _validateProductPrice(int productID) async {
    try {
      final serverProduct = await ProductRepository.instance.refreshProduct(productID: productID, partnerPriceListID: bpartnerPriceListID);
      if (!mounted || serverProduct == null) {
        throw Exception('Product unavailable');
      }
      final serverPrice = _r2(serverProduct['price'] ?? 0);
      final serverListPrice = _r2(serverProduct['priceList'] ?? serverPrice);
      setState(() {
        for (final line in invoiceLines.where((item) => item['id'] == productID)) {
          final baseline = _r2(line['catalogPriceAtAdd'] ?? line['price'] ?? 0);
          line['serverPrice'] = serverPrice;
          line['serverPriceList'] = serverListPrice;
          line['priceSyncState'] = baseline == serverPrice ? 'valid' : 'changed';
          if (baseline == serverPrice) {
            line['fromCache'] = false;
            line['QtyAvailable'] = serverProduct['QtyAvailable'];
          }
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        for (final line in invoiceLines.where((item) => item['id'] == productID)) {
          line['priceSyncState'] = 'error';
        }
      });
    }
    _validateForm();
  }

  void _acceptServerPrice(Map<String, dynamic> line) {
    final serverPrice = _r2(line['serverPrice'] ?? line['price'] ?? 0);
    final serverListPrice = _r2(line['serverPriceList'] ?? serverPrice);
    final manual = line['manualPriceOverride'] == true && (!POS.isPOS || POS.isModifyPrice);
    setState(() {
      if (!manual) line['price'] = serverPrice;
      line['PriceList'] = serverListPrice;
      line['priceList'] = serverListPrice;
      line['catalogPriceAtAdd'] = serverPrice;
      line['Discount'] = serverListPrice > 0 ? _r2(100 * (1 - (_r2(line['price'] ?? 0) / serverListPrice))) : 0.0;
      line['priceSyncState'] = 'valid';
      line['fromCache'] = false;
    });
    _recalculateSummary();
    _validateForm();
  }

  Future<bool> _ensurePricesValid() async {
    for (final line in invoiceLines.where((item) => item['priceSyncState'] == 'error').toList()) {
      final id = line['id'] as int?;
      if (id != null) _startPriceValidation(line);
    }
    if (_priceValidations.isNotEmpty) {
      await Future.wait(_priceValidations.values.toList());
    }
    if (!mounted) return false;
    if (invoiceLines.any((line) => line['priceSyncState'] == 'changed')) {
      ToastMessage.show(context: context, message: AppLocale.priceValidationRequired.getString(context), type: ToastType.warning);
      return false;
    }
    if (invoiceLines.any((line) => line['priceSyncState'] == 'error' || line['priceSyncState'] == 'pending')) {
      ToastMessage.show(context: context, message: AppLocale.priceValidationFailed.getString(context), type: ToastType.failure);
      return false;
    }
    return true;
  }

  Future<void> _loadBPartner({bool showLoadingIndicator = false}) async {
    if (showLoadingIndicator) {
      setState(() {
        isCustomerSearchLoading = true;
        canShowCreateCustomerButton = false;
        createAnchorCustomerTerm = null;
      });
    }

    final partner = await fetchBPartner(context: context, searchTerm: clienteController.text.trim());

    setState(() {
      bPartnerOptions = partner;
      isCustomerSearchLoading = false;
      if (bPartnerOptions.isNotEmpty) {
        canShowCreateCustomerButton = false;
        createAnchorCustomerTerm = null;
      } else {
        canShowCreateCustomerButton = clienteController.text.trim().isNotEmpty;
        createAnchorCustomerTerm = canShowCreateCustomerButton ? clienteController.text.trim() : null;
      }
    });
    if (mounted && firtsLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        customerFieldController.requestFocus();
      });
    }
    if (productOptions.isNotEmpty && bPartnerOptions.isNotEmpty) {
      firtsLoad = true;
    }
  }

  Future<void> _loadProduct({bool showLoadingIndicator = false, bool requestFieldFocus = true}) async {
    if (showLoadingIndicator) {
      setState(() {
        isProductSearchLoading = true;
        canShowCreateProductButton = false; // Limpiamos al empezar a buscar
        createAnchorProductTerm = null;
      });
    }

    final searchTerm = productController.text.trim();
    final filtered = searchTerm.isNotEmpty || selectedCategories.isNotEmpty;
    final page = await fetchProductPage(
      categoryID: selectedCategories.toList(),
      searchTerm: searchTerm,
      priceListID: bpartnerPriceListID,
      preferCache: !filtered,
      waitForStock: filtered,
    );
    final product = page.records;

    if (!mounted) return;
    setState(() {
      productOptions = product;
      isProductLoading = false;
      isProductSearchLoading = false;

      // --- NUEVA LÓGICA: ¿Mostramos el botón de crear producto? ---
      if (productOptions.isNotEmpty) {
        canShowCreateProductButton = false;
        createAnchorProductTerm = null;
      } else {
        // Si no hay resultados y el usuario escribió algo, encendemos el botón
        canShowCreateProductButton = productController.text.trim().isNotEmpty;
        createAnchorProductTerm = canShowCreateProductButton ? productController.text.trim() : null;
      }
    });

    if (mounted && firtsLoad && requestFieldFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        productFieldController.requestFocus();
      });
    }
    if (productOptions.isNotEmpty && bPartnerOptions.isNotEmpty) {
      firtsLoad = true;
    }
  }

  Future<List<Map<String, dynamic>>> _searchProductSuggestions(String query) async {
    final page = await fetchProductPage(
      categoryID: selectedCategories.toList(),
      searchTerm: query.trim(),
      priceListID: bpartnerPriceListID,
      preferCache: false,
      waitForStock: true,
    );
    return page.records;
  }

  Future<void> _showProductSelectionPopup() async {
    final selection = await ProductSelectionPopup.show(
      context,
      priceListID: bpartnerPriceListID,
      initialSearch: productController.text.trim(),
      initialCategoryIDs: selectedCategories,
      onCategoriesChanged: (categories) {
        if (mounted) {
          setState(() => selectedCategories = categories);
          unawaited(_loadProduct(showLoadingIndicator: true, requestFieldFocus: false));
        }
      },
    );
    if (selection != null) {
      setState(() => selectedCategories = {...selection.categoryIDs});
      final selectedProducts = selection.products;
      if (selectedProducts.isEmpty) return;
      if (POS.cPosID != null) {
        if (!await _resetPaymentsForProductChange()) return;
      }
      final addedLines = <Map<String, dynamic>>[];
      setState(() {
        for (final item in selectedProducts) {
          final int? selectedTaxID = (item['C_Tax_ID'] ?? item['tax']?['id'] ?? selectedTax?['id']) as int?;
          final double priceActual = _r2((item['price'] ?? item['Price'] ?? 0).toDouble());
          final double priceList = _r2((item['PriceList'] ?? item['priceList'] ?? item['price'] ?? 0).toDouble());
          final double discount = priceList > 0 ? _r2(100 * (1 - (priceActual / priceList))) : 0.0;

          final line = <String, dynamic>{
            ...item,
            'quantity': 1,
            'price': priceActual,
            'C_Tax_ID': selectedTaxID,
            'Description': item['Description'] ?? '',
            'PriceList': priceList,
            'Discount': discount,
            'catalogPriceAtAdd': priceActual,
            'priceSyncState': item['fromCache'] == true ? 'pending' : 'valid',
          };
          invoiceLines.add(line);
          addedLines.add(line);
        }
      });
      for (final line in addedLines) {
        _startPriceValidation(line);
      }
      if (POS.cPosID != null) {
        _recalculateSummary();
        _validateForm();
      } else {
        _recalculateSummary();
      }
    }
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
    final defaultTax = tax.isNotEmpty ? tax.firstWhere((t) => t['isdefault'] == true, orElse: () => tax.first) : null;
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
      final price = _r2(line['price'] ?? 0);
      final quantity = _r2(line['quantity'] ?? 1);
      final taxID = line['C_Tax_ID'];

      final lineNet = _r2(price * quantity);
      newSubtotal += lineNet;

      final tax = taxOptions.firstWhere((t) => t['id'] == taxID, orElse: () => {});
      final taxPercent = _r2(double.tryParse('${tax['rate'] ?? '0'}') ?? 0.0);

      final lineTax = _r2(lineNet * (taxPercent / 100));
      newIVA += lineTax;
    }

    setState(() {
      subtotal = _r2(newSubtotal);
      iva = _r2(newIVA);
      total = _r2(subtotal + getTotalTaxAmount());
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
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _showQuantityDialog(Map<String, dynamic> product, {int? index}) async {
    final canModifyPrice = !POS.isPOS || POS.isModifyPrice;
    int? selectedTaxID = index != null ? (product['C_Tax_ID'] ?? product['tax']?['id']) : (product['tax']?['id'] ?? selectedTax?['id']);

    final quantityController = TextEditingController(
      text: index != null && product['quantity'] != null ? product['quantity'].toString() : "1",
    );

    // --- Funciones Matemáticas sin la función clamp para permitir negativos ---
    double r2local(num v) {
      final x = v * 100.0;
      final adj = v >= 0 ? 1e-9 : -1e-9;
      return ((x + adj).round()) / 100.0;
    }

    // Si el precio es mayor al de lista, el descuento dará negativo
    double calcDiscount(double priceList, double priceActual) => priceList <= 0 ? 0 : (100 * (1 - (priceActual / priceList)));

    double calcPrice(double priceList, double discount) => priceList * (1 - (discount / 100));

    final double priceList =
        (index != null
                ? (product['PriceList'] ?? product['priceList'] ?? product['price'] ?? 0)
                : (product['PriceList'] ?? product['priceList'] ?? product['price'] ?? 0))
            .toDouble();

    // Valores iniciales
    double initialPrice = index != null ? (product['price'] ?? product['PriceActual'] ?? 0).toDouble() : (product['price'] ?? 0).toDouble();

    double initialDiscount = index != null ? (product['Discount'] ?? 0).toDouble() : calcDiscount(priceList, initialPrice);

    final priceController = TextEditingController(text: initialPrice == 0 ? '' : initialPrice.toStringAsFixed(2));
    final discountController = TextEditingController(text: initialDiscount == 0 ? '' : initialDiscount.toStringAsFixed(2));
    final descriptionController = TextEditingController(
      text: index != null && product['Description'] != null ? product['Description'].toString() : '',
    );

    Future<void> onSubmitted(BuildContext dialogContext) async {
      final qty = int.tryParse(quantityController.text) ?? 1;
      final effectivePrice = double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0.0;
      final effectiveDiscount = double.tryParse(discountController.text.replaceAll(',', '.')) ?? 0.0;

      if (!await _resetPaymentsForProductChange()) {
        return;
      }

      if (index != null) {
        invoiceLines.removeAt(index);
      }

      late Map<String, dynamic> addedLine;
      setState(() {
        addedLine = <String, dynamic>{
          ...product,
          'quantity': qty,
          'price': r2local(effectivePrice),
          'C_Tax_ID': selectedTaxID ?? selectedTax?['id'],
          'Description': descriptionController.text,
          'PriceList': r2local(priceList),
          'Discount': r2local(effectiveDiscount),
          'catalogPriceAtAdd': product['catalogPriceAtAdd'] ?? initialPrice,
          'manualPriceOverride':
              product['manualPriceOverride'] == true || (canModifyPrice && r2local(effectivePrice) != r2local(initialPrice)),
          'priceSyncState': product['priceSyncState'] ?? (product['fromCache'] == true ? 'pending' : 'valid'),
        };
        invoiceLines.insert(index ?? invoiceLines.length, addedLine);
      });

      _startPriceValidation(addedLine);

      _recalculateSummary();
      productController.clear();
      _validateForm();
      Navigator.pop(dialogContext, true);
    }

    final result = await showDialog<bool>(
      useSafeArea: true,
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return WillPopScope(
          onWillPop: () async {
            productController.clear();
            return true;
          },
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return AlertDialog(
                backgroundColor: Theme.of(context).cardColor,
                insetPadding: const EdgeInsets.all(16.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

                title: Text(product['name'] ?? 'Producto', style: Theme.of(context).textTheme.bodyMedium),

                content: SizedBox(
                  width: 500,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: MediaQuery.of(context).viewInsets,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Divider(color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: CustomSpacer.medium),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: IconButton(
                                  icon: const Icon(Icons.remove),
                                  color: ColorTheme.error,
                                  onPressed: () {
                                    int current = int.tryParse(quantityController.text) ?? 1;
                                    if (current > 1) {
                                      setModalState(() {
                                        quantityController.text = (current - 1).toString();
                                      });
                                    }
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 120,
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
                                  icon: const Icon(Icons.add),
                                  color: ColorTheme.success,
                                  onPressed: () {
                                    int current = int.tryParse(quantityController.text) ?? 1;
                                    setModalState(() {
                                      quantityController.text = (current + 1).toString();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: CustomSpacer.medium),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.local_offer_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppLocale.priceList.getString(context),
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '\$${r2local(priceList).toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: CustomSpacer.large),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 6,
                                child: TextfieldTheme(
                                  controlador: priceController,
                                  readOnly: !canModifyPrice,
                                  pista: product['price'] == 0 ? product['price'].toString() : null,
                                  texto: AppLocale.price.getString(context),
                                  inputType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]'))],
                                  onChanged: canModifyPrice
                                      ? (val) {
                                          setModalState(() {
                                            final p = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                                            discountController.text = calcDiscount(priceList, p).toStringAsFixed(2);
                                          });
                                        }
                                      : null,
                                ),
                              ),
                              const SizedBox(width: CustomSpacer.small),
                              Expanded(
                                flex: 4,
                                child: TextfieldTheme(
                                  controlador: discountController,
                                  readOnly: !canModifyPrice,
                                  texto: '% Desc.',
                                  inputType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\-0-9\.,]'))],
                                  onChanged: canModifyPrice
                                      ? (val) {
                                          setModalState(() {
                                            if (val == '-') return;
                                            final d = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                                            priceController.text = calcPrice(priceList, d).toStringAsFixed(2);
                                          });
                                        }
                                      : null,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: CustomSpacer.small),
                          Divider(color: Colors.grey.withOpacity(0.3), thickness: 1, height: 24),

                          SearchableDropdown<int>(
                            labelText: AppLocale.taxType.getString(context),
                            showSearchBox: false,
                            options: taxOptions,
                            value: selectedTaxID,
                            onChanged: (value) {
                              setModalState(() {
                                selectedTaxID = value;
                              });
                            },
                            displayItem: (item) => '${item['name']} (${item['rate']}%)',
                          ),
                          const SizedBox(height: CustomSpacer.medium),
                          TextFieldComments(
                            controlador: descriptionController,
                            texto: AppLocale.descriptionOptional.getString(context),
                            onSubmitted: (_) => onSubmitted(dialogContext),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  TextButton(
                    onPressed: () {
                      productController.clear();
                      Navigator.pop(dialogContext, false);
                    },
                    child: Text(AppLocale.cancel.getString(context)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => onSubmitted(dialogContext),
                    child: Text(index != null ? 'Editar' : AppLocale.add.getString(context)),
                  ),
                ],
              );
            },
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
      ToastMessage.show(context: context, message: result['message'] ?? 'No se pudo generar el QR', type: ToastType.failure);
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
                  ToastMessage.show(context: context, message: 'Pago recibido correctamente', type: ToastType.success);
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
                await cancelYappyTransaction(transactionId: yappyTransactionId!);
                setState(() {
                  yappyTransactionId = null;
                });

                ToastMessage.show(context: context, message: 'Pago cancelado o tiempo agotado', type: ToastType.failure);
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
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                          color: Colors.white,
                        ),
                        child: Center(child: Image.asset('assets/img/yappyLogo.png', width: 240)),
                      ),
                      const SizedBox(height: CustomSpacer.xlarge),

                      // QR grande centrado
                      Container(
                        padding: const EdgeInsets.all(8),
                        width: 280,
                        // height: 280,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white),
                        child: Center(
                          child: Column(
                            children: [
                              QrImageView(data: hash, version: QrVersions.auto, size: 260),
                              // Contador
                              Text('Tiempo restante: $mm:$ss', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 6),
                              // Id de transacción (pequeño)
                              Text('Transacción: $yappyTransactionId', style: Theme.of(context).textTheme.labelSmall),
                              const SizedBox(height: CustomSpacer.medium),
                              TextButton(
                                style: TextButton.styleFrom(backgroundColor: ColorTheme.error.withOpacity(0.2)),
                                onPressed: () {
                                  closed = true;
                                  ticker?.cancel();
                                  cancelYappyTransaction(transactionId: yappyTransactionId!);
                                  setState(() {
                                    yappyTransactionId = null;
                                  });

                                  ToastMessage.show(context: context, message: 'Pago cancelado o tiempo agotado', type: ToastType.failure);
                                  Navigator.of(dialogContext).pop(false);
                                },
                                child: Text(
                                  AppLocale.cancel.getString(context),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: CustomSpacer.xlarge),
                      Text(
                        'Escanéalo desde Yappy App o desde Yappy en el App de tu banco',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
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

  Future<void> _deleteLine(int index) async {
    if (!await _resetPaymentsForProductChange()) {
      return;
    }

    setState(() {
      invoiceLines.removeAt(index);
      _recalculateSummary();
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
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(AppLocale.no.getString(context))),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(AppLocale.yes.getString(context))),
        ],
      ),
    );
  }

  Future<void> _createInvoice({required List<Map<String, dynamic>> product, required int bPartner}) async {
    if (!await _ensurePricesValid()) return;
    if (widget.isRefund && widget.sourceOrderId != null) {
      try {
        final alreadyReturned = await hasActiveReturnForOrder(orderId: widget.sourceOrderId!);
        if (alreadyReturned) {
          if (!mounted) return;
          ToastMessage.show(context: context, message: AppLocale.returnAlreadyExists.getString(context), type: ToastType.warning);
          return;
        }
      } catch (_) {
        if (!mounted) return;
        ToastMessage.show(context: context, message: AppLocale.returnValidationError.getString(context), type: ToastType.failure);
        return;
      }
    }
    final String actionLabel = (() {
      try {
        final match = POS.documentActions.firstWhere(
          (a) => a['code'] == (selectedDocActionCode ?? ''),
          orElse: () => POS.documentActions.isNotEmpty ? POS.documentActions.first : const {'name': ''},
        );
        return (match['name'] ?? '').toString();
      } catch (_) {
        return AppLocale.process.getString(context);
      }
    })();

    final confirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(AppLocale.process.getString(context)),
          content: Text(
            widget.isRefund
                ? AppLocale.confirmCompleteCreditNote
                      .getString(context)
                      .replaceAll('{action}', actionLabel.isEmpty ? AppLocale.process.getString(context) : actionLabel)
                : AppLocale.confirmCompleteOrder
                      .getString(context)
                      .replaceAll('{action}', actionLabel.isEmpty ? AppLocale.process.getString(context) : actionLabel),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocale.cancel.getString(context))),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(AppLocale.confirm.getString(context))),
          ],
        );
      },
    );

    if (confirm != true) return;

    if (widget.isRefund && widget.sourceOrderId != null) {
      try {
        if (await hasActiveReturnForOrder(orderId: widget.sourceOrderId!)) {
          if (!mounted) return;
          ToastMessage.show(context: context, message: AppLocale.returnAlreadyExists.getString(context), type: ToastType.warning);
          return;
        }
      } catch (_) {
        if (!mounted) return;
        ToastMessage.show(context: context, message: AppLocale.returnValidationError.getString(context), type: ToastType.failure);
        return;
      }
    }

    setState(() => isSending = true);
    final List<Map<String, dynamic>> invoiceLine = product.map((item) {
      final double price = _r2(item['price'] ?? 0);
      final double priceList = _r2(item['PriceList'] ?? item['priceList'] ?? item['price'] ?? 0);
      final double discount = _r2(item['Discount'] ?? (priceList > 0 ? (100 * (1 - (price / priceList))) : 0));
      return {
        'M_Product_ID': item['id'],
        'SKU': item['sku'],
        'upc': item['upc'],
        'Category': item['category'],
        'Name': item['name'],
        'Price': price,
        'PriceList': priceList,
        'Discount': discount,
        'Quantity': item['quantity'],
        'C_Tax_ID': item['C_Tax_ID'],
        'Description': item['Description'] ?? '',
      };
    }).toList();

    double remainingChange = _r2(calculatedChange);
    final paymentData = paymentControllers.entries
        .where((entry) {
          if (_isDiscountMethod(_paymentMethod(entry.key))) return false;
          final txt = entry.value.text.trim();
          final amt = double.tryParse(txt.replaceAll(',', '.')) ?? 0.0;
          return amt > 0;
        })
        .map((entry) {
          final txt = entry.value.text.trim();
          final originalAmt = double.tryParse(txt.replaceAll(',', '.')) ?? 0.0;

          final method = paymentMethods.firstWhere((m) => m['id'] == entry.key, orElse: () => const <String, dynamic>{});

          final bool isYappy = (method['name']?.toString().toLowerCase().contains('yappy') == true);
          final bool isCash = (method['isCash'] == true);

          // Distribuir el vuelto una sola vez entre los métodos de efectivo.
          double adjustedAmt = _r2(originalAmt);
          if (isCash && remainingChange > 0) {
            final changeFromThisPayment = adjustedAmt < remainingChange ? adjustedAmt : remainingChange;
            adjustedAmt = _r2(adjustedAmt - changeFromThisPayment);
            remainingChange = _r2(remainingChange - changeFromThisPayment);
          }

          final Map<String, dynamic> data = {'PayAmt': adjustedAmt, 'C_POSTenderType_ID': entry.key};

          // Si es Yappy y hay transacción, incluirla como RoutingNo
          if (isYappy && yappyTransactionId != null && yappyTransactionId!.isNotEmpty) {
            data['RoutingNo'] = yappyTransactionId;
          }

          return data;
        })
        // Excluir pagos que quedaron en 0 luego del ajuste
        .where((p) => (p['PayAmt'] ?? 0) > 0)
        .toList();

    final discountData = _buildDiscountLines();

    final result = await postInvoice(
      cBPartnerID: bPartner,
      salesRepID: selectedSalesRepID!,
      invoiceLines: invoiceLine,
      discounts: discountData,
      payments: paymentData,
      context: context,
      docAction: selectedDocActionCode ?? 'DR',
      isRefund: widget.isRefund,
      doctypeID: widget.doctypeID,
      priceListID: bpartnerPriceListID,
      sourceOrderId: widget.sourceOrderId,
    );

    if (result['success'] == true) {
      if (_resumedTicketId != null) {
        await HeldTicketStore.instance.delete(_resumedTicketId!);
        _resumedTicketId = null;
        _resumedTicketCreatedAt = null;
        HeldTicketStore.instance.activeTicketId = null;
      }
      if (calculatedChange > 0) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: Text(AppLocale.change.getString(context), style: Theme.of(context).textTheme.titleMedium),
            content: Text(
              '\$${calculatedChange.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocale.close.getString(context)))],
          ),
        );
      }

      final Map<String, dynamic>? order = await fetchOrderById(orderId: int.parse(result['Record_ID'].toString()), context: context);

      if (order != null) {
        if (POS.isPOS == true) {
          final confirmPrintTicket = await _printTicketConfirmation(context);
          if (confirmPrintTicket == true) {
            try {
              final pdfBytes = await generatePOSTicket(order);

              try {
                final printers = await Printing.listPrinters();
                final defaultPrinter = printers.firstWhere(
                  (p) => p.isDefault,
                  orElse: () => printers.isNotEmpty ? printers.first : throw Exception('No hay impresoras disponibles'),
                );

                await Printing.directPrintPdf(
                  printer: defaultPrinter,
                  usePrinterSettings: true,
                  dynamicLayout: true,
                  onLayout: (_) => pdfBytes,
                );
              } catch (e) {
                await Printing.sharePdf(bytes: pdfBytes, filename: 'Order_${order['DocumentNo']}.pdf');
              }
            } catch (e) {
              try {
                final pdfBytes = await generatePOSTicket(order);
                await Printing.sharePdf(bytes: pdfBytes, filename: 'Order_${order['DocumentNo']}.pdf');
              } catch (_) {}
            }
          }
        } else {
          //? Mostrar detalle de la orden [NO Es POS]
          await Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailPage(order: order)));
        }
      }
      ToastMessage.show(
        context: context,
        message: widget.isRefund ? AppLocale.creditNote.getString(context) : AppLocale.newOrder.getString(context),
        type: ToastType.success,
      );

      clearInvoiceFields();
      _loadSequence();
      _initialPartner();
      setState(() {
        invoiceLines.clear();
        subtotal = 0.0;
        iva = 0.0;
        total = 0.0;
        paymentControllers.forEach((key, controller) => controller.clear());
        selectedDocActionCode = POS.documentActions.first['code'];
        selectedSalesRepID = UserData.id;
        _validateForm();
      });
    } else {
      ToastMessage.show(
        context: context,
        message: result['message'] ?? AppLocale.errorCompleteOrder.getString(context),
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
      final tax = taxOptions.firstWhere((t) => t['id'] == taxID, orElse: () => {});
      final rate = (tax['rate'] ?? 0).toDouble();
      final name = tax['name'] ?? AppLocale.noTax.getString(context);

      final taxAmount = price * quantity * (rate / 100);
      groupedTaxes['$name (${rate.toStringAsFixed(2)}%)'] = (groupedTaxes['$name (${rate.toStringAsFixed(2)}%)'] ?? 0) + taxAmount;
    }

    groupedTaxes.updateAll((_, amount) => _r2(amount));
    return groupedTaxes;
  }

  double getTotalTaxAmount() {
    final taxes = getGroupedTaxTotals();
    return _r2(taxes.values.fold(0.0, (sum, amount) => sum + amount));
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 700 ? true : false;
    final discountPaymentMethods = !_hasDiscountConfig ? <Map<String, dynamic>>[] : _orderedDiscountMethods;
    final standardPaymentMethods = paymentMethods.where((method) => !_isDiscountMethod(method)).toList();
    final orderedPaymentMethods = [...discountPaymentMethods, ...standardPaymentMethods];

    return WillPopScope(
      onWillPop: () async {
        //TODO manejar lo de cancelar el yappy si me salgo

        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${AppLocale.user.getString(context)}: ${UserData.name}',
                style: TextStyle(fontSize: isMobile ? 12 : 14, fontWeight: FontWeight.w400, color: Colors.white70),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                widget.orderName != null
                    ? '${widget.orderName!}: ${docNoSequenceNumber ?? ""}'
                    : widget.isRefund
                    ? '${AppLocale.creditNote.getString(context)}${docNoSequenceNumber != null ? ": $docNoSequenceNumber" : ""}'
                    : '${AppLocale.newOrder.getString(context)}${docNoSequenceNumber != null ? ": $docNoSequenceNumber" : ""}',
                style: TextStyle(fontSize: isMobile ? 16 : 20, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          backgroundColor: widget.isRefund ? Theme.of(context).colorScheme.error : null,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: CustomSpacer.medium),
              child: Center(
                child: Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(CustomSpacer.small), color: Colors.white),
                  padding: EdgeInsets.all(isMobile ? 4.0 : CustomSpacer.small),
                  child: Logo(width: isMobile ? 45 : 60),
                ),
              ),
            ),
          ],
        ),
        drawer: MenuDrawer(),
        bottomNavigationBar: CustomFooter(),
        body: SingleChildScrollView(
          child: Center(
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.end,
              children: [
                CustomContainer(
                  maxWidthContainer: 320,
                  margin: const EdgeInsets.only(top: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: CustomSpacer.medium),
                      SearchableDropdown<int>(
                        value: selectedSalesRepID,
                        options: salesRep,
                        showSearchBox: false,
                        labelText: AppLocale.seller.getString(context),
                        onChanged: (value) {
                          setState(() {
                            selectedSalesRepID = value;
                          });
                        },
                      ),
                      const SizedBox(height: CustomSpacer.medium),
                      if (isCustomerSearchLoading) ...[
                        const SizedBox(height: 4),
                        const LinearProgressIndicator(),
                        const SizedBox(height: 8),
                      ],

                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: EdgeInsets.all(selectedBPartnerID == null ? 8.0 : 0.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selectedBPartnerID == null ? Colors.red.shade400 : Colors.transparent,
                            width: selectedBPartnerID == null ? 1.5 : 0,
                          ),
                          color: selectedBPartnerID == null ? Colors.red.withOpacity(0.02) : Colors.transparent,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: CustomSearchField(
                                    options: bPartnerOptions,
                                    labelText: AppLocale.customer.getString(context),
                                    searchBy: "TaxID",
                                    controller: clienteController,
                                    showCreateButtonIfNotFound: canShowCreateCustomerButton,
                                    createAnchorTerm: createAnchorCustomerTerm,
                                    fieldController: customerFieldController,
                                    onSubmit: (_) => _loadBPartner(showLoadingIndicator: true),
                                    onCreate: (value) async {
                                      final previousEffectivePriceListID = resolveEffectivePriceListID(
                                        isPOS: POS.isPOS,
                                        posPriceListID: POS.priceListID,
                                        bPartnerPriceListID: bpartnerPriceListID,
                                      );
                                      if (!POS.isPOS && selectedBPartnerID != null && invoiceLines.isNotEmpty) {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            backgroundColor: Theme.of(context).cardColor,
                                            title: const Column(
                                              children: [
                                                Icon(Icons.warning_amber_rounded, size: 45, color: Colors.orange),
                                                SizedBox(height: 10),
                                                Text(
                                                  '¿Cambiar cliente?',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                                ),
                                              ],
                                            ),
                                            content: const Text(
                                              'Si selecciona otro cliente, se eliminarán los productos.\n¿Desea continuar?',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(fontSize: 16),
                                            ),
                                            actionsAlignment: MainAxisAlignment.spaceEvenly,
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, false),
                                                child: Text(AppLocale.no.getString(context)),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.redAccent,
                                                  foregroundColor: Colors.white,
                                                ),
                                                onPressed: () => Navigator.pop(ctx, true),
                                                child: Text(AppLocale.yes.getString(context)),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm != true) return;
                                        if (!await _resetPaymentsForProductChange()) {
                                          return;
                                        }
                                        setState(() {
                                          invoiceLines.clear();
                                          _recalculateSummary();
                                        });
                                      }
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => BPartnerNewPage(bpartnerName: value)),
                                      );
                                      if (result != null && result?['created'] == true) {
                                        final dynamic rawPriceListID = result['bpartner']['M_PriceList_ID'];
                                        final int? newBPartnerPriceListID = rawPriceListID is Map
                                            ? rawPriceListID['id'] as int?
                                            : rawPriceListID as int?;
                                        setState(() {
                                          clienteController.text = result['bpartner']['Name'];
                                          selectedBPartnerID = result['bpartner']['id'];
                                          bpartnerPriceListID = newBPartnerPriceListID;
                                          hasLocationBPartner = true;
                                          _validateForm();
                                        });
                                        _loadBPartner(showLoadingIndicator: true);
                                        final nextEffectivePriceListID = resolveEffectivePriceListID(
                                          isPOS: POS.isPOS,
                                          posPriceListID: POS.priceListID,
                                          bPartnerPriceListID: newBPartnerPriceListID,
                                        );
                                        if (!POS.isPOS && previousEffectivePriceListID != nextEffectivePriceListID) {
                                          ProductSelectionPopup.clearGlobalCache();
                                          await _loadProduct(showLoadingIndicator: true);
                                        }
                                      }
                                    },
                                    onItemSelected: (item) async {
                                      if (!POS.isPOS &&
                                          selectedBPartnerID != null &&
                                          selectedBPartnerID != item['id'] &&
                                          invoiceLines.isNotEmpty) {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            backgroundColor: Theme.of(context).cardColor,
                                            title: Column(
                                              children: [
                                                Icon(Icons.warning_amber_rounded, size: 45, color: Colors.orange),
                                                SizedBox(height: 10),
                                                Text(
                                                  AppLocale.changeClient.getString(context),
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                                ),
                                              ],
                                            ),
                                            content: Text(
                                              AppLocale.changeClientWarning.getString(context),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(fontSize: 16),
                                            ),
                                            actionsAlignment: MainAxisAlignment.spaceEvenly,
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, false),
                                                child: Text(AppLocale.no.getString(context)),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.redAccent,
                                                  foregroundColor: Colors.white,
                                                ),
                                                onPressed: () => Navigator.pop(ctx, true),
                                                child: Text(AppLocale.yes.getString(context)),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm != true) {
                                          final prevCustomer = bPartnerOptions.firstWhere(
                                            (c) => c['id'] == selectedBPartnerID,
                                            orElse: () => {'name': ''},
                                          );
                                          setState(() => clienteController.text = prevCustomer['name']);
                                          return;
                                        }
                                        if (!await _resetPaymentsForProductChange()) {
                                          return;
                                        }
                                        setState(() {
                                          invoiceLines.clear();
                                          _recalculateSummary();
                                        });
                                      }
                                      final previousEffectivePriceListID = resolveEffectivePriceListID(
                                        isPOS: POS.isPOS,
                                        posPriceListID: POS.priceListID,
                                        bPartnerPriceListID: bpartnerPriceListID,
                                      );
                                      final nextBPartnerPriceListID = item['M_PriceList_ID'] as int?;
                                      final nextEffectivePriceListID = resolveEffectivePriceListID(
                                        isPOS: POS.isPOS,
                                        posPriceListID: POS.priceListID,
                                        bPartnerPriceListID: nextBPartnerPriceListID,
                                      );
                                      setState(() {
                                        bpartnerPriceListID = nextBPartnerPriceListID;
                                        selectedBPartnerID = item['id'];
                                        hasLocationBPartner = item['C_BPartner_Location_ID'] != null;
                                        _validateForm();
                                      });
                                      if (!POS.isPOS && previousEffectivePriceListID != nextEffectivePriceListID) {
                                        ProductSelectionPopup.clearGlobalCache();
                                        await _loadProduct(showLoadingIndicator: true);
                                      }
                                    },
                                    itemBuilder: (item) => Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(item['name'], style: Theme.of(context).textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
                                        if (item['TaxID'] != null)
                                          Text(
                                            item['TaxID'],
                                            style: Theme.of(context).textTheme.bodyMedium,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: CustomSpacer.small),

                                // --- BOTÓN DINÁMICO PARA BUSCAR Y BORRAR ---
                                if (selectedBPartnerID != null)
                                  IconButton(
                                    tooltip: 'Quitar cliente',
                                    icon: const Icon(Icons.cancel, color: Colors.redAccent),
                                    onPressed: () async {
                                      if (!POS.isPOS && invoiceLines.isNotEmpty) {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            backgroundColor: Theme.of(context).cardColor,
                                            title: const Column(
                                              children: [
                                                Icon(Icons.warning_amber_rounded, size: 45, color: Colors.orange),
                                                SizedBox(height: 10),
                                                Text(
                                                  '¿Quitar cliente?',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                                ),
                                              ],
                                            ),
                                            content: const Text(
                                              'Al quitar el cliente, se eliminarán los productos agregados a la orden.\n¿Desea continuar?',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(fontSize: 16),
                                            ),
                                            actionsAlignment: MainAxisAlignment.spaceEvenly,
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, false),
                                                child: Text(AppLocale.no.getString(context)),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.redAccent,
                                                  foregroundColor: Colors.white,
                                                ),
                                                onPressed: () => Navigator.pop(ctx, true),
                                                child: Text(AppLocale.yes.getString(context)),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm != true) return;
                                      }
                                      if (!POS.isPOS) {
                                        if (!await _resetPaymentsForProductChange()) {
                                          return;
                                        }
                                      }
                                      setState(() {
                                        selectedBPartnerID = null;
                                        bpartnerPriceListID = null;
                                        clienteController.clear();
                                        if (!POS.isPOS) {
                                          invoiceLines.clear();
                                          _recalculateSummary();
                                        }
                                        _validateForm();
                                      });
                                      if (!POS.isPOS) {
                                        ProductSelectionPopup.clearGlobalCache();
                                        await _loadProduct(showLoadingIndicator: true);
                                      }
                                    },
                                  )
                                else
                                  IconButton(
                                    tooltip: AppLocale.refresh.getString(context),
                                    icon: const Icon(Icons.search),
                                    onPressed: () => _loadBPartner(showLoadingIndicator: true),
                                  ),
                              ],
                            ),

                            if (selectedBPartnerID == null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        AppLocale.selectCustomer.getString(context),
                                        style: TextStyle(color: Colors.red.shade400, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            if (hasLocationBPartner == false && selectedBPartnerID != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        AppLocale.customerNoAddressError.getString(context),
                                        style: TextStyle(color: Colors.red.shade400, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: CustomSpacer.medium),

                      // --- ANIMACIÓN PARA PRODUCTOS ---
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 400),
                        crossFadeState: (selectedBPartnerID == null || hasLocationBPartner == false)
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        firstChild: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withOpacity(0.3), style: BorderStyle.solid),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey.withOpacity(0.6)),
                              const SizedBox(height: 12),
                              Text(
                                AppLocale.selectValidCustomerForProducts.getString(context),
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        secondChild: isProductLoading
                            ? _buildShimmerField()
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isProductCategoryLoading)
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            TextButton.icon(
                                              style: ButtonStyle(
                                                textStyle: MaterialStateProperty.all(Theme.of(context).textTheme.bodyMedium),
                                                backgroundColor: MaterialStateProperty.all(Theme.of(context).colorScheme.secondary),
                                                foregroundColor: MaterialStateProperty.all(Theme.of(context).colorScheme.onSecondary),
                                              ),
                                              icon: const Icon(Icons.category),
                                              label: Text(AppLocale.categories.getString(context)),
                                              onPressed: () async {
                                                Set<int> tempSelected = Set<int>.from(selectedCategories);
                                                await showModalBottomSheet(
                                                  context: context,
                                                  isScrollControlled: true,
                                                  builder: (context) {
                                                    return StatefulBuilder(
                                                      builder: (context, setModalState) {
                                                        return SafeArea(
                                                          child: Padding(
                                                            padding: MediaQuery.of(context).viewInsets,
                                                            child: Container(
                                                              constraints: const BoxConstraints(maxHeight: 400),
                                                              child: Column(
                                                                mainAxisSize: MainAxisSize.min,
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Padding(
                                                                    padding: const EdgeInsets.all(16.0),
                                                                    child: Text(
                                                                      AppLocale.selectCategories.getString(context),
                                                                      style: Theme.of(context).textTheme.bodyLarge,
                                                                    ),
                                                                  ),
                                                                  Expanded(
                                                                    child: ListView.builder(
                                                                      shrinkWrap: true,
                                                                      itemCount: categpryOptions.length,
                                                                      itemBuilder: (context, idx) {
                                                                        final cat = categpryOptions[idx];
                                                                        final isSelected = tempSelected.contains(cat['id']);
                                                                        return ListTile(
                                                                          title: Text(cat['name']),
                                                                          selected: isSelected,
                                                                          onTap: () {
                                                                            setModalState(() {
                                                                              if (isSelected) {
                                                                                tempSelected.remove(cat['id']);
                                                                              } else {
                                                                                tempSelected.add(cat['id']);
                                                                              }
                                                                            });
                                                                          },
                                                                          trailing: isSelected
                                                                              ? const Icon(Icons.check, color: Colors.blue)
                                                                              : null,
                                                                        );
                                                                      },
                                                                    ),
                                                                  ),
                                                                  Padding(
                                                                    padding: const EdgeInsets.all(16.0),
                                                                    child: Row(
                                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                                      children: [
                                                                        TextButton(
                                                                          onPressed: () {
                                                                            Navigator.pop(context);
                                                                          },
                                                                          child: Text(AppLocale.cancel.getString(context)),
                                                                        ),
                                                                        const SizedBox(width: 8),
                                                                        ElevatedButton(
                                                                          onPressed: () {
                                                                            Navigator.pop(context, tempSelected);
                                                                          },
                                                                          child: Text(AppLocale.apply.getString(context)),
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
                                                  if (result != null && result is Set<int>) {
                                                    setState(() {
                                                      selectedCategories = Set<int>.from(result);
                                                    });
                                                    _loadProduct(showLoadingIndicator: true, requestFieldFocus: false);
                                                  }
                                                });
                                              },
                                            ),
                                            Material(
                                              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                              shape: const CircleBorder(),
                                              clipBehavior: Clip.hardEdge,
                                              child: IconButton(
                                                tooltip: "Selección Múltiple",
                                                icon: const Icon(Icons.grid_view),
                                                color: Theme.of(context).colorScheme.secondary,
                                                splashColor: Theme.of(context).colorScheme.secondary.withOpacity(0.4),
                                                highlightColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                                                onPressed: _showProductSelectionPopup,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (selectedCategories.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Wrap(
                                              spacing: 6,
                                              runSpacing: 6,
                                              children: selectedCategories.map((catId) {
                                                final cat = categpryOptions.firstWhere(
                                                  (c) => c['id'] == catId,
                                                  orElse: () => <String, dynamic>{},
                                                );
                                                final catName = cat.isNotEmpty ? cat['name'] : 'Categoría';
                                                return Chip(
                                                  label: Text(catName),
                                                  onDeleted: () {
                                                    setState(() {
                                                      selectedCategories.remove(catId);
                                                    });
                                                    _loadProduct(showLoadingIndicator: true, requestFieldFocus: false);
                                                  },
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        const SizedBox(height: CustomSpacer.medium),
                                      ],
                                    ),
                                  if (isProductSearchLoading) ...[
                                    const SizedBox(height: 4),
                                    const LinearProgressIndicator(),
                                    const SizedBox(height: 8),
                                  ],
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CustomSearchField(
                                          options: productOptions,
                                          controller: productController,
                                          labelText: AppLocale.product.getString(context),
                                          searchBy: 'UPC',
                                          searchByText: 'UPC, SKU',
                                          onSearch: _searchProductSuggestions,
                                          fieldController: productFieldController,

                                          // --- CREACION DE PRODUCTOS DESDE BUSQUEDA ---
                                          showCreateButtonIfNotFound: canShowCreateProductButton,
                                          createAnchorTerm: createAnchorProductTerm,
                                          onCreate: (value) async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => ProductNewPage(productName: value)),
                                            );
                                            if (result != null && result['created'] == true) {
                                              setState(() {
                                                productController.text = result['product']['name'] ?? result['product']['Name'] ?? value;
                                              });
                                              _loadProduct(showLoadingIndicator: true);
                                            }
                                          },

                                          onItemSelected: (item) async {
                                            if (POS.cPosID != null) {
                                              if (!await _resetPaymentsForProductChange()) {
                                                return;
                                              }
                                              final int? selectedTaxID =
                                                  (item['C_Tax_ID'] ?? item['tax']?['id'] ?? selectedTax?['id']) as int?;
                                              final double priceActual = _r2((item['price'] ?? item['Price'] ?? 0).toDouble());
                                              final double priceList = _r2(
                                                (item['PriceList'] ?? item['priceList'] ?? item['price'] ?? 0).toDouble(),
                                              );
                                              final double discount = priceList > 0 ? _r2(100 * (1 - (priceActual / priceList))) : 0.0;
                                              late Map<String, dynamic> addedLine;
                                              setState(() {
                                                addedLine = <String, dynamic>{
                                                  ...item,
                                                  'quantity': 1,
                                                  'price': priceActual,
                                                  'C_Tax_ID': selectedTaxID,
                                                  'Description': item['Description'] ?? '',
                                                  'PriceList': priceList,
                                                  'Discount': discount,
                                                  'catalogPriceAtAdd': priceActual,
                                                  'priceSyncState': item['fromCache'] == true ? 'pending' : 'valid',
                                                };
                                                invoiceLines.add(addedLine);
                                              });
                                              _startPriceValidation(addedLine);
                                              _recalculateSummary();
                                              productController.clear();
                                              _validateForm();
                                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                                if (mounted) {
                                                  productFieldController.requestFocus();
                                                }
                                              });
                                            } else {
                                              _showQuantityDialog(item);
                                            }
                                          },
                                          onSubmit: (_) => _loadProduct(showLoadingIndicator: true),
                                          itemBuilder: (item) => Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '${item['name'] ?? ''}',
                                                      overflow: TextOverflow.ellipsis,
                                                      style: Theme.of(context).textTheme.bodySmall,
                                                    ),
                                                    if (item['value'] != null)
                                                      Text(
                                                        'Cod: ${item['value'] ?? ''}',
                                                        maxLines: 2,
                                                        style: Theme.of(context).textTheme.bodySmall,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    if (POS.isPOS)
                                                      Row(
                                                        children: [
                                                          if (item['stockLoading'] == true)
                                                            const Padding(
                                                              padding: EdgeInsets.only(right: 5),
                                                              child: SizedBox(
                                                                width: 12,
                                                                height: 12,
                                                                child: CircularProgressIndicator(strokeWidth: 2),
                                                              ),
                                                            ),
                                                          Text(
                                                            item['QtyAvailable'] != null
                                                                ? '${AppLocale.exist.getString(context)}: ${item['QtyAvailable']}'
                                                                : AppLocale.updatingStock.getString(context),
                                                            style: Theme.of(
                                                              context,
                                                            ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                                                          ),
                                                        ],
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                '\$${item['price'] ?? '0.00'}',
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: CustomSpacer.small),
                                      Material(
                                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                        shape: const CircleBorder(),
                                        clipBehavior: Clip.hardEdge,
                                        child: IconButton(
                                          tooltip: AppLocale.refresh.getString(context),
                                          icon: const Icon(Icons.search),
                                          color: Theme.of(context).colorScheme.secondary,
                                          splashColor: Theme.of(context).colorScheme.secondary.withOpacity(0.4),
                                          highlightColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                                          onPressed: () => _loadProduct(showLoadingIndicator: true),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (invoiceLines.isNotEmpty) ...[
                                    const SizedBox(height: CustomSpacer.large),
                                    Text(AppLocale.productSummary.getString(context), style: Theme.of(context).textTheme.titleLarge),
                                    const SizedBox(height: CustomSpacer.medium),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: invoiceLines.asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final line = entry.value;
                                        final tax = taxOptions.firstWhere((t) => t['id'] == line['C_Tax_ID'], orElse: () => {});
                                        final taxRate = tax['rate'] != null ? '${tax['rate']}%' : AppLocale.noTax.getString(context);
                                        final priceChanged = line['priceSyncState'] == 'changed';
                                        return Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (priceChanged)
                                              Container(
                                                margin: const EdgeInsets.only(bottom: 4),
                                                padding: const EdgeInsets.only(left: 10),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).colorScheme.errorContainer,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        '${AppLocale.serverPriceChanged.getString(context)}: \$${_r2(line['serverPrice'] ?? 0).toStringAsFixed(2)}',
                                                        style: TextStyle(
                                                          color: Theme.of(context).colorScheme.onErrorContainer,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      tooltip: AppLocale.updatePrice.getString(context),
                                                      onPressed: () => _acceptServerPrice(line),
                                                      icon: const Icon(Icons.refresh, size: 18),
                                                      color: Theme.of(context).colorScheme.onErrorContainer,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            Tooltip(
                                              message: line['name'],
                                              child: InputChip(
                                                onPressed: () => _showQuantityDialog(line, index: index),
                                                deleteIcon: const Icon(Icons.close),
                                                onDeleted: () => _deleteLine(index),
                                                deleteIconColor: ColorTheme.error,
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                label: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      line['name'],
                                                      overflow: TextOverflow.ellipsis,
                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                                    ),
                                                    if (line['Description'] != null && line['Description'].toString().isNotEmpty)
                                                      Text('${line['Description']}', style: Theme.of(context).textTheme.labelSmall),
                                                    Text(
                                                      '${line['quantity']} x \$${line['price']} + $taxRate',
                                                      style: Theme.of(context).textTheme.bodySmall,
                                                    ),
                                                  ],
                                                ),
                                                backgroundColor: Theme.of(context).cardColor,
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
                if (POS.isPOS && POSTenderType.isMultiPayment)
                  CustomContainer(
                    maxWidthContainer: 320,
                    margin: EdgeInsets.only(top: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isPaymentMethodsLoading)
                              _buildShimmerField()
                            else ...[
                              ...orderedPaymentMethods.map((method) {
                                final isFirstDiscount =
                                    discountPaymentMethods.isNotEmpty && method['id'] == discountPaymentMethods.first['id'];
                                final isFirstStandard =
                                    standardPaymentMethods.isNotEmpty && method['id'] == standardPaymentMethods.first['id'];

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isFirstDiscount) ...[
                                      Text(AppLocale.discounts.getString(context), style: Theme.of(context).textTheme.titleMedium),
                                      const SizedBox(height: 6),
                                    ],
                                    if (isFirstStandard) ...[
                                      if (discountPaymentMethods.isNotEmpty) const SizedBox(height: CustomSpacer.medium),
                                      Text(
                                        (widget.isRefund ? AppLocale.refundMethods : AppLocale.paymentMethods).getString(context),
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 6),
                                    ],
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextfieldTheme(
                                                  controlador: paymentControllers[method['id']],
                                                  texto: method['name'],
                                                  inputType: TextInputType.number,
                                                  inputFormatters: [NumericTextFormatterWithDecimal()],
                                                  readOnly: method['isRetireDiscount'] == true || _lockedPayments.contains(method['id']),
                                                  onChanged: (value) {
                                                    if (method['isGlobalDiscount'] == true) {
                                                      _clampGlobalDiscount(method['id'], value);
                                                    } else {
                                                      _validateForm();
                                                    }
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              if (method['isRetireDiscount'] == true)
                                                IconButton(
                                                  icon: const Icon(Icons.percent_rounded),
                                                  tooltip: 'Aplicar descuento 25%',
                                                  onPressed: () => _applyRetireDiscount(method['id']),
                                                )
                                              else if (!_isDiscountMethod(method))
                                                IconButton(
                                                  icon: const Icon(Icons.attach_money_rounded),
                                                  tooltip: 'Llenar con el máximo disponible',
                                                  onPressed: () {
                                                    final currentSum = paymentControllers.entries
                                                        .where(
                                                          (entry) =>
                                                              entry.key != method['id'] && !_isDiscountMethod(_paymentMethod(entry.key)),
                                                        )
                                                        .map((entry) => _controllerAmount(entry.key))
                                                        .fold(0.0, (a, b) => a + b);

                                                    final remaining = _r2((netTotalAmount - currentSum).clamp(0.0, netTotalAmount));
                                                    paymentControllers[method['id']]?.text = remaining.toStringAsFixed(2);
                                                    _validateForm();
                                                  },
                                                ),
                                              if (_isDiscountMethod(method) &&
                                                  _r2(
                                                        double.tryParse(
                                                              paymentControllers[method['id']]?.text.replaceAll(',', '.') ?? '0',
                                                            ) ??
                                                            0.0,
                                                      ) >
                                                      0)
                                                IconButton(
                                                  icon: const Icon(Icons.close),
                                                  color: ColorTheme.error,
                                                  tooltip: AppLocale.removeDiscount.getString(context),
                                                  onPressed: () => _clearRetireDiscount(method['id']),
                                                ),
                                              if (method['name'].toString().toLowerCase().contains('yappy') &&
                                                  isYappyConfigAvailable &&
                                                  paymentControllers[method['id']]?.text != null &&
                                                  (double.tryParse(paymentControllers[method['id']]?.text ?? '0') ?? 0) > 0 &&
                                                  yappyTransactionId == null)
                                                isYappyLoading
                                                    ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator())
                                                    : IconButton(
                                                        icon: const Icon(Icons.qr_code),
                                                        tooltip: 'Mostrar código QR',
                                                        onPressed: () {
                                                          _showYappyQRDialog(
                                                            subTotal: double.parse(
                                                              paymentControllers[method['id']]?.text.toString() ?? '0',
                                                            ),
                                                            totalTax: 0,
                                                            total: double.parse(paymentControllers[method['id']]?.text.toString() ?? '0'),
                                                            methodId: method['id'],
                                                          );
                                                        },
                                                      ),
                                              if (yappyTransactionId != null &&
                                                  method['name'].toString().toLowerCase().contains('yappy') &&
                                                  paymentControllers[method['id']]?.text != null &&
                                                  (paymentControllers[method['id']]?.text ?? '0.0') != '0.0')
                                                if (yappyTransactionId != null)
                                                  IconButton(
                                                    icon: Icon(Icons.cancel),
                                                    color: ColorTheme.error,
                                                    tooltip: 'Anular transacción Yappy',
                                                    onPressed: () async {
                                                      final confirm = await showDialog(
                                                        context: context,
                                                        builder: (context) {
                                                          return AlertDialog(
                                                            backgroundColor: Theme.of(context).cardColor,
                                                            title: Text(AppLocale.cancelYappyTransaction.getString(context)),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () => Navigator.pop(context, false),
                                                                child: Text(AppLocale.cancel.getString(context)),
                                                              ),
                                                              ElevatedButton(
                                                                onPressed: () => Navigator.pop(context, true),
                                                                child: Text(
                                                                  AppLocale.confirm.getString(context),
                                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                                    color: Theme.of(context).colorScheme.surface,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      );

                                                      if (confirm != true) {
                                                        return;
                                                      }

                                                      final paid = await cancelYappyTransaction(transactionId: yappyTransactionId!);
                                                      if (paid) {
                                                        if (mounted) {
                                                          paymentControllers[method['id']]?.text = '0.0';
                                                          yappyTransactionId = null;
                                                          _validateForm();
                                                          ToastMessage.show(
                                                            context: context,
                                                            message: 'Pago anulado correctamente',
                                                            type: ToastType.help,
                                                          );
                                                        }
                                                      }
                                                    },
                                                  ),
                                            ],
                                          ),
                                          if (calculatedChange > 0 && method['isCash'])
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2, bottom: 4),
                                              child: Text(
                                                'Vuelto: \$${calculatedChange.toStringAsFixed(2)}',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ],
                        ),
                        if (!_isInvoiceValid && clientSelected && products.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              AppLocale.paymentSumMustEqualTotal.getString(context),
                              style: TextStyle(color: ColorTheme.error, fontSize: 13),
                            ),
                          ),
                      ],
                    ),
                  ),

                //? Resumen de la factura
                CustomContainer(
                  maxWidthContainer: 320,
                  margin: EdgeInsets.only(top: 24, bottom: 36),
                  child: Column(
                    children: [
                      Center(child: Text(AppLocale.summary.getString(context), style: Theme.of(context).textTheme.titleLarge)),
                      const SizedBox(height: CustomSpacer.medium),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(AppLocale.listSubtotal.getString(context), style: Theme.of(context).textTheme.bodyMedium),
                          Text('\$${listSubtotal.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: CustomSpacer.medium),
                      if (lineDiscountTotal > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(AppLocale.lineDiscounts.getString(context), style: Theme.of(context).textTheme.bodyMedium),
                            Text('-\$${lineDiscountTotal.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                        const SizedBox(height: CustomSpacer.medium),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(AppLocale.netSubtotal.getString(context), style: Theme.of(context).textTheme.bodyMedium),
                          Text('\$${subtotal.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: CustomSpacer.medium),
                      if (invoiceLines.isNotEmpty && getTotalTaxAmount() > 0) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocale.taxes.getString(context), style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: CustomSpacer.small),
                            ...getGroupedTaxTotals().entries
                                .where((entry) => entry.value > 0)
                                .map(
                                  (entry) => Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(entry.key, style: Theme.of(context).textTheme.bodyMedium),
                                      Text('\$${entry.value.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyMedium),
                                    ],
                                  ),
                                ),
                            const SizedBox(height: CustomSpacer.small),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppLocale.totalTaxes.getString(context),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '\$${getTotalTaxAmount().toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: CustomSpacer.medium),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(AppLocale.totalWithTaxes.getString(context), style: Theme.of(context).textTheme.bodyMedium),
                          Text('\$${totalAmount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                      if (specialDiscountSummary.isNotEmpty) ...[
                        const SizedBox(height: CustomSpacer.medium),
                        ...specialDiscountSummary.map(
                          (discount) => Padding(
                            padding: const EdgeInsets.only(bottom: CustomSpacer.small),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(discount['Name'].toString(), style: Theme.of(context).textTheme.bodyMedium)),
                                Text(
                                  '-\$${(discount['Amount'] as double).toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: CustomSpacer.medium),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(AppLocale.totalToPay.getString(context), style: Theme.of(context).textTheme.titleLarge),
                          Text('\$${netTotalAmount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: CustomSpacer.xlarge),
                      if (isDocActionsLoading)
                        const ShimmerList(count: 1)
                      else
                        SearchableDropdown<String>(
                          options: POS.documentActions,
                          idKey: 'code',
                          nameKey: 'name',
                          labelText: AppLocale.documentAction.getString(context),
                          value: selectedDocActionCode,
                          showSearchBox: false,
                          onChanged: (value) {
                            setState(() {
                              selectedDocActionCode = value;
                            });
                          },
                        ),
                      const SizedBox(height: CustomSpacer.small),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.08),
                            disabledForegroundColor: Colors.grey.shade500,
                            disabledBackgroundColor: Colors.grey.withOpacity(0.06),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: _hasMeaningfulContent && !isSending
                                    ? Theme.of(context).primaryColor.withOpacity(0.35)
                                    : Colors.grey.withOpacity(0.2),
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.pause_circle_outline, size: 20),
                          label: Text(AppLocale.putOnHold.getString(context), style: const TextStyle(fontWeight: FontWeight.w600)),
                          onPressed: _hasMeaningfulContent && !isSending ? _putOnHold : null,
                        ),
                      ),
                      const SizedBox(height: CustomSpacer.small),
                      if (invoiceLines.any((line) => line['priceSyncState'] == 'changed')) ...[
                        Text(
                          AppLocale.priceValidationRequired.getString(context),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: CustomSpacer.small),
                      ],
                      Container(
                        child: isSending
                            ? ButtonLoading(fullWidth: true)
                            : ButtonPrimary(
                                fullWidth: true,
                                texto: AppLocale.process.getString(context),
                                enable: _isInvoiceValid,
                                onPressed: () =>
                                    _isInvoiceValid ? _createInvoice(product: invoiceLines, bPartner: selectedBPartnerID ?? 0) : null,
                              ),
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
