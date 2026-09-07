// ignore_for_file: unused_local_variable, unused_element, deprecated_member_use, use_build_context_synchronously, avoid_print, depend_on_referenced_packages

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../API/endpoint.dart';
import '../../API/pos.api.dart';
import '../../API/token.api.dart';
import '../../main.dart';
import '../../shared/toast_message.dart';
import 'login_view.dart';
import '../../API/user.api.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<void> handle401(BuildContext context) async {
  Token.auth = null;
  Token.adOrgInfoUU = null;
  POS.bankAccountID = null;
  UserData.rolName = null;
  UserData.imageBytes = null;
  claveController.clear();
  await _clearLastTokenGeneratedAt();

  Navigator.push(context, MaterialPageRoute(builder: (context) => MainApp()));
  ToastMessage.show(context: context, message: "Por su seguridad la sesión a expirado", type: ToastType.warning);
}

Future<void> _loadAppVersion() async {
  final info = await PackageInfo.fromPlatform();
  AppInfo.appVersion = '${info.version}+${info.buildNumber}';
}

const String _lastTokenGeneratedAtKey = 'last_token_generated_at';
const int _tokenReuseWindowMinutes = 40;

Future<void> _saveLastTokenGeneratedAt() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_lastTokenGeneratedAtKey, DateTime.now().toIso8601String());
}

Future<DateTime?> _getLastTokenGeneratedAt() async {
  final prefs = await SharedPreferences.getInstance();
  final rawValue = prefs.getString(_lastTokenGeneratedAtKey);

  if (rawValue == null || rawValue.isEmpty) {
    return null;
  }

  return DateTime.tryParse(rawValue);
}

Future<bool> _canReuseCurrentToken() async {
  if (Token.auth == null || Token.auth!.trim().isEmpty) {
    return false;
  }

  final lastGeneratedAt = await _getLastTokenGeneratedAt();
  if (lastGeneratedAt == null) {
    return false;
  }

  final minutesSinceLastToken = DateTime.now().difference(lastGeneratedAt).inMinutes;
  return minutesSinceLastToken < _tokenReuseWindowMinutes;
}

Future<void> _clearLastTokenGeneratedAt() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_lastTokenGeneratedAtKey);
}

Future<Map<String, dynamic>?> preAuth(String usuario, String clave, BuildContext context) async {
  try {
    if (usuario.isEmpty || clave.isEmpty) {
      return null;
    }

    final Map<String, dynamic> data = {"userName": usuario, "password": clave};

    final response = await post(Uri.parse(EndPoints.postUserAuth), headers: {'Content-Type': 'application/json'}, body: jsonEncode(data));

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      Token.preAuth = 'Bearer ${responseData["token"]}';

      return responseData;
    } else {
      CurrentLogMessage.add('preAuth Error: ${response.statusCode}, ${response.body}', level: 'ERROR', tag: 'preAuth');
    }
  } catch (e) {
    // print(e);
    // if (e is ClientException) {
    //   handle401(context);
    // }
  }
  return null;
}

Future<List<Map<String, dynamic>>?> getRoles(int clientId, BuildContext context) async {
  try {
    final response = await get(
      Uri.parse(GetRol(clientID: clientId).endPoint),
      headers: {'Content-Type': 'application/json; charset=UTF-8', 'Authorization': Token.preAuth!},
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(utf8.decode(response.bodyBytes));

      List<Map<String, dynamic>> roles = (responseData['roles'] as List).map((role) => {'id': role['id'], 'name': role['name']}).toList();
      return roles;
    } else {
      CurrentLogMessage.add('getRoles Error: ${response.statusCode}, ${response.body}', level: 'ERROR', tag: 'getRoles');
    }
  } catch (e) {
    if (e is ClientException) {
      handle401(context);
    }
  }
  return null;
}

