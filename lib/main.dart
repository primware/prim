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
import 'package:primware/API/user.api.dart';
import 'views/Home/product/product_repository.dart';
import 'views/Home/product/product_sync_overlay.dart';
import 'views/Home/order/order_history_repository.dart';
import 'views/Home/bpartner/bpartner_repository.dart';
import 'views/Home/bpartner/bpartner_sync_overlay.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isMacOS) {
    await protocolHandler.register('primware');
  }

  HttpOverrides.global = MyHttpOverrides();
  await FlutterLocalization.instance.ensureInitialized();
  await ProductRepository.instance.initialize();
  await OrderHistoryRepository.instance.initialize();
  await BPartnerRepository.instance.initialize();
  
  await UserData.loadFromCache();
  
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;
  
  runApp(MainApp(initialIsDarkMode: isDarkMode));
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
  final bool initialIsDarkMode;
  const MainApp({super.key, required this.initialIsDarkMode});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final FlutterLocalization _localization = FlutterLocalization.instance;

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();

    _localization.init(
      mapLocales: [
        const MapLocale('en', AppLocale.en),
        const MapLocale('es', AppLocale.es),
      ],
      initLanguageCode: 'es',
    );
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
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: Base.title,
      // Pass the initial theme statically; ThemeProvider will override it below.
      theme: widget.initialIsDarkMode ? AppThemes.darkTheme : AppThemes.lightTheme,
      supportedLocales: _localization.supportedLocales,
      localizationsDelegates: _localization.localizationsDelegates,
      locale: _localization.currentLocale,
      home: const LoginPage(),
      builder: (context, child) => ThemeProvider(
        initTheme: widget.initialIsDarkMode ? AppThemes.darkTheme : AppThemes.lightTheme,
        builder: (context, myTheme) {
          return Theme(
            data: myTheme,
            child: Stack(
              children: [
                if (child != null) child,
                const ProductSyncOverlay(),
                const BPartnerSyncOverlay(),
              ],
            ),
          );
        },
      ),
    );
  }
}
