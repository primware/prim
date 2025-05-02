import 'package:flutter/material.dart';
import 'package:primware/shared/custom_container.dart';
import 'package:primware/shared/custom_spacer.dart';
import 'package:primware/views/Home/product/product_funtions.dart';

import '../../../shared/button.widget.dart';
import '../../../shared/textfield.widget.dart';
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
  final TextEditingController priceController = TextEditingController();

  bool isValid = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.productName != null) {
      nameController.text = widget.productName!;
    }

    nameController.addListener(_isFormValid);
    priceController.addListener(_isFormValid);
  }

  void _isFormValid() {
    setState(() {
      isValid =
          nameController.text.isNotEmpty && priceController.text.isNotEmpty;
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
        body: SafeArea(
      child: SingleChildScrollView(
        child: Center(
          child: CustomContainer(
              margin: const EdgeInsets.all(12),
              maxWidthContainer: 800,
              padding: 16,
              child: Column(
                children: [
                  Center(
                    child: Text('Producto nuevo',
                        style: Theme.of(context).textTheme.headlineLarge),
                  ),
                  const SizedBox(height: CustomSpacer.xlarge),
                  TextfieldTheme(
                    controlador: nameController,
                    texto: 'Nombre*',
                    colorEmpty:
                        nameController.text.isEmpty ? ColorTheme.error : null,
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
                    controlador: priceController,
                    texto: 'Precio*',
                    colorEmpty:
                        priceController.text.isEmpty ? ColorTheme.error : null,
                    inputType: TextInputType.number,
                  ),
                  const SizedBox(height: CustomSpacer.xlarge),
                  Row(
                    children: [
                      if (!isLoading) ...[
                        Expanded(
                          child: ButtonSecondary(
                            fullWidth: true,
                            texto: 'Cancelar',
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        const SizedBox(width: CustomSpacer.medium)
                      ],
                      Expanded(
                        child: Container(
                          child: isValid
                              ? isLoading
                                  ? ButtonLoading(fullWidth: true)
                                  : ButtonPrimary(
                                      fullWidth: true,
                                      texto: 'Completar',
                                      onPressed: _createProduct,
                                    )
                              : null,
                        ),
                      ),
                    ],
                  )
                ],
              )),
        ),
      ),
    ));
  }
}
