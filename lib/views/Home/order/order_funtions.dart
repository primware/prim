import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:pdf/pdf.dart';
import 'package:primware/API/pos.api.dart';
import 'package:primware/API/user.api.dart';
import '../../../API/endpoint.api.dart';
import 'dart:convert';
import '../../../API/token.api.dart';
import '../../Auth/auth_funtions.dart';
import 'package:pdf/widgets.dart' as pw;

Future<List<Map<String, dynamic>>> fetchBPartner({
  required BuildContext context,
  String? searchTerm = '',
}) async {
  try {
    await usuarioAuth(
      context: context,
    );
    final filterQuery =
        'IsCustomer eq true${searchTerm!.isNotEmpty ? ' and (contains(tolower(Name), ${searchTerm.toLowerCase()}) or contains(tolower(TaxID), ${searchTerm.toLowerCase()}))' : ''}';

    final response = await get(
      Uri.parse(
          '${EndPoints.cBPartner}?\$filter=$filterQuery&\$expand=AD_User,C_BPartner_Location'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      final records = jsonResponse['records'] as List;
      return records.map((record) {
        return {
          'id': record['id'],
          'name': record['Name'],
          'TaxID': record['TaxID'],
          'dv': record['dv'],
          'TipoClienteFE': record['TipoClienteFE']?['id'],
          'LCO_TaxIdType_ID': record['LCO_TaxIdType_ID']?['id'],
          'LCO_TaxIdTypeName': record['LCO_TaxIdType_ID']?['identifier'],
          'C_BP_Group_ID': record['C_BP_Group_ID']?['id'],
          'AD_User_ID': record['AD_User']?[0]?['id'],
          'email': record['AD_User']?[0]?['EMail'],
          'C_BPartner_Location_ID': record['C_BPartner_Location']?[0]?['id'],
          'locationName': record['C_BPartner_Location']?[0]?['Name'],
        };
      }).toList();
    } else {
      throw Exception('Error al cargar los terceros: ${response.statusCode}');
    }
  } catch (e) {
    CurrentLogMessage.add('Excepción al obtener terceros: $e',
        level: 'ERROR', tag: 'fetchBPartner');
    return [];
  }
}

Future<List<Map<String, dynamic>>> fetchProductInPriceList({
  required BuildContext context,
  List<int>? categoryID = const [],
  String? searchTerm = '',
}) async {
  try {
    if (POS.priceListID == null) {
      return [];
    }

    // Construir filtro de categorías usando 'or' si hay varias categorías, para compatibilidad con iDempiere.
    String categoryFilter = '';
    if (categoryID != null && categoryID.isNotEmpty) {
      categoryFilter =
          ' and (${categoryID.map((id) => 'M_Product_Category_ID eq $id').join(' or ')})';
    }
    final filterQuery = 'IsSold eq true'
        '${searchTerm!.isNotEmpty ? ' and (contains(tolower(Name), ${searchTerm.toLowerCase()}) or contains(tolower(SKU), ${searchTerm.toLowerCase()}))' : ''}'
        '$categoryFilter';
    final url =
        '${EndPoints.mProduct}?\$filter=$filterQuery&\$select=Value,Name,C_TaxCategory_ID,SKU,UPC,ProductType,M_Product_Category_ID&\$expand=M_ProductPrice(\$select=PriceStd,M_PriceList_Version_ID;\$filter=M_PriceList_Version_ID eq ${POS.priceListVersionID})';
    final response = await get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      final records = jsonResponse['records'] as List;

      List<Map<String, dynamic>> productList = [];

      for (var record in records) {
        final taxCategoryID = record['C_TaxCategory_ID']?['id'];
        if (taxCategoryID == null || record['M_ProductPrice'] == null) continue;

        Map<String, dynamic>? assignedTax;

        if (POS.principalTaxs.containsKey(taxCategoryID)) {
          assignedTax = POS.principalTaxs[taxCategoryID];
        }

        productList.add({
          'id': record['id'],
          'name': record['Name'],
          'value': record['Value'],
          'sku': record['SKU'],
          'upc': record['UPC'],
          'category': record['M_Product_Category_ID'] != null
              ? record['M_Product_Category_ID']['id']
              : null,
          'price': record['M_ProductPrice'] != null &&
                  record['M_ProductPrice'].isNotEmpty
              ? record['M_ProductPrice'][0]['PriceStd']
              : null,
          'C_TaxCategory_ID': taxCategoryID,
          'tax': assignedTax,
          'ProductType': record['ProductType']['id'],
        });
      }

      return productList;
    } else {
      throw Exception('Error al cargar los productos: ${response.statusCode}');
    }
  } catch (e) {
    CurrentLogMessage.add('Excepción al obtener productos: $e',
        level: 'ERROR', tag: 'fetchProductInPriceList');
    return [];
  }
}

