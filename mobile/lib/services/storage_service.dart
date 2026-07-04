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

  static Future<void> savePays(String pays) async {
    await _prefs.setString('pays', pays);
  }

  static String? getPays() => _prefs.getString('pays');

  static Future<void> saveFontSize(double size) async {
    await _prefs.setDouble('font_size', size);
  }

  static double? getFontSize() => _prefs.getDouble('font_size');

  static Future<void> saveFcmToken(String token) async {
    await _prefs.setString('fcm_token', token);
  }

  static String? getFcmToken() => _prefs.getString('fcm_token');

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

  static Future<void> saveNotificationsActives(bool actif) async {
    await _prefs.setBool('notifications_actives', actif);
  }

  static bool getNotificationsActives() => _prefs.getBool('notifications_actives') ?? true;

  static Future<void> saveSonActif(bool actif) async {
    await _prefs.setBool('son_actif', actif);
  }

  static bool getSonActif() => _prefs.getBool('son_actif') ?? true;

  static Future<void> saveVocalActif(bool actif) async {
    await _prefs.setBool('vocal_actif', actif);
  }

  static bool getVocalActif() => _prefs.getBool('vocal_actif') ?? true;

  static Future<void> saveModeSombre(bool sombre) async {
    await _prefs.setBool('mode_sombre', sombre);
  }

  static bool getModeSombre() => _prefs.getBool('mode_sombre') ?? false;

  static Future<void> saveIndicatif(String indicatif) async {
    await _prefs.setString('indicatif', indicatif);
  }

  static String getIndicatif() => _prefs.getString('indicatif') ?? '+226';

  static Future<void> saveDevise(String devise) async {
    await _prefs.setString('devise', devise);
  }

  static String getDevise() => _prefs.getString('devise') ?? 'XOF';

  static Future<void> setPremiereConnexion(bool val) async {
    await _prefs.setBool('premiere_connexion', val);
  }

  static bool isPremiereConnexion() => _prefs.getBool('premiere_connexion') ?? true;

  static Future<void> clearAll() async {
    await _prefs.remove('auth_token');
    await _prefs.remove('user_data');
    await _prefs.remove('tontines_cache');
    await _prefs.remove('tontines_cache_date');
    await _prefs.remove('fcm_token');
  }

  static Future<void> clearSession() async {
    await _prefs.remove('auth_token');
    await _prefs.remove('user_data');
  }

  static Map<String, dynamic> getAllSettings() {
    return {
      'langue': getLangue() ?? 'fr',
      'pays': getPays() ?? 'BF',
      'font_size': getFontSize() ?? 14.0,
      'notifications_actives': getNotificationsActives(),
      'son_actif': getSonActif(),
      'vocal_actif': getVocalActif(),
      'mode_sombre': getModeSombre(),
      'indicatif': getIndicatif(),
      'devise': getDevise(),
    };
  }

  static Future<void> saveAllSettings(Map<String, dynamic> settings) async {
    if (settings['langue'] != null) await saveLangue(settings['langue']);
    if (settings['pays'] != null) await savePays(settings['pays']);
    if (settings['font_size'] != null) await saveFontSize(settings['font_size']);
    if (settings['notifications_actives'] != null) {
      await saveNotificationsActives(settings['notifications_actives']);
    }
    if (settings['son_actif'] != null) await saveSonActif(settings['son_actif']);
    if (settings['vocal_actif'] != null) await saveVocalActif(settings['vocal_actif']);
    if (settings['mode_sombre'] != null) await saveModeSombre(settings['mode_sombre']);
    if (settings['indicatif'] != null) await saveIndicatif(settings['indicatif']);
    if (settings['devise'] != null) await saveDevise(settings['devise']);
  }
}
