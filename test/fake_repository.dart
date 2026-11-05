import 'package:piste/data/candidature_repository.dart';
import 'package:piste/models/candidature.dart';

/// Double de test : aucune donnée d'exemple n'est injectée en production.
class FakeCandidatureRepository implements CandidatureRepository {
  final List<Candidature> elements = [];
  bool echecLecture = false;
  bool echecEcriture = false;
  bool echecSuppression = false;
  bool fermerAppelee = false;
  int ecritures = 0;
  int _prochainId = 1;
  Future<void>? attenteEcriture;
  Future<void>? attenteLecture;

  @override
  Future<List<Candidature>> toutes() async {
    await attenteLecture;
    if (echecLecture) throw Exception('Erreur de lecture simulée');
    return List.of(elements)..sort((a, b) {
      final date = b.dateModification.compareTo(a.dateModification);
      return date != 0 ? date : b.id!.compareTo(a.id!);
    });
  }

  @override
  Future<void> enregistrer(Candidature candidature) async {
    await attenteEcriture;
    if (echecEcriture) throw Exception('Erreur d’écriture simulée');
    ecritures++;
    final ligne = candidature.toDatabase();
    ligne['id'] = candidature.id ?? _prochainId++;
    elements.removeWhere((c) => c.id == ligne['id']);
    elements.add(Candidature.fromDatabase(ligne));
  }

  @override
  Future<void> supprimer(int id) async {
    if (echecSuppression) throw Exception('Erreur de suppression simulée');
    elements.removeWhere((c) => c.id == id);
  }

  @override
  Future<void> fermer() async => fermerAppelee = true;
}

Candidature exemple({
  String entreprise = 'Nexora',
  String poste = 'Développeur Flutter',
  Statut statut = Statut.envoyee,
}) => Candidature(
  entreprise: entreprise,
  poste: poste,
  statut: statut,
  dateCreation: DateTime(2026, 11, 5),
  dateModification: DateTime(2026, 11, 5),
);
