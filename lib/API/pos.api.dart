import 'dart:typed_data';

class POS {
  static int? cPosID;
  static int? priceListID;
  static int? priceListVersionID;
  static int? docTypeID;
  static String? docTypeName;
  static String? docTypeRefundName;
  static String? docSubType;
  static int? docTypeRefundID;
  static int? templatePartnerID;
  static String? templatePartnerName;
  static bool isPOS = false;

  static List<Map<String, dynamic>> docTypesComplete = [];

  static List<Map<String, String>> documentActions = [
    // {'code': 'DR', 'name': 'Borrador'}
  ];

  static Map<dynamic, dynamic> principalTaxs = {};
}

class POSTenderType {
  static bool isMultiPayment = false;
}

class POSPrinter {
  static String? headerName;
  static String? headerAddress;
  static String? headerPhone;
  static String? headerEmail;
  static Uint8List? logo;
}

class Yappy {
  static String? token;
  static String? secretKey;
  static String? apiKey;
  static int? yappyConfigID;
  static String? groupId;
  static String? deviceId;
  static bool? isTest;
  static int? cPOSTenderTypeID;
}
