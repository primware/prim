import 'dart:typed_data';

class POS {
  static int? cPosID;
  static int? priceListID;
  static int? cPaymentTermID;
  static int? priceListVersionID;
  static int? docTypeID;
  static String? docTypeName;
  static String? docSubType;
  static int? docTypeRefundID;
  static String? docTypeRefundName;
  static String? docSubTypeRefund;
  static int? warehouseID;
  static int? discountChargeID;

  static int? templatePartnerID;
  static String? templatePartnerName;
  static String? currencySymbol = '\$';
  static bool isPOS = false;

  static List<Map<String, dynamic>> docTypesComplete = [];

  static List<Map<String, String>> documentActions = [
    // {'code': 'DR', 'name': 'Borrador'}
  ];

  static Map<dynamic, dynamic> principalTaxs = {};
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

class POSTenderType {
  static bool isMultiPayment = false;
}

class POSPrinter {
  static String? headerName;
  static String? headerAddress;
  static String? headerTaxID;
  static String? headerDV;
  static String? headerPhone;
  static String? headerEmail;
  static Uint8List? logo;
  static bool isLogoSet = false;

  static String? header1;
  static String? header2;
  static String? header3;
  static String? header4;
  static String? footer1;
  static String? footer2;
  static String? footer3;
  static String? footer4;
}

class docSubTypeSO {
  static String factura = 'WI';
  static String pedido = 'SO';
  static String cotizacion = 'OB';
}
