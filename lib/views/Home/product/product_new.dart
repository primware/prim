import 'package:flutter/material.dart';
import 'dart:ui';
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
import '../../../shared/custom_searchfield.dart';
import '../../../shared/toast_message.dart';
import '../../../Widgets/GlassDesign.dart';
import 'product_category.dart';

class ProductNewPage extends StatefulWidget {
  final String? productName;

  const ProductNewPage({super.key, this.productName});

  static Future<Map<String, dynamic>?> show(BuildContext context, {String? productName}) {
    return showGeneralDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ProductNewPage',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ProductNewPage(productName: productName);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeIn,
            ),
            child: child,
          ),
        );
      },
    );
  }

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

  String _getSelectedProductTypeName() {
    final matched = productTypes.firstWhere((t) => t['value'] == selectedProductType, orElse: () => {'label': ''});
    return matched['label'].toString();
  }

  String _getSelectedTaxName() {
    if (selectedTaxID == null) return '';
    final matched = taxies.firstWhere((t) => t['id'] == selectedTaxID, orElse: () => <String, dynamic>{});
    return (matched['name'] ?? matched['Name'] ?? '').toString();
  }

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
    final result = await ProductCategoryDialog.show(context, initialName: initialName);
    if (result != null && result['success'] == true) {
      setState(() {
        categories.add({'id': result['id'], 'name': result['name']});
        categoryController.text = result['name'];
        selectedCategoryID = result['id'];
        categorySearchTerm = result['name'];
        _isFormValid();
      });
    }
  }

  Future<void> _createProduct() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return GlassAlertDialog(
          title: Text(AppLocale.newProduct.getString(context)),
          content: Text(AppLocale.confirmCreateProduct.getString(context)),
          actionsAlignment: MainAxisAlignment.end,
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
      ToastMessage.show(context: context, message: AppLocale.productCreatedSuccessfully.getString(context), type: ToastType.success);
    } else {
      ToastMessage.show(context: context, message: AppLocale.errorCreatingProduct.getString(context), type: ToastType.failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: GlassContainer(
          padding: const EdgeInsets.all(24.0),
          borderRadius: BorderRadius.circular(20),
          hasShadow: false,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocale.newProduct.getString(context),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: CustomSpacer.large),
                  TextfieldTheme(
                    controlador: skuController,
                    texto: AppLocale.code.getString(context),
                    inputType: TextInputType.text,
                    fillColor: Colors.white.withOpacity(0.24),
                    textColor: Colors.white,
                    labelColor: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(height: CustomSpacer.medium),
                  TextfieldTheme(
                    controlador: nameController,
                    texto: '${AppLocale.name.getString(context)}*',
                    colorEmpty: nameController.text.isEmpty,
                    inputType: TextInputType.text,
                    fillColor: Colors.white.withOpacity(0.24),
                    textColor: Colors.white,
                    labelColor: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(height: CustomSpacer.medium),
                  TextfieldTheme(
                    controlador: upcController,
                    texto: AppLocale.upc.getString(context),
                    inputType: TextInputType.text,
                    fillColor: Colors.white.withOpacity(0.24),
                    textColor: Colors.white,
                    labelColor: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(height: CustomSpacer.medium),
                  GlassDropdown<String>(
                    label: '${AppLocale.productType.getString(context)} *',
                    currentValue: _getSelectedProductTypeName(),
                    icon: Icons.category_outlined,
                    items: productTypes.map((type) => GlassDropdownItem<String>(value: type['value'], text: type['label'])).toList(),
                    textColor: Colors.white,
                    labelColor: Colors.white.withOpacity(0.9),
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
                      : GlassSearchField(
                          controller: categoryController,
                          label: '${AppLocale.productCategory.getString(context)} *',
                          options: categories,
                          showCreateButtonIfNotFound: true,
                          createAnchorTerm: categorySearchTerm,
                          fillColor: Colors.white.withOpacity(0.24),
                          textColor: Colors.white,
                          labelColor: Colors.white.withOpacity(0.9),
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
                              categoryController.text = (item['name'] ?? item['Name'] ?? '').toString();
                              _isFormValid();
                            });
                          },
                          onCreate: (String searchTerm) {
                            _showCreateCategoryDialog(searchTerm);
                          },
                        ),
                  const SizedBox(height: CustomSpacer.medium),
                  _isTaxiesLoading
                      ? const ShimmerList(count: 1)
                      : GlassDropdown<int>(
                          label: '${AppLocale.taxCategory.getString(context)} *',
                          currentValue: _getSelectedTaxName(),
                          icon: Icons.percent_outlined,
                          items: taxies.map((t) => GlassDropdownItem<int>(value: t['id'], text: (t['name'] ?? t['Name'] ?? '').toString())).toList(),
                          textColor: Colors.white,
                          labelColor: Colors.white.withOpacity(0.9),
                          onChanged: (int? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedTaxID = newValue;
                                _isFormValid();
                              });
                            }
                          },
                        ),
                  const SizedBox(height: CustomSpacer.medium),
                  TextfieldTheme(
                    controlador: priceController,
                    texto: '${AppLocale.price.getString(context)}*',
                    colorEmpty: priceController.text.isEmpty,
                    inputType: TextInputType.text,
                    inputFormatters: [NumericTextFormatterWithDecimal()],
                    fillColor: Colors.white.withOpacity(0.24),
                    textColor: Colors.white,
                    labelColor: Colors.white.withOpacity(0.9),
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