Future<List<Map<String, dynamic>>> fetchTax() async {
  try {
    final response = await get(
      Uri.parse(EndPoints.cTax),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      final records = jsonResponse['records'] as List;
      return records.map((record) {
        return {
          'id': record['id'],
          'name': record['Name'],
          'rate': record['Rate'],
          'istaxexempt': record['IsTaxExempt'],
          'issalestax': record['IsSalesTax'],
          'isdefault': record['IsDefault'],
        };
      }).toList();
    } else {
      throw Exception('Error al cargar los impuestos: ${response.statusCode}');
    }
  } catch (e) {
    CurrentLogMessage.add('Excepción al obtener impuesto: $e',
        level: 'ERROR', tag: 'fetchTax');
    return [];
  }
}

Future<Map<String, dynamic>> postInvoice({
  required int cBPartnerID,
  required List<Map<String, dynamic>> invoiceLines,
  required List<Map<String, dynamic>> payments,
  required BuildContext context,
  required String docAction,
  required bool isRefund,
  int? doctypeID,
}) async {
  try {
    await usuarioAuth(
      context: context,
    );

    final orderLines = invoiceLines.map((line) {
      return {
        "M_Product_ID": {"id": line['M_Product_ID']},
        "QtyEntered": line['Quantity'],
        "QtyOrdered": line['Quantity'],
        "PriceActual": line['Price'],
        "PriceEntered": line['Price'],
        "C_Tax_ID": {"id": line['C_Tax_ID']},
        "Description": line['Description'] ?? '',
      };
    }).toList();

    final posPayments = payments.map((payment) {
      return {
        "C_POSTenderType_ID": {"id": payment['C_POSTenderType_ID']},
        "PayAmt": payment['PayAmt'],
        if (payment['RoutingNo'] != null) "RoutingNo": payment['RoutingNo'],
      };
    }).toList();

    final Map<String, dynamic> orderData = {
      "C_BPartner_ID": {"id": cBPartnerID},
      "AD_Org_ID": {"id": Token.organitation},
      "M_Warehouse_ID": {"id": Token.warehouseID},
      "C_DocTypeTarget_ID": doctypeID ??
          (isRefund
              ? POS.docTypeRefundID
              : POS.docTypeID ?? {"identifier": "POS Order"}),
      "SalesRep_ID": {"id": UserData.id},
      "DeliveryRule": "A",
      "DeliveryViaRule": "P",
      "InvoiceRule": "I",
      "PriorityRule": "5",
      "FreightCostRule": "I",
      "PaymentRule": POSTenderType.isMultiPayment ? "M" : "B",
      "M_PriceList_ID": POS.priceListID ?? {"identifier": "Standard"},
      "IsSOTrx": true,
      "order-line": orderLines,
      if (POSTenderType.isMultiPayment) "pos-payment": posPayments,
      "doc-action": docAction
    };

    final orderResponse = await post(
      Uri.parse('${Base.baseURL}/api/v1/windows/sales-order'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.auth!,
      },
      body: jsonEncode(orderData),
    );

    if (orderResponse.statusCode != 201) {
      CurrentLogMessage.add(
          'Error al crear y completar la orden: ${orderResponse.body}',
          level: 'ERROR',
          tag: 'postInvoice');

      return {
        'success': false,
        'message': 'Error al crear y completar la orden.',
      };
    }

    Map<String, dynamic> jsonData = jsonDecode(orderResponse.body);

    return {'success': true, 'Record_ID': jsonData['id']};
  } catch (e) {
    CurrentLogMessage.add('Excepción general: $e',
        level: 'ERROR', tag: 'postInvoice');
    return {'success': false, 'message': 'Excepción inesperada: $e'};
  }
}

