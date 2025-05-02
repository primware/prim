import 'package:flutter/material.dart';
import 'package:primware/shared/custom_container.dart';
import 'package:primware/shared/custom_spacer.dart';
import '../../../shared/button.widget.dart';
import '../../../shared/textfield.widget.dart';
import '../../../theme/colors.dart';
import 'bpartner_funtions.dart';

class BPartnerNewPage extends StatefulWidget {
  final String? bpartnerName;

  const BPartnerNewPage({super.key, this.bpartnerName});

  @override
  State<BPartnerNewPage> createState() => _BPartnerNewPageState();
}

class _BPartnerNewPageState extends State<BPartnerNewPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController taxController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  bool isValid = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.bpartnerName != null) {
      nameController.text = widget.bpartnerName!;
    }
    locationController.text = 'Ubicación de ${widget.bpartnerName}';
    nameController.addListener(_isFormValid);
    emailController.addListener(_isFormValid);
    taxController.addListener(_isFormValid);
    locationController.addListener(_isFormValid);
  }

  void clearPartnerFields() {
    nameController.clear();
    locationController.clear();
    taxController.clear();
    emailController.clear();
  }

  void _isFormValid() {
    setState(() {
      isValid = nameController.text.isNotEmpty &&
          locationController.text.isNotEmpty &&
          isValidEmail(emailController.text);
    });
  }

  bool isValidEmail(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  @override
  void dispose() {
    nameController.removeListener(_isFormValid);
    emailController.removeListener(_isFormValid);
    taxController.removeListener(_isFormValid);
    locationController.removeListener(_isFormValid);

    super.dispose();
  }

  Future<void> _createBPartner() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text('Crear cliente'),
          content: Text('¿Está seguro de que desea crear el cliente?'),
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

    final result = await postBPartner(
      name: nameController.text,
      location: locationController.text,
      taxID: taxController.text,
      email: emailController.text,
      context: context,
    );

    setState(() => isLoading = false);

    if (result['success'] == true) {
      clearPartnerFields();
      Navigator.pop(context, {
        'created': true,
        'bpartner': result['bpartner'],
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
              child: Text(result['message'] ?? 'Error al crear cliente')),
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
                    child: Text('Cliente nuevo',
                        style: Theme.of(context).textTheme.headlineLarge),
                  ),
                  const SizedBox(height: CustomSpacer.xlarge),
                  TextfieldTheme(
                    controlador: nameController,
                    texto: 'Nombre*',
                    colorEmpty:
                        nameController.text.isEmpty ? ColorTheme.error : null,
                    inputType: TextInputType.name,
                  ),
                  const SizedBox(height: CustomSpacer.medium),
                  TextfieldTheme(
                    controlador: taxController,
                    texto: 'Nro. de identificación',
                    inputType: TextInputType.text,
                  ),
                  const SizedBox(height: CustomSpacer.medium),
                  TextfieldTheme(
                    controlador: emailController,
                    texto: 'Correo electrónico*',
                    colorEmpty: !isValidEmail(emailController.text)
                        ? ColorTheme.error
                        : null,
                    inputType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: CustomSpacer.medium),
                  TextfieldTheme(
                    controlador: locationController,
                    texto: 'Ubicación*',
                    colorEmpty: locationController.text.isEmpty
                        ? ColorTheme.error
                        : null,
                    inputType: TextInputType.name,
                  ),
                  const SizedBox(height: CustomSpacer.xlarge),
                  if (!isLoading) ...[
                    ButtonSecondary(
                      fullWidth: true,
                      texto: 'Cancelar',
                      onPressed: () {
                        clearPartnerFields();
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
                                onPressed: _createBPartner,
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
