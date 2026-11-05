import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piste/main.dart';
import 'package:piste/models/candidature.dart';

import 'fake_repository.dart';

Future<void> ouvrir(WidgetTester tester, FakeCandidatureRepository repo) async {
  await tester.pumpWidget(PisteApp(repository: repo));
  await tester.pumpAndSettle();
}

Future<void> appuyer(WidgetTester tester, Finder cible) async {
  // Le message de réussite temporaire peut recouvrir un bouton en bas de page.
  if (find.byType(SnackBar).evaluate().isNotEmpty) {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }
  if (cible.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      cible,
      200,
      scrollable: find.byType(Scrollable).last,
    );
  }
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

Future<void> enregistrer(WidgetTester tester) =>
    appuyer(tester, find.byKey(const Key('enregistrer')));

void main() {
  testWidgets(
    'création validée puis consultation, édition et suppression confirmée',
    (tester) async {
      final repo = FakeCandidatureRepository();
      await ouvrir(tester, repo);
      expect(find.text('Ta prochaine piste commence ici'), findsOneWidget);
      await appuyer(tester, find.text('Ajouter'));
      await enregistrer(tester);
      expect(find.text('Indique le nom de l’entreprise.'), findsOneWidget);
      expect(find.text('Indique le poste recherché.'), findsOneWidget);
      expect(repo.ecritures, 0);
      await tester.enterText(find.byKey(const Key('entreprise')), 'Nexora');
      await tester.enterText(
        find.byKey(const Key('poste')),
        'Développeur Flutter',
      );
      await enregistrer(tester);
      expect(repo.elements, hasLength(1));
      await appuyer(tester, find.text('Développeur Flutter'));
      expect(find.text('Créée le'), findsOneWidget);
      await appuyer(tester, find.text('Modifier'));
      expect(find.widgetWithText(TextFormField, 'Nexora'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('poste')), 'Lead Flutter');
      await appuyer(tester, find.byType(DropdownButtonFormField<Statut>));
      await appuyer(tester, find.text('Entretien').last);
      await enregistrer(tester);
      await tester.drag(find.byType(ListView), const Offset(0, 800));
      await tester.pumpAndSettle();
      expect(find.text('Lead Flutter'), findsOneWidget);
      expect(repo.elements.single.statut, Statut.entretien);
      await appuyer(tester, find.text('Supprimer'));
      await appuyer(tester, find.text('Annuler'));
      expect(repo.elements, hasLength(1));
      await appuyer(tester, find.text('Supprimer'));
      await appuyer(tester, find.widgetWithText(FilledButton, 'Supprimer'));
      expect(repo.elements, isEmpty);
      expect(find.text('Ta prochaine piste commence ici'), findsOneWidget);
    },
  );

  testWidgets(
    'échec de sauvegarde : formulaire conservé puis nouvelle tentative réussie',
    (tester) async {
      final repo = FakeCandidatureRepository()..echecEcriture = true;
      await ouvrir(tester, repo);
      await appuyer(tester, find.text('Ajouter'));
      await tester.enterText(find.byKey(const Key('entreprise')), 'Asteria');
      await tester.enterText(find.byKey(const Key('poste')), 'Mobile');
      await enregistrer(tester);
      expect(find.text('Nouvelle candidature'), findsOneWidget);
      expect(
        find.text(
          'Enregistrement impossible. Tes champs sont conservés, réessaie.',
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextFormField, 'Asteria'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('enregistrer')))
            .onPressed,
        isNotNull,
      );
      repo.echecEcriture = false;
      await enregistrer(tester);
      expect(repo.elements.single.entreprise, 'Asteria');
      expect(find.text('Mes candidatures'), findsOneWidget);
    },
  );

  testWidgets(
    'erreur de lecture visible puis Réessayer affiche un vrai état vide',
    (tester) async {
      final repo = FakeCandidatureRepository()..echecLecture = true;
      await ouvrir(tester, repo);
      expect(find.text('Chargement impossible'), findsOneWidget);
      expect(find.text('Ta prochaine piste commence ici'), findsNothing);
      repo.echecLecture = false;
      await appuyer(tester, find.text('Réessayer'));
      expect(find.text('Ta prochaine piste commence ici'), findsOneWidget);
    },
  );

  testWidgets(
    'double appui pendant une sauvegarde : bouton désactivé et une insertion',
    (tester) async {
      final repo = FakeCandidatureRepository();
      final attente = Completer<void>();
      repo.attenteEcriture = attente.future;
      await ouvrir(tester, repo);
      await appuyer(tester, find.text('Ajouter'));
      await tester.enterText(find.byKey(const Key('entreprise')), 'Nexora');
      await tester.enterText(find.byKey(const Key('poste')), 'Flutter');
      final bouton = find.byKey(const Key('enregistrer'));
      await tester.ensureVisible(bouton);
      await tester.tap(bouton);
      await tester.pump();
      expect(tester.widget<FilledButton>(bouton).onPressed, isNull);
      await tester.tap(bouton);
      attente.complete();
      await tester.pumpAndSettle();
      expect(repo.ecritures, 1);
      expect(repo.elements, hasLength(1));
    },
  );

  testWidgets(
    'recherche et filtre combinés, bilan calculé sur la liste complète',
    (tester) async {
      final repo = FakeCandidatureRepository();
      await repo.enregistrer(exemple(statut: Statut.entretien));
      await repo.enregistrer(exemple(entreprise: 'Asteria'));
      await ouvrir(tester, repo);
      await tester.enterText(find.byKey(const Key('recherche')), 'NEXORA');
      await tester.pumpAndSettle();
      await appuyer(tester, find.widgetWithText(ChoiceChip, 'Entretien'));
      expect(find.text('1 résultat sur 2 candidatures'), findsOneWidget);
      await appuyer(tester, find.text('Bilan'));
      expect(find.text('Mon bilan'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('bilan-total'))).data,
        '2',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('bilan-envoyee'))).data,
        '1',
      );
    },
  );

  testWidgets(
    'URL incorrecte refusée ; date facultative sélectionnable puis effaçable',
    (tester) async {
      final repo = FakeCandidatureRepository();
      await ouvrir(tester, repo);
      await appuyer(tester, find.text('Ajouter'));
      await tester.enterText(find.byKey(const Key('entreprise')), 'Nexora');
      await tester.enterText(find.byKey(const Key('poste')), 'Flutter');
      await tester.enterText(
        find.byKey(const Key('url')),
        'javascript:alert(1)',
      );
      await enregistrer(tester);
      expect(
        find.text('Indique une adresse http:// ou https:// valide.'),
        findsOneWidget,
      );
      expect(repo.ecritures, 0);
      await tester.enterText(find.byKey(const Key('url')), '');
      await appuyer(tester, find.text('Prochaine relance'));
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await appuyer(tester, find.text('OK'));
      expect(find.byTooltip('Retirer la date'), findsOneWidget);
      await appuyer(tester, find.byTooltip('Retirer la date'));
      expect(find.text('Facultative'), findsOneWidget);
      await enregistrer(tester);
      expect(repo.elements.single.prochaineRelance, isNull);
    },
  );

  testWidgets(
    'petit écran, grands caractères et clavier : pas de débordement',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      final repo = FakeCandidatureRepository();
      await repo.enregistrer(
        exemple(
          entreprise: 'Une entreprise avec un nom très long',
          poste: 'Développeur mobile Flutter et responsable des interfaces',
        ),
      );
      await ouvrir(tester, repo);
      expect(tester.takeException(), isNull);
      await appuyer(tester, find.text('Ajouter'));
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      await tester.pumpAndSettle();
      await enregistrer(tester);
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
    },
  );
}
