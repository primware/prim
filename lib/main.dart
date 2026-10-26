import 'dart:io';
import 'package:flutter/foundation.dart';
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
import 'views/Home/product/product_sync_overlay.dart';
import 'views/Home/bpartner/bpartner_sync_overlay.dart';
import 'shared/theme_switcher_controller.dart';
import 'package:upgrader/upgrader.dart';
import 'shared/custom_upgrade_alert.dart';
import 'shared/startup_app.dart';
import 'shared/startup_diagnostics.dart';
import 'shared/local_cache_storage.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final ValueNotifier<ThemeData> appThemeNotifier = ValueNotifier(AppThemes.lightTheme);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final diagnostics = StartupDiagnostics()..start();
  final previousFlutterError = FlutterError.onError;
  FlutterError.onError = (details) {
    diagnostics.record('FLUTTER_ERROR: ${details.exceptionAsString()}\n${details.stack}');
    previousFlutterError?.call(details);
  };
  final dispatcher = WidgetsBinding.instance.platformDispatcher;
  final previousPlatformError = dispatcher.onError;
  dispatcher.onError = (error, stack) {
    diagnostics.record('UNHANDLED_ERROR: $error\n$stack');
    return previousPlatformError?.call(error, stack) ?? false;
  };
  runApp(StartupApp(initialize: _initializeApp, diagnostics: diagnostics));
}

Future<Widget> _initializeApp(StartupDiagnostics diagnostics) async {
  if (!kIsWeb) {
    if (Platform.isWindows || Platform.isMacOS) {
      await diagnostics.optional<void>('protocol.register', () => protocolHandler.register('primware'), null);
    }
    HttpOverrides.global = MyHttpOverrides();
  }

  await diagnostics.run('localization.initialize', FlutterLocalization.instance.ensureInitialized);
  // Repositories initialize lazily: a cache failure must not block the login.
  await diagnostics.optional<void>('user.loadFromCache', UserData.loadFromCache, null);

  final isDarkMode = await diagnostics.optional<bool>('preferences.theme', () async {
    final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 20));
    return prefs.getBool('isDarkMode') ?? false;
  }, false);
  appThemeNotifier.value = isDarkMode ? AppThemes.darkTheme : AppThemes.lightTheme;

  return MainApp(initialIsDarkMode: isDarkMode);
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
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

    _localization.init(mapLocales: [const MapLocale('en', AppLocale.en), const MapLocale('es', AppLocale.es)], initLanguageCode: 'es');
    _localization.onTranslatedLanguage = _onLanguageChanged;

    // Escuchamos el notifier de tema para actualizar el MaterialApp
    // sin recrearlo (así el Navigator no se reinicia).
    appThemeNotifier.addListener(_onThemeChanged);

    _initDeepLinks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Prepare/migrate storage after the login frame, without blocking it.
      unawaited(LocalCacheStorage.instance.initialize().catchError((Object error, StackTrace stack) {
        StartupDiagnostics.active?.record('CACHE_PREPARE_ERROR: $error\n$stack');
      }));
    });
  }

  void _onThemeChanged() => setState(() {});

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
    appThemeNotifier.removeListener(_onThemeChanged);
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _onLanguageChanged(Locale? locale) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CircularRevealOverlay(
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: Base.title,
        theme: appThemeNotifier.value,
        supportedLocales: _localization.supportedLocales,
        localizationsDelegates: _localization.localizationsDelegates,
        locale: _localization.currentLocale,
        home: const LoginPage(),
        builder: (context, child) => CustomUpgradeAlert(
          navigatorKey: navigatorKey,
          upgrader: Upgrader(languageCode: _localization.currentLocale?.languageCode ?? 'es'),
          child: Stack(children: [if (child != null) child, const ProductSyncOverlay(), const BPartnerSyncOverlay()]),
        ),
      ),
    );
  }
}
