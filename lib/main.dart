// main.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:primware/views/Auth/login_view.dart';
import 'package:primware/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'API/endpoint.api.dart';

//TODO crear un registro Bancos/Cajas de Caja, y actualizar el esquema contable en dias de historia 360 al momento de crear la empresa
//TODO crear tercero por defecto de cliente externo, con su  direccion
//TODO agregar lista de precios M_PriceList que sea de venta
//TODO agregar el acceso a ventana al usuario a la ventana de tasa de impuesto
//TODO agregar el acceso a ventana categoria de producto
//TODO agregar el acceso a ventana categoria de impuesto
//TODO crear un rol maestro para tener todos los permisos y no tener que ir uno por uno

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MainApp());
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class ThemeManager {
  static late _MainAppState themeNotifier;
}

class _MainAppState extends State<MainApp> {
  bool _isDarkMode = false;

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = !_isDarkMode;
      prefs.setBool('isDarkMode', _isDarkMode);
    });
  }

  @override
  void initState() {
    super.initState();
    ThemeManager.themeNotifier = this;
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: Base.title,
      theme: _isDarkMode ? AppThemes.darkTheme : AppThemes.lightTheme,
      home: const LoginPage(),
    );
  }
}
