import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'candidature_repository.dart';

/// SQLite WebAssembly conserve la base dans IndexedDB, pour cette origine.
/// Seul le pilote change : schéma, migrations et requêtes restent communs.
CandidatureRepository creerRepository() => SqliteCandidatureRepository(
  factory: databaseFactoryFfiWeb,
  databasePath: 'piste.db',
);
