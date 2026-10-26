import 'package:flutter/material.dart';
import '../localization/app_locale.dart';
import '../theme/theme_material.dart';
import 'startup_diagnostics.dart';

/// Shows a first frame before plugins and local storage are initialized.
class StartupApp extends StatefulWidget {
  const StartupApp({
    super.key,
    required this.initialize,
    required this.diagnostics,
  });
  final Future<Widget> Function(StartupDiagnostics diagnostics) initialize;
  final StartupDiagnostics diagnostics;

  @override
  State<StartupApp> createState() => _StartupAppState();
}

class _StartupAppState extends State<StartupApp> {
  Widget? _app;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    try {
      final app = await widget.initialize(widget.diagnostics);
      if (!mounted) return;
      setState(() => _app = app);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.diagnostics.record('APP_FRAME');
      });
    } catch (error, stack) {
      widget.diagnostics.record(
        'STARTUP_FAILED (${widget.diagnostics.stage}): $error\n$stack',
      );
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_app != null) return _app!;
    // Localization itself may fail: this screen must not depend on that plugin.
    final strings =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'en'
        ? AppLocale.en
        : AppLocale.es;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: MaterialTheme.lightScheme(),
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Primware',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 24),
                      if (!_failed) ...[
                        const LinearProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(strings[AppLocale.startupLoading] as String),
                      ] else ...[
                        Text(strings[AppLocale.startupFailed] as String),
                        const SizedBox(height: 16),
                        Text(strings[AppLocale.startupHelp] as String),
                        if (widget.diagnostics.logPath != null) ...[
                          const SizedBox(height: 16),
                          Text(strings[AppLocale.startupLog] as String),
                          SelectableText(widget.diagnostics.logPath!),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
