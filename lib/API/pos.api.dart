class POS {
  static int? priceListID;
  static int? priceListVersionID;
  static int? docTypeID;
  static int? docTypeRefundID;
  static int? templatePartnerID;
  static bool isPOS = false;

  static List<Map<String, String>> documentActions = [
    {'code': 'DR', 'name': 'Borrador'}
  ];

  static Map<dynamic, dynamic> principalTaxs = {};
}

class POSTenderType {
  static bool isMultiPayment = false;
}
