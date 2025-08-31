// main.dart

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/views/Auth/login_view.dart';
import 'package:primware/theme/theme.dart';
import 'package:primware/localization/app_locale.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'API/endpoint.api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // HttpOverrides.global = MyHttpOverrides();
  await FlutterLocalization.instance.ensureInitialized();
  runApp(const MainApp());
}

// class MyHttpOverrides extends HttpOverrides {
//   @override
//   HttpClient createHttpClient(SecurityContext? context) {
//     return super.createHttpClient(context)
//       ..badCertificateCallback =
//           (X509Certificate cert, String host, int port) => true;
//   }
// }

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
  final FlutterLocalization _localization = FlutterLocalization.instance;

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

    _localization.init(
      mapLocales: [
        const MapLocale('en', AppLocale.en),
        const MapLocale('es', AppLocale.es),
      ],
      initLanguageCode: 'es',
    );
    _localization.onTranslatedLanguage = _onLanguageChanged;
  }

  void _onLanguageChanged(Locale? locale) {
    setState(() {});
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
      supportedLocales: _localization.supportedLocales,
      localizationsDelegates: _localization.localizationsDelegates,
      locale: _localization.currentLocale,
      home: const LoginPage(),
    );
  }
}