Future<List<Map<String, dynamic>>?> getOrganizations(int clientId, int roleId, BuildContext context) async {
  try {
    final response = await get(
      Uri.parse(GetOrganization(rolID: roleId, clientID: clientId).endPoint),
      headers: {'Content-Type': 'application/json', 'Authorization': Token.preAuth!},
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      List<Map<String, dynamic>> organizations = (responseData['organizations'] as List)
          .map((organization) => {'id': organization['id'], 'name': organization['name']})
          .toList();
      return organizations;
    } else {
      CurrentLogMessage.add('getOrganizations Error: ${response.statusCode}, ${response.body}', level: 'ERROR', tag: 'getOrganizations');
    }
  } catch (e) {
    if (e is ClientException) {
      handle401(context);
    }
  }
  return null;
}

Future<bool> getWarehouse({required int clientId, required int roleId, required int organitaionId, required BuildContext context}) async {
  try {
    final response = await get(
      Uri.parse(GetWarehouse(rolID: roleId, clientID: clientId, organizationID: organitaionId).endPoint),
      headers: {'Content-Type': 'application/json', 'Authorization': Token.preAuth!},
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      Token.warehouseID = responseData?['warehouses'][0]['id'];

      return true;
    } else {
      CurrentLogMessage.add('Error en getWarehouse: ${response.statusCode}, ${response.body}', level: 'ERROR', tag: 'getWarehouse');
    }
  } catch (e) {
    CurrentLogMessage.add('Excepción en getWarehouse: $e', level: 'ERROR', tag: 'getWarehouse');
  }
  return false;
}

Future<bool> usuarioAuth({required BuildContext context, bool forceNewToken = false}) async {
  try {
    if (usuarioController.text.isEmpty || claveController.text.isEmpty) {
      return false;
    }

    //? Si han pasado 40 mins o mas, se solicita un nuevo token
    // Si forceNewToken es true, ignoramos el caché (útil al cambiar de organización)
    if (!forceNewToken && await _canReuseCurrentToken()) {
      return true;
    }

    if (Token.warehouseID == null) {
      await getWarehouse(clientId: Token.client!, roleId: Token.rol!, organitaionId: Token.organitation!, context: context);
    }

    final Map<String, dynamic> data = {
      "userName": usuarioController.text.trim(),
      "password": claveController.text.trim(),
      "parameters": {
        "clientId": Token.client,
        "roleId": Token.rol,
        "organizationId": Token.organitation,
        "warehouseId": Token.warehouseID ?? 0,
        "language": "en_US",
      },
    };

    final response = await post(Uri.parse(EndPoints.postUserAuth), headers: {'Content-Type': 'application/json'}, body: jsonEncode(data));

    if (response.statusCode == 200) {
      Token.auth = '${Token.tokenType} ${json.decode(response.body)["token"]}';
      UserData.id = json.decode(response.body)["userId"];
      await _saveLastTokenGeneratedAt();
      bool success = await _loadUserData(context);
      await _loadPOSData(context);
      await _loadPOSPrinterData();
      await _loadChartIDs();
      POSTenderType.isMultiPayment = await _posTenderExists();
      await _loadAppVersion();
      return success;
    } else {
      await _clearLastTokenGeneratedAt();
      CurrentLogMessage.add('usuarioAuth Error: ${response.statusCode}, ${response.body}', level: 'ERROR', tag: 'usuarioAuth');
    }
  } catch (e) {
    await _clearLastTokenGeneratedAt();
    CurrentLogMessage.add('Excepción en usuarioAuth: $e', level: 'ERROR', tag: 'usuarioAuth');
  }
  return false;
}

Future<bool> _loadUserData(BuildContext context) async {
  try {
    final response = await get(
      Uri.parse(GetUserData(adUserID: UserData.id!).endPoint),
      headers: {'Content-Type': 'application/json; charset=UTF-8', 'Authorization': Token.auth!},
    );

    if (response.statusCode == 200) {
      final userData = json.decode(utf8.decode(response.bodyBytes))['records'][0];

      UserData.uu = userData['uid'];
      UserData.name = userData['Name'];
      UserData.email = userData['EMail'];
      UserData.phone = userData['Phone'];

      if (userData['AD_Image_ID'] != null) {
        UserData.imageBytes = base64Decode(userData['AD_Image_ID']['data']);
      }
      return true;
    } else {
      CurrentLogMessage.add(
        'Error al cargar loadUserData, codigo: ${response.statusCode}, detalle: ${response.body}',
        level: 'ERROR',
        tag: '_loadUserData',
      );
    }
  } catch (e) {
    CurrentLogMessage.add('Excepción en _loadUserData: $e', level: 'ERROR', tag: '_loadUserData');
  }

  return false;
}

