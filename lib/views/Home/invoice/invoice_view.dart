import 'package:flutter/material.dart';
import '../../../shared/custom_app_menu.dart';
import '../../../shared/custom_dropdown.dart';
import '../../../shared/custom_searchfield.dart';
import '../../../shared/custom_spacer.dart';
import '../../../shared/loading_container.dart';
import 'invoice_funtions.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  bool isLoading = true;
  bool isValid = false;

  List<Map<String, dynamic>> bPartnerOptions = [];
  List<Map<String, dynamic>> productOptions = [];

  int? selectedBPartnerID, selectedProductID;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOptions();
      _validateForm();
    });
    // clientNameController.addListener(_validateForm);
    // adminUserEmailController.addListener(_validateForm);
  }

  Future<void> _loadOptions() async {
    setState(() {
      isLoading = true;
    });
    final partner = await fetchBPartner(context: context);
    setState(() {
      bPartnerOptions = partner;
    });

    final product = await fetchProduct(context: context);
    setState(() {
      productOptions = product;
    });

    setState(() {
      isLoading = false;
    });
  }

  void _validateForm() {
    // setState(() {
    //   isValid = clientNameController.text.isNotEmpty &&
    //       isValidEmail(adminUserEmailController.text) &&
    //       selectedCountryID != null &&
    //       selectedCurrencyID != null;
    // });
  }

  @override
  Widget build(BuildContext context) {
    bool ismobile = MediaQuery.of(context).size.width <= 750;

    return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        drawer: ismobile ? MenuDrawer() : null,
        body: Stack(children: [
          SingleChildScrollView(
            child: Center(
              child: Column(
                children: [
                  CustomAppMenu(),
                  Container(
                    constraints: BoxConstraints(maxWidth: 800),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Facturación',
                          style: Theme.of(context).textTheme.headlineLarge,
                          overflow: TextOverflow.visible,
                        ),
                        SizedBox(height: CustomSpacer.medium),
                        SearchableDropdown<int>(
                          value: selectedBPartnerID,
                          options: bPartnerOptions,
                          labelText: 'Tercero',
                          onChanged: (value) {
                            setState(() {
                              selectedBPartnerID = value;
                              // _validateForm();
                            });
                          },
                        ),
                        SizedBox(height: CustomSpacer.medium),
                        CustomSearchField(
                          options: productOptions,
                          labelText: "Producto",
                          searchBy: "sku",
                          onItemSelected: (item) {
                            print('Seleccionaste: ${item['name']}');
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
                        SizedBox(height: CustomSpacer.medium),
                        Divider(
                          color: Theme.of(context).dividerColor,
                          height: 60,
                        ),
                        Center(
                          child: Text('Resumen de la Factura',
                              style: Theme.of(context).textTheme.titleLarge),
                        ),
                        SizedBox(height: CustomSpacer.medium),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Subtotal',
                                style: Theme.of(context).textTheme.bodyMedium),
                            Text('0.00',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                        SizedBox(height: CustomSpacer.medium),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('IVA',
                                style: Theme.of(context).textTheme.bodyMedium),
                            Text('0.00',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                        SizedBox(height: CustomSpacer.medium),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total',
                                style: Theme.of(context).textTheme.titleLarge),
                            Text('0.00',
                                style: Theme.of(context).textTheme.titleLarge),
                          ],
                        ),
                        SizedBox(height: CustomSpacer.medium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading) LoadingContainer(),
        ]));
  }
}
