import 'package:flutter/material.dart';
import '../../../shared/custom_app_menu.dart';
import '../../../shared/custom_dropdown.dart';
import '../../../shared/custom_searchfield.dart';
import '../../../shared/custom_spacer.dart';
import '../../../shared/loading_container.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOptions();
    });
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
    setState(() {
      subtotal = newSubtotal;
      iva = subtotal * 0.07;
      total = subtotal + iva;
    });
  }

  Future<void> _showQuantityDialog(Map<String, dynamic> product) async {
    final quantityController = TextEditingController(text: "1");

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Agregar cantidad'),
          content: TextField(
            controller: quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Cantidad',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final qty = int.tryParse(quantityController.text) ?? 1;
                setState(() {
                  invoiceLines.add({
                    ...product,
                    'quantity': qty,
                  });
                });
                _recalculateSummary();
                Navigator.pop(context);
              },
              child: const Text('Agregar'),
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
                            setState(() {
                              selectedBPartnerID = value;
                            });
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
                                    content: Text(
                                        'El producto ya ha sido agregado')),
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Detalle de productos',
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: CustomSpacer.medium),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    invoiceLines.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final line = entry.value;
                                  return Chip(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    deleteIconColor: ColorTheme.error,
                                    label: Text(
                                      '${line['quantity']}x ${line['sku']} - ${line['name']}  \$${(line['price'] ?? 0) * (line['quantity'] ?? 1)}',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                    deleteIcon: const Icon(Icons.close),
                                    onDeleted: () => _deleteLine(index),
                                    backgroundColor:
                                        Theme.of(context).cardColor,
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: CustomSpacer.large),
                            ],
                          ),
                        ],
                        Divider(
                            color: Theme.of(context).dividerColor, height: 60),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('IVA (7%)',
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