Future<bool> _loadPOSPrinterData() async {
  try {
    final response = await get(
      Uri.parse('${EndPoints.adOrgInfo}?\$filter=AD_Org_ID eq ${Token.organitation}&\$expand=C_Location_ID'),
      headers: {'Content-Type': 'application/json; charset=UTF-8', 'Authorization': Token.auth!},
    );

    if (response.statusCode == 200) {
      final record = json.decode(utf8.decode(response.bodyBytes))['records'][0];

      Token.adOrgInfoUU = record['uid']?.toString();
      POSPrinter.headerName = record['AD_Client_ID']?['identifier'];
      POSPrinter.headerAddress =
          '${record['C_Location_ID']?['Address1'] ?? ''}${record['C_Location_ID']?['Address2'] != null ? ', ${record['C_Location_ID']?['Address2']}' : ''}${record['C_Location_ID']?['Address3'] != null ? ', ${record['C_Location_ID']?['Address3']}' : ''}${record['C_Location_ID']?['Address4'] != null ? ', ${record['C_Location_ID']?['Address4']}' : ''}';
      POSPrinter.headerPhone = record['Phone2']?.toString() ?? record['Phone']?.toString();
      POSPrinter.headerTaxID = record['TaxID'];
      POSPrinter.headerDV = record['dv'];
      POSPrinter.headerEmail = record['EMail'];

      if (record['Logo_ID'] != null) {
        POSPrinter.logo = base64Decode(record['Logo_ID']['data']);
        POSPrinter.isLogoSet = true;
      } else {
        final bytes = await rootBundle.load('assets/img/logo.png');
        POSPrinter.logo = bytes.buffer.asUint8List();
      }
      return true;
    } else {
      CurrentLogMessage.add(
        'Error al cargar _loadPOSPrinterData, codigo: ${response.statusCode}, detalle: ${response.body}',
        level: 'ERROR',
        tag: '_loadPOSPrinterData',
      );
    }
  } catch (e) {
    CurrentLogMessage.add('Excepción en _loadPOSPrinterData: $e', level: 'ERROR', tag: '_loadPOSPrinterData');
  }

  return false;
}

Future<void> _loadDynamicPOSPrinterConfig() async {
  if (!POS.isPOS || POS.cPosID == null) return;
  try {
    final response = await get(
      Uri.parse('${EndPoints.cdsPOSPrinterConfig}?\$filter=C_POS_ID eq ${POS.cPosID}'),
      headers: {'Content-Type': 'application/json; charset=UTF-8', 'Authorization': Token.auth!},
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      final records = decoded['records'] as List?;
      if (records != null && records.isNotEmpty) {
        final data = records.first;
        POSPrinter.header1 = data['Header1']?.toString();
        POSPrinter.header2 = data['Header2']?.toString();
        POSPrinter.header3 = data['Header3']?.toString();
        POSPrinter.header4 = data['Header4']?.toString();
        POSPrinter.footer1 = data['Footer1']?.toString();
        POSPrinter.footer2 = data['Footer2']?.toString();
        POSPrinter.footer3 = data['Footer3']?.toString();
        POSPrinter.footer4 = data['Footer4']?.toString();
      }
    }
  } catch (e) {
    CurrentLogMessage.add('Excepción en _loadDynamicPOSPrinterConfig: $e', level: 'ERROR', tag: '_loadDynamicPOSPrinterConfig');
  }
}

