import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:primware/shared/local_cache_storage.dart';

void main() {
  test('Windows path follows executable, not the working directory', () {
    expect(
      desktopCachePath(
        r'C:\primpos\primware.exe',
        isMacOS: false,
        paths: p.Context(style: p.Style.windows),
      ),
      r'C:\primpos\primware-data\cache',
    );
  });

  test('macOS path is outside the signed app bundle', () {
    expect(
      desktopCachePath(
        '/Applications/primware.app/Contents/MacOS/primware',
        isMacOS: true,
        paths: p.Context(style: p.Style.posix),
      ),
      '/Applications/primware-data/cache',
    );
    expect(
      desktopCachePath(
        '/tmp/build/primware',
        isMacOS: true,
        paths: p.Context(style: p.Style.posix),
      ),
      '/tmp/build/primware-data/cache',
    );
  });

  group('desktop filesystem', () {
    late Directory root;
    setUp(
      () async => root = await Directory.systemTemp.createTemp(
        'primware-storage-test-',
      ),
    );
    tearDown(() async {
      await Hive.close();
      await root.delete(recursive: true);
    });

    test(
      'creates a writable installation folder without consulting fallback',
      () async {
        final result = await selectDesktopCacheDirectory(
          executable: p.join(root.path, 'primware.exe'),
          isMacOS: false,
          applicationSupport: () => throw StateError('fallback should not run'),
          log: (_) {},
        );
        expect(result.path, p.join(root.path, 'primware-data', 'cache'));
        expect(await result.list().toList(), isEmpty);
      },
    );

    test(
      'unwritable installation uses private application support storage',
      () async {
        await File(
          p.join(root.path, 'primware-data'),
        ).writeAsString('blocked directory');
        final messages = <String>[];
        final result = await selectDesktopCacheDirectory(
          executable: p.join(root.path, 'primware.exe'),
          isMacOS: false,
          applicationSupport: () async =>
              Directory(p.join(root.path, 'support')),
          log: messages.add,
        );
        expect(result.path, p.join(root.path, 'support', 'cache'));
        expect(messages.single, contains('CACHE_DIRECTORY_FALLBACK'));
      },
    );

    test('migrates a real Hive box while preserving original data', () async {
      final legacy = await Directory(p.join(root.path, 'documents')).create();
      final destination = await Directory(
        p.join(root.path, 'new-cache'),
      ).create();
      Hive.init(legacy.path);
      final oldBox = await Hive.openBox<dynamic>('product_cache_v1');
      await oldBox.put('item', {'id': 42, 'name': 'Producto'});
      await oldBox.close();
      final original = File(p.join(legacy.path, 'product_cache_v1.hive'));
      final bytes = await original.readAsBytes();
      await migrateLegacyCaches(
        legacy: legacy,
        destination: destination,
        log: (_) {},
      );
      expect(await original.readAsBytes(), bytes);
      Hive.init(destination.path);
      final copied = await Hive.openBox<dynamic>('product_cache_v1');
      expect(copied.get('item'), {'id': 42, 'name': 'Producto'});
      expect(
        await File(
          p.join(destination.path, 'product_cache_v1.hive.migrating'),
        ).exists(),
        isFalse,
      );
    });

    test(
      'never overwrites a destination box or copies unrelated documents',
      () async {
        final legacy = await Directory(p.join(root.path, 'documents')).create();
        final destination = await Directory(
          p.join(root.path, 'new-cache'),
        ).create();
        await File(
          p.join(legacy.path, 'product_cache_v1.hive'),
        ).writeAsString('old cache');
        await File(p.join(legacy.path, 'other.txt')).writeAsString('unrelated');
        final target = File(p.join(destination.path, 'product_cache_v1.hive'));
        await target.writeAsString('new cache');
        await migrateLegacyCaches(
          legacy: legacy,
          destination: destination,
          log: (_) {},
        );
        expect(await target.readAsString(), 'new cache');
        expect(await destination.list().length, 1);
      },
    );
  });
}
