import 'package:flutter/material.dart';
import 'package:primware/theme/fonts.dart';
import 'package:primware/views/register/register_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/colors.dart';
import '../../shared/button.widget.dart';
import '../../shared/custom_checkbox.dart';
import '../../shared/custom_container.dart';
import '../../shared/custom_spacer.dart';
import '../../shared/logo.dart';
import '../../shared/message.custom.dart';
import '../../shared/textfield.widget.dart';
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

  bool rememberUser = false;
  String version = '';
  @override
  void initState() {
    super.initState();

    _loadRememberedUser();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    String checkVersion = await fetchAppVersion();
    setState(() {
      version = checkVersion;
    });
  }

  Future<void> _loadRememberedUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? remember = prefs.getBool('rememberUser');
    if (remember != null && remember) {
      String? usuario = prefs.getString('usuario');
      String? clave = prefs.getString('clave');

      if (usuario != null && clave != null) {
        usuarioController.text = usuario;
        claveController.text = clave;
        setState(() {
          rememberUser = true;
        });
      }
    }
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
      SnackMessage.show(
        context: context,
        message: "Credenciales incorrectas",
        type: SnackType.failure,
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool mobile = MediaQuery.of(context).size.width < 750 ? true : false;
    final double maxWidthContainer = mobile ? 360 : 400;

    return Scaffold(
      backgroundColor: ColorTheme.backgroundLight,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Logo(
                  width: 320,
                ),
                const SizedBox(
                    height: CustomSpacer.xlarge + CustomSpacer.medium),
                CustomContainer(
                  maxWidthContainer: maxWidthContainer,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextfieldTheme(
                        icono: Icons.mail_outline,
                        texto: 'Usuario',
                        inputType: TextInputType.emailAddress,
                        controlador: usuarioController,
                      ),
                      const SizedBox(height: CustomSpacer.small),
                      TextfieldTheme(
                        icono: Icons.lock_outline,
                        texto: 'Contraseña',
                        obscure: true,
                        showSubIcon: true,
                        controlador: claveController,
                        onSubmitted: (_) => _funcionLogin(
                            usuarioController.text.trim(),
                            claveController.text.trim()),
                      ),
                      const SizedBox(height: CustomSpacer.small),
                      CustomCheckbox(
                        value: rememberUser,
                        text: 'Recordar usuario',
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
                                bgcolor: ColorTheme.aL700,
                                textcolor: ColorTheme.textDark,
                              )
                            : ButtonPrimary(
                                texto: 'Iniciar sesión',
                                fullWidth: true,
                                bgcolor: ColorTheme.accentLight,
                                textcolor: ColorTheme.textDark,
                                onPressed: () {
                                  _funcionLogin(usuarioController.text.trim(),
                                      claveController.text.trim());
                                },
                              ),
                      ),
                      const SizedBox(height: CustomSpacer.medium),
                      ButtonSecondary(
                        texto: 'Crear cuenta',
                        bgcolor: ColorTheme.textDark,
                        borderColor: ColorTheme.accentLight,
                        textcolor: ColorTheme.accentLight,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegisterUser(),
                          ),
                        ),
                        fullWidth: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                    height: CustomSpacer.xlarge + CustomSpacer.medium),
                Text(
                  version,
                  style: FontsTheme.pMini(),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