Future<void> _loadDiscountTaxConfig() async {
  final chargeId = POS.discountChargeID;
  if (chargeId == null) return;

  try {
    final chargeResponse = await get(
      Uri.parse('${EndPoints.cCharge}?\$filter=C_Charge_ID eq $chargeId&\$select=C_TaxCategory_ID'),
      headers: {'Content-Type': 'application/json; charset=UTF-8', 'Authorization': Token.auth!},
    );
    if (chargeResponse.statusCode != 200) {
      throw Exception('No se pudo consultar C_Charge: ${chargeResponse.statusCode} ${chargeResponse.body}');
    }

    final chargeRecords = (json.decode(utf8.decode(chargeResponse.bodyBytes))['records'] as List?) ?? const [];
    final dynamic taxCategoryField = chargeRecords.isNotEmpty ? chargeRecords.first['C_TaxCategory_ID'] : null;
    final dynamic taxCategoryId = taxCategoryField is Map ? taxCategoryField['id'] : null;
    if (taxCategoryId is! num) {
      throw Exception('El charge $chargeId no tiene C_TaxCategory_ID configurado.');
    }

    final categoryResponse = await get(
      Uri.parse(
        '${EndPoints.cTaxCategory}?\$filter=C_TaxCategory_ID eq ${taxCategoryId.toInt()}&\$select=Name&\$expand=C_Tax(\$select=Name,Rate)',
      ),
      headers: {'Content-Type': 'application/json; charset=UTF-8', 'Authorization': Token.auth!},
    );
    if (categoryResponse.statusCode != 200) {
      throw Exception('No se pudo consultar C_TaxCategory: ${categoryResponse.statusCode} ${categoryResponse.body}');
    }

    final categoryRecords = (json.decode(utf8.decode(categoryResponse.bodyBytes))['records'] as List?) ?? const [];
    final List<dynamic> taxes = categoryRecords.isNotEmpty ? (categoryRecords.first['C_Tax'] as List? ?? const []) : const [];
    if (taxes.isEmpty) {
      throw Exception('La categoría ${taxCategoryId.toInt()} no tiene impuestos configurados.');
    }

    final firstTax = taxes.first;
    final dynamic taxId = firstTax['id'];
    final dynamic rawRate = firstTax['Rate'];
    final rate = rawRate is num ? rawRate.toDouble() : double.tryParse(rawRate?.toString() ?? '');
    if (taxId is! num || rate == null) {
      throw Exception('El primer impuesto de la categoría ${taxCategoryId.toInt()} no tiene ID o Rate válido.');
    }

    POS.discountTaxID = taxId.toInt();
    POS.discountTaxRate = rate;
  } catch (e) {
    POS.discountTaxID = null;
    POS.discountTaxRate = null;
    CurrentLogMessage.add('Configuración fiscal del descuento no disponible: $e', level: 'ERROR', tag: '_loadDiscountTaxConfig');
  }
}

