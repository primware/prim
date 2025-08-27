import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/shared/custom_container.dart';
import 'package:primware/shared/custom_spacer.dart';
import 'package:primware/shared/shimmer_list.dart';
import 'package:primware/views/Home/product/product_funtions.dart';

import '../../../localization/app_locale.dart';
import '../../../shared/button.widget.dart';
import '../../../shared/custom_dropdown.dart';
import '../../../shared/formater.dart';
import '../../../shared/custom_textfield.dart';
import '../../../theme/colors.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController skuController = TextEditingController();
  final TextEditingController upcController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  bool isValid = false,
      isLoading = false,
      _isCategoryLoading = true,
      _isTaxiesLoading = true,
      _taxError = false;

  int? selectedCategoryID;
  int? selectedTaxID;

  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> taxies = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadTaxies();

    // Pre-fill with product data
    nameController.text = widget.product['name'] ?? '';
    skuController.text = widget.product['sku'] ?? '';
    upcController.text = widget.product['upc'] ?? '';
    priceController.text = widget.product['price']?.toString() ?? '';

    selectedCategoryID = widget.product['category'];
    selectedTaxID = widget.product['C_TaxCategory_ID'];

    nameController.addListener(_isFormValid);
    priceController.addListener(_isFormValid);
  }

  Future<void> _loadCategories() async {
    final fetchedCategories = await getMProductCategoryID(context) ?? [];
    /*if (fetchedCategories != null) {
      setState(() {
        categories = fetchedCategories;
        _isCategoryLoading = false;
      });
    }*/
    setState(() {
      categories = fetchedCategories;
      _isCategoryLoading = false;
    });
  }

  Future<void> _loadTaxies() async {
    final fetchedTaxies = await getCTaxCategoryID(context) ?? [];
    /*if (fetchedTaxies != null) {
      setState(() {
        taxies = fetchedTaxies;
        _isTaxiesLoading = false;
      });
    }*/
    setState(() {
      taxies = fetchedTaxies;
      _isTaxiesLoading = false;
      _taxError = taxies.isEmpty;
    });
  }

  void _isFormValid() {
    setState(() {
      isValid = nameController.text.isNotEmpty &&
          priceController.text.isNotEmpty &&
          selectedCategoryID != null &&
          selectedTaxID != null &&
          !_taxError;
    });
  }

  @override
  void dispose() {
    nameController.removeListener(_isFormValid);
    priceController.removeListener(_isFormValid);
    super.dispose();
  }

  Future<void> _updateProduct() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(AppLocale.updateProduct.getString(context)),
          content: Text(AppLocale.confirmDeleteProduct.getString(context)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocale.cancel.getString(context)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                AppLocale.updateProduct.getString(context),
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

    setState(() => isLoading = true);

    final result = await putProduct(
      id: widget.product['id'],
      name: nameController.text,
      sku: skuController.text,
      upc: upcController.text,
      taxID: selectedTaxID!,
      categoryID: selectedCategoryID!,
      price: priceController.text,
      context: context,
    );

    setState(() => isLoading = false);

    if (result['success'] == true) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
              child: Text(
                  AppLocale.productUpdatedSuccessfully.getString(context))),
          backgroundColor: ColorTheme.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
              child: Text(AppLocale.errorUpdatingProduct.getString(context))),
          backgroundColor: ColorTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(AppLocale.productDetail.getString(context))),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: CustomContainer(
                  child: Column(
                children: [
                  TextfieldTheme(
                    controlador: nameController,
                    texto: '${AppLocale.name.getString(context)}*',
                    colorEmpty: nameController.text.isEmpty,
                    inputType: TextInputType.text,
                  ),
                  const SizedBox(height: CustomSpacer.medium),
                  TextfieldTheme(
                    controlador: skuController,
                    texto: AppLocale.code.getString(context),
                    inputType: TextInputType.text,
                  ),
                  const SizedBox(height: CustomSpacer.medium),
                  TextfieldTheme(
                    controlador: upcController,
                    texto: AppLocale.description.getString(context),
                    inputType: TextInputType.text,
                  ),
                  const SizedBox(height: CustomSpacer.medium),
                  _isCategoryLoading
                      ? ShimmerList(count: 1)
                      : SearchableDropdown<int>(
                          value: selectedCategoryID,
                          options: categories,
                          showSearchBox: true,
                          labelText:
                              '${AppLocale.category.getString(context)} *',
                          onChanged: (int? newValue) {
                            setState(() {
                              selectedCategoryID = newValue;
                              _isFormValid();
                            });
                          },
                        ),
                  const SizedBox(height: CustomSpacer.medium),
                  _isTaxiesLoading
                      ? ShimmerList(count: 1)
                      : SearchableDropdown<int>(
                          value: selectedTaxID,
                          options: taxies,
                          showSearchBox: true,
                          labelText: '${AppLocale.price.getString(context)} *',
                          onChanged: (int? newValue) {
                            setState(() {
                              selectedTaxID = newValue;
                              _isFormValid();
                            });
                          },
                        ),
                        // Mensaje de error si taxTypes está vacío
                        /*if (_taxError && !_isTaxiesLoading)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                            child: Text(
                              AppLocale.noTaxCategoryAvailable.getString(context),
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),*/
                  const SizedBox(height: CustomSpacer.medium),
                  TextfieldTheme(
                    controlador: priceController,
                    texto: '${AppLocale.price.getString(context)}*',
                    colorEmpty: priceController.text.isEmpty,
                    inputType: TextInputType.number,
                    inputFormatters: [NumericTextFormatterWithDecimal()],
                  ),
                  const SizedBox(height: CustomSpacer.xlarge),
                  if (!isLoading) ...[
                    ButtonSecondary(
                      fullWidth: true,
                      texto: AppLocale.cancel.getString(context),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: CustomSpacer.medium)
                  ],
                  Container(
                    child: isValid
                        ? isLoading
                            ? ButtonLoading(fullWidth: true)
                            : ButtonPrimary(
                                fullWidth: true,
                                texto:
                                    AppLocale.updateProduct.getString(context),
                                onPressed: _updateProduct,
                              )
                        : null,
                  )
                ],
              )),
            ),
          ),
        ));
  }
}
