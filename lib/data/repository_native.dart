import 'candidature_repository.dart';

/// Android, iOS et macOS utilisent le plugin SQLite natif du TP.
CandidatureRepository creerRepository() => SqliteCandidatureRepository();
