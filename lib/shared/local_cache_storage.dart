import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'startup_diagnostics.dart';

/// Selects one location for all Hive caches. Preferences stay OS-managed.
class LocalCacheStorage {
  static final LocalCacheStorage instance = LocalCacheStorage();

  Future<void>? _initialization;
  String? directoryPath;

  Future<Box<dynamic>> openBox(String name) async {
    _log('CACHE_OPEN_BEGIN $name');
    try {
      await initialize();
      final box = await Hive.openBox<dynamic>(
        name,
      ).timeout(const Duration(seconds: 30));
      _log('CACHE_OPEN_OK $name');
      return box;
    } catch (error, stack) {
      _log('CACHE_OPEN_ERROR $name: $error\n$stack');
      rethrow;
    }
  }

  Future<void> initialize() =>
      _initialization ??= _initialize().timeout(const Duration(seconds: 30));

  Future<void> _initialize() async {
    if (kIsWeb || !(Platform.isWindows || Platform.isMacOS)) {
      // Preserve existing Android/iOS storage and web IndexedDB behavior.
      await Hive.initFlutter();
      return;
    }
    final directory = await selectDesktopCacheDirectory(
      executable: Platform.resolvedExecutable,
      isMacOS: Platform.isMacOS,
      applicationSupport: getApplicationSupportDirectory,
      log: _log,
    );
    directoryPath = directory.path;
    _log('CACHE_DIRECTORY ${directory.path}');
    await migrateLegacyCaches(
      legacy: await getApplicationDocumentsDirectory(),
      destination: directory,
      log: _log,
    );
    Hive.init(directory.path);
  }

  static void _log(String message) {
    final diagnostics = StartupDiagnostics.active;
    if (diagnostics != null) {
      diagnostics.record(message);
    } else {
      debugPrint(message);
    }
  }
}

/// On macOS use the .app's parent, never modify its signed bundle contents.
String desktopCachePath(
  String executable, {
  required bool isMacOS,
  p.Context? paths,
}) {
  final context = paths ?? p.context;
  var parent = context.dirname(executable);
  if (isMacOS) {
    while (context.dirname(parent) != parent) {
      if (context.basename(parent).endsWith('.app')) {
        parent = context.dirname(parent);
        break;
      }
      parent = context.dirname(parent);
    }
    // Non-bundle executables (for example tests) use their own directory.
    if (context.dirname(parent) == parent) parent = context.dirname(executable);
  }
  return context.join(parent, 'primware-data', 'cache');
}

Future<Directory> selectDesktopCacheDirectory({
  required String executable,
  required bool isMacOS,
  required Future<Directory> Function() applicationSupport,
  required void Function(String) log,
}) async {
  final preferred = Directory(desktopCachePath(executable, isMacOS: isMacOS));
  try {
    await _checkWritable(preferred);
    return preferred;
  } on FileSystemException catch (error) {
    log('CACHE_DIRECTORY_FALLBACK: $error');
    final fallback = Directory(
      p.join((await applicationSupport()).path, 'cache'),
    );
    await _checkWritable(fallback);
    return fallback;
  }
}

Future<void> _checkWritable(Directory directory) async {
  await directory.create(recursive: true);
  final probe = await directory.createTemp('.write-probe-');
  try {
    await File(p.join(probe.path, 'probe')).writeAsString('');
  } finally {
    await probe.delete(recursive: true);
  }
}

/// Copy only known boxes, while holding Hive's lock. Never overwrite a new box
/// or remove legacy data. Rename a completed copy so partial files aren't used.
Future<void> migrateLegacyCaches({
  required Directory legacy,
  required Directory destination,
  required void Function(String) log,
}) async {
  for (final name in [
    'product_cache_v1',
    'order_history_cache_v1',
    'bpartner_cache_v1',
  ]) {
    final source = File(p.join(legacy.path, '$name.hive'));
    final target = File(p.join(destination.path, '$name.hive'));
    if (await target.exists() || !await source.exists()) continue;
    final lock = await File(
      p.join(legacy.path, '$name.lock'),
    ).open(mode: FileMode.append);
    final temporary = File('${target.path}.migrating');
    var locked = false;
    try {
      await lock.lock(FileLock.exclusive);
      locked = true;
      // A second new instance may have migrated while we waited for the lock.
      if (await target.exists()) continue;
      await source.copy(temporary.path);
      await temporary.rename(target.path);
      log('CACHE_MIGRATED $name: ${source.path} -> ${target.path}');
    } finally {
      if (locked) {
        if (await temporary.exists()) await temporary.delete();
        await lock.unlock();
      }
      await lock.close();
    }
  }
}
