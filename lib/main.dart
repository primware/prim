// main.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/views/Auth/login_view.dart';
import 'package:primware/theme/theme.dart';
import 'package:primware/localization/app_locale.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'API/endpoint.dart';
import 'package:app_links/app_links.dart';
import 'package:protocol_handler/protocol_handler.dart';
import 'dart:async';
import 'views/Home/product/product_repository.dart';
import 'views/Home/product/product_sync_overlay.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isMacOS) {
    await protocolHandler.register('primware');
  }

  HttpOverrides.global = MyHttpOverrides();
  await FlutterLocalization.instance.ensureInitialized();
  await ProductRepository.instance.initialize();
  runApp(const MainApp());
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
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
  final FlutterLocalization _localization = FlutterLocalization.instance;

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

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

    _localization.init(mapLocales: [const MapLocale('en', AppLocale.en), const MapLocale('es', AppLocale.es)], initLanguageCode: 'es');
    _localization.onTranslatedLanguage = _onLanguageChanged;

    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint("Error getting initial link: $e");
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri? uri) {
        if (uri != null) {
          _handleDeepLink(uri);
        }
      },
      onError: (err) {
        debugPrint("Error listening to link: $err");
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'primware' && uri.host == 'login') {
      navigatorKey.currentState?.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
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
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: Base.title,
      theme: _isDarkMode ? AppThemes.darkTheme : AppThemes.lightTheme,
      supportedLocales: _localization.supportedLocales,
      localizationsDelegates: _localization.localizationsDelegates,
      locale: _localization.currentLocale,
      home: const LoginPage(),
      builder: (context, child) => Stack(children: [if (child != null) child, const ProductSyncOverlay()]),
    );
  }
}
