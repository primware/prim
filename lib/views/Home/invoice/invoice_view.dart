import 'package:flutter/material.dart';
import '../../../shared/button.widget.dart';
import '../../../shared/custom_app_menu.dart';
import '../../../shared/custom_dropdown.dart';
import '../../../shared/custom_searchfield.dart';
import '../../../shared/custom_spacer.dart';
import '../../../shared/loading_container.dart';
import '../../../shared/textfield.widget.dart';
import '../../../theme/colors.dart';
import 'invoice_funtions.dart';

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

    void onSubmitted(String value) {
      final qty = int.tryParse(quantityController.text) ?? 1;
      setState(() {
        invoiceLines.add({
          ...product,
          'quantity': qty,
        });
      });
      _recalculateSummary();
      Navigator.pop(context);
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text('Definir cantidad'),
          content: TextfieldTheme(
            controlador: quantityController,
            inputType: TextInputType.number,
            texto: 'Cantidad',
            onSubmitted: onSubmitted,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => onSubmitted(quantityController.text),
              child: Text(
                'Agregar',
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

  void _deleteLine(int index) {
    setState(() {
      invoiceLines.removeAt(index);
    });
    _recalculateSummary();
  }

  @override
  Widget build(BuildContext context) {
    bool ismobile = MediaQuery.of(context).size.width <= 750;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: ismobile ? const MenuDrawer() : null,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Center(
              child: Column(
                children: [
                  const CustomAppMenu(),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 800),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Facturación',
                            style: Theme.of(context).textTheme.headlineLarge),
                        const SizedBox(height: CustomSpacer.medium),
                        SearchableDropdown<int>(
                          value: selectedBPartnerID,
                          options: bPartnerOptions,
                          labelText: 'Tercero',
                          onChanged: (value) {
                            setState(() => selectedBPartnerID = value);
                          },
                        ),
                        const SizedBox(height: CustomSpacer.medium),
                        CustomSearchField(
                          options: productOptions,
                          labelText: "Producto",
                          searchBy: "sku",
                          onItemSelected: (item) {
                            final alreadyExists =
                                invoiceLines.any((p) => p['id'] == item['id']);
                            if (alreadyExists) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: ColorTheme.atention,
                                  content:
                                      Text('El producto ya ha sido agregado'),
                                ),
                              );
                              return;
                            }
                            _showQuantityDialog(item);
                          },
                          itemBuilder: (item) => Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item['sku'] ?? ''} - ${item['name'] ?? ''}',
                                  style: Theme.of(context).textTheme.bodyMedium,
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
                            runSpacing: 8,
                            children: invoiceLines.asMap().entries.map((entry) {
                              final index = entry.key;
                              final line = entry.value;
                              return Chip(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                deleteIconColor: ColorTheme.error,
                                label: Text(
                                  '${line['quantity']}x ${line['sku'] ?? ''} - ${line['name']}  \$${(line['price'] ?? 0) * (line['quantity'] ?? 1)}',
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
                                style: Theme.of(context).textTheme.bodyMedium),
                            Text('\$${iva.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                        const SizedBox(height: CustomSpacer.medium),
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
                        ButtonPrimary(
                          fullWidth: true,
                          texto: 'Crear Factura',
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
    );
  }
}
