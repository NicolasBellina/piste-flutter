import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:piste/models/candidature.dart';
import 'package:piste/state/candidature_controller.dart';

import 'fake_repository.dart';

void main() {
  late FakeCandidatureRepository repo;
  late CandidatureController controller;
  setUp(() {
    repo = FakeCandidatureRepository();
    controller = CandidatureController(repo);
  });
  tearDown(() => controller.dispose());

  test('loading, erreur de lecture puis récupération vers empty', () async {
    final attente = Completer<void>();
    repo.attenteLecture = attente.future;
    repo.echecLecture = true;
    final chargement = controller.charger();
    expect(controller.etat, EtatChargement.loading);
    attente.complete();
    await chargement;
    expect(controller.etat, EtatChargement.error);
    expect(controller.messageErreur, isNotEmpty);
    repo.echecLecture = false;
    await controller.charger();
    expect(controller.etat, EtatChargement.empty);
  });

  test(
    'recherche et statut se combinent sans altérer les compteurs du bilan',
    () async {
      await repo.enregistrer(exemple(statut: Statut.entretien));
      await repo.enregistrer(exemple(entreprise: 'Asteria'));
      await repo.enregistrer(exemple(entreprise: 'Nexora', poste: 'Designer'));
      await controller.charger();
      controller.rechercher('  NEXORA  ');
      controller.filtrer(Statut.entretien);
      expect(controller.visibles, hasLength(1));
      expect(controller.elements, hasLength(3));
      expect(controller.nombre(Statut.envoyee), 2);
      expect(controller.proportion(Statut.entretien), closeTo(1 / 3, .0001));
      controller.rechercher('flutter');
      controller.filtrer(null);
      expect(controller.visibles, hasLength(2));
    },
  );

  test('bilan vide : pas de division par zéro', () async {
    await controller.charger();
    expect(controller.proportion(Statut.offre), 0);
    expect(controller.nombre(Statut.offre), 0);
  });

  test(
    'échec écriture : exception propagée et données précédentes conservées',
    () async {
      await controller.enregistrer(exemple());
      repo.echecEcriture = true;
      await expectLater(
        controller.enregistrer(exemple(entreprise: 'Échec')),
        throwsException,
      );
      expect(controller.elements.single.entreprise, 'Nexora');
      expect(controller.occupe, isFalse);
      expect(controller.messageErreur, isNotNull);
      repo.echecEcriture = false;
      await controller.enregistrer(exemple(entreprise: 'Asteria'));
      expect(controller.elements, hasLength(2));
    },
  );

  test('deux écritures simultanées ne créent pas deux candidatures', () async {
    final attente = Completer<void>();
    repo.attenteEcriture = attente.future;
    final premiere = controller.enregistrer(exemple());
    await expectLater(controller.enregistrer(exemple()), throwsStateError);
    attente.complete();
    await premiere;
    expect(repo.ecritures, 1);
    expect(controller.elements, hasLength(1));
  });

  test(
    'écriture réussie puis relecture échouée : aucune invitation à réinsérer',
    () async {
      repo.echecLecture = true;
      await controller.enregistrer(exemple());
      expect(repo.ecritures, 1);
      expect(controller.etat, EtatChargement.error);
      expect(controller.messageErreur, contains('enregistrée'));
      repo.echecLecture = false;
      await controller.charger();
      expect(controller.elements, hasLength(1));
    },
  );

  test(
    'suppression échouée conserve la fiche puis suppression réussie',
    () async {
      await controller.enregistrer(exemple());
      final id = controller.elements.single.id!;
      repo.echecSuppression = true;
      await expectLater(controller.supprimer(id), throwsException);
      expect(controller.parId(id), isNotNull);
      repo.echecSuppression = false;
      await controller.supprimer(id);
      expect(controller.parId(id), isNull);
      expect(controller.etat, EtatChargement.empty);
    },
  );

  test(
    'chargement terminé après dispose : pas de notification tardive',
    () async {
      final attente = Completer<void>();
      final autre = CandidatureController(repo);
      repo.attenteLecture = attente.future;
      final chargement = autre.charger();
      autre.dispose();
      attente.complete();
      await chargement;
    },
  );
}
