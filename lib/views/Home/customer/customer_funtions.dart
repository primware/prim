import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../API/endpoint.api.dart';
import '../../../API/token.api.dart';
import '../../Auth/auth_funtions.dart';
import '../../Auth/login_view.dart';
import 'customer_controllers.dart';

Future<bool> userExists(String email) async {
  final response = await http.get(
    Uri.parse("${EndPoints.user}?\$filter=EMail eq '$email'"),
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

Future<List<Map<String, dynamic>>> fetchCustomer(
    {required String id, required BuildContext context}) async {
  try {
    if (await usuarioAuth(
        usuario: usuarioController.text.trim(),
        clave: claveController.text.trim(),
        context: context)) {
      final response = await http.get(
        Uri.parse(GetCustomerData(id: id).endPoint),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': Token.auth!,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        final records = jsonResponse['records'] as List;

        return records.map((record) {
          final salesRep = record['SalesRep_ID'];
          final customState = record['AMP_CustomStates_ID'];
          final customSubState = record['AMP_CustomStates_Info_ID'];
          final adUserList = record['AD_User'] ?? [{}];

          final user = adUserList.isNotEmpty ? adUserList[0] : {};

          return {
            'partnerID': record['id'],
            'value': record['Value'] ?? '',
            'name': record['Name'] ?? '',
            'address': record['Description'] ?? '',
            'taxId': record['TaxID'] ?? '',
            'name2': record['Name2'] ?? '',
            'salesRep': salesRep != null
                ? {'id': salesRep['id'], 'name': salesRep['identifier']}
                : null,
            'customState': customState != null
                ? {'id': customState['id'], 'name': customState['identifier']}
                : null,
            'customSubState': customSubState != null
                ? {
                    'id': customSubState['id'],
                    'name': customSubState['identifier']
                  }
                : null,
            'userID': user['id'] ?? '',
            'email': user['EMail'] ?? '',
            'phone': user['Phone'] ?? '',
            'mobile': user['Phone2'] ?? '',
            'birthday': user['Birthday'] ?? '',
            'comments': user['Comments'] ?? '',
            'AD_Image_ID': user['AD_Image_ID']?['data'],
          };
        }).toList();
      } else {
        throw Exception('Error al cargar los clientes');
      }
    } else {
      return [];
    }
  } catch (e) {
    print('Excepción al obtener clientes: $e');
    return [];
  }
}

Future<List<Map<String, dynamic>>> fetchSalesRep(
    {required BuildContext context}) async {
  try {
    if (await usuarioAuth(
        usuario: usuarioController.text.trim(),
        clave: claveController.text.trim(),
        context: context)) {
      final response = await http.get(
        Uri.parse(EndPoints.salesRep),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': Token.auth!,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        final records = jsonResponse['records'] as List;

        return records
            .where((record) =>
                record['AD_User'] != null &&
                (record['AD_User'] as List).isNotEmpty)
            .map((record) {
          final firstUser = record['AD_User'][0];
          return {
            'id': firstUser['id'],
            'name': firstUser['Name'],
          };
        }).toList();
      } else {
        throw Exception('Error al cargar los representantes comerciales');
      }
    } else {
      return [];
    }
  } catch (e) {
    print('Excepción al obtener representantes comerciales: $e');
    return [];
  }
}

Future<List<Map<String, dynamic>>> fetchCustomStateSales(
    {required BuildContext context}) async {
  try {
    if (await usuarioAuth(
        usuario: usuarioController.text.trim(),
        clave: claveController.text.trim(),
        context: context)) {
      final response = await http.get(
        Uri.parse(EndPoints.customStateSales),
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
            'description': record['Description'] ?? 'Sin descricción',
            'isInTransit': record['IsInTransit']?['id'] ?? 'N/A',
            'subStates': record['AMP_CustomStates_Info'] != null
                ? (record['AMP_CustomStates_Info'] as List)
                    .map((sub) => {
                          'id': sub['id'],
                          'name': sub['Name'],
                          'description': sub['Description'] ?? 'Sin descricción'
                        })
                    .toList()
                : [],
          };
        }).toList();
      } else {
        throw Exception('Error al cargar los estados personalizados');
      }
    } else {
      return [];
    }
  } catch (e) {
    print('Excepción al obtener estados personalizados: $e');
    return [];
  }
}

