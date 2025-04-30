import 'package:flutter/material.dart';
import 'package:primware/API/user.api.dart';
import 'package:primware/views/Auth/login_view.dart';
import '../../../API/endpoint.api.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
    final response = await http.get(
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

Future<List<Map<String, dynamic>>> fetchProduct(
    {required BuildContext context}) async {
  try {
    final response = await http.get(
      Uri.parse(
          '${EndPoints.mProduct}?\$select=Name,SKU&\$expand=M_ProductPrice(\$select=PriceStd)'),
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
          'sku': record['SKU'],
          'price': record['M_ProductPrice'] != null &&
                  record['M_ProductPrice'].isNotEmpty
              ? record['M_ProductPrice'][0]['PriceStd']
              : null,
        };
      }).toList();
    } else {
      throw Exception('Error al cargar los productos: ${response.statusCode}');
    }
  } catch (e) {
    print('Excepción al obtener productos: $e');
    return [];
  }
}

Future<List<Map<String, dynamic>>> fetchTax(
    {required BuildContext context}) async {
  try {
    final response = await http.get(
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
          "isdefault": record['IsDefault'],
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
  required int ctaxID,
  required List<Map<String, dynamic>> invoiceLines,
  required BuildContext context,
}) async {
  try {
    await usuarioAuth(
      usuario: usuarioController.text.trim(),
      clave: claveController.text.trim(),
      context: context,
    );

//? Crear la orden de venta
    final Map<String, dynamic> orderData = {
      "C_BPartner_ID": cBPartnerID,
      "M_Warehouse_ID": Token.warehouseID,
      "C_DocTypeTarget_ID": Token.cDocTypeTargetID,
      "deliveryViaRule": "P",
      "SalesRep_ID": UserData.id,
      "isSOTrx": true,
    };

    final orderResponse = await http.post(
      Uri.parse(EndPoints.cOrder),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.auth!,
      },
      body: jsonEncode(orderData),
    );

    if (orderResponse.statusCode != 201) {
      print('Error al crear la orden: ${orderResponse.statusCode}');
      print(orderResponse.body);
      return {
        'success': false,
        'message': 'Error al crear la orden.',
      };
    }

    final createdOrder = json.decode(orderResponse.body);
    final int cOrderID = createdOrder['id'];

//? Crear la línea de la orden
    for (var line in invoiceLines) {
      final lineData = {
        "M_Product_ID": line['M_Product_ID'],
        "QtyEntered": line['Quantity'],
        "PriceActual": line['Price'],
        "PriceEntered": line['Price'],
        "C_Tax_ID": ctaxID,
        "C_Order_ID": cOrderID
      };

      final lineResponse = await http.post(
        Uri.parse(EndPoints.cOrderLine),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': Token.auth!,
        },
        body: jsonEncode(lineData),
      );

      if (lineResponse.statusCode != 201) {
        print('Error al crear línea: ${lineResponse.statusCode}');
        print(lineResponse.body);
        return {
          'success': false,
          'message': 'Error al crear líneas de la orden.',
        };
      }
    }

//? Completar la orden

    final completeOrderResponse = await http.put(
      Uri.parse('${EndPoints.cOrder}/$cOrderID'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.auth!,
      },
      body: jsonEncode({
        "DocStatus": {"id": "CO"}
      }),
    );

    if (completeOrderResponse.statusCode != 200) {
      print('Error al completar la orden: ${completeOrderResponse.statusCode}');
      print(completeOrderResponse.body);
      return {
        'success': false,
        'message': 'Error al completar la orden.',
      };
    }

    return {'success': true};
  } catch (e) {
    print('Excepción general: $e');
    return {'success': false, 'message': 'Excepción inesperada: $e'};
  }
}
