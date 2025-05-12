class Token {
  static String? preAuth;
  static String? auth;
  static String? superAuth;
  static int? client;
  static int? rol;
  static int? organitation;
  static int? warehouseID; //? Estandar
  // static int? cDocTypeTargetID = 1000139; //? POS Order

  static String tokenType = 'Bearer';
  static String? tokenSystem =
      'eyJraWQiOiJpZGVtcGllcmUiLCJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJTdXBlclVzZXIiLCJBRF9MYW5ndWFnZSI6ImVzX1BBIiwiQURfU2Vzc2lvbl9JRCI6MTAwMDc2MSwiQURfVXNlcl9JRCI6MTAwLCJBRF9Sb2xlX0lEIjoxMDAwMDEwLCJBRF9PcmdfSUQiOjAsImlzcyI6ImlkZW1waWVyZS5vcmciLCJBRF9DbGllbnRfSUQiOjB9.42CRffm69T0JOZz4Kw_uYNmWEuJUBa1MKHJrSu2IU_MgCY4LsyYDrX-utbtqsNOM06Rwb8-tQJHQaFt27tmH6g';

  static String tokenRegister = '$tokenType $tokenSystem';
}
