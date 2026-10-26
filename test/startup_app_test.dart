import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:primware/shared/startup_app.dart';
import 'package:primware/shared/startup_diagnostics.dart';

class RecordingDiagnostics extends StartupDiagnostics {
  final List<String> messages = [];

  @override
  void record(String message) => messages.add(message);
}

void main() {
  test('optional user cache failure allows startup to continue', () async {
    final diagnostics = RecordingDiagnostics();
    final result = await diagnostics.optional<bool>(
      'user.loadFromCache',
      () => throw const FormatException('invalid cache'),
      false,
    );
    expect(result, isFalse);
    expect(diagnostics.messages.last, 'CONTINUE_WITHOUT user.loadFromCache');
    expect(await diagnostics.run('next stage', () => true), isTrue);
  });

  testWidgets('optional timeout still opens login without waiting for cache', (
    tester,
  ) async {
    final diagnostics = RecordingDiagnostics();
    final pending = Completer<void>();
    await tester.pumpWidget(
      StartupApp(
        diagnostics: diagnostics,
        initialize: (diagnostics) async {
          await diagnostics.optional<void>(
            'user.loadFromCache',
            () => pending.future,
            null,
          );
          return const MaterialApp(home: Text('Login ready'));
        },
      ),
    );
    await tester.pump(const Duration(seconds: 31));
    await tester.pumpAndSettle();
    expect(find.text('Login ready'), findsOneWidget);
    pending.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  test(
    'records the failed stage and stack without running subsequent stages',
    () async {
      final diagnostics = RecordingDiagnostics();
      var laterStageRan = false;
      Future<void> initialize() async {
        await diagnostics.run<void>(
          'cache.products',
          () => throw StateError('cache unavailable'),
        );
        await diagnostics.run('user.loadFromCache', () => laterStageRan = true);
      }

      await expectLater(initialize(), throwsStateError);
      expect(diagnostics.stage, 'cache.products');
      expect(diagnostics.messages.last, contains('ERROR cache.products:'));
      expect(diagnostics.messages.last, contains('startup_app_test.dart'));
      expect(laterStageRan, isFalse);
    },
  );

  testWidgets(
    'renders loading before initialization and then the application',
    (tester) async {
      final diagnostics = RecordingDiagnostics();
      final ready = Completer<Widget>();
      await tester.pumpWidget(
        StartupApp(diagnostics: diagnostics, initialize: (_) => ready.future),
      );
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      ready.complete(const MaterialApp(home: Text('Login ready')));
      await tester.pumpAndSettle();
      expect(find.text('Login ready'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(diagnostics.messages, contains('APP_FRAME'));
    },
  );

  testWidgets(
    'failed storage shows help even without initialized localization',
    (tester) async {
      final diagnostics = RecordingDiagnostics();
      await tester.pumpWidget(
        StartupApp(
          diagnostics: diagnostics,
          initialize: (diagnostics) async {
            await diagnostics.run<void>(
              'cache.products',
              () => throw StateError('cache unavailable'),
            );
            return const SizedBox();
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.textContaining('could not finish'), findsOneWidget);
      expect(find.textContaining('has not been deleted'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'timeout stays failed even if the pending operation later completes',
    (tester) async {
      final diagnostics = RecordingDiagnostics();
      final cache = Completer<void>();
      var laterStageRan = false;
      await tester.pumpWidget(
        StartupApp(
          diagnostics: diagnostics,
          initialize: (diagnostics) async {
            await diagnostics.run('cache.products', () => cache.future);
            laterStageRan = true;
            return const MaterialApp(home: Text('Login ready'));
          },
        ),
      );
      await tester.pump(const Duration(seconds: 31));
      await tester.pumpAndSettle();
      expect(find.textContaining('could not finish'), findsOneWidget);
      expect(
        diagnostics.messages.any((line) => line.contains('TimeoutException')),
        isTrue,
      );
      cache.complete();
      await tester.pumpAndSettle();
      expect(laterStageRan, isFalse);
      expect(find.text('Login ready'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
