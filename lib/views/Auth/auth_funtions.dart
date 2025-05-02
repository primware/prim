// ignore_for_file: unused_local_variable, unused_element, deprecated_member_use, use_build_context_synchronously, avoid_print, depend_on_referenced_packages

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../API/endpoint.api.dart';
import '../../API/token.api.dart';
import '../../main.dart';
import '../../shared/message.custom.dart';

import 'login_view.dart';
import '../../API/user.api.dart';

Future<void> handle401(BuildContext context) async {
  Token.auth = null;
  UserData.rolName = null;
  UserData.imageBytes = null;
  usuarioController.clear();
  claveController.clear();

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => MainApp(),
    ),
  );
  SnackMessage.show(
    context: context,
    message: "Por su seguridad la sesión a expirado",
    type: SnackType.warning,
  );
}

Future<Map<String, dynamic>?> preAuth(
    String usuario, String clave, BuildContext context) async {
  try {
    if (usuario.isEmpty || clave.isEmpty) {
      return null;
    }

    final Map<String, dynamic> data = {"userName": usuario, "password": clave};

    final response = await http.post(
      Uri.parse(EndPoints.postUserAuth),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      Token.preAuth = 'Bearer ${responseData["token"]}';

      return responseData;
    } else {
      print('Error: ${response.statusCode}, ${response.body}');
    }
  } catch (e) {
    print(e);
    if (e is http.ClientException) {
      handle401(context);
    }
  }
  return null;
}

Future<List<Map<String, dynamic>>?> getRoles(
    int clientId, BuildContext context) async {
  try {
    final response = await http.get(
      Uri.parse(GetRol(clientID: clientId).endPoint),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.preAuth!,
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(utf8.decode(response.bodyBytes));

      List<Map<String, dynamic>> roles = (responseData['roles'] as List)
          .map((role) => {
                'id': role['id'],
                'name': role['name'],
              })
          .toList();
      return roles;
    } else {
      print('Error: ${response.statusCode}, ${response.body}');
    }
  } catch (e) {
    if (e is http.ClientException) {
      handle401(context);
    }
  }
  return null;
}

Future<List<Map<String, dynamic>>?> getOrganizations(
    int clientId, int roleId, BuildContext context) async {
  try {
    final response = await http.get(
      Uri.parse(GetOrganization(rolID: roleId, clientID: clientId).endPoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.preAuth!,
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      List<Map<String, dynamic>> organizations =
          (responseData['organizations'] as List)
              .map((organization) => {
                    'id': organization['id'],
                    'name': organization['name'],
                  })
              .toList();
      return organizations;
    } else {
      print('Error: ${response.statusCode}, ${response.body}');
    }
  } catch (e) {
    if (e is http.ClientException) {
      handle401(context);
    }
  }
  return null;
}

Future<bool> getWarehouse({
  required int clientId,
  required int roleId,
  required int organitaionId,
  required BuildContext context,
}) async {
  try {
    final response = await http.get(
      Uri.parse(GetWarehouse(
              rolID: roleId, clientID: clientId, organizationID: organitaionId)
          .endPoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.preAuth!,
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      Token.warehouseID = responseData['warehouses'][0]['id'];

      return true;
    } else {
      print('Error en getWarehouse: ${response.statusCode}, ${response.body}');
    }
  } catch (e) {
    if (e is http.ClientException) {
      handle401(context);
    }
  }
  return false;
}

Future<bool> usuarioAuth(
    {required String usuario,
    required String clave,
    required BuildContext context}) async {
  try {
    if (usuario.isEmpty || clave.isEmpty) {
      return false;
    }

    if (Token.warehouseID == null) {
      await getWarehouse(
          clientId: Token.client!,
          roleId: Token.rol!,
          organitaionId: Token.organitation!,
          context: context);
    }

    final Map<String, dynamic> data = {
      "userName": usuario,
      "password": clave,
      "parameters": {
        "clientId": Token.client,
        "roleId": Token.rol,
        "organizationId": Token.organitation,
        "warehouseId": Token.warehouseID,
        "language": "en_US"
      }
    };

    final response = await http.post(
      Uri.parse(EndPoints.postUserAuth),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      Token.auth = '${Token.tokenType} ${json.decode(response.body)["token"]}';
      UserData.id = json.decode(response.body)["userId"];
      bool success = await loadUserData(context);

      return success;
    } else {
      print('Error: ${response.statusCode}, ${response.body}');
    }
  } catch (e) {
    if (e is http.ClientException) {
      handle401(context);
    }
  }
  return false;
}

Future<bool> superAuth(
    String usuario, String clave, BuildContext context) async {
  try {
    if (usuario.isEmpty || clave.isEmpty) {
      return false;
    }

    final Map<String, dynamic> data = {
      "userName": usuario,
      "password": clave,
      "parameters": {
        "clientId": Token.client,
        "roleId": 1000032, //! Produccion
        "organizationId": Token.organitation,
        "warehouseId": 0,
        "language": "en_US"
      }
    };

    final response = await http.post(
      Uri.parse(EndPoints.postUserAuth),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      Token.superAuth = 'Bearer ${json.decode(response.body)["token"]}';

      return true;
    } else {
      print('Error: ${response.statusCode}, ${response.body}');
    }
  } catch (e) {
    if (e is http.ClientException) {
      handle401(context);
    }
  }
  return false;
}

Future<bool> loadUserData(BuildContext context) async {
  try {
    final response = await http.get(
      Uri.parse(GetUserData(adUserID: UserData.id!).endPoint),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode == 200) {
      final userData =
          json.decode(utf8.decode(response.bodyBytes))['records'][0];

      UserData.name = userData['Name'];
      UserData.email = userData['EMail'];
      UserData.phone = userData['Phone'];

      if (userData['AD_Image_ID'] != null) {
        UserData.imageBytes = base64Decode(userData['AD_Image_ID']['data']);
      }
      return true;
    } else {
      print(
          'Error al cargar loadUserData, codigo: ${response.statusCode}, detalle: ${response.body}');
    }
  } catch (e) {
    if (e is http.ClientException) {
      handle401(context);
    }
  }

  return false;
}

Future<List<Map<String, dynamic>>?> getOrganizationsAfterLogin(
    BuildContext context) async {
  try {
    final response = await http.get(
      Uri.parse(EndPoints.getOrganizationsAfterLogin),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      List<Map<String, dynamic>> organizations =
          (responseData['records'] as List)
              .map((organization) => {
                    'id': organization['id'],
                    'name': organization['Name'],
                  })
              .toList();
      return organizations;
    } else if (response.statusCode == 401) {
      handle401(context);
    } else {
      print(
          'Error getOrganizationsAfterLogin: ${response.statusCode}, ${response.body}');
    }
  } catch (e) {
    print('Error general getOrganizationsAfterLogin: $e');
  }
  return null;
}
