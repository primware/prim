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
    final prefs = await SharedPreferences.getInstance();
    
    id = prefs.getInt('UserData_id');
    uu = prefs.getString('UserData_uu');
    rolName = prefs.getString('UserData_rolName');
    clientName = prefs.getString('UserData_clientName');
    name = prefs.getString('UserData_name');
    email = prefs.getString('UserData_email');
    phone = prefs.getString('UserData_phone');
    
    final imageString = prefs.getString('UserData_imageBytes');
    if (imageString != null) {
      imageBytes = base64Decode(imageString);
    }
    
    final clientsString = prefs.getString('UserData_clients');
    if (clientsString != null) {
      clients = jsonDecode(clientsString);
    }
    
    final orgsString = prefs.getString('UserData_organizations');
    if (orgsString != null) {
      organizations = List<Map<String, dynamic>>.from(jsonDecode(orgsString));
    }
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('UserData_'));
    for (String key in keys) {
      await prefs.remove(key);
    }
  }
}
