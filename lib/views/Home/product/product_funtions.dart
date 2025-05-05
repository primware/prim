import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../API/endpoint.api.dart';
import '../../../API/token.api.dart';
import '../../Auth/auth_funtions.dart';
import '../../Auth/login_view.dart';

Future<Map<String, dynamic>> postProduct({
  required String name,
  String? sku,
  required String price,
  required BuildContext context,
}) async {
  try {
    await usuarioAuth(
      usuario: usuarioController.text.trim(),
      clave: claveController.text.trim(),
      context: context,
    );

//? Revisar el sku
    if (sku != null) {
      bool uniqueSKU = await productSKUExists(sku);

      if (uniqueSKU) {
        return {
          'success': false,
          'message': 'Ya existe un producto con este SKU.',
        };
      }
    }

//? Obtener el ID de M_Product_Category_ID
    final int? productCategoryID = await getMProductCategoryID();
    if (productCategoryID == null) {
      return {
        'success': false,
        'message': 'Error al obtener el ID de M_Product_Category_ID.',
      };
    }

    //? Obtener el ID de C_TaxCategory_ID
    final int? taxCategoryID = await getCTaxCategory();
    if (taxCategoryID == null) {
      return {
        'success': false,
        'message': 'Error al obtener el ID de C_TaxCategory_ID.',
      };
    }

//? Crear el producto
    final Map<String, dynamic> productData = {
      "Name": name,
      "C_UOM_ID": 100,
      "M_Product_Category_ID": productCategoryID,
      "C_TaxCategory_ID": taxCategoryID,
      if (sku != null) "SKU": sku,
      "IsSold": true,
    };

    final productResponse = await http.post(
      Uri.parse(EndPoints.mProduct),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.auth!,
      },
      body: jsonEncode(productData),
    );

    if (productResponse.statusCode != 201) {
      print('Error al crear el producto: ${productResponse.statusCode}');
      print(productResponse.body);
      return {
        'success': false,
        'message': 'Error al crear el producto.',
      };
    }

    final createdProduct = json.decode(productResponse.body);
    final int productID = createdProduct['id'];

//? Identificar el ID de M_PriceList_Version_ID

    final int? priceListVersionID = await getMPriceListVersionID();
    if (priceListVersionID == null) {
      return {
        'success': false,
        'message': 'Error al obtener el ID de M_PriceList_Version_ID.',
      };
    }

//? Precio del producto

    final Map<String, dynamic> priceData = {
      "M_Product_ID": productID,
      "M_PriceList_Version_ID": priceListVersionID,
      "PriceStd": double.parse(price),
      "PriceLimit": double.parse(price),
      "PriceList": double.parse(price)
    };

    final priceResponse = await http.post(
      Uri.parse(EndPoints.mProductPrice),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.auth!,
      },
      body: jsonEncode(priceData),
    );

    if (priceResponse.statusCode != 201) {
      print('Error al crear precio: ${priceResponse.statusCode}');
      print(priceResponse.body);
      return {
        'success': false,
        'message': 'Error al crear el precio.',
      };
    }

    return {
      'success': true,
      'message': 'Producto creado con éxito.',
      'product': createdProduct,
    };
  } catch (e) {
    print('Excepción general: $e');
    return {
      'success': false,
      'message': 'Error inesperado al crear el producto.',
    };
  }
}

Future<bool> productSKUExists(String sku) async {
  final response = await http.get(
    Uri.parse("${EndPoints.mProduct}?\$filter=SKU eq '$sku'"),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': Token.auth!,
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['row-count'] > 0;
  } else {
    print(
        'Error al verificar usuario: ${response.statusCode}, ${response.body}');
    return false;
  }
}

Future<int?> getMPriceListVersionID() async {
  try {
    final response = await http.get(
      Uri.parse(
          '${EndPoints.mPriceList}?\$filter=IsSOPriceList eq true&\$expand=M_PriceList_Version'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return responseData['records'][0]['M_PriceList_Version']?[0]['id'];
    } else {
      print(
          'Error en getMPriceListVersionID: ${response.statusCode}, ${response.body}');
    }
  } catch (e) {
    print('Error en getMPriceListVersionID: $e');
  }
  return null;
}

Future<int?> getMProductCategoryID() async {
  try {
    final response = await http.get(
      Uri.parse(EndPoints.mProductCategory),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return responseData['records'][0]['id'];
    } else {
      print(
          'Error en getMProductCategoryID: ${response.statusCode}, ${response.body}');
    }
  } catch (e) {
    print('Error en getMProductCategoryID: $e');
  }
  return null;
}

Future<int?> getCTaxCategory() async {
  try {
    final response = await http.get(
      Uri.parse(EndPoints.cTaxCategory),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return responseData['records'][0]['id'];
    } else {
      print(
          'Error en getCTaxCategory: ${response.statusCode}, ${response.body}');
    }
  } catch (e) {
    print('Error en getCTaxCategory: $e');
  }
  return null;
}
