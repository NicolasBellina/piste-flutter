# Recette manuelle sur appareil ou émulateur

Cette liste est à exécuter après configuration du SDK Android. Les cases ne sont pas cochées : aucun essai sur appareil n'a été réalisé dans l'environnement de création.

## Parcours principal

- [ ] Installer et démarrer Piste sur un téléphone ou émulateur Android.
- [ ] Vérifier le titre Piste, l'état vide, Ajouter et les onglets Suivi/Bilan.
- [ ] Ouvrir Ajouter, laisser entreprise et poste vides, appuyer sur Enregistrer : deux erreurs sous les champs et aucun retour à la liste.
- [ ] Renseigner Nexora / Développeur Flutter, statut Entretien, une date de relance et une note. Enregistrer par deux appuis rapprochés : une seule fiche doit être créée.
- [ ] Ajouter Asteria / Développeur mobile au statut Envoyée, sans URL ni relance.
- [ ] Rechercher `nexora` puis `FLUTTER` : recherche insensible à la casse et espaces extérieurs ignorés.
- [ ] Combiner la recherche avec Entretien, puis Envoyée : résultats cohérents et état sans résultat explicite.
- [ ] Ouvrir Bilan alors que le filtre est actif : total 2, Entretien 1, Envoyée 1.
- [ ] Effacer la recherche et choisir Tous. Ouvrir Nexora, vérifier notes, statut, lien et dates.
- [ ] Modifier Nexora : nouveau poste, statut Offre, autre date de relance. Vérifier la fiche et le bilan recalculés.
- [ ] Retirer la date de relance, enregistrer, vérifier son absence dans la fiche.
- [ ] Fermer complètement l'application puis la relancer : deux entrées conservées avec leurs dernières valeurs.
- [ ] Supprimer une candidature, choisir Annuler : la fiche reste présente.
- [ ] Confirmer la suppression, fermer et relancer : une seule candidature, compteurs recalculés.
- [ ] Supprimer la dernière entrée : état vide, bilan à zéro sans erreur.
- [ ] Recommencer le parcours en mode avion : le CRUD et le bilan restent opérationnels.

## Saisie et ergonomie

- [ ] Un champ composé uniquement d'espaces est refusé.
- [ ] Une URL sans protocole, ou `javascript:alert(1)`, est refusée ; `https://example.org/offre` est acceptée ; une URL vide est acceptée.
- [ ] Sur petit écran et en augmentant la taille du texte, tous les champs et boutons restent accessibles par défilement.
- [ ] Avec le clavier ouvert, Enregistrer reste accessible ; les textes longs ne débordent pas horizontalement.
- [ ] Les boutons et messages sont compréhensibles avec un lecteur d'écran.

## Incident contrôlé reproductible

Les scénarios suivants sont automatisés sans modifier le code de production :

```sh
./tool/flutterw test test/widget_test.dart --plain-name "erreur de lecture visible puis Réessayer affiche un vrai état vide"
./tool/flutterw test test/widget_test.dart --plain-name "échec de sauvegarde : formulaire conservé puis nouvelle tentative réussie"
./tool/flutterw test test/candidature_controller_test.dart
./tool/flutterw test test/sqlite_repository_test.dart
```

1. Le test de lecture initialise le fake avec `echecLecture = true`. L'accueil affiche Chargement impossible et Réessayer, sans état vide. L'erreur est désactivée ; Réessayer conduit à une lecture réussie.
2. Le test d'écriture initialise `echecEcriture = true`, renseigne un formulaire valide puis enregistre. Les champs restent présents et le bouton redevient actif. L'erreur est désactivée et une seconde tentative ajoute une seule candidature.
3. Le test du contrôleur retarde l'écriture et lance deux opérations : la seconde est refusée. Il vérifie aussi qu'une relecture échouée après insertion ne provoque pas une seconde insertion.
4. Le test SQLite commence avec un chemin bloqué par un fichier, constate l'échec d'ouverture, corrige le chemin et vérifie que la tentative suivante fonctionne. Un autre test migre une véritable base version 1.

Diagnostic : le repository produit l'erreur ; le contrôleur gère l'état et la propage selon l'opération ; la page présente le message et l'action possible. Le fake ne doit pas être branché dans l'application destinée à la livraison.
