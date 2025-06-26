class POS {
  static int? priceListID;
  static int? docTypeID;
  static int? templatePartnerID;
  static bool isPOS = false;

  static List<Map<String, String>> documentActions = [
    {'code': 'DR', 'name': 'Borrador'}
  ];
}

class POSTenderType {
  static bool isMultiPayment = false;
}
