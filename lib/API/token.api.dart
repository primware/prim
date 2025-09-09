class Token {
  static String? preAuth;
  static String? auth;
  static String? superAuth;
  static int? client;
  static int? rol;
  static int? organitation;
  static int? warehouseID; //? Estandar

  static String tokenType = 'Bearer';
}

class CurrentLogMessage {
  static List<Map<String, dynamic>> log = [];
  static void add(String message, {String level = 'INFO', String? tag}) {
    final entry = {
      'ts': DateTime.now().toIso8601String(),
      'level': level,
      'tag': tag,
      'message': message,
    };
    log.add(entry);
    print(message);

    if (log.length > 1000) {
      log.removeAt(0);
    }
  }
}
