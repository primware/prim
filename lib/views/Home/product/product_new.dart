import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/shared/custom_container.dart';
import 'package:primware/shared/custom_spacer.dart';
import 'package:primware/shared/shimmer_list.dart';
import 'package:primware/views/Home/product/product_funtions.dart';
import '../../../localization/app_locale.dart';
import '../../../shared/button.widget.dart';
import '../../../shared/custom_dropdown.dart';
import '../../../shared/footer.dart';
import '../../../shared/formater.dart';
import '../../../shared/custom_textfield.dart';
import '../../../theme/colors.dart';
import '../../../shared/custom_searchfield.dart';

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
  final TextEditingController categoryController = TextEditingController();

  bool isValid = false, isLoading = false, _isCategoryLoading = true, _isTaxiesLoading = true, _taxError = false;

  int? selectedCategoryID;
  int? selectedTaxID;
  String? selectedProductType = 'I'; // Valor por defecto: Artículo
  String categorySearchTerm = '';

  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> taxies = [];

  // Opciones para el tipo de producto
  final List<Map<String, dynamic>> productTypes = [
    {'value': 'I', 'label': 'Artículo'},
    {'value': 'S', 'label': 'Servicio'},
  ];

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
    final fetchedCategories = await getMProductCategoryID(context) ?? [];
    if (!mounted) return;
    setState(() {
      categories = fetchedCategories;
      _isCategoryLoading = false;
    });
  }

  Future<void> _loadTaxies() async {
    final fetchedTaxies = await getCTaxCategoryID(context) ?? [];
    if (!mounted) return;
    setState(() {
      taxies = fetchedTaxies;
      _isTaxiesLoading = false;
      _taxError = taxies.isEmpty;
    });
  }

  void _isFormValid() {
    setState(() {
      String rawPrice = priceController.text.trim().replaceAll(',', '.');
      bool isPriceValid = rawPrice.isNotEmpty && double.tryParse(rawPrice) != null;

      print('--- VALIDACIÓN ---');
      print('Nombre: ${nameController.text.isNotEmpty} | Precio: $isPriceValid (Raw: "$rawPrice")');
      print(
        'Cat: ${selectedCategoryID != null} | Tax: ${selectedTaxID != null} | Tipo: ${selectedProductType != null} | SinErrorTax: ${!_taxError}',
      );

      isValid =
          nameController.text.isNotEmpty &&
          isPriceValid &&
          selectedCategoryID != null &&
          selectedTaxID != null &&
          selectedProductType != null &&
          !_taxError;
    });
  }

  @override
  void dispose() {
    nameController.removeListener(_isFormValid);
    priceController.removeListener(_isFormValid);
    categoryController.dispose();
    super.dispose();
  }

  Future<void> _showCreateCategoryDialog(String initialName) async {
    final TextEditingController catNameController = TextEditingController(text: initialName);
    final TextEditingController catValueController = TextEditingController();
    final TextEditingController catDescController = TextEditingController();
    bool isCreating = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              insetPadding: const EdgeInsets.all(16.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Nueva Categoría', style: Theme.of(context).textTheme.bodyMedium),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextfieldTheme(
                      controlador: catNameController,
                      texto: '${AppLocale.name.getString(context)}*',
                      inputType: TextInputType.text,
                    ),
                    const SizedBox(height: CustomSpacer.medium),
                    TextfieldTheme(controlador: catValueController, texto: 'Código (Valor)', inputType: TextInputType.text),
                    const SizedBox(height: CustomSpacer.medium),
                    TextfieldTheme(controlador: catDescController, texto: 'Descripción (Opcional)', inputType: TextInputType.text),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                if (!isCreating)
                  TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(AppLocale.cancel.getString(context))),
                if (!isCreating)
                  ElevatedButton(
                    onPressed: () async {
                      if (catNameController.text.isEmpty) return;

                      setModalState(() => isCreating = true);

                      final result = await postProductCategory(name: catNameController.text, context: context);

                      if (!mounted) return;

                      if (result['success'] == true) {
                        final newCat = result['category'];
                        setState(() {
                          categories.add({'id': newCat['id'], 'name': newCat['Name'] ?? newCat['name'] ?? catNameController.text});
                          categoryController.text = catNameController.text;
                          selectedCategoryID = newCat['id'];
                          categorySearchTerm = catNameController.text;
                          _isFormValid();
                        });

                        Navigator.pop(dialogContext);
                        //TODO cambiar a Toast
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('Categoría creada con éxito'), backgroundColor: ColorTheme.success));
                      } else {
                        setModalState(() => isCreating = false);
                        //TODO cambiar a Toast
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Error al crear'), backgroundColor: ColorTheme.error));
                      }
                    },
                    child: Text(AppLocale.save.getString(context)),
                  ),
                if (isCreating) const CircularProgressIndicator(),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createProduct() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(AppLocale.newProduct.getString(context)),
          content: Text(AppLocale.confirmCreateProduct.getString(context)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocale.cancel.getString(context))),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                AppLocale.save.getString(context),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.surface),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => isLoading = true);

    String finalPrice = priceController.text.trim().replaceAll(',', '.');

    final result = await postProduct(
      name: nameController.text,
      sku: skuController.text,
      upc: upcController.text,
      taxID: selectedTaxID!,
      categoryID: selectedCategoryID!,
      price: finalPrice,
      productType: selectedProductType!,
      context: context,
    );

    if (!mounted) return;

    setState(() => isLoading = false);

    if (result['success'] == true) {
      Navigator.pop(context, {'created': true, 'product': result['product']});
      //TODO cambiar a Toast
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(child: Text(AppLocale.productCreatedSuccessfully.getString(context))),
          backgroundColor: ColorTheme.success,
        ),
      );
    } else {
      //TODO cambiar a Toast
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(child: Text(AppLocale.errorCreatingProduct.getString(context))),
          backgroundColor: ColorTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocale.newProduct.getString(context))),
      bottomNavigationBar: CustomFooter(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: CustomContainer(
              child: Column(
                children: [
                  TextfieldTheme(controlador: skuController, texto: AppLocale.code.getString(context), inputType: TextInputType.text),
                  const SizedBox(height: CustomSpacer.medium),
                  TextfieldTheme(
                    controlador: nameController,
                    texto: '${AppLocale.name.getString(context)}*',
                    colorEmpty: nameController.text.isEmpty,
                    inputType: TextInputType.text,
                  ),
                  const SizedBox(height: CustomSpacer.medium),
                  TextfieldTheme(controlador: upcController, texto: AppLocale.upc.getString(context), inputType: TextInputType.text),
                  const SizedBox(height: CustomSpacer.medium),
                  SearchableDropdown<String>(
                    value: selectedProductType,
                    options: productTypes.map((type) => {'id': type['value'], 'name': type['label']}).toList(),
                    labelText: '${AppLocale.productType.getString(context)} *',
                    showSearchBox: false,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedProductType = newValue;
                          _isFormValid();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: CustomSpacer.medium),
                  _isCategoryLoading
                      ? const ShimmerList(count: 1)
                      : CustomSearchField(
                          controller: categoryController,
                          labelText: '${AppLocale.productCategory.getString(context)} *',
                          options: categories,
                          showCreateButtonIfNotFound: true,
                          createAnchorTerm: categorySearchTerm,
                          onChanged: (String val) {
                            setState(() {
                              categorySearchTerm = val;
                              bool matchFound = false;
                              for (var cat in categories) {
                                String catName = (cat['name'] ?? cat['Name'] ?? '').toString();
                                if (catName == val) {
                                  selectedCategoryID = cat['id'];
                                  matchFound = true;
                                  break;
                                }
                              }
                              if (!matchFound) {
                                selectedCategoryID = null;
                              }

                              _isFormValid();
                            });
                          },
                          onItemSelected: (Map<String, dynamic> item) {
                            setState(() {
                              selectedCategoryID = item['id'];
                              _isFormValid();
                            });
                          },
                          onCreate: (String searchTerm) {
                            _showCreateCategoryDialog(searchTerm);
                          },
                        ),
                  const SizedBox(height: CustomSpacer.medium),
                  _isTaxiesLoading
                      ? ShimmerList(count: 1)
                      : SearchableDropdown<int>(
                          value: selectedTaxID,
                          options: taxies,
                          showSearchBox: true,
                          labelText: '${AppLocale.taxCategory.getString(context)} *',
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
                    texto: '${AppLocale.price.getString(context)}*',
                    colorEmpty: priceController.text.isEmpty,
                    inputType: TextInputType.text,
                    inputFormatters: [NumericTextFormatterWithDecimal()],
                    onChanged: (value) {
                      _isFormValid();
                    },
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
                    const SizedBox(height: CustomSpacer.medium),
                  ],
                  Container(
                    child: isValid
                        ? isLoading
                              ? ButtonLoading(fullWidth: true)
                              : ButtonPrimary(fullWidth: true, texto: AppLocale.save.getString(context), onPressed: _createProduct)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
