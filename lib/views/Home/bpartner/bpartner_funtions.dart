import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../../../API/endpoint.api.dart';
import '../../../API/token.api.dart';
import '../../Auth/auth_funtions.dart';

Future<Map<String, dynamic>> postBPartner({
  required String name,
  required String location,
  required String email,
  required int cTaxTypeID,
  required int cBPartnerGroupID,
  String? taxID,
  required BuildContext context,
}) async {
  try {
    await usuarioAuth(
      context: context,
    );

    bool uniqueUser = await userExists(email);

    if (uniqueUser) {
      return {
        'success': false,
        'message': 'Ya existe un usuario con este correo.',
      };
    }

//? Tercero
    final Map<String, dynamic> partnerData = {
      "Name": name,
      if (taxID != null) "TaxID": taxID,
      "IsCustomer": true,
      "LCO_TaxIdType_ID": cTaxTypeID,
      "C_BP_Group_ID": cBPartnerGroupID,
    };

    final bPartnerResponse = await post(
      Uri.parse(EndPoints.cBPartner),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.auth!,
      },
      body: jsonEncode(partnerData),
    );

    if (bPartnerResponse.statusCode != 201) {
      print('Error al crear el tercero: ${bPartnerResponse.statusCode}');
      print(bPartnerResponse.body);
      return {
        'success': false,
        'message': 'Error al crear el cliente.',
      };
    }

//? Ubicación
    final locationResponse = await post(
      Uri.parse(EndPoints.cLocation),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.auth!,
      },
      body: jsonEncode({
        "Address1": location,
      }),
    );

    if (locationResponse.statusCode != 201) {
      print('Error al crear location: ${locationResponse.statusCode}');
      print(locationResponse.body);
      return {
        'success': false,
        'message': 'Error al crear la dirección.',
      };
    }

    final createdPartner = json.decode(bPartnerResponse.body);
    final int bPartnerID = createdPartner['id'];

    final createdLocation = json.decode(locationResponse.body);
    final int cLocationID = createdLocation['id'];

//? Ubicación del tercero
    final locationPartnerData = {
      "Name": location,
      "C_BPartner_ID": bPartnerID,
      "C_Location_ID": cLocationID,
      "IsShipTo": true,
      "IsPayFrom": true,
      "IsBillTo": true,
      "IsRemitTo": true,
    };

    final locationPartnerResponse = await post(
      Uri.parse(EndPoints.cBPartnerLocation),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.auth!,
      },
      body: jsonEncode(locationPartnerData),
    );

    if (locationPartnerResponse.statusCode != 201) {
      print(
          'Error al crear locationPartner: ${locationPartnerResponse.statusCode}');
      print(locationPartnerResponse.body);
      return {
        'success': false,
        'message': 'Error al asignar la dirección al cliente.',
      };
    }

//? Usuario del tercero
    final userData = {
      "Name": name,
      "C_BPartner_ID": bPartnerID,
      "EMail": email,
      "IsBillTo": true,
    };

    final userResponse = await post(
      Uri.parse(EndPoints.adUser),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.auth!,
      },
      body: jsonEncode(userData),
    );

    if (userResponse.statusCode != 201) {
      print('Error al crear user: ${userResponse.statusCode}');
      print(userResponse.body);
      return {
        'success': false,
        'message': 'Error al crear el usuario.',
      };
    }

    return {
      'success': true,
      'message': 'Cliente creado con éxito.',
      'bpartner': createdPartner,
    };
  } catch (e) {
    print('Excepción general: $e');
    return {
      'success': false,
      'message': 'Error inesperado al crear el cliente.',
    };
  }
}

Future<bool> userExists(String email) async {
  final response = await get(
    Uri.parse("${EndPoints.adUser}?\$filter=EMail eq '$email'"),
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

Future<List<Map<String, dynamic>>?> getCTaxTypeID(BuildContext context) async {
  try {
    await usuarioAuth(
      context: context,
    );

    final response = await get(
      Uri.parse(EndPoints.lcoTaxIdType),
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
            'name': record['Name'] ?? '',
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
    print('Error al obtener tipo de identificacion: $e');
  }
  return null;
}

Future<List<Map<String, dynamic>>?> getCBPGroup(BuildContext context) async {
  try {
    await usuarioAuth(
      context: context,
    );

    final response = await get(
      Uri.parse(EndPoints.cBPGroup),
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
            'name': record['Name'] ?? '',
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
    print('Error al obtener grupo de terceros: $e');
  }
  return null;
}
