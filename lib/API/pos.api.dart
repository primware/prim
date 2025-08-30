class POS {
  static int? priceListID;
  static int? priceListVersionID;
  static int? docTypeID;
  static String? docTypeName;
  static int? docTypeRefundID;
  static int? templatePartnerID;
  static bool isPOS = false;
  static int? docNoSequence;
  static List<Map<String, dynamic>> docTypesComplete = [];

  static List<Map<String, String>> documentActions = [
    // {'code': 'DR', 'name': 'Borrador'}
  ];

  static Map<dynamic, dynamic> principalTaxs = {};
}

class POSTenderType {
  static bool isMultiPayment = false;
}

class Yappy {
  static String? token;
  static String? secretKey;
  static String? apiKey;
  static int? yappyConfigID;
  static String? groupId;
  static String? deviceId;
  static bool? isTest;
}
