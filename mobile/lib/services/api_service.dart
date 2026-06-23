import 'package:dio/dio.dart';
import 'storage_service.dart';
import 'offline_service.dart';
import 'connectivity_service.dart';

class ApiService {
  static const String baseUrl = 'https://tontine-bf.onrender.com/api';

  static Dio get _dio {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = StorageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (err, handler) {
        if (err.response?.statusCode == 401) {
          StorageService.clearAll();
        }
        return handler.next(err);
      },
    ));

    return dio;
  }

  // ── AUTH ──────────────────────────────────────────
  static Future<Map<String, dynamic>> inscription({
    required String nom,
    required String prenom,
    required String telephone,
    required String codePin,
    required String langue,
    required String pays,
    required String moyenPaiement,
    String? indicatif,
  }) async {
    try {
      final ind = indicatif ?? '+226';
      final resp = await _dio.post('/auth/inscription', data: {
        'nom': nom,
        'prenom': prenom,
        'telephone': '$ind$telephone',
        'code_pin': codePin,
        'langue': langue,
        'pays': pays,
        '${moyenPaiement}_numero': '$ind$telephone',
      });
      return resp.data['data'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> connexion({
    required String telephone,
    required String codePin,
    String? indicatif,
  }) async {
    try {
      final ind = indicatif ?? '+226';
      final resp = await _dio.post('/auth/connexion', data: {
        'telephone': '$ind$telephone',
        'code_pin': codePin,
      });
      return resp.data['data'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── TONTINES ──────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getMesTontines() async {
    final connecte = await ConnectivityService.estConnecte();
    if (!connecte) {
      final locales = await OfflineService.getTontinesLocales();
      return locales.map((t) => Map<String, dynamic>.from(t)).toList();
    }
    try {
      final resp = await _dio.get('/tontines');
      final data = resp.data['data'] as List;
      final tontines =
          data.map((e) => Map<String, dynamic>.from(e)).toList();
      await OfflineService.sauvegarderTontines(tontines);
      return tontines;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        final locales = await OfflineService.getTontinesLocales();
        if (locales.isNotEmpty) return locales;
      }
      throw _handleError(e);
    }
  }

  static Future<List<Map<String, dynamic>>> getTontinesPubliques(
      {String search = ''}) async {
    try {
      final resp = await _dio.get('/tontines/publiques',
          queryParameters:
              search.isNotEmpty ? {'search': search} : {});
      return List<Map<String, dynamic>>.from(resp.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> getTontine(String id) async {
    try {
      final resp = await _dio.get('/tontines/$id');
      return resp.data['data'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> creerTontine(
      Map<String, dynamic> data) async {
    try {
      final resp = await _dio.post('/tontines', data: data);
      return resp.data['data'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> demanderAdhesion(String tontineId,
      {String message = ''}) async {
    try {
      await _dio.post('/tontines/$tontineId/demander-adhesion',
          data: {'message': message});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── MEMBRES ───────────────────────────────────────
  static Future<void> inviterMembre(
      String tontineId, String telephone) async {
    try {
      await _dio.post('/tontines/$tontineId/membres/inviter',
          data: {'telephone': telephone});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── COTISATIONS ───────────────────────────────────
  static Future<List<Map<String, dynamic>>> getMesCotisations() async {
    try {
      final resp = await _dio.get('/cotisations/mes-cotisations');
      final data = resp.data['data'] as List;
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>?> getCotisationEnCours(
      String tontineId) async {
    try {
      final resp = await _dio.get('/cotisations/mes-cotisations');
      final data = resp.data['data'] as List;
      final cotisations =
          data.map((e) => Map<String, dynamic>.from(e)).toList();
      final enAttente = cotisations
          .where((c) =>
              c['tontine_id'] == tontineId &&
              c['statut'] == 'en_attente')
          .toList();
      if (enAttente.isEmpty) return null;
      enAttente.sort((a, b) =>
          DateTime.parse(a['date_echeance'])
              .compareTo(DateTime.parse(b['date_echeance'])));
      return enAttente.first;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> initierPaiement({
    required String cotisationId,
    required String methodePaiement,
    String? telephone,
  }) async {
    try {
      final resp = await _dio.post('/cotisations/payer', data: {
        'cotisation_id': cotisationId,
        'methode_paiement': methodePaiement,
        if (telephone != null) 'telephone_paiement': telephone,
      });
      return resp.data['data'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── CATALOGUE ─────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getCatalogue(
      {String? categorie}) async {
    try {
      final resp = await _dio.get('/catalogue', queryParameters: {
        if (categorie != null) 'categorie': categorie,
      });
      final data = resp.data['data'] as List;
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── NOTIFICATIONS ─────────────────────────────────
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final resp = await _dio.get('/notifications');
      return List<Map<String, dynamic>>.from(resp.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> marquerNotificationLue(String id) async {
    try {
      await _dio.put('/notifications/$id/lue');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> marquerToutesNotificationsLues() async {
    try {
      await _dio.put('/notifications/tout-lire');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── PROFIL ────────────────────────────────────────
  static Future<void> mettreAJourProfil(
      Map<String, dynamic> data) async {
    try {
      await _dio.put('/users/profil', data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> enregistrerFcmToken(String token) async {
    try {
      await _dio.post('/users/fcm-token', data: {'fcm_token': token});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── STATISTIQUES ──────────────────────────────────
  static Future<Map<String, dynamic>> getStatistiques(
      String tontineId) async {
    try {
      final resp =
          await _dio.get('/tontines/$tontineId/statistiques');
      return resp.data['data'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── ERREURS ───────────────────────────────────────
  static String _handleError(DioException e) {
    if (e.response?.data?['error'] != null) {
      return e.response!.data['error'];
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connexion lente. Vérifiez votre réseau.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Pas de connexion internet. Mode hors-ligne activé.';
    }
    return 'Erreur inattendue. Réessayez.';
  }
static Future<Map<String, dynamic>> getCompteVirtuel(
    String tontineId) async {
  try {
    final resp =
        await _dio.get('/tontines/$tontineId/compte-virtuel');
    return resp.data['data'];
  } on DioException catch (e) {
    throw _handleError(e);
  }
}

static Future<Map<String, dynamic>> effectuerDepotVirtuel({
  required String tontineId,
  required double montant,
  required String methodePaiement,
  String? telephonePaiement,
}) async {
  try {
    final resp = await _dio.post(
        '/tontines/$tontineId/compte-virtuel/depot',
        data: {
          'montant': montant,
          'methode_paiement': methodePaiement,
          if (telephonePaiement != null)
            'telephone_paiement': telephonePaiement,
        });
    return resp.data['data'];
  } on DioException catch (e) {
    throw _handleError(e);
  }
}

static Future<Map<String, dynamic>> initierRetraitVirtuel({
  required String tontineId,
  required double montant,
  required String methodeRetrait,
  String? telephoneRetrait,
  String? motif,
}) async {
  try {
    final resp = await _dio.post(
        '/tontines/$tontineId/compte-virtuel/retrait/initier',
        data: {
          'montant': montant,
          'methode_retrait': methodeRetrait,
          if (telephoneRetrait != null)
            'telephone_retrait': telephoneRetrait,
          if (motif != null) 'motif': motif,
        });
    return resp.data['data'];
  } on DioException catch (e) {
    throw _handleError(e);
  }
}

static Future<Map<String, dynamic>> voterRetrait({
  required String tontineId,
  required String retraitId,
  required String vote,
}) async {
  try {
    final resp = await _dio.post(
        '/tontines/$tontineId/compte-virtuel/retrait/$retraitId/voter',
        data: {'vote': vote});
    return resp.data;
  } on DioException catch (e) {
    throw _handleError(e);
  }
}  
}