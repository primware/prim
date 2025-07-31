import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:primware/API/pos.api.dart';
import 'package:primware/API/user.api.dart';
import '../../../API/endpoint.api.dart';
import 'dart:convert';
import '../../../API/token.api.dart';
import '../../Auth/auth_funtions.dart';

Future<List<Map<String, dynamic>>> fetchBPartner({
  required BuildContext context,
  String? searchTerm = '',
}) async {
  try {
    await usuarioAuth(
      context: context,
    );
    final filterQuery = 'IsCustomer eq true'
        '${searchTerm!.isNotEmpty ? ' and contains(tolower(Name), ${searchTerm.toLowerCase()})' : ''}';

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
          'LCO_TaxIdType_ID': record['LCO_TaxIdType_ID']?['id'],
          'LCO_TaxIdTypeName': record['LCO_TaxIdType_ID']?['identifier'],
          'C_BP_Group_ID': record['C_BP_Group_ID']?['id'],
          'AD_User_ID': record['AD_User']?[0]?['id'],
          'C_BPartner_Location_ID': record['C_BPartner_Location']?[0]?['id'],
          'locationName': record['C_BPartner_Location']?[0]?['Name'],
        };
      }).toList();
    } else {
      throw Exception('Error al cargar los terceros: ${response.statusCode}');
    }
  } catch (e) {
    print('Excepción al obtener terceros: $e');
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
        '${EndPoints.mProduct}?\$filter=$filterQuery&\$select=Value,Name,C_TaxCategory_ID,SKU,UPC,M_Product_Category_ID&\$expand=M_ProductPrice(\$select=PriceStd,M_PriceList_Version_ID;\$filter=M_PriceList_Version_ID eq ${POS.priceListVersionID})';
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
        });
      }

      return productList;
    } else {
      throw Exception('Error al cargar los productos: ${response.statusCode}');
    }
  } catch (e) {
    print('Excepción al obtener productos: $e');
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
    print('Excepción al obtener impuesto: $e');
    return [];
  }
}

Future<Map<String, dynamic>> postInvoice({
  required int cBPartnerID,
  required List<Map<String, dynamic>> invoiceLines,
  required List<Map<String, dynamic>> payments,
  required BuildContext context,
  required String docAction,
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
      };
    }).toList();

    final Map<String, dynamic> orderData = {
      "C_BPartner_ID": {"id": cBPartnerID},
      "AD_Org_ID": {"id": Token.organitation},
      "M_Warehouse_ID": {"id": Token.warehouseID},
      "C_DocTypeTarget_ID": POS.docTypeID ?? {"identifier": "POS Order"},
      "SalesRep_ID": {"id": UserData.id},
      "DeliveryRule": "A",
      "DeliveryViaRule": "P",
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
      print('Error al crear y completar la orden: ${orderResponse.statusCode}');
      print(orderResponse.body);
      return {
        'success': false,
        'message': 'Error al crear y completar la orden.',
      };
    }

    return {'success': true};
  } catch (e) {
    print('Excepción general: $e');
    return {'success': false, 'message': 'Excepción inesperada: $e'};
  }
}

Future<List<Map<String, dynamic>>> fetchOrders(
    {required BuildContext context}) async {
  try {
    await usuarioAuth(
      context: context,
    );

    final response = await get(
      Uri.parse(
          '${EndPoints.cOrder}?\$filter=SalesRep_ID eq ${UserData.id}&\$orderby=DateOrdered desc&\$expand=C_OrderLine(\$expand=C_Tax_ID)'),
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
            'name': record['C_BPartner_ID']?['identifier'],
          },
          'C_OrderLine': record['C_OrderLine'] ?? [],
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
    print('Excepción al obtener métodos de pago: $e');
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
    print('Excepción al obtener las categorias de los productos: $e');
    return [];
  }
}
