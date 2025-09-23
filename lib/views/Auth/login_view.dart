import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/API/pos.api.dart';
import 'package:primware/localization/app_locale.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../API/endpoint.api.dart';
import '../../shared/button.widget.dart';
import '../../shared/custom_checkbox.dart';
import '../../shared/custom_container.dart';
import '../../shared/custom_dropdown.dart';
import '../../shared/custom_spacer.dart';
import '../../shared/logo.dart';
import '../../shared/custom_textfield.dart';
import '../../shared/toast_message.dart';
import '../../theme/colors.dart';
import 'auth_funtions.dart';
import 'config_view.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

TextEditingController usuarioController = TextEditingController();
TextEditingController claveController = TextEditingController();

class _LoginPageState extends State<LoginPage> {
  bool isLoading = false;
  final TextEditingController baseURLController = TextEditingController(),
      cPosController = TextEditingController();
  bool rememberUser = false;
  String version = '';

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _loadRememberedUser();
    _loadSavedLanguage();
    _checkVersion();
  }

  Future<void> _loadRememberedUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? remember = prefs.getBool('rememberUser');
    if (remember != null && remember) {
      String? usuario = prefs.getString('usuario');
      // String? clave = prefs.getString('clave');

      if (usuario != null) {
        usuarioController.text = usuario;
        // claveController.text = clave;
        setState(() {
          rememberUser = true;
        });
      }
    }
  }

  Future<void> _loadSavedLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('rememberUser') ?? false) {
      String? lang = prefs.getString('languageCode');
      if (lang != null) {
        FlutterLocalization.instance.translate(lang);
      }
    }
  }

  Future<void> _checkVersion() async {
    String checkVersion = await fetchAppVersion();
    setState(() {
      version = checkVersion;
    });
  }

  Future<void> _saveConfig() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String baseURL = baseURLController.text.trim();
    String cPosID = cPosController.text.trim();
    await prefs.setString('baseURL', baseURL);
    await prefs.setString('cPosID', cPosID);
    Base.baseURL = baseURL;
    POS.cPosID = int.tryParse(cPosID);
  }

  Future<void> _loadConfig() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? baseURL = prefs.getString('baseURL') ?? 'https://fe.primware.net';

    String? cPosID = prefs.getString('cPosID');

    setState(() {
      baseURLController.text = baseURL;
      cPosController.text = cPosID ?? '';
      Base.baseURL = baseURL;
      POS.cPosID = int.tryParse(cPosController.text);
    });
  }

  Future<void> _showBaseURLDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            AppLocale.server.getString(context),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextfieldTheme(
                texto: 'URL',
                controlador: baseURLController,
                pista: 'Ej: https://test.idempiere.org',
              ),
              const SizedBox(height: CustomSpacer.medium),
              TextfieldTheme(
                texto: 'POS ID',
                controlador: cPosController,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                inputType: TextInputType.number,
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.cancel_outlined),
              color: ColorTheme.error,
              iconSize: 32,
            ),
            IconButton(
              onPressed: () {
                _saveConfig();
                Navigator.of(context).pop();
                _resetDialog();
              },
              icon: const Icon(Icons.check_circle_outline),
              color: ColorTheme.success,
              iconSize: 32,
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            AppLocale.server.getString(context),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          content: Text(
            AppLocale.serverSaved.getString(context),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.check_circle_outline),
              color: ColorTheme.success,
              iconSize: 32,
            ),
          ],
        );
      },
    );
  }

  Future<void> _funcionLogin(String usuario, String clave) async {
    setState(() {
      isLoading = true;
    });

    final authData = await preAuth(usuario, clave, context);
    if (authData != null) {
      if (rememberUser) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('usuario', usuario);
        await prefs.setString('clave', clave);
        await prefs.setBool('rememberUser', true);
      } else {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('usuario');
        await prefs.remove('clave');
        await prefs.setBool('rememberUser', false);
      }
      _saveConfig();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConfigPage(
            clients: authData['clients'],
          ),
        ),
      );
      // }
    } else {
      ToastMessage.show(
        context: context,
        message: AppLocale.invalidCredentials.getString(context),
        type: ToastType.failure,
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile =
        MediaQuery.of(context).size.width < 750 ? true : false;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: _showBaseURLDialog,
          child: Icon(Icons.settings),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomContainer(
                  maxWidthContainer: isMobile ? 420 : 500,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Logo(
                          width: isMobile ? 200 : 320,
                        ),
                      ),
                      SizedBox(
                          height: CustomSpacer.medium +
                              (!isMobile ? CustomSpacer.xlarge : 10)),
                      TextfieldTheme(
                        icono: Icons.mail_outline,
                        texto: AppLocale.user.getString(context),
                        inputType: TextInputType.emailAddress,
                        controlador: usuarioController,
                      ),
                      const SizedBox(height: CustomSpacer.small),
                      TextfieldTheme(
                        icono: Icons.lock_outline,
                        texto: AppLocale.pass.getString(context),
                        obscure: true,
                        showSubIcon: true,
                        controlador: claveController,
                        onSubmitted: (_) => _funcionLogin(
                            usuarioController.text.trim(),
                            claveController.text.trim()),
                      ),
                      const SizedBox(height: CustomSpacer.medium),
                      SearchableDropdown<String>(
                        value: FlutterLocalization
                            .instance.currentLocale?.languageCode,
                        onChanged: (String? lang) async {
                          if (lang != null) {
                            FlutterLocalization.instance.translate(lang);
                            if (rememberUser) {
                              SharedPreferences prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setString('languageCode', lang);
                            }
                          }
                        },
                        labelText: AppLocale.lang.getString(context),
                        showSearchBox: false,
                        options: [
                          {'id': 'es', 'name': 'Español'},
                          {'id': 'en', 'name': 'English'},
                        ],
                      ),
                      const SizedBox(height: CustomSpacer.small),
                      CustomCheckbox(
                        value: rememberUser,
                        text: AppLocale.rememberMe.getString(context),
                        onChanged: (newValue) {
                          setState(() {
                            rememberUser = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: CustomSpacer.xlarge),
                      Container(
                        child: isLoading
                            ? ButtonLoading(
                                fullWidth: true,
                              )
                            : ButtonPrimary(
                                texto: AppLocale.login.getString(context),
                                fullWidth: true,
                                onPressed: () {
                                  _funcionLogin(usuarioController.text.trim(),
                                      claveController.text.trim());
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                if (version != 'No es web') ...[
                  const SizedBox(
                      height: CustomSpacer.xlarge + CustomSpacer.medium),
                  Text(
                    version,
                    style: Theme.of(context).textTheme.labelMedium,
                  )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
