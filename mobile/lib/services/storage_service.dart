import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> saveToken(String token) async {
    await _prefs.setString('auth_token', token);
  }

  static String? getToken() => _prefs.getString('auth_token');

  static Future<void> saveUser(Map<String, dynamic> user) async {
    await _prefs.setString('user_data', jsonEncode(user));
    if (user['telephone'] != null) {
      await _prefs.setString('dernier_telephone', user['telephone']);
    }
  }

  static Map<String, dynamic>? getUser() {
    final data = _prefs.getString('user_data');
    if (data == null) return null;
    return jsonDecode(data);
  }

  static String? getDernierTelephone() => _prefs.getString('dernier_telephone');

  static Future<void> saveLangue(String langue) async {
    await _prefs.setString('langue', langue);
  }

  static String? getLangue() => _prefs.getString('langue');

  static Future<void> saveTontinesCache(List<dynamic> tontines) async {
    await _prefs.setString('tontines_cache', jsonEncode(tontines));
    await _prefs.setString('tontines_cache_date', DateTime.now().toIso8601String());
  }

  static List<dynamic>? getTontinesCache() {
    final data = _prefs.getString('tontines_cache');
    if (data == null) return null;
    final dateStr = _prefs.getString('tontines_cache_date');
    if (dateStr != null) {
      final date = DateTime.parse(dateStr);
      if (DateTime.now().difference(date).inHours > 1) return null;
    }
    return jsonDecode(data);
  }

  static Future<void> clearAll() async {
    await _prefs.remove('auth_token');
    await _prefs.remove('user_data');
    await _prefs.remove('tontines_cache');
  }
}

static Future<void> savePays(String pays) async {
  await _prefs.setString('pays', pays);
}

static String? getPays() => _prefs.getString('pays');