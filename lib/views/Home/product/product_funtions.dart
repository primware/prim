import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../../../API/endpoint.api.dart';
import '../../../API/token.api.dart';
import '../../Auth/auth_funtions.dart';

Future<Map<String, dynamic>> postProduct({
  required String name,
  String? sku,
  String? upc,
  required int categoryID,
  required int taxID,
  required String price,
  required BuildContext context,
}) async {
  try {
    await usuarioAuth(
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

//? Crear el producto
    final Map<String, dynamic> productData = {
      "Name": name,
      "C_UOM_ID": 100,
      "M_Product_Category_ID": categoryID,
      "C_TaxCategory_ID": taxID,
      if (sku != null && sku.isNotEmpty) "SKU": sku,
      if (upc != null && upc.isNotEmpty) "UPC": upc,
      "IsSold": true,
    };

    final productResponse = await post(
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

    final priceResponse = await post(
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
  final response = await get(
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
    final response = await get(
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

Future<List<Map<String, dynamic>>?> getMProductCategoryID(
    BuildContext context) async {
  try {
    await usuarioAuth(
      context: context,
    );

    final response = await get(
      Uri.parse(EndPoints.mProductCategory),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(utf8.decode(response.bodyBytes));

      if (responseData['records'] != null && responseData['records'] is List) {
        List<Map<String, dynamic>> records =
            (responseData['records'] as List).map((record) {
          return {
            'id': record['id'],
            'name': record['Name'] ?? record['name'] ?? '',
          };
        }).toList();
        return records;
      } else {
        print('Error: formato inesperado de la respuesta.');
        return null;
      }
    } else {
      print('Error: ${response.statusCode}, ${response.body}');
    }
  } catch (e) {
    print('Error al obtener categorías de productos: $e');
  }
  return null;
}

Future<List<Map<String, dynamic>>?> getCTaxCategoryID(
    BuildContext context) async {
  try {
    await usuarioAuth(
      context: context,
    );

    final response = await get(
      Uri.parse(EndPoints.cTaxCategory),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(utf8.decode(response.bodyBytes));

      if (responseData['records'] != null && responseData['records'] is List) {
        List<Map<String, dynamic>> records =
            (responseData['records'] as List).map((record) {
          return {
            'id': record['id'],
            'name': record['Name'] ?? record['name'] ?? '',
          };
        }).toList();
        return records;
      } else {
        print('Error: formato inesperado de la respuesta.');
        return null;
      }
    } else {
      print('Error: ${response.statusCode}, ${response.body}');
    }
  } catch (e) {
    print('Error al obtener impuestos de productos: $e');
  }
  return null;
}

Future<int?> getMProductPriceID(int productID) async {
  try {
    final response = await get(
      Uri.parse(
          "${EndPoints.mProductPrice}?\$filter=M_Product_ID eq $productID"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['records'] != null && data['records'].isNotEmpty) {
        return data['records'][0]['id'];
      }
    } else {
      print(
          "Error al obtener M_ProductPrice_ID: ${response.statusCode} - ${response.body}");
    }
  } catch (e) {
    print("Excepción en getMProductPriceID: $e");
  }
  return null;
}

Future<Map<String, dynamic>> putProduct({
  required int id,
  required String name,
  String? sku,
  String? upc,
  required int taxID,
  required int categoryID,
  required String price,
  required BuildContext context,
}) async {
  try {
    await usuarioAuth(context: context);

    // Primero actualizar datos del producto
    final Map<String, dynamic> productData = {
      "Name": name,
      if (sku != null && sku.isNotEmpty) "SKU": sku,
      if (upc != null && upc.isNotEmpty) "UPC": upc,
      "C_TaxCategory_ID": {"id": taxID},
      "M_Product_Category_ID": {"id": categoryID}
    };

    final response = await put(
      Uri.parse("${EndPoints.mProduct}($id)"),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.auth!,
      },
      body: jsonEncode(productData),
    );

    if (response.statusCode != 200) {
      print("Error actualizando producto: ${response.body}");
      return {"success": false, "message": "Error al actualizar producto."};
    }

    // Luego actualizar precios usando el ID de M_ProductPrice
    final productPriceID = await getMProductPriceID(id);
    if (productPriceID == null) {
      return {
        "success": false,
        "message": "No se encontró M_ProductPrice para este producto."
      };
    }

    final Map<String, dynamic> priceData = {
      "PriceStd": double.tryParse(price) ?? 0,
      "PriceLimit": double.tryParse(price) ?? 0,
      "PriceList": double.tryParse(price) ?? 0,
    };

    final priceResponse = await put(
      Uri.parse("${EndPoints.mProductPrice}($productPriceID)"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.auth!,
      },
      body: jsonEncode(priceData),
    );

    if (priceResponse.statusCode != 200) {
      print("Error actualizando precio: ${priceResponse.body}");
      return {"success": false, "message": "Error al actualizar precio."};
    }

    return {"success": true};
  } catch (e) {
    print("Excepción en putProduct: $e");
    return {"success": false, "message": "Excepción: $e"};
  }
}
