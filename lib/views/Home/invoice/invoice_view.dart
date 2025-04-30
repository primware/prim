import 'package:flutter/material.dart';
import 'package:primware/shared/custom_container.dart';
import 'package:primware/views/Home/invoice/invoice_controller.dart';
import '../../../shared/button.widget.dart';
import '../../../shared/custom_app_menu.dart';
import '../../../shared/custom_dropdown.dart';
import '../../../shared/custom_searchfield.dart';
import '../../../shared/custom_spacer.dart';
import '../../../shared/loading_container.dart';
import '../../../shared/textfield.widget.dart';
import '../../../theme/colors.dart';
import 'invoice_funtions.dart';

//TODO cargar los impuestos y la tasa de C_Tax

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  bool isLoading = true;

  List<Map<String, dynamic>> bPartnerOptions = [];
  List<Map<String, dynamic>> productOptions = [];
  List<Map<String, dynamic>> invoiceLines = [];

  int? selectedBPartnerID;
  double subtotal = 0.0;
  double iva = 0.0;
  double total = 0.0;

  final List<Map<String, dynamic>> taxOptions = [
    {'id': 0, 'name': '0%'},
    {'id': 7, 'name': '7%'},
    {'id': 10, 'name': '10%'},
    {'id': 15, 'name': '15%'},
    {'id': -1, 'name': 'Otro'},
  ];

  int selectedTaxId = 7;
  bool useCustomTax = false;
  final customTaxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOptions();
    });
  }

  @override
  void dispose() {
    customTaxController.dispose();
    super.dispose();
  }

  bool _isInvoiceValid() {
    return selectedBPartnerID != null && invoiceLines.isNotEmpty;
  }

  Future<void> _loadOptions() async {
    setState(() => isLoading = true);

    final partner = await fetchBPartner(context: context);
    final product = await fetchProduct(context: context);

    setState(() {
      bPartnerOptions = partner;
      productOptions = product;
      isLoading = false;
    });
  }

  void _recalculateSummary() {
    double newSubtotal = 0.0;
    for (var line in invoiceLines) {
      final price = (line['price'] ?? 0) as num;
      final quantity = (line['quantity'] ?? 1) as num;
      newSubtotal += price * quantity;
    }

    final taxPercent = useCustomTax
        ? double.tryParse(customTaxController.text) ?? 0
        : selectedTaxId.toDouble();

    setState(() {
      subtotal = newSubtotal;
      iva = subtotal * (taxPercent / 100);
      total = subtotal + iva;
    });
  }

  Future<void> _showQuantityDialog(Map<String, dynamic> product) async {
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
              const SizedBox(height: 16),
              TextfieldTheme(
                controlador: priceController,
                texto: 'Precio',
                inputType: TextInputType.number,
                onSubmitted: (_) => onSubmitted,
              ),
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
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text('Completar'),
          content: Text('¿Está seguro de que desea completar la orden?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() => isLoading = true);

                final List<Map<String, dynamic>> invoiceLine =
                    product.map((item) {
                  return {
                    'M_Product_ID': item['id'],
                    'SKU': item['sku'],
                    'Name': item['name'],
                    'Price': item['price'],
                    'Quantity': item['quantity'],
                  };
                }).toList();

                bool sucess = await postInvoice(
                    cBPartnerID: bPartner,
                    invoiceLines: invoiceLine,
                    context: context);

                if (sucess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Orden completada"),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Error al completar la orden"),
                      backgroundColor: ColorTheme.error,
                    ),
                  );
                }
                setState(() => isLoading = false);
                Navigator.pop(context);
              },
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
  }

  @override
  Widget build(BuildContext context) {
    bool ismobile = MediaQuery.of(context).size.width <= 750;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: ismobile ? const MenuDrawer() : null,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
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
                                style:
                                    Theme.of(context).textTheme.headlineLarge),
                          ),
                          const SizedBox(height: CustomSpacer.medium),
                          CustomSearchField(
                            options: bPartnerOptions,
                            labelText: "Cliente",
                            searchBy: "TaxID",
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
                          CustomSearchField(
                            options: productOptions,
                            controller: productController,
                            labelText: "Producto",
                            searchBy: "sku",
                            onItemSelected: (item) {
                              _showQuantityDialog(item);
                            },
                            itemBuilder: (item) => Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item['sku'] ?? ''} - ${item['name'] ?? ''}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
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
                              children:
                                  invoiceLines.asMap().entries.map((entry) {
                                final index = entry.key;
                                final line = entry.value;
                                return Chip(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  deleteIconColor: ColorTheme.error,
                                  label: Text(
                                    '${line['quantity']} x \$${line['price']} (${line['name']})',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
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
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                              Text('\$${subtotal.toStringAsFixed(2)}',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                          const SizedBox(height: CustomSpacer.medium),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Expanded(
                                child: SearchableDropdown<int>(
                                  value: selectedTaxId,
                                  options: taxOptions,
                                  showSearchBox: false,
                                  labelText: 'Impuesto (%)',
                                  onChanged: (value) {
                                    if (value == -1) {
                                      setState(() {
                                        useCustomTax = true;
                                        selectedTaxId = 0;
                                      });
                                    } else {
                                      setState(() {
                                        useCustomTax = false;
                                        selectedTaxId = value ?? 0;
                                        customTaxController.clear();
                                      });
                                      _recalculateSummary();
                                    }
                                  },
                                ),
                              ),
                              if (useCustomTax) ...[
                                const SizedBox(width: CustomSpacer.small),
                                Expanded(
                                  child: TextfieldTheme(
                                    texto: "Monto",
                                    controlador: customTaxController,
                                    inputType: TextInputType.number,
                                    icono: Icons.percent,
                                    onChanged: (_) => _recalculateSummary(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: CustomSpacer.medium),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('IVA',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                              Text('\$${iva.toStringAsFixed(2)}',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                          const SizedBox(height: CustomSpacer.medium),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total',
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              Text('\$${total.toStringAsFixed(2)}',
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                            ],
                          ),
                          const SizedBox(height: CustomSpacer.xlarge),
                          Container(
                            child: _isInvoiceValid()
                                ? ButtonPrimary(
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
            if (isLoading) const LoadingContainer(),
          ],
        ),
      ),
    );
  }
}
