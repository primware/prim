import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../../../API/endpoint.api.dart';
import '../../../API/token.api.dart';
import '../../Auth/auth_funtions.dart';

Future<Map<String, dynamic>> postBPartner({
  required String name,
  required String location,
  String? email,
  required int cTaxTypeID,
  required int cBPartnerGroupID,
  String? taxID,
  String? dv,
  required String customerType,
  required BuildContext context,
}) async {
  try {
    await usuarioAuth(context: context);

    if (email != null && email.isNotEmpty) {
      bool uniqueUser = await userExists(email);

      if (uniqueUser) {
        return {
          'success': false,
          'message': 'Ya existe un usuario con este correo.',
        };
      }
    }

    //? Ubicación
    final locationResponse = await post(
      Uri.parse(EndPoints.cLocation),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.auth!,
      },
      body: jsonEncode({"Address1": location}),
    );

    if (locationResponse.statusCode != 201) {
      print('Error al crear location: ${locationResponse.statusCode}');
      print(locationResponse.body);
      return {'success': false, 'message': 'Error al crear la dirección.'};
    }

    final createdLocation = json.decode(locationResponse.body);
    final int cLocationID = createdLocation['id'];

    //? Tercero con usuario y ubicación
    final Map<String, dynamic> partnerData = {
      "Name": name,
      if (taxID != null && taxID.isNotEmpty) "TaxID": taxID,
      if (dv != null && dv.isNotEmpty) "dv": dv,
      "IsCustomer": true,
      "LCO_TaxIdType_ID": cTaxTypeID,
      "C_BP_Group_ID": cBPartnerGroupID,
      "TipoClienteFE": customerType,
      "AD_User": [
        {
          "Name": name,
          if (email != null && email.isNotEmpty) "EMail": email,
          "IsBillTo": true,
        },
      ],
      "C_BPartner_Location": [
        {"Name": location, "C_Location_ID": cLocationID},
      ],
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
      return {'success': false, 'message': 'Error al crear el cliente.'};
    }

    final createdPartner = json.decode(bPartnerResponse.body);

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
    headers: {'Content-Type': 'application/json', 'Authorization': Token.auth!},
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['row-count'] > 0;
  } else {
    print(
      'Error al verificar usuario: ${response.statusCode}, ${response.body}',
    );
    return false;
  }
}

Future<List<Map<String, dynamic>>?> getCTaxTypeID(BuildContext context) async {
  try {
    await usuarioAuth(context: context);

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
        List<Map<String, dynamic>> records = (responseData['records'] as List)
            .map((record) {
              return {'id': record['id'], 'name': record['Name'] ?? ''};
            })
            .toList();
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
    await usuarioAuth(context: context);

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
        List<Map<String, dynamic>> records = (responseData['records'] as List)
            .map((record) {
              return {'id': record['id'], 'name': record['Name'] ?? ''};
            })
            .toList();
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

Future<Map<String, dynamic>> putBPartner({
  required int id,
  required String name,
  required String location,
  String? taxID,
  String? dv,
  required int cBPartnerGroupID,
  String? email,
  required int cTaxTypeID,
  required String customerType,
  required BuildContext context,
  required int? userID,
  required int? locationID,
}) async {
  try {
    await usuarioAuth(context: context);

    // Validar email duplicado si se cambió (como userExists)
    if (email == null) {
      final emailCheckResponse = await get(
        Uri.parse(
          "${EndPoints.adUser}?\$filter=EMail eq '$email' and C_BPartner_ID neq $id",
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': Token.auth!,
        },
      );
      if (emailCheckResponse.statusCode == 200) {
        final data = json.decode(emailCheckResponse.body);
        if (data['row-count'] > 0) {
          return {
            "success": false,
            "message": "El correo ya está siendo usado por otro usuario.",
          };
        }
      }
    }

    // Validar TaxID duplicado si se cambió (como fetchPartnerByTaxAndDV)
    if (taxID != null) {
      final taxCheckResponse = await get(
        Uri.parse(
          "${EndPoints.cBPartner}?\$filter=TaxID eq '$taxID' and C_BPartner_ID neq $id",
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': Token.auth!,
        },
      );
      if (taxCheckResponse.statusCode == 200) {
        final taxData = json.decode(taxCheckResponse.body);
        if (taxData['row-count'] > 0) {
          return {
            "success": false,
            "message": "La identificación ya está en uso por otro cliente.",
          };
        }
      }
    }

    // Actualizar C_BPartner primero
    final Map<String, dynamic> bpartnerData = {
      "Name": name,
      if (taxID != null && taxID.isNotEmpty) "TaxID": taxID,
      if (dv != null && dv.isNotEmpty) "dv": dv,
      "C_BP_Group_ID": {"id": cBPartnerGroupID},
      "LCO_TaxIdType_ID": {"id": cTaxTypeID},
      "TipoClienteFE": customerType,
    };
    final responseBPartner = await put(
      Uri.parse("${EndPoints.cBPartner}/$id"),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.auth!,
      },
      body: jsonEncode(bpartnerData),
    );
    if (responseBPartner.statusCode != 200) {
      print("Error PUT C_BPartner: ${responseBPartner.body}");
      return {"success": false, "message": "Error al actualizar el cliente."};
    }

    // Actualizar AD_User relacionado
    if (userID != null) {
      final Map<String, dynamic> userData = {
        "Name": name,
        if (email != null) "EMail": email,
      };
      final responseUser = await put(
        Uri.parse("${EndPoints.adUser}/$userID"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': Token.auth!,
        },
        body: jsonEncode(userData),
      );
      if (responseUser.statusCode != 200) {
        print("Error PUT AD_User: ${responseUser.body}");
        return {
          "success": false,
          "message": "Error al actualizar el usuario del cliente.",
        };
      }
    }

    // Actualizar C_BPartnerLocation y C_Location
    if (locationID != null && location.trim().isNotEmpty) {
      final locationPartnerUpdate = {"Name": location};
      final responseLocationPartner = await put(
        Uri.parse("${EndPoints.cBPartnerLocation}/$locationID"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': Token.auth!,
        },
        body: jsonEncode(locationPartnerUpdate),
      );
      if (responseLocationPartner.statusCode == 200) {
        final responseBody = jsonDecode(responseLocationPartner.body);
        final cLocationId = responseBody['C_Location_ID']?['id'];
        if (cLocationId != null) {
          // Luego actualizar C_Location
          final locationUpdate = {"Address1": location};
          final responseLocation = await put(
            Uri.parse("${EndPoints.cLocation}/$cLocationId"),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': Token.auth!,
            },
            body: jsonEncode(locationUpdate),
          );
          if (responseLocation.statusCode != 200) {
            print("Error actualizando C_Location: ${responseLocation.body}");
          }
        }
      } else {
        print("Error PUT C_BPartnerLocation: ${responseLocationPartner.body}");
      }
    }

    return {"success": true};
  } catch (e) {
    print("Excepción en putBPartner: $e");
    return {"success": false, "message": "Excepción: $e"};
  }
}
