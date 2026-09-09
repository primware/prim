import 'dart:io';

Future<int?> productCacheFileSize(String? path) async {
  if (path == null || path.isEmpty) return null;
  final file = File(path);
  if (!await file.exists()) return 0;
  return file.length();
}
