// ignore_for_file: unused_local_variable, unused_element, deprecated_member_use, use_build_context_synchronously, avoid_print, depend_on_referenced_packages

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../../API/endpoint.api.dart';
import '../../API/pos.api.dart';
import '../../API/token.api.dart';
import '../../main.dart';
import '../../shared/toast_message.dart';
import 'login_view.dart';
import '../../API/user.api.dart';

Future<void> handle401(BuildContext context) async {
  Token.auth = null;
  UserData.rolName = null;
  UserData.imageBytes = null;
  // usuarioController.clear();
  claveController.clear();

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => MainApp(),
    ),
  );
  ToastMessage.show(
    context: context,
    message: "Por su seguridad la sesión a expirado",
    type: ToastType.warning,
  );
}

Future<Map<String, dynamic>?> preAuth(
    String usuario, String clave, BuildContext context) async {
  try {
    if (usuario.isEmpty || clave.isEmpty) {
      return null;
    }

    final Map<String, dynamic> data = {"userName": usuario, "password": clave};

    final response = await post(
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
    // print(e);
    // if (e is ClientException) {
    //   handle401(context);
    // }
  }
  return null;
}

Future<List<Map<String, dynamic>>?> getRoles(
    int clientId, BuildContext context) async {
  try {
    final response = await get(
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
    if (e is ClientException) {
      handle401(context);
    }
  }
  return null;
}

Future<List<Map<String, dynamic>>?> getOrganizations(
    int clientId, int roleId, BuildContext context) async {
  try {
    final response = await get(
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
    if (e is ClientException) {
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
    final response = await get(
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
      Token.warehouseID = responseData?['warehouses'][0]['id'];

      return true;
    } else {
      print('Error en getWarehouse: ${response.statusCode}, ${response.body}');
    }
  } catch (e) {
    print(e);
  }
  return false;
}

Future<bool> usuarioAuth({required BuildContext context}) async {
  try {
    if (usuarioController.text.isEmpty || claveController.text.isEmpty) {
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
      "userName": usuarioController.text.trim(),
      "password": claveController.text.trim(),
      "parameters": {
        "clientId": Token.client,
        "roleId": Token.rol,
        "organizationId": Token.organitation,
        "warehouseId": Token.warehouseID ?? 0,
        "language": "en_US"
      }
    };

    final response = await post(
      Uri.parse(EndPoints.postUserAuth),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      Token.auth = '${Token.tokenType} ${json.decode(response.body)["token"]}';
      UserData.id = json.decode(response.body)["userId"];
      bool success = await _loadUserData(context);
      await _loadPOSData(context);
      await _loadPOSPrinterData();
      POSTenderType.isMultiPayment = await _posTenderExists();
      return success;
    } else {
      print('Error: ${response.statusCode}, ${response.body}');
    }
  } catch (e) {
    print(e);
  }
  return false;
}

Future<bool> _loadUserData(BuildContext context) async {
  try {
    final response = await get(
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
    print(e);
  }

  return false;
}

Future<bool> _loadPOSPrinterData() async {
  try {
    final response = await get(
      Uri.parse(
          '${EndPoints.adOrgInfo}?\$filter=AD_Org_ID eq ${Token.organitation}'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode == 200) {
      final record = json.decode(utf8.decode(response.bodyBytes))['records'][0];

      POSPrinter.headerName = record['AD_Client_ID']?['identifier'];
      POSPrinter.headerAddress = record['Address1'];
      POSPrinter.headerPhone = record['Phone'];
      POSPrinter.headerEmail = record['EMail'];

      if (record['Logo_ID'] != null) {
        POSPrinter.logo = base64Decode(record['Logo_ID']['data']);
      }
      return true;
    } else {
      print(
          'Error al cargar _loadPOSPrinterData, codigo: ${response.statusCode}, detalle: ${response.body}');
    }
  } catch (e) {
    print(e);
  }

  return false;
}

Future<void> _loadPOSData(BuildContext context) async {
  try {
    final String filter = POS.cPosID != null
        ? 'C_POS_ID eq ${POS.cPosID}'
        : 'SalesRep_ID eq ${UserData.id}';

    final response = await get(
      Uri.parse(
          '${EndPoints.cPos}?\$filter=$filter&\$expand=C_DocType_ID,C_DocTypeRefund_ID'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      final records = decoded['records'] as List?;

      if (records == null || records.isEmpty) {
        print(
            'No hay Terminal PDV configurado para este usuario, obteniendo datos por defecto del priceList');
        POS.priceListID ??= await _getMPriceListID();
        POS.priceListVersionID =
            await _getMPriceListVersion(POS.priceListID ?? 0);
        await fetchTaxs();
        await _getCDocTypeComplete();

        return;
      }

      final posData = records.first;

      POS.priceListID = posData['M_PriceList_ID']?['id'];
      POS.docTypeID = posData['C_DocType_ID']?['id'];
      POS.docTypeName = posData['C_DocType_ID']?['PrintName'];
      POS.docTypeRefundName = posData['C_DocTypeRefund_ID']?['PrintName'];
      POS.templatePartnerID = posData['C_BPartnerCashTrx_ID']?['id'];
      POS.templatePartnerName = posData['C_BPartnerCashTrx_ID']?['identifier'];
      POS.docSubTypeRefund =
          posData['C_DocTypeRefund_ID']?['DocSubTypeSO']?['id'];
      POS.docTypeRefundID = posData['C_DocTypeRefund_ID']?['id'];
      POS.priceListVersionID =
          await _getMPriceListVersion(POS.priceListID ?? 0);

      await fetchTaxs();

      POS.docSubType = posData['C_DocType_ID']?['DocSubTypeSO']?['id'];
      POS.isPOS = POS.docSubType == 'WR' || POS.cPosID != null;
      //? WR = Orden Punto de Venta

      // Tomamos la informacion del Yappy si existe, si no se mantiene en null
      Yappy.yappyConfigID = posData?['CDS_YappyConf_ID']?['id'];
      Yappy.groupId = posData?['CDS_YappyGroup_ID']?['identifier'];
      Yappy.deviceId = posData?['CDS_YappyReceiptUnit_ID']?['identifier'];

      if (Yappy.yappyConfigID != null &&
          Yappy.groupId != null &&
          Yappy.deviceId != null) {
        await _getYappyEndPoint();
        await _getYappyKeys();
      }

      // Cargamos los tipos de documentos disponibles para el POS
      POS.docTypesComplete = [
        {
          'id': POS.docTypeID.toString(),
          'name': POS.docTypeName ?? '',
          'DocSubTypeSO': POS.docSubType ?? ''
        },
        if (POS.docTypeRefundID != null)
          {
            'id': POS.docTypeRefundID.toString(),
            'name': POS.docTypeRefundName ?? '',
            'DocSubTypeSO': POS.docSubTypeRefund ?? ''
          }
      ];
    } else {
      print(
          'Error al cargar loadPOSData, código: ${response.statusCode}, detalle: ${response.body}');
    }
  } catch (e) {
    print('Excepción en loadPOSData: $e');
    if (e is ClientException) {
      handle401(context);
    }
  }
}

Future<bool> _posTenderExists() async {
  final response = await get(
    Uri.parse(EndPoints.cPOSTenderType),
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
        'Error al verificar existencia de PosTenderExists: ${response.statusCode}, ${response.body}');
    return false;
  }
}

Future<void> _getYappyKeys() async {
  try {
    final response = await get(
      Uri.parse(
          '${EndPoints.cdsYappyGroup}?\$filter=CDS_YappyConf_ID eq ${Yappy.yappyConfigID}&\$select=Name,Value,CDS_API_Key,CDS_Secret_Key'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final record = responseData['records'][0];

      Yappy.apiKey = record['CDS_API_Key'];
      Yappy.secretKey = record['CDS_Secret_Key'];
    } else {
      print(
          'Error en _getMPriceListID: ${response.statusCode}, ${response.body}');
    }
  } catch (e) {
    print('Error en _getMPriceListID: $e');
  }
}

Future<void> _getYappyEndPoint() async {
  try {
    final response = await get(
      Uri.parse(
          '${EndPoints.cdsYappyConf}?\$filter=CDS_YappyConf_ID eq ${Yappy.yappyConfigID}&\$select=Name,CDS_YappyEndPoint,CDS_IsYappyTest'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final record = responseData['records'][0];

      Base.yappyURL = record['CDS_YappyEndPoint'];

      Yappy.isTest = record['CDS_IsYappyTest'] ?? false;
    } else {
      print(
          'Error en _getMPriceListID: ${response.statusCode}, ${response.body}');
    }
  } catch (e) {
    print('Error en _getMPriceListID: $e');
  }
}

Future<int?> _getMPriceListID() async {
  try {
    final response = await get(
      Uri.parse(
          '${EndPoints.mPriceList}?\$filter=IsSOPriceList eq true AND IsDefault eq true'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final record = responseData['records'][0];

      return responseData['records'][0]['id'];
    } else {
      print(
          'Error en _getMPriceListID: ${response.statusCode}, ${response.body}');
    }
  } catch (e) {
    print('Error en _getMPriceListID: $e');
  }
  return null;
}

Future<int?> _getMPriceListVersion(int id) async {
  try {
    final response = await get(
      Uri.parse(
          '${EndPoints.mPriceList}?\$filter=M_PriceList_ID eq $id&\$expand=M_PriceList_Version'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final record = responseData['records'][0];
      final versions = record['M_PriceList_Version'] as List?;
      if (versions != null && versions.isNotEmpty) {
        final latestVersion = versions.first;
        return latestVersion['id'];
      }
    } else {
      print(
          'Error en _getMPriceListID: ${response.statusCode}, ${response.body}');
    }
  } catch (e) {
    print('Error en _getMPriceListID: $e');
  }
  return null;
}

Future<int?> _getCDocTypeComplete() async {
  try {
    final response = await get(
      Uri.parse(
          '${EndPoints.cDocType}?\$filter=DocBaseType eq \'SOO\'&\$orderby=Name&\$select=PrintName,DocSubTypeSO'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final records = responseData['records'] as List;
      POS.docTypesComplete = records
          .map((r) => {
                'id': r['id'].toString(),
                'name': r['PrintName'] ?? '',
                'DocSubTypeSO': r['DocSubTypeSO']['id'] ?? ''
              })
          .toList();
    } else {
      print(
          'Error en _getCDocTypeComplete: ${response.statusCode}, ${response.body}');
    }
  } catch (e) {
    print('Error en _getCDocTypeComplete: $e');
  }
  return null;
}

Future<int?> _getCDocType() async {
  try {
    final response = await get(
      Uri.parse(
          '${EndPoints.cDocType}?\$filter=DocBaseType eq \'SOO\' AND IsDefault eq true OR DocSubTypeSO eq \'OB\'&\$orderby=IsDefault desc'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return responseData['records'][0]['id'];
    } else {
      print('Error en _getCDocType: ${response.statusCode}, ${response.body}');
    }
  } catch (e) {
    print('Error en _getCDocType: $e');
  }
  return null;
}

Future<List<Map<String, dynamic>>?> getOrganizationsAfterLogin(
    BuildContext context) async {
  try {
    final response = await get(
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

Future<String> fetchAppVersion() async {
  try {
    final response = await get(Uri.parse('index.html'));

    if (response.statusCode == 200) {
      final htmlContent = response.body;

      final regex = RegExp(r'flutter_bootstrap\.js\?v=(\d+)"');
      final match = regex.firstMatch(htmlContent);

      if (match != null) {
        return 'Versión: ${match.group(1)}';
      } else {
        return 'Versión: no encontrada';
      }
    } else {
      return 'Versión: error al cargar index.html';
    }
  } catch (e) {
    return 'No es web';
  }
}

Future<void> fetchTaxs() async {
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
      POS.principalTaxs = {
        for (var record in jsonResponse['records'])
          record['C_TaxCategory_ID']['id']: {
            'id': record['id'],
            'name': record['Name'],
            'rate': record['Rate'],
            'istaxexempt': record['IsTaxExempt'],
            'issalestax': record['IsSalesTax'],
            'isdefault': record['IsDefault'],
          }
      };
    } else {
      throw Exception('Error al cargar los impuestos: ${response.statusCode}');
    }
  } catch (e) {
    print('Excepción al obtener impuesto: $e');
  }
}
