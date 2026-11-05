import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:piste/data/candidature_repository.dart';
import 'package:piste/models/candidature.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fake_repository.dart';

void main() {
  sqfliteFfiInit();
  late Directory dossier;
  late String fichier;
  late SqliteCandidatureRepository repo;
  setUp(() async {
    dossier = await Directory.systemTemp.createTemp('piste-sqlite-');
    fichier = path.join(dossier.path, 'piste.db');
    repo = SqliteCandidatureRepository(
      factory: databaseFactoryFfi,
      databasePath: fichier,
    );
  });
  tearDown(() async {
    await repo.fermer();
    await dossier.delete(recursive: true);
  });

  test(
    'CRUD sur disque : création, édition et suppression survivent aux réouvertures',
    () async {
      expect(await repo.toutes(), isEmpty);
      await repo.enregistrer(
        exemple(entreprise: "L'Atelier ; DROP TABLE candidatures"),
      );
      final original = (await repo.toutes()).single;
      await repo.fermer();
      expect((await repo.toutes()).single.id, original.id);
      final edition = original.toDatabase()
        ..['status'] = Statut.entretien.name
        ..['date_modification'] = DateTime(2026, 11, 6).toIso8601String();
      await repo.enregistrer(Candidature.fromDatabase(edition));
      await repo.fermer();
      final modifiee = (await repo.toutes()).single;
      expect(modifiee.statut, Statut.entretien);
      expect(modifiee.dateCreation, original.dateCreation);
      expect(modifiee.dateModification, DateTime(2026, 11, 6));
      await repo.supprimer(modifiee.id!);
      await repo.fermer();
      expect(await repo.toutes(), isEmpty);
    },
  );

  test(
    'migration version 1 vers 2 conserve les lignes et initialise la modification',
    () async {
      final ancien = await databaseFactoryFfi.openDatabase(
        fichier,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''CREATE TABLE candidatures (
          id INTEGER PRIMARY KEY AUTOINCREMENT, entreprise TEXT NOT NULL,
          poste TEXT NOT NULL, status TEXT NOT NULL, notes TEXT NOT NULL,
          url TEXT NOT NULL, date_creation TEXT NOT NULL, prochaine_relance TEXT
        )''');
          },
        ),
      );
      final valeurs = exemple().toDatabase()..remove('date_modification');
      await ancien.insert('candidatures', valeurs);
      await ancien.close();
      final migree = (await repo.toutes()).single;
      expect(migree.entreprise, 'Nexora');
      expect(migree.dateModification, migree.dateCreation);
    },
  );

  test('mise à jour ou suppression absente remonte une erreur', () async {
    final absente = exemple().toDatabase()..['id'] = 999;
    await expectLater(
      repo.enregistrer(Candidature.fromDatabase(absente)),
      throwsA(isA<CandidatureStorageException>()),
    );
    await expectLater(
      repo.supprimer(999),
      throwsA(isA<CandidatureStorageException>()),
    );
  });

  test(
    'une ouverture ratée peut être retentée après correction du chemin',
    () async {
      final parent = Directory(path.join(dossier.path, 'parent'));
      final obstacle = File(parent.path)..writeAsStringSync('obstacle');
      final autre = SqliteCandidatureRepository(
        factory: databaseFactoryFfi,
        databasePath: path.join(parent.path, 'piste.db'),
      );
      await expectLater(
        autre.toutes(),
        throwsA(isA<CandidatureStorageException>()),
      );
      await obstacle.delete();
      await parent.create();
      expect(await autre.toutes(), isEmpty);
      await autre.fermer();
    },
  );
}
