import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/candidature.dart';

abstract interface class CandidatureRepository {
  Future<List<Candidature>> toutes();
  Future<void> enregistrer(Candidature candidature);
  Future<void> supprimer(int id);
  Future<void> fermer();
}

class CandidatureStorageException implements Exception {
  const CandidatureStorageException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Seule cette couche connaît SQLite. La factory injectable permet de tester
/// les vraies requêtes et la migration sans plugin Android/iOS.
class SqliteCandidatureRepository implements CandidatureRepository {
  SqliteCandidatureRepository({DatabaseFactory? factory, String? databasePath})
    : _factory = factory ?? databaseFactory,
      _databasePath = databasePath;

  final DatabaseFactory _factory;
  final String? _databasePath;
  Future<Database>? _ouverture;

  Future<Database> get _db => _ouverture ??= _ouvrir();

  Future<Database> _ouvrir() async {
    try {
      final fichier =
          _databasePath ??
          path.join(await _factory.getDatabasesPath(), 'piste.db');
      return await _factory.openDatabase(
        fichier,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE candidatures (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                entreprise TEXT NOT NULL,
                poste TEXT NOT NULL,
                status TEXT NOT NULL,
                notes TEXT NOT NULL,
                url TEXT NOT NULL,
                date_creation TEXT NOT NULL,
                date_modification TEXT NOT NULL,
                prochaine_relance TEXT
              )
            ''');
          },
          onUpgrade: (db, ancienneVersion, nouvelleVersion) async {
            if (ancienneVersion < 2) {
              await db.execute(
                'ALTER TABLE candidatures ADD COLUMN date_modification TEXT',
              );
              await db.execute(
                'UPDATE candidatures SET date_modification = date_creation',
              );
            }
          },
        ),
      );
    } catch (_) {
      // Une ouverture ratée ne doit pas rendre « Réessayer » inopérant.
      _ouverture = null;
      rethrow;
    }
  }

  @override
  Future<List<Candidature>> toutes() async {
    try {
      final lignes = await (await _db).query(
        'candidatures',
        orderBy: 'date_modification DESC, id DESC',
      );
      return lignes.map(Candidature.fromDatabase).toList();
    } catch (erreur, trace) {
      Error.throwWithStackTrace(
        const CandidatureStorageException(
          'Lecture des candidatures impossible.',
        ),
        trace,
      );
    }
  }

  @override
  Future<void> enregistrer(Candidature candidature) async {
    try {
      final db = await _db;
      final valeurs = candidature.toDatabase()..remove('id');
      if (candidature.id == null) {
        await db.insert('candidatures', valeurs);
      } else {
        final nombre = await db.update(
          'candidatures',
          valeurs,
          where: 'id = ?',
          whereArgs: [candidature.id],
        );
        if (nombre != 1) {
          throw const CandidatureStorageException('Candidature introuvable.');
        }
      }
    } catch (erreur, trace) {
      Error.throwWithStackTrace(
        const CandidatureStorageException(
          'Enregistrement impossible. Réessaie.',
        ),
        trace,
      );
    }
  }

  @override
  Future<void> supprimer(int id) async {
    try {
      final nombre = await (await _db).delete(
        'candidatures',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (nombre != 1) {
        throw const CandidatureStorageException('Candidature introuvable.');
      }
    } catch (erreur, trace) {
      Error.throwWithStackTrace(
        const CandidatureStorageException('Suppression impossible. Réessaie.'),
        trace,
      );
    }
  }

  @override
  Future<void> fermer() async {
    final ouverture = _ouverture;
    _ouverture = null;
    if (ouverture != null) await (await ouverture).close();
  }
}
