import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class OfflineService {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'tontine_bf.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tontines (
            id TEXT PRIMARY KEY,
            nom TEXT,
            type TEXT,
            description TEXT,
            montant_cotisation REAL,
            periodicite TEXT,
            periodicite_jours INTEGER,
            nombre_membres INTEGER,
            date_debut TEXT,
            date_fin TEXT,
            statut TEXT,
            responsable_id TEXT,
            jours_restants INTEGER,
            pourcentage_completion INTEGER,
            total_membres INTEGER,
            membres_payes INTEGER,
            position_rotation INTEGER,
            a_recu INTEGER,
            synced_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE cotisations (
            id TEXT PRIMARY KEY,
            tontine_id TEXT,
            montant REAL,
            periode_numero INTEGER,
            date_echeance TEXT,
            date_paiement TEXT,
            statut TEXT,
            methode_paiement TEXT,
            nom_tontine TEXT,
            synced_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE notifications_cache (
            id TEXT PRIMARY KEY,
            type TEXT,
            titre TEXT,
            message TEXT,
            est_lu INTEGER DEFAULT 0,
            created_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE actions_en_attente (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT,
            data TEXT,
            created_at TEXT,
            tentatives INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  // ── Tontines ──────────────────────────────────────

  static Future<void> sauvegarderTontines(
      List<Map<String, dynamic>> tontines) async {
    final database = await db;
    final batch = database.batch();
    for (final t in tontines) {
      batch.insert(
        'tontines',
        {
          'id': t['id'],
          'nom': t['nom'],
          'type': t['type'],
          'description': t['description'],
          'montant_cotisation': t['montant_cotisation'],
          'periodicite': t['periodicite'],
          'periodicite_jours': t['periodicite_jours'],
          'nombre_membres': t['nombre_membres'],
          'date_debut': t['date_debut'],
          'date_fin': t['date_fin'],
          'statut': t['statut'],
          'jours_restants': t['jours_restants'],
          'pourcentage_completion': t['pourcentage_completion'],
          'total_membres': t['total_membres'],
          'membres_payes': t['membres_payes_periode_actuelle'],
          'position_rotation': t['position_rotation'],
          'a_recu': t['a_recu'] == true ? 1 : 0,
          'synced_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getTontinesLocales() async {
    final database = await db;
    return database.query('tontines', orderBy: 'synced_at DESC');
  }

  // ── Cotisations ───────────────────────────────────

  static Future<void> sauvegarderCotisations(
      List<Map<String, dynamic>> cotisations) async {
    final database = await db;
    final batch = database.batch();
    for (final c in cotisations) {
      batch.insert(
        'cotisations',
        {
          'id': c['id'],
          'tontine_id': c['tontine_id'],
          'montant': c['montant'],
          'periode_numero': c['periode_numero'],
          'date_echeance': c['date_echeance'],
          'date_paiement': c['date_paiement'],
          'statut': c['statut'],
          'methode_paiement': c['methode_paiement'],
          'nom_tontine': c['nom_tontine'],
          'synced_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getCotisationsLocales(
      String tontineId) async {
    final database = await db;
    return database.query(
      'cotisations',
      where: 'tontine_id = ? AND statut = ?',
      whereArgs: [tontineId, 'en_attente'],
      orderBy: 'date_echeance ASC',
    );
  }

  // ── Actions en attente (offline) ──────────────────

  static Future<void> sauvegarderActionEnAttente(
      String type, Map<String, dynamic> data) async {
    final database = await db;
    await database.insert('actions_en_attente', {
      'type': type,
      'data': data.toString(),
      'created_at': DateTime.now().toIso8601String(),
      'tentatives': 0,
    });
  }

  static Future<List<Map<String, dynamic>>> getActionsEnAttente() async {
    final database = await db;
    return database.query(
      'actions_en_attente',
      orderBy: 'created_at ASC',
    );
  }

  static Future<void> supprimerAction(int id) async {
    final database = await db;
    await database.delete(
      'actions_en_attente',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> viderCache() async {
    final database = await db;
    await database.delete('tontines');
    await database.delete('cotisations');
    await database.delete('notifications_cache');
  }

  static Future<bool> cacheRecent() async {
    final database = await db;
    final result = await database.query(
      'tontines',
      limit: 1,
      orderBy: 'synced_at DESC',
    );
    if (result.isEmpty) return false;
    final syncedAt = DateTime.parse(result.first['synced_at'] as String);
    return DateTime.now().difference(syncedAt).inMinutes < 30;
  }
}