import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Records startup independently of preferences, Hive and localization.
class StartupDiagnostics {
  static StartupDiagnostics? active;
  StartupDiagnostics({this.stageTimeout = const Duration(seconds: 30)});

  final Duration stageTimeout;
  String stage = 'startup';
  File? _file;
  String? get logPath => _file?.path;

  void start() {
    active = this;
    if (!kIsWeb) {
      try {
        final file = File(
          '${Directory.systemTemp.path}${Platform.pathSeparator}primware-startup.log',
        );
        if (file.existsSync() && file.lengthSync() > 1024 * 1024) {
          file.copySync('${file.path}.previous');
          file.writeAsStringSync('');
        }
        file.writeAsStringSync('\n', mode: FileMode.append);
        _file = file;
      } catch (_) {
        // Logging must never prevent startup or the error screen opening.
      }
    }
    record('START');
  }

  void record(String message) {
    final line = '${DateTime.now().toIso8601String()} $message';
    debugPrint(line);
    try {
      _file?.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
    } catch (_) {
      _file = null;
    }
  }

  Future<T> run<T>(String name, FutureOr<T> Function() action) async {
    stage = name;
    record('BEGIN $name');
    try {
      final result = await Future<T>.sync(action).timeout(stageTimeout);
      record('OK $name');
      return result;
    } catch (error, stack) {
      record('ERROR $name: $error\n$stack');
      rethrow;
    }
  }

  /// Nonessential startup work must not prevent the login from appearing.
  Future<T> optional<T>(
    String name,
    FutureOr<T> Function() action,
    T fallback,
  ) async {
    try {
      return await run(name, action);
    } catch (_) {
      record('CONTINUE_WITHOUT $name');
      return fallback;
    }
  }
}
