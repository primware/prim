import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:primware/API/pos.api.dart';
import 'package:primware/API/user.api.dart';
import 'package:primware/views/Auth/login_view.dart';
import '../../../API/endpoint.api.dart';
import 'dart:convert';
import '../../../API/token.api.dart';
import '../../Auth/auth_funtions.dart';

Future<List<Map<String, dynamic>>> fetchBPartner(
    {required BuildContext context}) async {
  try {
    await usuarioAuth(
      usuario: usuarioController.text.trim(),
      clave: claveController.text.trim(),
      context: context,
    );
    final response = await get(
      Uri.parse('${EndPoints.cBPartner}?\$filter=IsCustomer eq true'),
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
      throw Exception('Error al cargar los terceros: ${response.statusCode}');
    }
  } catch (e) {
    print('Excepción al obtener terceros: $e');
    return [];
  }
}

Future<List<Map<String, dynamic>>> fetchProductInPriceList({
  required BuildContext context,
}) async {
  try {
    if (POS.priceListID == null) {
      return [];
    }

    final validProductIDs =
        await _fetchLatestPricelistProductIDs(mPriceListID: POS.priceListID!);
    if (validProductIDs.isEmpty) return [];

    final response = await get(
      Uri.parse(
        '${EndPoints.mProduct}?\$select=Name,C_TaxCategory_ID,SKU&\$expand=M_ProductPrice(\$select=PriceStd)',
      ),
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
        if (!validProductIDs.contains(record['id'])) continue;

        final taxCategoryID = record['C_TaxCategory_ID']?['id'];
        Map<String, dynamic>? assignedTax;

        if (taxCategoryID != null) {
          final taxes = await fetchTax(
            context: context,
            cTaxCategoryID: taxCategoryID,
          );

          if (taxes.isNotEmpty) {
            assignedTax = taxes.first;
          }
        }

        productList.add({
          'id': record['id'],
          'name': record['Name'],
          'sku': record['SKU'],
          'price': record['M_ProductPrice'] != null &&
                  record['M_ProductPrice'].isNotEmpty
              ? record['M_ProductPrice'][0]['PriceStd']
              : null,
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

Future<List<int>> _fetchLatestPricelistProductIDs(
    {required int mPriceListID}) async {
  try {
    final response = await get(
      Uri.parse(GetProductInPriceList(mPriceListID: mPriceListID).endPoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Error al obtener la lista de precios: ${response.statusCode}');
    }

    final data = json.decode(utf8.decode(response.bodyBytes));
    final records = data['records'] as List;

    if (records.isEmpty) return [];

    final latestVersion = records.first;
    final prices = latestVersion['M_ProductPrice'] as List;

    final productIDs = prices
        .map((entry) => entry['M_Product_ID']?['id'])
        .where((id) => id != null)
        .cast<int>()
        .toList();

    return productIDs;
  } catch (e) {
    print('Error al obtener productos desde la lista de precios: $e');
    return [];
  }
}

Future<List<Map<String, dynamic>>> fetchTax({
  required BuildContext context,
  int? cTaxCategoryID,
}) async {
  try {
    String url = EndPoints.cTax;
    if (cTaxCategoryID != null) {
      url += '?\$filter=C_TaxCategory_ID eq $cTaxCategoryID';
    }

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
      usuario: usuarioController.text.trim(),
      clave: claveController.text.trim(),
      context: context,
    );

    final orderLines = invoiceLines.map((line) {
      return {
        "M_Product_ID": {"id": line['M_Product_ID']},
        "QtyEntered": line['Quantity'],
        "QtyOrdered": line['Quantity'],
        "PriceActual": line['Price'],
        "PriceEntered": line['Price'],
        "C_Tax_ID": {"id": line['C_Tax_ID']}
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
      usuario: usuarioController.text.trim(),
      clave: claveController.text.trim(),
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
      Uri.parse('${EndPoints.cPOSTenderType}?\$select=Name,TenderType'),
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