Future<void> _loadPOSData(BuildContext context) async {
  try {
    // Evita reutilizar el charge de una sesión/POS anterior cuando el campo no viene configurado.
    POS.discountChargeID = null;
    POS.discountTaxID = null;
    POS.discountTaxRate = null;
    POS.bankAccountID = null;
    POS.isModifyPrice = false;
    final String filter = 'C_POS_ID eq ${POS.cPosID}';

    final response = await get(
      Uri.parse(
        '${EndPoints.cPos}?\$filter=$filter&\$expand=C_DocType_ID,C_DocTypeRefund_ID,C_BankAccount_ID',
      ),
      headers: {'Content-Type': 'application/json; charset=UTF-8', 'Authorization': Token.auth!},
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      final records = decoded['records'] as List?;

      if (records == null || records.isEmpty) {
        //? No hay Terminal PDV configurado para este usuario, obteniendo datos por defecto del priceList
        POS.priceListID ??= await _getMPriceListID();
        POS.priceListVersionID = await getMPriceListVersion(POS.priceListID ?? 0);
        POS.cPaymentTermID = await _getcPaymentTermID();
        await fetchTaxs();
        await _getCDocTypeComplete();

        return;
      }

      final posData = records.first;

      POS.priceListID = posData['M_PriceList_ID']?['id'];
      POS.docTypeID = posData['C_DocType_ID']?['id'];
      POS.docTypeName = posData['C_DocType_ID']?['Name'];
      POS.docSubType = posData['C_DocType_ID']?['DocSubTypeSO']?['id'];
      POS.docTypeRefundID = posData['C_DocTypeRefund_ID']?['id'];
      POS.docTypeRefundName = posData['C_DocTypeRefund_ID']?['Name'];
      POS.docSubTypeRefund = posData['C_DocTypeRefund_ID']?['DocSubTypeSO']?['id'];
      POS.templatePartnerID = posData['C_BPartnerCashTrx_ID']?['id'];
      POS.templatePartnerName = posData['C_BPartnerCashTrx_ID']?['identifier'];
      POS.warehouseID = posData['M_Warehouse_ID']?['id'];
      POS.isModifyPrice = posData['IsModifyPrice'] == true;
      final dynamic bankAccount = posData['C_BankAccount_ID'];
      final dynamic rawBankAccountId = bankAccount is Map ? bankAccount['id'] : bankAccount;
      POS.bankAccountID = rawBankAccountId is num
          ? rawBankAccountId.toInt()
          : int.tryParse(rawBankAccountId?.toString() ?? '');
      final dynamic discountChargeId = posData['POS_Discount_Charge_ID']?['id'];
      POS.discountChargeID = discountChargeId is num && discountChargeId.toInt() > 0 ? discountChargeId.toInt() : null;
      await _loadDiscountTaxConfig();
      POS.priceListVersionID = await getMPriceListVersion(POS.priceListID ?? 0);

      await fetchTaxs();

      POS.isPOS = POS.cPosID != null;
      await _loadDynamicPOSPrinterConfig();

      // Tomamos la informacion del Yappy si existe, si no se mantiene en null
      Yappy.yappyConfigID = posData?['CDS_YappyConf_ID']?['id'];
      Yappy.groupId = posData?['CDS_YappyGroup_ID']?['identifier'];
      Yappy.deviceId = posData?['CDS_YappyReceiptUnit_ID']?['identifier'];

      if (Yappy.yappyConfigID != null && Yappy.groupId != null && Yappy.deviceId != null) {
        await _getYappyEndPoint();
        await _getYappyKeys();
      }

      // Cargamos los tipos de documentos disponibles para el POS
      POS.docTypesComplete = [
        if (POS.docTypeID != null) {'id': POS.docTypeID.toString(), 'name': POS.docTypeName ?? '', 'DocSubTypeSO': POS.docSubType ?? ''},
        if (POS.docTypeRefundID != null)
          {'id': POS.docTypeRefundID.toString(), 'name': POS.docTypeRefundName ?? '', 'DocSubTypeSO': POS.docSubTypeRefund ?? ''},
      ];
    } else {
      CurrentLogMessage.add(
        'Error al cargar loadPOSData, código: ${response.statusCode}, detalle: ${response.body}',
        level: 'ERROR',
        tag: '_loadPOSData',
      );
    }
  } catch (e) {
    CurrentLogMessage.add('Excepción en loadPOSData: $e', level: 'ERROR', tag: '_loadPOSData');
    if (e is ClientException) {
      handle401(context);
    }
  }
}

Future<bool> _posTenderExists() async {
  final response = await get(
    Uri.parse(EndPoints.cPOSTenderType),
    headers: {'Content-Type': 'application/json', 'Authorization': Token.auth!},
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['row-count'] > 0;
  } else {
    CurrentLogMessage.add(
      'Error al verificar existencia de PosTenderExists: ${response.statusCode}, ${response.body}',
      level: 'ERROR',
      tag: '_posTenderExists',
    );
    return false;
  }
}

