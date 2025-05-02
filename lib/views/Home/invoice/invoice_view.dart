import 'package:flutter/material.dart';
import 'package:primware/shared/custom_container.dart';
import 'package:primware/shared/custom_dropdown.dart';
import 'package:primware/views/Home/product/product_new_view.dart';
import '../../../shared/button.widget.dart';
import '../../../shared/custom_app_menu.dart';
import '../../../shared/custom_searchfield.dart';
import '../../../shared/custom_spacer.dart';
import '../../../shared/textfield.widget.dart';
import '../../../theme/colors.dart';
import '../bpartner/bpartner_new_view.dart';
import 'invoice_funtions.dart';
import 'package:shimmer/shimmer.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  TextEditingController clienteController = TextEditingController();
  TextEditingController qtyProductController = TextEditingController();
  TextEditingController productController = TextEditingController();
  TextEditingController taxController = TextEditingController();
  bool isSending = false;
  bool isBPartnerLoading = true;
  bool isProductLoading = true;
  bool isTaxLoading = true;

  List<Map<String, dynamic>> bPartnerOptions = [];
  List<Map<String, dynamic>> productOptions = [];
  List<Map<String, dynamic>> taxOptions = [];
  List<Map<String, dynamic>> invoiceLines = [];

  int? selectedBPartnerID;
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
      _loadProduct();
      _loadTax();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool _isInvoiceValid() {
    return selectedBPartnerID != null && invoiceLines.isNotEmpty;
  }

  Future<void> _loadBPartner() async {
    final partner = await fetchBPartner(context: context);
    setState(() {
      bPartnerOptions = partner;
      isBPartnerLoading = false;
    });
  }

  Future<void> _loadProduct() async {
    final product = await fetchProduct(context: context);
    setState(() {
      productOptions = product;
      isProductLoading = false;
    });
  }

  Future<void> _loadTax() async {
    final tax = await fetchTax(context: context);
    final defaultTax = tax.isNotEmpty
        ? tax.firstWhere((t) => t['isdefault'] == true, orElse: () => tax.first)
        : null;
    setState(() {
      taxOptions = tax;
      if (defaultTax != null) {
        selectedTax = defaultTax;
        taxController.text = defaultTax['name'];
        _recalculateSummary();
      }
      isTaxLoading = false;
    });
  }

  void _recalculateSummary() {
    double newSubtotal = 0.0;
    for (var line in invoiceLines) {
      final price = (line['price'] ?? 0) as num;
      final quantity = (line['quantity'] ?? 1) as num;
      newSubtotal += price * quantity;
    }

    final taxPercent = (selectedTax?['rate'] ?? 0).toDouble();

    setState(() {
      subtotal = newSubtotal;
      iva = subtotal * (taxPercent / 100);
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

  Future<void> _showQuantityDialog(Map<String, dynamic> product) async {
    int? selectedTaxID = selectedTax?['id'];
    final quantityController = TextEditingController(text: "1");
    final priceController =
        TextEditingController(text: product['price'].toString());

    void onSubmitted() {
      final qty = int.tryParse(quantityController.text) ?? 1;
      final price =
          double.tryParse(priceController.text) ?? (product['price'] ?? 0);

      setState(() {
        invoiceLines.add({
          ...product,
          'quantity': qty,
          'price': price,
          'C_Tax_ID': selectedTaxID,
        });
      });

      _recalculateSummary();
      productController.clear();
      Navigator.pop(context);
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text('Definir cantidad y precio'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextfieldTheme(
                controlador: quantityController,
                texto: 'Cantidad',
                inputType: TextInputType.number,
                onSubmitted: (_) => onSubmitted,
              ),
              const SizedBox(height: CustomSpacer.medium),
              TextfieldTheme(
                controlador: priceController,
                texto: 'Precio',
                inputType: TextInputType.number,
                onSubmitted: (_) => onSubmitted,
              ),
              const SizedBox(height: CustomSpacer.medium),
              SearchableDropdown<int>(
                labelText: 'Tipo de impuesto',
                showSearchBox: false,
                options: taxOptions,
                value: selectedTaxID,
                onChanged: (value) {
                  setState(() {
                    selectedTaxID = value;
                  });
                },
                displayItem: (item) => '${item['name']} (${item['rate']}%)',
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: onSubmitted,
              child: Text(
                'Agregar',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.surface,
                    ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onProductCreated(Map<String, dynamic> newProduct) async {
    await _loadProduct();
    final createdProduct = productOptions.firstWhere(
      (p) => p['id'] == newProduct['id'],
      orElse: () => {},
    );
    if (createdProduct.isNotEmpty) {
      _showQuantityDialog(createdProduct);
    }
  }

  void _deleteLine(int index) {
    setState(() {
      invoiceLines.removeAt(index);
    });
    _recalculateSummary();
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
          title: Text('Completar'),
          content: Text('¿Está seguro de que desea completar la orden?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Confirmar',
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
        'Name': item['name'],
        'Price': item['price'],
        'Quantity': item['quantity'],
        'C_Tax_ID': item['C_Tax_ID'],
      };
    }).toList();

    final result = await postInvoice(
      cBPartnerID: bPartner,
      invoiceLines: invoiceLine,
      context: context,
    );

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Orden completada"),
          backgroundColor: Colors.green,
        ),
      );
      clearInvoiceFields();
      setState(() {
        invoiceLines.clear();
        subtotal = 0.0;
        iva = 0.0;
        total = 0.0;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? "Error al completar la orden"),
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
      final name = tax['name'] ?? 'Sin impuesto';

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
    bool ismobile = MediaQuery.of(context).size.width <= 750;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: ismobile ? const MenuDrawer() : null,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                const CustomAppMenu(),
                CustomContainer(
                  margin: const EdgeInsets.all(12),
                  maxWidthContainer: 800,
                  padding: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text('Orden de venta',
                            style: Theme.of(context).textTheme.headlineLarge),
                      ),
                      const SizedBox(height: CustomSpacer.medium),
                      isBPartnerLoading
                          ? _buildShimmerField()
                          : CustomSearchField(
                              options: bPartnerOptions,
                              labelText: "Cliente",
                              searchBy: "TaxID",
                              showCreateButtonIfNotFound: true,
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
                          : CustomSearchField(
                              options: productOptions,
                              controller: productController,
                              showCreateButtonIfNotFound: true,
                              labelText: "Producto",
                              searchBy: "sku",
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
                                  _onProductCreated(result['product']);
                                }
                              },
                              onItemSelected: (item) {
                                _showQuantityDialog(item);
                              },
                              itemBuilder: (item) => Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item['sku'] ?? ''} - ${item['name'] ?? ''}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                      overflow: TextOverflow.ellipsis,
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
                      if (invoiceLines.isNotEmpty) ...[
                        const SizedBox(height: CustomSpacer.large),
                        Text('Detalle de productos',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: CustomSpacer.medium),
                        Wrap(
                          spacing: 8,
                          runSpacing: 2,
                          children: invoiceLines.asMap().entries.map((entry) {
                            final index = entry.key;
                            final line = entry.value;
                            final tax = taxOptions.firstWhere(
                              (t) => t['id'] == line['C_Tax_ID'],
                              orElse: () => {},
                            );
                            final taxRate = tax['rate'] != null
                                ? '${tax['rate']}%'
                                : 'Sin impuesto';
                            return Chip(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              deleteIconColor: ColorTheme.error,
                              label: Text(
                                '${line['quantity']} x \$${line['price']} + $taxRate (${line['name']})',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              deleteIcon: const Icon(Icons.close),
                              onDeleted: () => _deleteLine(index),
                              backgroundColor: Theme.of(context).cardColor,
                            );
                          }).toList(),
                        ),
                      ],
                      Divider(
                        color: Theme.of(context).dividerColor,
                        height: 60,
                      ),
                      Center(
                        child: Text('Resumen de la Factura',
                            style: Theme.of(context).textTheme.titleLarge),
                      ),
                      const SizedBox(height: CustomSpacer.medium),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal',
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
                            Text('Resumen de impuestos',
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
                                Text('Total impuestos',
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
                          Text('Total',
                              style: Theme.of(context).textTheme.titleLarge),
                          Text('\$${total.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleLarge),
                        ],
                      ),
                      const SizedBox(height: CustomSpacer.xlarge),
                      Container(
                        child: _isInvoiceValid()
                            ? isSending
                                ? ButtonLoading(fullWidth: true)
                                : ButtonPrimary(
                                    fullWidth: true,
                                    texto: 'Completar',
                                    onPressed: () => _createInvoice(
                                      product: invoiceLines,
                                      bPartner: selectedBPartnerID ?? 0,
                                    ),
                                  )
                            : null,
                      )
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
