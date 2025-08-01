import 'package:flutter/material.dart';
import 'package:primware/shared/custom_container.dart';
import 'package:primware/shared/custom_spacer.dart';
import 'package:primware/shared/shimmer_list.dart';
import 'package:primware/views/Home/product/product_funtions.dart';

import '../../../shared/button.widget.dart';
import '../../../shared/custom_dropdown.dart';
import '../../../shared/formater.dart';
import '../../../shared/custom_textfield.dart';
import '../../../theme/colors.dart';

class ProductNewPage extends StatefulWidget {
  final String? productName;

  const ProductNewPage({super.key, this.productName});

  @override
  State<ProductNewPage> createState() => _ProductNewPageState();
}

class _ProductNewPageState extends State<ProductNewPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController skuController = TextEditingController();
  final TextEditingController upcController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  bool isValid = false,
      isLoading = false,
      _isCategoryLoading = true,
      _isTaxiesLoading = true;

  int? selectedCategoryID;
  int? selectedTaxID;

  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> taxies = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadTaxies();

    if (widget.productName != null) {
      nameController.text = widget.productName!;
    }

    nameController.addListener(_isFormValid);
    priceController.addListener(_isFormValid);
  }

  Future<void> _loadCategories() async {
    final fetchedCategories = await getMProductCategoryID(context);
    if (fetchedCategories != null) {
      setState(() {
        categories = fetchedCategories;
        _isCategoryLoading = false;
      });
    }
  }

  Future<void> _loadTaxies() async {
    final fetchedTaxies = await getCTaxCategoryID(context);
    if (fetchedTaxies != null) {
      setState(() {
        taxies = fetchedTaxies;
        _isTaxiesLoading = false;
      });
    }
  }

  void _isFormValid() {
    setState(() {
      isValid = nameController.text.isNotEmpty &&
          priceController.text.isNotEmpty &&
          selectedCategoryID != null &&
          selectedTaxID != null;
    });
  }

  @override
  void dispose() {
    nameController.removeListener(_isFormValid);
    priceController.removeListener(_isFormValid);

    super.dispose();
  }

  Future<void> _createProduct() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text('Crear producto'),
          content: Text('¿Está seguro de que desea crear el producto?'),
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

    setState(() => isLoading = true);

    final result = await postProduct(
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
      Navigator.pop(context, {
        'created': true,
        'product': result['product'],
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
              child: Text(result['message'] ?? 'Error al crear producto')),
          backgroundColor: ColorTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Producto nuevo')),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: CustomContainer(
                  child: Column(
                children: [
                  TextfieldTheme(
                    controlador: nameController,
                    texto: 'Nombre*',
                    colorEmpty: nameController.text.isEmpty,
                    inputType: TextInputType.text,
                  ),
                  const SizedBox(height: CustomSpacer.medium),
                  TextfieldTheme(
                    controlador: skuController,
                    texto: 'SKU',
                    inputType: TextInputType.text,
                  ),
                  const SizedBox(height: CustomSpacer.medium),
                  TextfieldTheme(
                    controlador: upcController,
                    texto: 'UPC',
                    inputType: TextInputType.text,
                  ),
                  const SizedBox(height: CustomSpacer.medium),
                  _isCategoryLoading
                      ? ShimmerList(
                          count: 1,
                        )
                      : SearchableDropdown<int>(
                          value: selectedCategoryID,
                          options: categories,
                          showSearchBox: true,
                          labelText: 'Categoría *',
                          onChanged: (int? newValue) {
                            setState(() {
                              selectedCategoryID = newValue;
                              _isFormValid();
                            });
                          },
                        ),
                  const SizedBox(height: CustomSpacer.medium),
                  _isTaxiesLoading
                      ? ShimmerList(
                          count: 1,
                        )
                      : SearchableDropdown<int>(
                          value: selectedTaxID,
                          options: taxies,
                          showSearchBox: true,
                          labelText: 'Impuesto *',
                          onChanged: (int? newValue) {
                            setState(() {
                              selectedTaxID = newValue;
                              _isFormValid();
                            });
                          },
                        ),
                  const SizedBox(height: CustomSpacer.medium),
                  TextfieldTheme(
                    controlador: priceController,
                    texto: 'Precio*',
                    colorEmpty: priceController.text.isEmpty,
                    inputType: TextInputType.number,
                    inputFormatters: [NumericTextFormatterWithDecimal()],
                  ),
                  const SizedBox(height: CustomSpacer.xlarge),
                  if (!isLoading) ...[
                    ButtonSecondary(
                      fullWidth: true,
                      texto: 'Cancelar',
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
                                texto: 'Completar',
                                onPressed: _createProduct,
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