Future<void> _getYappyKeys() async {
  try {
    final response = await get(
      Uri.parse(
        '${EndPoints.cdsYappyGroup}?\$filter=CDS_YappyConf_ID eq ${Yappy.yappyConfigID}&\$select=Name,Value,CDS_API_Key,CDS_Secret_Key',
      ),
      headers: {'Content-Type': 'application/json', 'Authorization': Token.auth!},
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final record = responseData['records'][0];

      Yappy.apiKey = record['CDS_API_Key'];
      Yappy.secretKey = record['CDS_Secret_Key'];
    } else {
      CurrentLogMessage.add('Error en _getYappyKeys: ${response.statusCode}, ${response.body}', level: 'ERROR', tag: '_getYappyKeys');
    }
  } catch (e) {
    CurrentLogMessage.add('Error en _getYappyKeys: $e', level: 'ERROR', tag: '_getYappyKeys');
  }
}

Future<void> _getYappyEndPoint() async {
  try {
    final response = await get(
      Uri.parse(
        '${EndPoints.cdsYappyConf}?\$filter=CDS_YappyConf_ID eq ${Yappy.yappyConfigID}&\$select=Name,CDS_YappyEndPoint,CDS_IsYappyTest',
      ),
      headers: {'Content-Type': 'application/json', 'Authorization': Token.auth!},
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final record = responseData['records'][0];

      Base.yappyURL = record['CDS_YappyEndPoint'];

      Yappy.isTest = record['CDS_IsYappyTest'] ?? false;
    } else {
      CurrentLogMessage.add(
        'Error en _getYappyEndPoint: ${response.statusCode}, ${response.body}',
        level: 'ERROR',
        tag: '_getYappyEndPoint',
      );
    }
  } catch (e) {
    CurrentLogMessage.add('Error en _getYappyEndPoint: $e', level: 'ERROR', tag: '_getYappyEndPoint');
  }
}

Future<int?> _getMPriceListID() async {
  try {
    final response = await get(
      Uri.parse('${EndPoints.mPriceList}?\$filter=IsSOPriceList eq true AND IsDefault eq true'),
      headers: {'Content-Type': 'application/json', 'Authorization': Token.auth!},
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final record = responseData['records'][0];

      return responseData['records'][0]['id'];
    } else {
      CurrentLogMessage.add('Error en _getMPriceListID: ${response.statusCode}, ${response.body}', level: 'ERROR', tag: '_getMPriceListID');
    }
  } catch (e) {
    CurrentLogMessage.add('Error en _getMPriceListID: $e', level: 'ERROR', tag: '_getMPriceListID');
  }
  return null;
}

Future<int?> getMPriceListVersion(int id) async {
  try {
    final response = await get(
      Uri.parse('${EndPoints.mPriceList}?\$filter=M_PriceList_ID eq $id&\$expand=M_PriceList_Version'),
      headers: {'Content-Type': 'application/json', 'Authorization': Token.auth!},
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
      CurrentLogMessage.add(
        'Error en _getMPriceListVersion: ${response.statusCode}, ${response.body}',
        level: 'ERROR',
        tag: '_getMPriceListVersion',
      );
    }
  } catch (e) {
    CurrentLogMessage.add('Error en _getMPriceListVersion: $e', level: 'ERROR', tag: '_getMPriceListVersion');
  }
  return null;
}

Future<int?> _getcPaymentTermID() async {
  try {
    final response = await get(
      Uri.parse('${EndPoints.cPaymentTermID}?\$filter=IsDefault eq true'),
      headers: {'Content-Type': 'application/json', 'Authorization': Token.auth!},
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final record = responseData['records'][0];

      return responseData['records'][0]['id'];
    } else {
      CurrentLogMessage.add(
        'Error en _getcPaymentTermID: ${response.statusCode}, ${response.body}',
        level: 'ERROR',
        tag: '_getcPaymentTermID',
      );
    }
  } catch (e) {
    CurrentLogMessage.add('Error en _getcPaymentTermID: $e', level: 'ERROR', tag: '_getcPaymentTermID');
  }
  return null;
}

