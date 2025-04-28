import 'package:flutter/material.dart';
import 'package:primware/views/Auth/login_view.dart';
import '../../../shared/textfield.widget.dart';
import '../../../theme/colors.dart';
import '../../../theme/fonts.dart';
import '../../shared/button.widget.dart';
import '../../shared/custom_dropdown.dart';
import '../../shared/custom_spacer.dart';
import '../../shared/loading_container.dart';
import 'register_controller.dart';
import 'register_funtions.dart';

class RegisterUser extends StatefulWidget {
  const RegisterUser({super.key});

  @override
  State<RegisterUser> createState() => _RegisterUserState();
}

class _RegisterUserState extends State<RegisterUser> {
  bool isLoading = true;
  bool isValid = false;

  List<Map<String, dynamic>> currencyOptions = [];
  List<Map<String, dynamic>> countryOptions = [];

  int? selectedCurrencyID, selectedCountryID;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOptions();
      _validateForm();
    });
    clientNameController.addListener(_validateForm);
    adminUserEmailController.addListener(_validateForm);
  }

  Future<void> _loadOptions() async {
    setState(() {
      isLoading = true;
    });
    final currency = await fetchCurrency();
    setState(() {
      currencyOptions = currency;
    });

    final country = await fetchCountry();
    setState(() {
      countryOptions = country;
    });
    setState(() {
      isLoading = false;
    });
  }

  bool isValidEmail(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  void _validateForm() {
    setState(() {
      isValid = clientNameController.text.isNotEmpty &&
          isValidEmail(adminUserEmailController.text) &&
          selectedCountryID != null &&
          selectedCurrencyID != null;
    });
  }

  Future<void> _funcionRegister() async {
    setState(() {
      isLoading = true;
    });
    Map<String, dynamic> result = await postNewTenant(
      clientName: clientNameController.text,
      orgValue: clientNameController.text.toLowerCase().trim(),
      orgName: clientNameController.text.toLowerCase().trim(),
      adminUserName: '${clientNameController.text.toLowerCase().trim()}Admin',
      adminUserEmail: adminUserEmailController.text,
      normalUserName: '${clientNameController.text.toLowerCase().trim()}User',
      currencyID: selectedCurrencyID!,
      countryID: selectedCountryID!,
    );

    if (result['isError'] == false) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Creacion de empresa exitosa'),
          content: Text(
              'Puede iniciar sesion con el usuario: ${clientNameController.text.toLowerCase().trim()}Admin y clave: ${clientNameController.text.toLowerCase().trim()}Admin \nEl usuario y clave son sensibles a mayusculas y minusculas\nRecuerde cambiar la clave al iniciar sesion'),
          actions: [
            TextButton(
              onPressed: () {
                usuarioController.text =
                    '${clientNameController.text.toLowerCase().trim()}Admin';
                claveController.text =
                    '${clientNameController.text.toLowerCase().trim()}Admin';
                clearTextFields();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginPage(),
                  ),
                );
              },
              child: Text('Iniciar sesion'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text(result['summary'].toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: ColorTheme.backgroundLight,
        body: Stack(children: [
          SingleChildScrollView(
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                constraints: const BoxConstraints(
                  maxWidth: 800,
                ),
                child: Column(
                  children: [
                    Text('Crear Empresa',
                        style: FontsTheme.h2Bold(
                          color: ColorTheme.accentLight,
                        )),
                    const SizedBox(height: CustomSpacer.medium),
                    TextfieldTheme(
                      texto: 'Nombre de la empresa',
                      controlador: clientNameController,
                      colorEmpty: clientNameController.text.isEmpty
                          ? ColorTheme.error
                          : null,
                      inputType: TextInputType.name,
                      onChanged: (p0) => _validateForm(),
                    ),
                    const SizedBox(height: CustomSpacer.medium),
                    TextfieldTheme(
                      texto: 'Correo del usuario administrador',
                      controlador: adminUserEmailController,
                      colorEmpty: !isValidEmail(adminUserEmailController.text)
                          ? ColorTheme.error
                          : null,
                      inputType: TextInputType.emailAddress,
                      onChanged: (p0) => _validateForm(),
                    ),
                    const SizedBox(height: CustomSpacer.medium),
                    SearchableDropdown<int>(
                      value: selectedCurrencyID,
                      options: currencyOptions,
                      labelText: 'Moneda',
                      onChanged: (value) {
                        setState(() {
                          selectedCurrencyID = value;
                          _validateForm();
                        });
                      },
                    ),
                    const SizedBox(height: CustomSpacer.medium),
                    SearchableDropdown<int>(
                      value: selectedCountryID,
                      options: countryOptions,
                      labelText: 'País',
                      onChanged: (value) {
                        setState(() {
                          selectedCountryID = value;
                          _validateForm();
                        });
                      },
                    ),
                    const SizedBox(
                        height: CustomSpacer.medium + CustomSpacer.xlarge),
                    Container(
                      child: isValid
                          ? isLoading
                              ? ButtonLoading(
                                  bgcolor: ColorTheme.aL700,
                                  textcolor: ColorTheme.textDark,
                                )
                              : ButtonPrimary(
                                  texto: 'Crear Empresa',
                                  fullWidth: true,
                                  bgcolor: ColorTheme.aL700,
                                  textcolor: ColorTheme.textDark,
                                  onPressed: _funcionRegister,
                                )
                          : Center(
                              child: Text(
                                'Completa todos los campos para registrar',
                                style:
                                    FontsTheme.h5Bold(color: ColorTheme.error),
                              ),
                            ),
                    ),
                    const SizedBox(height: CustomSpacer.medium),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Ya tengo cuenta',
                          style: FontsTheme.p(),
                        ),
                        Text(
                          ' - ',
                          style: FontsTheme.p(),
                        ),
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginPage(),
                            ),
                          ),
                          child: Text(
                            'Iniciar sesión',
                            style:
                                FontsTheme.pBold(color: ColorTheme.textLight),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isLoading) LoadingContainer(),
        ]));
  }
}
