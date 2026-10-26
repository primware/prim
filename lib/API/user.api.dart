import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

class UserData {
  static int? id;
  static String? uu;
  static String? rolName;
  static String? clientName;
  static String? name;
  static String? email;
  static String? phone;
  static Uint8List? imageBytes;
  static List<dynamic>? clients;
  static List<Map<String, dynamic>> organizations = [];

  static Future<void> saveToCache() async {
    final prefs = await SharedPreferences.getInstance();
    if (id != null) await prefs.setInt('UserData_id', id!);
    if (uu != null) await prefs.setString('UserData_uu', uu!);
    if (rolName != null) await prefs.setString('UserData_rolName', rolName!);
    if (clientName != null) await prefs.setString('UserData_clientName', clientName!);
    if (name != null) await prefs.setString('UserData_name', name!);
    if (email != null) await prefs.setString('UserData_email', email!);
    if (phone != null) await prefs.setString('UserData_phone', phone!);
    
    if (imageBytes != null) {
      await prefs.setString('UserData_imageBytes', base64Encode(imageBytes!));
    }
    
    if (clients != null) {
      await prefs.setString('UserData_clients', jsonEncode(clients));
    }
    
    await prefs.setString('UserData_organizations', jsonEncode(organizations));
  }

  static Future<void> loadFromCache() async {
    // Bound the await before touching session state. A late preferences result
    // must not overwrite a user who has already logged in after a timeout.
    final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 20));

    // Validate all cached values before applying any of them to the session.
    final cachedId = prefs.getInt('UserData_id');
    final cachedUu = prefs.getString('UserData_uu');
    final cachedRolName = prefs.getString('UserData_rolName');
    final cachedClientName = prefs.getString('UserData_clientName');
    final cachedName = prefs.getString('UserData_name');
    final cachedEmail = prefs.getString('UserData_email');
    final cachedPhone = prefs.getString('UserData_phone');
    final imageString = prefs.getString('UserData_imageBytes');
    final cachedImage = imageString == null ? null : base64Decode(imageString);
    final clientsString = prefs.getString('UserData_clients');
    final cachedClients = clientsString == null ? null : jsonDecode(clientsString) as List<dynamic>;
    final orgsString = prefs.getString('UserData_organizations');
    final cachedOrganizations = orgsString == null ? <Map<String, dynamic>>[] : List<Map<String, dynamic>>.from(jsonDecode(orgsString));

    id = cachedId;
    uu = cachedUu;
    rolName = cachedRolName;
    clientName = cachedClientName;
    name = cachedName;
    email = cachedEmail;
    phone = cachedPhone;
    imageBytes = cachedImage;
    clients = cachedClients;
    organizations = cachedOrganizations;
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('UserData_'));
    for (String key in keys) {
      await prefs.remove(key);
    }
  }
}