Future<bool> postNewClientUser(
    {String? base64,
    required int? salesRep,
    required int? state,
    required int? substate,
    required BuildContext context}) async {
  try {
    if (await usuarioAuth(
        usuario: usuarioController.text.trim(),
        clave: claveController.text.trim(),
        context: context)) {
      final Map<String, dynamic> data = {
        "Name": nombreController.text.trim(),
        "Name2": apellidoController.text.trim(),
        "TaxID": taxIdController.text.trim(),
        "IsCustomer": true,
        if (salesRep != null) "SalesRep_ID": salesRep,
        if (state != null) "AMP_CustomStates_ID": state,
        if (substate != null) "AMP_CustomStates_Info_ID": substate,
        "Description": direccionController.text.trim(),
      };

      final response = await http.post(
        Uri.parse(EndPoints.partner),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': Token.auth!,
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        bool succes = await _postNewUser(
            cBpartnerId: json.decode(response.body)["id"],
            base64: base64,
            context: context);
        if (succes) {
          return true;
        }
      } else {
        print(
            'Error postNewClientUser: ${response.statusCode}, ${response.body}');
      }
    }
  } catch (e) {
    if (e is http.ClientException) {
      print('Error de postNewClientUser: ${e.message}');
    } else {
      print('Error general postNewClientUser: $e');
    }
  }
  return false;
}

Future<bool> _postNewUser(
    {String? base64,
    required int cBpartnerId,
    required BuildContext context}) async {
  try {
    final Map<String, dynamic> data = {
      "Name":
          '${nombreController.text.trim()} ${apellidoController.text.trim()}',
      "EMail": correoController.text.trim(),
      "Phone": telefonoController.text.trim(),
      "Phone2": movilController.text.trim(),
      "Comments": comentariosController.text.trim(),
      if (cumpleanosController.text.trim() != "")
        "Birthday": cumpleanosController.text.trim(),
      "C_BPartner_ID": cBpartnerId,
      "Password": taxIdController.text.trim(),
      if (base64!.isNotEmpty) "AD_Image_ID": {"data": base64}
    };

    final response = await http.post(
      Uri.parse(EndPoints.user),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.auth!,
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      await _putRol(
          json.decode(response.body)["id"], context, Base.rolEstudiante);
      return true;
    } else {
      print('Error postNewUser: ${response.statusCode}, ${response.body}');
    }
  } catch (e) {
    if (e is http.ClientException) {
      print('Error de postNewUser: ${e.message}');
    } else {
      print('Error general postNewUser: $e');
    }
  }
  return false;
}

Future<bool> _putRol(int userID, BuildContext context, int rol) async {
  try {
    final Map<String, dynamic> data = {
      "AD_Role_ID": {"id": rol},
      "AD_User_ID": {"id": userID},
    };

    final response = await http.post(
      Uri.parse(EndPoints.rol),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.auth!,
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else if (response.statusCode == 401) {
      print('error al agregar el rol');
      handle401(context);
    } else {
      print('Error: ${response.statusCode}, ${response.body}');
    }
  } catch (e) {
    if (e is http.ClientException) {
      print('Error de cliente: ${e.message}');
    } else {
      print('Error general: $e');
    }
  }
  return false;
}

Future<bool> putUpdateCustomer(BuildContext context,
    {String? base64,
    required int userID,
    required int? salesRep,
    required int? state,
    required int? substate,
    required int partnerID}) async {
  try {
    if (await usuarioAuth(
        usuario: usuarioController.text.trim(),
        clave: claveController.text.trim(),
        context: context)) {
      final Map<String, dynamic> data = {
        "Name": nombreController.text.trim(),
        "Name2": apellidoController.text.trim(),
        "TaxID": taxIdController.text.trim(),
        "IsCustomer": true,
        if (salesRep != null) "SalesRep_ID": salesRep,
        if (state != null) "AMP_CustomStates_ID": state,
        if (substate != null) "AMP_CustomStates_Info_ID": substate,
        "Description": direccionController.text.trim(),
      };

      final response = await http.put(
        Uri.parse('${EndPoints.partner}/$partnerID'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': Token.auth!,
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (await _putUser(userID: userID, base64: base64, context)) {
          return true;
        }
      } else {
        print(
            'Error putUpdateCustomer: ${response.statusCode}, ${response.body}');
      }
    }
  } catch (e) {
    if (e is http.ClientException) {
      handle401(context);
    }
  }
  return false;
}

Future<bool> _putUser(BuildContext context,
    {required int userID, String? base64}) async {
  try {
    final Map<String, dynamic> data = {
      "Name":
          '${nombreController.text.trim()} ${apellidoController.text.trim()}',
      "EMail": correoController.text.trim(),
      "Phone": telefonoController.text.trim(),
      "Phone2": movilController.text.trim(),
      "Comments": comentariosController.text.trim(),
      if (cumpleanosController.text.trim() != "")
        "Birthday": cumpleanosController.text.trim(),
      "Password": taxIdController.text.trim(),
      if (base64!.isNotEmpty) "AD_Image_ID": {"data": base64}
    };

    final response = await http.put(
      Uri.parse('${EndPoints.user}/$userID'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.auth!,
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      print('Error _putUser: ${response.statusCode}, ${response.body}');
    }
  } catch (e) {
    if (e is http.ClientException) {
      handle401(context);
    }
  }
  return false;
}
