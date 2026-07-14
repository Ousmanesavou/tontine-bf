import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  static const String _cloudName = 's55o6u5u';
  static const String _uploadPreset = 'tontine_africa';
  static const String _baseUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName';

  // ── UPLOAD IMAGE ──────────────────────────────────
  static Future<String?> uploadImage(String filePath,
      {String folder = 'tontine-africa'}) async {
    try {
      final uri = Uri.parse('$_baseUrl/image/upload');
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = folder;
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body);

      if (response.statusCode == 200) {
        return data['secure_url'];
      } else {
        print('Cloudinary erreur: ${data['error']?['message']}');
        return null;
      }
    } catch (e) {
      print('Erreur upload image: $e');
      return null;
    }
  }

  // ── UPLOAD VIDEO ──────────────────────────────────
  static Future<String?> uploadVideo(String filePath,
      {String folder = 'tontine-africa/videos'}) async {
    try {
      final uri = Uri.parse('$_baseUrl/video/upload');
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = folder;
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body);

      if (response.statusCode == 200) {
        return data['secure_url'];
      } else {
        print('Cloudinary erreur: ${data['error']?['message']}');
        return null;
      }
    } catch (e) {
      print('Erreur upload vidéo: $e');
      return null;
    }
  }

  // ── UPLOAD PHOTO PROFIL ───────────────────────────
  static Future<String?> uploadPhotoProfil(
      String filePath, String userId) async {
    return await uploadImage(filePath,
        folder: 'tontine-africa/profils/$userId');
  }

  // ── UPLOAD PHOTO TONTINE ──────────────────────────
  static Future<String?> uploadPhotoTontine(
      String filePath, String tontineId) async {
    return await uploadImage(filePath,
        folder: 'tontine-africa/tontines/$tontineId');
  }
}
