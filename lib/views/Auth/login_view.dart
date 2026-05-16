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
    return showGeneralDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack).value,
          child: Opacity(opacity: anim1.value, child: child),
        );
      },
      pageBuilder: (BuildContext context, _, __) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: GlassContainer(
            padding: const EdgeInsets.all(24),
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppLocale.server.getString(context), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
                const SizedBox(height: CustomSpacer.large),
                GlassTextField(label: 'URL', controller: baseURLController, hint: 'Ej: https://test.idempiere.org', icon: Icons.link),
                const SizedBox(height: CustomSpacer.medium),
                GlassTextField(label: 'POS ID', controller: cPosController, inputFormatters: [FilteringTextInputFormatter.digitsOnly], keyboardType: TextInputType.number, icon: Icons.point_of_sale),
                const SizedBox(height: CustomSpacer.large),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GlassPressable(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: ColorTheme.error.withOpacity(0.15), shape: BoxShape.circle),
                        child: const Icon(Icons.cancel_outlined, color: ColorTheme.error, size: 32),
                      ),
                    ),
                    GlassPressable(
                      onTap: () async {
                        SharedPreferences prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        _saveConfig();
                        if (!mounted) return;
                        Navigator.of(context).pop();
                        _resetDialog();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: ColorTheme.success.withOpacity(0.15), shape: BoxShape.circle),
                        child: const Icon(Icons.check_circle_outline, color: ColorTheme.success, size: 32),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _resetDialog() async {
    return showGeneralDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack).value,
          child: Opacity(opacity: anim1.value, child: child),
        );
      },
      pageBuilder: (BuildContext context, _, __) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: GlassContainer(
            padding: const EdgeInsets.all(24),
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, color: ColorTheme.success, size: 64),
                const SizedBox(height: CustomSpacer.medium),
                Text(AppLocale.server.getString(context), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
                const SizedBox(height: CustomSpacer.small),
                Text(AppLocale.serverSaved.getString(context), style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87), textAlign: TextAlign.center),
                const SizedBox(height: CustomSpacer.large),
                GlassPressable(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    decoration: BoxDecoration(color: ColorTheme.success.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                    child: const Text('OK', style: TextStyle(color: ColorTheme.success, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
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


  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 750 ? true : false;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        floatingActionButton: GlassPressable(
          onTap: _showBaseURLDialog,
          child: GlassContainer(
            padding: const EdgeInsets.all(14),
            borderRadius: BorderRadius.circular(20),
            hasShadow: false,
            child: Icon(Icons.settings, color: Theme.of(context).primaryColor, size: 28),
          ),
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

                        GlassDropdown<String>(
                          label: AppLocale.lang.getString(context),
                          icon: Icons.language,
                          currentValue: FlutterLocalization.instance.currentLocale?.languageCode == 'en' ? 'English 🇺🇸' : 'Español 🇪🇸',
                          items: [
                            GlassDropdownItem(value: 'es', text: 'Español 🇪🇸'),
                            GlassDropdownItem(value: 'en', text: 'English 🇺🇸'),
                          ],
                          onChanged: (code) async {
                            FlutterLocalization.instance.translate(code);
                            if (rememberUser) {
                              SharedPreferences prefs = await SharedPreferences.getInstance();
                              await prefs.setString('languageCode', code);
                            }
                            setState(() {});
                          },
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