Future<Map<String, dynamic>?> fetchOrderById({required int orderId}) async {
  try {
    final response = await get(
      Uri.parse(
          '${EndPoints.cOrder}?\$filter=C_Order_ID eq $orderId&\$expand=C_OrderLine(\$expand=C_Tax_ID),Bill_Location_ID,C_BPartner_ID,Bill_User_ID,C_POSPayment'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> responseData =
          json.decode(utf8.decode(response.bodyBytes));
      final record = responseData['records'][0];

      return {
        'id': record['id'],
        'Created': record['Created'],
        'DocumentNo': record['DocumentNo'],
        'DateOrdered': record['DateOrdered'],
        'GrandTotal': record['GrandTotal'],
        'TotalLines': record['TotalLines'],
        'bpartner': {
          'id': record['C_BPartner_ID']?['id'],
          'name': record['C_BPartner_ID']?['Name'],
          'location': record['Bill_Location_ID']?['C_Location_ID']
              ?['identifier'],
          'taxID': record['C_BPartner_ID']?['TaxID'],
          'phone': record['Bill_User_ID']?['Phone'],
        },
        'doctypetarget': {
          'id': record['C_DocTypeTarget_ID']?['id'],
          'name': record['C_DocTypeTarget_ID']?['identifier'],
        },
        'SalesRep_ID': {
          'id': record['SalesRep_ID']?['id'],
          'name': record['SalesRep_ID']?['identifier'],
        },
        'C_OrderLine': record['C_OrderLine'] ?? [],
        'payments': record['C_POSPayment'] ?? [],
      };
    } else {
      debugPrint('Error al obtener la orden: ${response.body}');
      return null;
    }
  } catch (e) {
    debugPrint('Error de red en fetchOrderById: $e');
    return null;
  }
}

Future<List<Map<String, dynamic>>> fetchOrders(
    {required BuildContext context, String? filter}) async {
  try {
    await usuarioAuth(
      context: context,
    );

    filter = (filter != null && filter.isNotEmpty)
        ? ' and contains(DocumentNo, $filter)'
        : '';

    final response = await get(
      Uri.parse(
          '${EndPoints.cOrder}?\$filter=SalesRep_ID eq ${UserData.id} and (DocStatus eq \'CO\' or DocStatus eq \'CL\')$filter&\$orderby=DateOrdered desc&\$expand=C_OrderLine(\$expand=C_Tax_ID),Bill_Location_ID,C_BPartner_ID,Bill_User_ID,C_POSPayment,C_DocTypeTarget_ID'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      final List records = jsonResponse['records'];

      return records.map((record) {
        return {
          'id': record['id'],
          'Created': record['Created'],
          'DocumentNo': record['DocumentNo'],
          'DateOrdered': record['DateOrdered'],
          'GrandTotal': record['GrandTotal'],
          'TotalLines': record['TotalLines'],
          'bpartner': {
            'id': record['C_BPartner_ID']?['id'],
            'name': record['C_BPartner_ID']?['Name'],
            'location': record['Bill_Location_ID']?['C_Location_ID']
                ?['identifier'],
            'taxID': record['C_BPartner_ID']?['TaxID'],
            'phone': record['Bill_User_ID']?['Phone'],
          },
          'doctypetarget': {
            'id': record['C_DocTypeTarget_ID']?['id'],
            'name': record['C_DocTypeTarget_ID']?['Name'],
            'subtype': record['C_DocTypeTarget_ID']?['DocSubTypeSO'],
          },
          'SalesRep_ID': {
            'id': record['SalesRep_ID']?['id'],
            'name': record['SalesRep_ID']?['identifier'],
          },
          'C_OrderLine': record['C_OrderLine'] ?? [],
          'payments': record['C_POSPayment'] ?? [],
        };
      }).toList();
    } else {
      debugPrint('Error al obtener órdenes: ${response.body}');
      return [];
    }
  } catch (e) {
    debugPrint('Error de red en fetchOrders: $e');
    return [];
  }
}

Future<List<Map<String, dynamic>>> fetchPaymentMethods() async {
  try {
    final response = await get(
      Uri.parse(
          '${EndPoints.cPOSTenderType}?\$select=Name,TenderType,Value&\$orderby=Value'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      final records = jsonResponse['records'] as List;
      return records.map((record) {
        return {
          'id': record['id'],
          'name': record['Name'],
          'tenderType': record['TenderType']?['identifier'] ?? 'Desconocido',
          'tenderTypeID': record['TenderType']?['id'],
          'isCash': record['TenderType']?['id'] == 'X',
        };
      }).toList();
    } else {
      throw Exception(
          'Error al cargar métodos de pago: ${response.statusCode}');
    }
  } catch (e) {
    CurrentLogMessage.add('Excepción al obtener métodos de pago: $e',
        level: 'ERROR', tag: 'fetchPaymentMethods');
    return [];
  }
}

Future<List<Map<String, dynamic>>> fetchProductCategory() async {
  try {
    final response = await get(
      Uri.parse('${EndPoints.mProductCategory}?\$select=Name&\$orderby=Name'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      final records = jsonResponse['records'] as List;
      return records.map((record) {
        return {
          'id': record['id'],
          'name': record['Name'],
        };
      }).toList();
    } else {
      throw Exception(
          'Error al cargar las categorias de los productos: ${response.statusCode}');
    }
  } catch (e) {
    CurrentLogMessage.add(
        'Excepción al obtener las categorias de los productos: $e',
        level: 'ERROR',
        tag: 'fetchProductCategory');
    return [];
  }
}

Future<void> fetchDocumentActions({required int docTypeID}) async {
  POS.documentActions.clear();
  final response = await get(
    Uri.parse(
        GetDocumentActions(roleID: Token.rol!, docTypeID: docTypeID).endPoint),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': Token.auth!,
    },
  );

  if (response.statusCode == 200) {
    final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
    final records = jsonResponse['records'] as List;

    final Map<String, Map<String, String>> actionMap = {
      'Complete': {'code': 'CO', 'name': 'Completar'},
      '<None>': {'code': 'DR', 'name': 'Borrador'},
      'Prepare': {'code': 'PR', 'name': 'Preparar'},
      'Approve': {'code': 'AP', 'name': 'Aprobar'},
      'Reject': {'code': 'RJ', 'name': 'Rechazar'},
      'Close': {'code': 'CL', 'name': 'Cerrar'},
      'Void': {'code': 'VO', 'name': 'Anular'},
      'WaitComplete': {'code': 'WC', 'name': 'Esperar Completar'},
      'Unlock': {'code': 'XL', 'name': 'Desbloquear'},
      'Invalidate': {'code': 'IN', 'name': 'Invalidar'},
      'ReverseCorrect': {'code': 'RC', 'name': 'Reversar Correcto'},
      'ReverseAccrual': {'code': 'RA', 'name': 'Reversar Devengo'},
      'ReActivate': {'code': 'RE', 'name': 'Reactivar'},
      'Post': {'code': 'PO', 'name': 'Contabilizar'},
      'UnPost': {'code': 'UP', 'name': 'Descontabilizar'},
      'Schedule': {'code': 'SC', 'name': 'Programar'},
      'Release': {'code': 'RL', 'name': 'Liberar'},
      'Confirm': {'code': 'CF', 'name': 'Confirmar'},
      'Start': {'code': 'ST', 'name': 'Iniciar'},
      'Finish': {'code': 'FI', 'name': 'Finalizar'},
      'ApprovePromotion': {'code': 'APr', 'name': 'Aprobar Promoción'},
    };

    final List<Map<String, String>> result = [];

    for (var record in records) {
      final identifier = record['AD_Ref_List_ID']?['identifier'];
      final action = actionMap[identifier];
      if (action != null && !result.any((e) => e['code'] == action['code'])) {
        result.add(action);
      }
    }

    POS.documentActions = result;
  } else {
    CurrentLogMessage.add(
        'Error al obtener acciones de documento: ${response.statusCode}',
        level: 'ERROR',
        tag: 'fetchDocumentActions');
  }
}

Future<Map<String, dynamic>> showYappyQR({
  required double subTotal,
  required double totalTax,
  required double total,
  String? docNoSequence,
  required BuildContext context,
}) async {
  try {
    final Map<String, dynamic> openDeviceData = {
      "body": {
        "device": {
          "id": Yappy.deviceId,
          "name": Yappy.deviceId,
          "user": Yappy.deviceId,
        },
        "group_id": Yappy.groupId
      }
    };

    final Map<String, dynamic> generateQRData = {
      "body": {
        "charge_amount": {
          "sub_total": subTotal,
          "tax": totalTax,
          "tip": 0,
          "discount": 0,
          "total": total
        },
        if (docNoSequence != null && docNoSequence.isNotEmpty)
          "order_id": docNoSequence,
      }
    };

    final deviceResponse = await post(
      Uri.parse(EndPoints.yappyDevice),
      headers: {
        'Content-Type': 'application/json',
        'api-key': Yappy.apiKey!,
        'secret-key': Yappy.secretKey!,
      },
      body: jsonEncode(openDeviceData),
    );

    if (deviceResponse.statusCode != 200) {
      CurrentLogMessage.add(
          'Error al abrir la caja de yappi: ${deviceResponse.body}',
          level: 'ERROR',
          tag: 'showYappyQR');

      return {
        'success': false,
        'message': 'Error al abrir la caja de yappi.',
      };
    }

    Yappy.token = json.decode(deviceResponse.body)['body']['token'];

    final qrResponse = await post(
      Uri.parse(EndPoints.yappyQRGeneratorDYN),
      headers: {
        'Content-Type': 'application/json',
        'api-key': Yappy.apiKey!,
        'secret-key': Yappy.secretKey!,
        'authorization': Yappy.token!,
      },
      body: jsonEncode(generateQRData),
    );

    if (qrResponse.statusCode != 200) {
      CurrentLogMessage.add(
          'Error al generar el QR de yappy: ${qrResponse.body}',
          level: 'ERROR',
          tag: 'showYappyQR');

      return {
        'success': false,
        'message': 'Error al generar el QR de yappy.',
      };
    }

    return {
      'success': true,
      'hash': json.decode(qrResponse.body)['body']['hash'],
      'transactionId': json.decode(qrResponse.body)['body']['transactionId'],
    };
  } catch (e) {
    return {'success': false, 'message': 'Excepción inesperada: $e'};
  }
}

Future<bool> checkYappyStatus(String transactionId) async {
  try {
    final response = await get(
      Uri.parse('${EndPoints.yappyTransaction}/$transactionId'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'api-key': Yappy.apiKey!,
        'secret-key': Yappy.secretKey!,
        'authorization': Yappy.token!,
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));

      final status = jsonResponse['body']['status'];
      if (status == 'COMPLETED') {
        return true;
      } else if (status == 'PENDING') {
        return false;
      } else {
        debugPrint('Transacción fallida o cancelada: $status');
        return false;
      }
    } else {
      debugPrint('Error al verificar el estado de Yappy: ${response.body}');
      return false;
    }
  } catch (e) {
    debugPrint('Error de red en checkYappyStatus: $e');
    return false;
  }
}

Future<bool> cancelYappyTransaction({required String transactionId}) async {
  try {
    final response = await put(
      Uri.parse('${EndPoints.yappyTransaction}/$transactionId'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'api-key': Yappy.apiKey!,
        'secret-key': Yappy.secretKey!,
        'authorization': Yappy.token!,
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));

      final status = jsonResponse['status']['code'];
      CurrentLogMessage.add('Status de la cancelación: $status',
          level: 'INFO', tag: 'cancelYappyTransaction');
      if (status == 'YP-0000' || status == 'YP-0016') {
        return true;
      } else {
        debugPrint(
            'Operacion para cancelar transacion fallida: ${response.body}');
        return false;
      }
    } else {
      debugPrint(
          'Operacion para cancelar transacion fallida: ${response.body}');
      return false;
    }
  } catch (e) {
    debugPrint('Error de red en cancelYappyTransaction: $e');
    return false;
  }
}

Future<int?> getDocNoSequenceID({required int recordID}) async {
  try {
    final response = await get(
      Uri.parse('${EndPoints.cDocType}?\$filter=C_DocType_ID eq $recordID'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final record = responseData['records'][0];

      return record['DocNoSequence_ID']?['id'];
    } else {
      CurrentLogMessage.add(
          'Error en getDocNoSequenceID: ${response.statusCode}, ${response.body}',
          level: 'ERROR',
          tag: 'getDocNoSequenceID');
    }
  } catch (e) {
    CurrentLogMessage.add('Error en getDocNoSequenceID: $e',
        level: 'ERROR', tag: 'getDocNoSequenceID');
  }
  return null;
}

Future<String?> getDocNoSequence({required int docNoSequenceID}) async {
  try {
    final response = await get(
      Uri.parse(
          '${EndPoints.adSequence}?\$filter=AD_Sequence_ID eq $docNoSequenceID'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final record = responseData['records'][0];

      return record['CurrentNext'].toString();
    } else {
      CurrentLogMessage.add(
          'Error en _getDocNoSequence: ${response.statusCode}, ${response.body}',
          level: 'ERROR',
          tag: '_getDocNoSequence');
    }
  } catch (e) {}
  return null;
}

Future<Map<String, String>?> fetchElectronicInvoiceInfo(
    {required int orderId}) async {
  try {
    final uri = Uri.parse(
        '${EndPoints.cInvoice}?\$filter=C_Order_ID eq $orderId&\$expand=FE_InvoiceResponseLog');
    final response = await get(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode != 200) {
      // Si la tabla/expand no existe o hay otro problema, devolver null silenciosamente
      debugPrint('FE query non-200: ${response.statusCode}');
      return null;
    }

    final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
    final List records = (jsonResponse['records'] as List?) ?? const [];
    if (records.isEmpty) return null;

    final invoice = records.first;
    final List logs = (invoice['FE_InvoiceResponseLog'] as List?) ?? const [];
    if (logs.isEmpty) return null;

    // Buscar el primer log con FE_ResponseCode == 200 (num o string)
    final match = logs.firstWhere(
      (e) {
        final code = e['FE_ResponseCode'];
        if (code == null) return false;
        if (code is num) return code == 200;
        if (code is String) return code.trim() == '200';
        return false;
      },
      orElse: () => null,
    );

    if (match == null) return null;

    final cufe = match['FE_ResponseCUFE']?.toString();
    final protocolo = match['FE_NroProtocoloAutorizacion']?.toString();
    final url = match['FE_ResponseQR']?.toString();

    if (cufe == null || protocolo == null || url == null) return null;

    return {
      'cufe': cufe,
      'protocolo': protocolo,
      'url': url,
    };
  } catch (e) {
    debugPrint('Error consultando FE_InvoiceResponseLog: $e');
    return null;
  }
}

Future<Uint8List> generateTicketPdf(Map<String, dynamic> order) async {
  // Consultar datos de Factura Electrónica (FE)
  final int? orderId = (order['id'] as int?);
  final feInfo = orderId != null
      ? await fetchElectronicInvoiceInfo(orderId: orderId)
      : null;

  final pdf = pw.Document();
  final pageFormat = PdfPageFormat.roll80;

  // Helpers
  String str(dynamic v) => v?.toString() ?? '';
  String money(num? v) => 'B/.${(v ?? 0).toDouble().toStringAsFixed(2)}';

  String docTypename = order['doctypetarget']?['name'] ?? '';

  // Order fields (safe access)
  final docNo = str(order['DocumentNo']);
  final date = str(order['DateOrdered']);
  final servedBy = str(order['SalesRep_ID']?['name'] ?? '');
  final taxID = str(order['bpartner']['taxID'] ?? '');
  final phone = str(order['bpartner']['phone'] ?? '');
  final customerName = str(order['bpartner']?['name'] ?? 'CONTADO');
  final customeLocation = str(order['bpartner']?['location'] ?? '');

  // Lines & taxes
  final List lines = (order['C_OrderLine'] as List?) ?? const [];
  final taxSummary = _calculateTaxSummary([order]);

  final double taxTotal = taxSummary.values
      .map((e) => e['tax'] as double)
      .fold(0.0, (a, b) => a + b);
  final double grandTotal = (order['GrandTotal'] as num?)?.toDouble() ?? 0.0;

  // Taxes summary (net + taxes)
  final netSum = taxSummary.values
      .map((e) => e['net'] as double)
      .fold(0.0, (a, b) => a + b);

  // Render PDF
  pdf.addPage(
    pw.Page(
      pageFormat: pageFormat.copyWith(
          marginTop: 8, marginBottom: 8, width: 75 * PdfPageFormat.mm),
      // theme: theme,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Encabezado centrado
            POSPrinter.logo != null
                ? pw.Center(
                    child: pw.Image(pw.MemoryImage(POSPrinter.logo!),
                        width: 60, height: 60, fit: pw.BoxFit.contain))
                : pw.SizedBox(),
            pw.SizedBox(height: 4),
            pw.Text(POSPrinter.headerName ?? '',
                textAlign: pw.TextAlign.center),
            pw.Text(POSPrinter.headerAddress ?? '',
                textAlign: pw.TextAlign.center),
            pw.Text(POSPrinter.headerPhone ?? '',
                textAlign: pw.TextAlign.center),
            pw.Text(POSPrinter.headerEmail ?? '',
                textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 12),
            pw.Text(docTypename,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                )),

            pw.SizedBox(height: 18),

            // Detalles (alineados a la izquierda)
            pw.Text('Recibo: $docNo'),
            pw.Text('Fecha: $date'),
            if (servedBy.isNotEmpty) pw.Text('Atendido por: $servedBy'),
            pw.Text('Cédula: $taxID'),
            pw.Text('Cliente: $customerName'),

            pw.Text('Dirección: $customeLocation'),
            pw.Text('Teléfono: $phone'),
            pw.SizedBox(height: 12),

            // Tabla de ítems (alineada en 4 columnas)
            pw.Row(
              children: [
                pw.Expanded(
                    flex: 20,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Ítem', maxLines: 1),
                        pw.Text('Precio x Cant',
                            maxLines: 1, style: pw.TextStyle(fontSize: 12)),
                      ],
                    )),
                pw.Expanded(
                  flex: 15,
                  child: pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text('Subtotal', maxLines: 1),
                  ),
                ),
              ],
            ),
            pw.Divider(),
            pw.SizedBox(height: 6),
            ...lines.map((line) {
              final name = (line['M_Product_ID']?['identifier'] ?? 'Ítem')
                  .toString()
                  .split('_')
                  .skip(1)
                  .join(' ');
              final qty = (line['QtyOrdered'] as num?)?.toDouble() ?? 0.0;
              final price = (line['PriceActual'] as num?)?.toDouble() ?? 0.0;
              final net = (line['LineNetAmt'] as num?)?.toDouble() ?? 0.0;
              final rate =
                  (line['C_Tax_ID']?['Rate'] as num?)?.toDouble() ?? 0.0;
              final tax = double.parse((net * (rate / 100)).toStringAsFixed(2));
              final value = net + tax;

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                          flex: 20,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                name,
                                // maxLines: 1,
                                overflow: pw.TextOverflow.span,
                              ),
                              pw.Text(
                                '${money(price)} x ${qty.toStringAsFixed(qty % 1 == 0 ? 0 : 2)}',
                                maxLines: 1,
                                style: pw.TextStyle(fontSize: 12),
                              ),
                            ],
                          )),
                      pw.Expanded(
                        flex: 15,
                        child: pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text(
                            money(value),
                            maxLines: 1,
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              );
            }),

            pw.SizedBox(height: 6),

            pw.Divider(),
            // Totales
            pw.Text('Cant. Items: ${lines.length}'),
            pw.SizedBox(height: 12),
            pw.Text('Total: ${money(grandTotal)}',
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            pw.SizedBox(height: 10),

            // Formas de pago
            pw.Text('Formas de Pago:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ...?order['payments']?.map<pw.Widget>((payment) {
              final payType =
                  payment['C_POSTenderType_ID']['identifier'] ?? 'Otro';
              final amount = (payment['PayAmt'] as num?)?.toDouble() ?? 0.0;
              return pw.Text('- $payType: ${money(amount)}');
            }),
            pw.SizedBox(height: 10),

            // Impuestos
            pw.Text('Neto sin ITBMS: ${money(netSum)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('ITBMS: ${money(taxTotal)}'),
            pw.SizedBox(height: 12),

            // Datos de Factura Electrónica (si existen)
            if (feInfo != null) ...[
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Text('FACTURA ELECTRÓNICA',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text('Protocolo de Autorización: ${feInfo['protocolo']}'),
              pw.Text('Consulte por la clave de acceso en:'),
              pw.Text(feInfo['url'] ?? '', style: pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 6),
              pw.Text('o escaneando el código QR:'),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.BarcodeWidget(
                  data: feInfo['url'] ?? '',
                  barcode: pw.Barcode.qrCode(),
                  width: 120,
                  height: 120,
                ),
              ),
              pw.SizedBox(height: 10),
            ],

            // Footer
            pw.Text('Gracias por mantener sus pagos al día',
                textAlign: pw.TextAlign.center),
          ],
        );
      },
    ),
  );

  return pdf.save();
}

Map<String, Map<String, double>> _calculateTaxSummary(List<dynamic> records) {
  final Map<String, Map<String, double>> taxSummary = {};

  for (var order in records) {
    if (order.containsKey("C_OrderLine")) {
      for (var line in order["C_OrderLine"]) {
        final tax = line["C_Tax_ID"];
        final String taxName = tax["Name"];
        final double taxRate = (tax["Rate"] as num).toDouble();
        final double lineNetAmt = (line["LineNetAmt"] as num).toDouble();

        final taxKey = "$taxName (${taxRate.toStringAsFixed(0)}%)";

        taxSummary.putIfAbsent(
            taxKey,
            () => {
                  "net": 0.0,
                  "tax": 0.0,
                  "total": 0.0,
                });

        final double taxAmount =
            double.parse((lineNetAmt * (taxRate / 100)).toStringAsFixed(2));
        taxSummary[taxKey]!["net"] = taxSummary[taxKey]!["net"]! + lineNetAmt;
        taxSummary[taxKey]!["tax"] = taxSummary[taxKey]!["tax"]! + taxAmount;
        taxSummary[taxKey]!["total"] =
            taxSummary[taxKey]!["total"]! + lineNetAmt + taxAmount;
      }
    }
  }

  return taxSummary;
}
