import 'package:flutter_test/flutter_test.dart';
import 'package:piste/models/candidature.dart';

void main() {
  test(
    'sérialisation complète, y compris les dates et les caractères spéciaux',
    () {
      final c = Candidature(
        id: 42,
        entreprise: "L'Atelier",
        poste: 'Développeur Flutter',
        statut: Statut.entretien,
        notes: 'Entretien technique\nPréparer la démo',
        url: 'https://example.org/offre',
        dateCreation: DateTime.utc(2026, 11, 1, 8),
        dateModification: DateTime.utc(2026, 11, 5, 12),
        prochaineRelance: DateTime(2026, 11, 10),
      );
      final relue = Candidature.fromDatabase(c.toDatabase());
      expect(relue.toDatabase(), c.toDatabase());
    },
  );

  test(
    'statut inconnu et ancienne date de modification : repli compatible',
    () {
      final c = Candidature.fromDatabase({
        'id': 1,
        'entreprise': 'Nexora',
        'poste': 'Flutter',
        'status': 'ancien_statut',
        'date_creation': '2026-11-01T08:00:00.000Z',
      });
      expect(c.statut, Statut.brouillon);
      expect(c.dateModification, c.dateCreation);
      expect(c.prochaineRelance, isNull);
      expect(c.notes, isEmpty);
    },
  );

  test('un objet neuf laisse SQLite attribuer son identifiant', () {
    final c = Candidature(
      entreprise: 'Asteria',
      poste: 'Mobile',
      dateCreation: DateTime(2026),
      dateModification: DateTime(2026),
    );
    expect(c.toDatabase().containsKey('id'), isFalse);
    expect(Statut.values, hasLength(5));
  });
}
