# Parcours pédagogique Piste

Ce projet regroupe le résultat final des trois TP guidés. Les noms de fichiers et les responsabilités suivent les pages 22 à 24 du cours. Les étapes ci-dessous expliquent la progression ; elles ne constituent pas un historique Git fictif.

## Mini-exercice Dart (page 5)

`tool/exercice_dart.dart` instancie deux candidatures différentes avec entreprise, poste et dates. `Statut` définit exactement cinq valeurs.

- `entreprise`, `poste`, `dateCreation` et `dateModification` sont obligatoires et non nullables.
- `id` est nullable uniquement tant que la candidature n'est pas enregistrée.
- `prochaineRelance` est nullable : l'utilisateur n'est pas obligé de prévoir une relance.
- `notes` et `url` sont facultatives à la saisie mais restent des chaînes non nullables, vides par défaut.
- `final` interdit de réaffecter un champ ; `const` permet une instance constante lorsque tous les arguments sont connus à la compilation.

## TP 1 - Première interface

Lire `main.dart`, puis `ui/accueil_page.dart`.

`MaterialApp` fournit le thème et les localisations. `Scaffold` organise l'AppBar, le contenu, le bouton flottant et la navigation Suivi/Bilan. La liste construit les cartes avec `ListView.builder`, `Card` et `ListTile`.

Pour obtenir les deux valeurs de l'étape initiale dans la version finale, créer Nexora / Développeur Flutter et Asteria / Développeur mobile via Ajouter. Les exemples correspondants sont aussi utilisés par les tests ; aucune donnée de démonstration n'est persistée automatiquement.

**Pourquoi éviter une Column de 80 ListTile ?** Une Column construit tous ses enfants et ne défile pas. Leur hauteur peut excéder celle de l'écran. ListView.builder défile et construit les éléments nécessaires, avec une zone de cache autour de la partie visible. Une Row trop large doit recevoir des contraintes adaptées, généralement un Expanded sur le texte ; diminuer arbitrairement les polices ne règle pas le problème.

**Hot reload et hot restart.** Le hot reload met à jour le code en conservant généralement l'état du widget. Le hot restart recrée l'état Dart. Les données SQLite survivent aux deux ainsi qu'à un arrêt complet de l'application.

## TP 2 - Modèle, formulaire et CRUD

Lire `models/candidature.dart`, `state/candidature_controller.dart`, puis les pages formulaire et détail.

Une seule instance de contrôleur est créée dans `PisteApp.initState`. Elle est transmise à tous les écrans. `ListenableBuilder` observe les notifications et reconstruit la présentation.

Le formulaire possède sa `GlobalKey<FormState>`, initialise les contrôleurs de texte depuis la candidature à modifier et les libère dans `dispose`. `validate()` précède toute écriture. Le bouton est désactivé pendant l'enregistrement et `mounted` est vérifié après les attentes asynchrones. L'édition conserve l'identifiant et la date de création. La fiche détail recherche la candidature par identifiant, ce qui permet d'afficher sa version actualisée au retour du formulaire.

La suppression nécessite un dialogue explicite. Annuler ne modifie ni le contrôleur ni la base.

**Pourquoi conserver les champs lors d'une erreur ?** L'échec du repository ne signifie pas que la saisie est incorrecte. Revenir à la liste ferait perdre le travail de l'utilisateur et laisserait croire que l'enregistrement a réussi. Le catch affiche l'erreur dans le formulaire ; finally réactive le bouton.

**Pourquoi un seul contrôleur ?** Deux instances auraient deux listes et deux états différents : une écriture depuis un formulaire ne mettrait pas forcément la liste affichée à jour. Le contrôleur partagé résout ce problème. `setState` reste utilisé pour les états locaux : onglet, date choisie et enregistrement en cours.

**Deux appuis rapprochés.** Le formulaire protège la commande et désactive le bouton ; le contrôleur refuse aussi une seconde mutation pendant une opération. Les tests vérifient une seule insertion.

## TP 3 - SQLite et qualité

Lire `data/candidature_repository.dart`, les méthodes asynchrones du contrôleur et les fichiers de test.

La base `piste.db` est ouverte à la demande. La table conserve une clé primaire entière, les données métier et des dates ISO 8601. La version 2 ajoute la date de modification aux bases version 1 et reprend la date de création pour les anciennes lignes. Toutes les mutations ciblent un identifiant avec des arguments paramétrés ; une mise à jour ou suppression sans ligne affectée remonte une erreur.

`charger()` expose success ou empty après lecture réussie ; une exception expose error et un message avec Réessayer. L'état empty n'est donc jamais utilisé pour masquer une erreur. Après une écriture réussie, les données sont relues avant notification. Le bilan utilise la liste complète ; seule la vue de suivi applique les filtres.

**Pourquoi ne pas transformer une exception en liste vide ?** Une liste vide signifie que la lecture a réussi et qu'il n'y a aucune candidature. Sur erreur, ce message serait faux et pourrait faire croire à une perte de données. Un état d'erreur propose une action de récupération explicite.

**Comment tester un échec ?** `FakeCandidatureRepository` expose `echecLecture`, `echecEcriture` et `echecSuppression`. Les tests activent puis désactivent ces erreurs pour vérifier la récupération. Les détails de la recette sont dans `RECETTE.md`.

**Quel test vérifie quoi ?** Le modèle vérifie les conversions et les valeurs de repli. Le contrôleur vérifie les règles et états. Les tests widgets manipulent formulaires et navigation. Les tests SQLite FFI utilisent un vrai fichier de base temporaire, ferment et rouvrent les connexions, puis vérifient le contenu. Ils ne remplacent pas un essai du plugin natif sur Android.

## Captures demandées dans le cours

À produire après exécution sur appareil ou émulateur : accueil vide, fiche détail, formulaire invalide, liste avec données et bilan. Dans VS Code : arborescence `lib/`, résultats de `flutter doctor` et `flutter test`. Une capture de maquette ou un rendu de test widget ne doit pas être présenté comme une capture d'émulateur.