Future<int?> _getCDocTypeComplete() async {
  try {
    final response = await get(
      Uri.parse('${EndPoints.cDocType}?\$filter=DocBaseType eq \'SOO\'&\$orderby=Name&\$select=Name,DocSubTypeSO'),
      headers: {'Content-Type': 'application/json', 'Authorization': Token.auth!},
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final records = responseData['records'] as List;
      POS.docTypesComplete = records
          .map((r) => {'id': r['id'].toString(), 'name': r['Name'] ?? '', 'DocSubTypeSO': r['DocSubTypeSO']['id'] ?? ''})
          .toList();
    } else {
      CurrentLogMessage.add(
        'Error en _getCDocTypeComplete: ${response.statusCode}, ${response.body}',
        level: 'ERROR',
        tag: '_getCDocTypeComplete',
      );
    }
  } catch (e) {
    CurrentLogMessage.add('Error en _getCDocTypeComplete: $e', level: 'ERROR', tag: '_getCDocTypeComplete');
  }
  return null;
}

Future<int?> _getCDocType() async {
  try {
    final response = await get(
      Uri.parse(
        '${EndPoints.cDocType}?\$filter=DocBaseType eq \'SOO\' AND IsDefault eq true OR DocSubTypeSO eq \'OB\'&\$orderby=IsDefault desc',
      ),
      headers: {'Content-Type': 'application/json', 'Authorization': Token.auth!},
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return responseData['records'][0]['id'];
    } else {
      CurrentLogMessage.add('Error en _getCDocType: ${response.statusCode}, ${response.body}', level: 'ERROR', tag: '_getCDocType');
    }
  } catch (e) {
    CurrentLogMessage.add('Error en _getCDocType: $e', level: 'ERROR', tag: '_getCDocType');
  }
  return null;
}

Future<int?> _getChartIDByName(String chartName) async {
  try {
    final response = await get(
      Uri.parse("${EndPoints.adChart}?\$filter=Name eq '$chartName'"),
      headers: {'Content-Type': 'application/json', 'Authorization': Token.auth!},
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(utf8.decode(response.bodyBytes));
      final records = responseData['records'] as List?;

      if (records != null && records.isNotEmpty) {
        return records.first['id'];
      }

      return null;
    } else {
      CurrentLogMessage.add(
        'Error en _getChartIDByName para $chartName: ${response.statusCode}, ${response.body}',
        level: 'ERROR',
        tag: '_getChartIDByName',
      );
    }
  } catch (e) {
    CurrentLogMessage.add('Error en _getChartIDByName para $chartName: $e', level: 'ERROR', tag: '_getChartIDByName');
  }

  return null;
}

Future<void> _loadChartIDs() async {
  Charts.salesYTDID = await _getChartIDByName('Sales YTD');
  Charts.salesPerDayID = await _getChartIDByName('Sales Per Day');
  Charts.salesYTDBySalesRepID = await _getChartIDByName('Sales YTD By SalesRep');
  Charts.salesPerDayByProductCategoryID = await _getChartIDByName('Sales Per Day By Product Category');
}

Future<List<Map<String, dynamic>>?> getOrganizationsAfterLogin(BuildContext context) async {
  try {
    final response = await get(
      Uri.parse(EndPoints.getOrganizationsAfterLogin),
      headers: {'Content-Type': 'application/json', 'Authorization': Token.auth!},
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      List<Map<String, dynamic>> organizations = (responseData['records'] as List)
          .map((organization) => {'id': organization['id'], 'name': organization['Name']})
          .toList();
      return organizations;
    } else if (response.statusCode == 401) {
      handle401(context);
    } else {
      CurrentLogMessage.add(
        'Error getOrganizationsAfterLogin: ${response.statusCode}, ${response.body}',
        level: 'ERROR',
        tag: 'getOrganizationsAfterLogin',
      );
    }
  } catch (e) {
    CurrentLogMessage.add('Error general getOrganizationsAfterLogin: $e', level: 'ERROR', tag: 'getOrganizationsAfterLogin');
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
      headers: {'Content-Type': 'application/json; charset=UTF-8', 'Authorization': Token.auth!},
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
          },
      };
    } else {
      throw Exception('Error al cargar los impuestos: ${response.statusCode}');
    }
  } catch (e) {
    CurrentLogMessage.add('Excepción al obtener impuesto: $e', level: 'ERROR', tag: 'fetchTaxs');
  }
}
