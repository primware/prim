import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:primware/API/pos.api.dart';
import 'package:primware/localization/app_locale.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import '../../API/endpoint.dart';
import '../../shared/button.widget.dart';
import '../../shared/custom_checkbox.dart';
import '../../shared/custom_spacer.dart';
import '../../shared/logo.dart';
import '../../shared/custom_textfield.dart';
import '../../shared/toast_message.dart';
import '../../theme/colors.dart';
import 'auth_funtions.dart';
import 'config_view.dart';
import '../../Widgets/GlassDesign.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

TextEditingController usuarioController = TextEditingController();
TextEditingController claveController = TextEditingController();

class _LoginPageState extends State<LoginPage> {
  bool isLoading = false;
  final TextEditingController baseURLController = TextEditingController(), cPosController = TextEditingController();
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
      if (usuario != null) {
        usuarioController.text = usuario;
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
          title: Text(AppLocale.server.getString(context), style: Theme.of(context).textTheme.bodyLarge),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextfieldTheme(texto: 'URL', controlador: baseURLController, pista: 'Ej: https://test.idempiere.org'),
              const SizedBox(height: CustomSpacer.medium),
              TextfieldTheme(texto: 'POS ID', controlador: cPosController, inputFormatters: [FilteringTextInputFormatter.digitsOnly], inputType: TextInputType.number),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.cancel_outlined), color: ColorTheme.error, iconSize: 32),
            IconButton(
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();
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
          title: Text(AppLocale.server.getString(context), style: Theme.of(context).textTheme.titleMedium),
          content: Text(AppLocale.serverSaved.getString(context), style: Theme.of(context).textTheme.bodyLarge),
          actions: [IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.check_circle_outline), color: ColorTheme.success, iconSize: 32)],
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

      Navigator.push(context, MaterialPageRoute(builder: (context) => ConfigPage(clients: authData['clients'])));
    } else {
      ToastMessage.show(context: context, message: AppLocale.invalidCredentials.getString(context), type: ToastType.failure);
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ToastMessage.show(context: context, message: 'No se pudo abrir el navegador.', type: ToastType.failure);
      }
    } catch (e) {
      if (mounted) {
        ToastMessage.show(context: context, message: 'No se pudo abrir el navegador.', type: ToastType.failure);
      }
    }
  }

  void _showLanguageBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.1),

      builder: (BuildContext bc) {
        return GlassContainer(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.5), borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 24),

              Text(AppLocale.lang.getString(context), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),

              // Opciones de idioma
              _buildLanguageOption('es', 'Español'),
              const SizedBox(height: 12),
              _buildLanguageOption('en', 'English'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String code, String name) {
    final isSelected = FlutterLocalization.instance.currentLocale?.languageCode == code;
    final primaryColor = Theme.of(context).primaryColor;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        FlutterLocalization.instance.translate(code);
        if (rememberUser) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('languageCode', code);
        }

        setState(() {});
        if (mounted) Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? primaryColor : Colors.grey.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? primaryColor : Theme.of(context).colorScheme.onSurface),
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: primaryColor),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 750 ? true : false;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        floatingActionButton: FloatingActionButton(
          onPressed: _showBaseURLDialog,
          backgroundColor: Theme.of(context).cardColor.withOpacity(0.9),
          elevation: 4,
          child: Icon(Icons.settings, color: Theme.of(context).primaryColor),
        ),

        body: LiquidBackground(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GlassContainer(
                    width: isMobile ? MediaQuery.of(context).size.width * 0.9 : 500,
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 40, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(child: Logo(width: isMobile ? 200 : 320)),
                        SizedBox(height: CustomSpacer.medium + (!isMobile ? CustomSpacer.xlarge : 10)),

                        TextfieldTheme(icono: Icons.mail_outline, texto: AppLocale.user.getString(context), inputType: TextInputType.emailAddress, controlador: usuarioController),
                        const SizedBox(height: CustomSpacer.small),

                        TextfieldTheme(icono: Icons.lock_outline, texto: AppLocale.pass.getString(context), obscure: true, showSubIcon: true, controlador: claveController, onSubmitted: (_) => _funcionLogin(usuarioController.text.trim(), claveController.text.trim())),
                        const SizedBox(height: CustomSpacer.medium),

                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showLanguageBottomSheet(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.language, color: Theme.of(context).primaryColor),
                                    const SizedBox(width: 12),
                                    Text(FlutterLocalization.instance.currentLocale?.languageCode == 'en' ? 'English 🇺🇸' : 'Español 🇪🇸', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                                  ],
                                ),
                                const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: CustomSpacer.small),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.verified_user_outlined, size: 22, color: rememberUser ? Theme.of(context).primaryColor : Colors.grey.shade600),
                                  const SizedBox(width: 12),
                                  Text(AppLocale.rememberMe.getString(context), style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: rememberUser ? FontWeight.bold : FontWeight.w500)),
                                ],
                              ),
                              GlassSwitch(
                                value: rememberUser,
                                onChanged: (newValue) {
                                  setState(() {
                                    rememberUser = newValue;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: CustomSpacer.medium),

                        Container(
                          child: isLoading
                              ? ButtonLoading(fullWidth: true)
                              : ButtonPrimary(
                                  texto: AppLocale.login.getString(context),
                                  fullWidth: true,
                                  onPressed: () {
                                    _funcionLogin(usuarioController.text.trim(), claveController.text.trim());
                                  },
                                ),
                        ),

                        if (Base.allowCreateAccount) ...[
                          const SizedBox(height: CustomSpacer.medium),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(AppLocale.noAccount.getString(context), style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                                const SizedBox(height: CustomSpacer.small),
                                InkWell(
                                  onTap: () => _openExternal('https://primware.net/register/'),
                                  child: Text(
                                    AppLocale.register.getString(context),
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, decoration: TextDecoration.underline, color: Theme.of(context).primaryColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (version != 'No es web') ...[
                    const SizedBox(height: CustomSpacer.xlarge),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(color: Theme.of(context).cardColor.withOpacity(0.4), borderRadius: BorderRadius.circular(20)),
                      child: Text(version, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
