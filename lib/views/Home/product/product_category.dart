import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../../../localization/app_locale.dart';
import '../../../shared/toast_message.dart';
import '../../../shared/custom_textfield.dart';
import '../../../Widgets/GlassDesign.dart';
import 'product_funtions.dart';

class ProductCategoryDialog {
  static Future<Map<String, dynamic>?> show(BuildContext context, {String initialName = ''}) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final TextEditingController catNameController = TextEditingController(text: initialName);
        bool isCreating = false;
        bool isCatNameValid = initialName.trim().isNotEmpty;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return GlassAlertDialog(
              title: Text(
                AppLocale.newCategory.getString(context),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextfieldTheme(
                      controlador: catNameController,
                      texto: '${AppLocale.name.getString(context)}*',
                      colorEmpty: catNameController.text.trim().isEmpty,
                      inputType: TextInputType.text,
                      fillColor: Colors.white.withOpacity(0.24),
                      textColor: Colors.white,
                      labelColor: Colors.white.withOpacity(0.9),
                      onChanged: (value) {
                        setModalState(() {
                          isCatNameValid = value.trim().isNotEmpty;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                if (!isCreating)
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, null),
                    child: Text(
                      AppLocale.cancel.getString(context),
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (!isCreating)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: isCatNameValid
                        ? () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => GlassAlertDialog(
                                title: const Column(
                                  children: [
                                    Icon(Icons.help_outline, size: 45, color: Colors.blueAccent),
                                    SizedBox(height: 10),
                                    Text(
                                      'Crear Categoría',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                                    ),
                                  ],
                                ),
                                content: Text(
                                  AppLocale.confirmCreateCategory.getString(context),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                                ),
                                actionsAlignment: MainAxisAlignment.spaceEvenly,
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text(
                                      AppLocale.no.getString(context),
                                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(AppLocale.yes.getString(context)),
                                  ),
                                ],
                              ),
                            );

                            if (confirm != true) return;

                            setModalState(() => isCreating = true);

                            final result = await postProductCategory(name: catNameController.text, context: context);

                            if (result['success'] == true) {
                              final newCat = result['category'];
                              Navigator.pop(dialogContext, {
                                'success': true,
                                'id': newCat['id'],
                                'name': newCat['Name'] ?? newCat['name'] ?? catNameController.text,
                              });
                              ToastMessage.show(context: context, message: 'Categoría creada con éxito', type: ToastType.success);
                            } else {
                              setModalState(() => isCreating = false);
                              ToastMessage.show(context: context, message: result['message'] ?? 'Error al crear', type: ToastType.failure);
                            }
                          }
                        : null,
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
}
