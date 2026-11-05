# Piste - TP guidés Flutter

Application de suivi de candidatures réalisée pour les TP 1, 2 et 3 du cours **Flutter, du premier widget à la publication (2026)**, pages 22 à 24. Elle permet de gérer ses démarches hors ligne, sans compte ni serveur.

## Fonctionnalités

- Accueil avec recherche sur l'entreprise et le poste, combinée au filtre par statut.
- Création, consultation, modification et suppression avec confirmation.
- Cinq statuts : Brouillon, Envoyée, Entretien, Offre et Refusée.
- Entreprise et poste obligatoires ; URL validée si renseignée ; notes et relance facultatives.
- Date de relance avec sélecteur français et possibilité de l'effacer.
- Identifiant SQLite stable, date de création conservée, date de modification actualisée.
- Bilan calculé sur toutes les candidatures, même avec un filtre actif.
- États loading / success / empty / error, bouton Réessayer et retour d'erreur d'écriture.
- Sauvegarde asynchrone, protection contre les doubles appuis et conservation de la saisie en cas d'échec.
- Interface Material 3 en français, défilante, testée sur une largeur de 320 px et avec de grands caractères.

La base est vide au premier lancement. Les données Nexora et Asteria sont des exemples de test, sans injection automatique dans la base utilisateur.

## Dépôt et APK

Code source : https://github.com/NicolasBellina/piste-flutter

Téléchargement de l'APK Android : https://github.com/NicolasBellina/piste-flutter/releases/tag/v1.0.0

## Lancer le projet

Utiliser Flutter stable. Le projet a été vérifié avec **Flutter 3.47.9 / Dart 3.13.7**. Le fichier `pubspec.lock` fixe les dépendances utilisées.

```sh
git clone https://github.com/NicolasBellina/piste-flutter.git
cd piste-flutter
flutter pub get
flutter doctor
flutter devices
flutter run -d <identifiant-appareil>
```

Android est la cible commune du cours. Dans Android Studio, terminer l'installation du SDK Android et de ses outils, accepter soi-même les licences demandées, puis démarrer un émulateur dans Device Manager ou connecter un téléphone avec le débogage USB actif. Les commandes de diagnostic sont `flutter doctor --android-licenses` et `flutter doctor -v`.

Pour iOS ou macOS, installer et configurer Xcode complet ; les Command Line Tools seuls ne suffisent pas. Les dossiers natifs Android, iOS et macOS sont fournis. Une cible Web est également disponible pour essayer le projet sans SDK mobile. Elle utilise SQLite WebAssembly et conserve sa base dans le stockage local du navigateur (IndexedDB).

Sur cette machine, le SDK Flutter téléchargé pour vérifier le TP se trouve provisoirement dans `/tmp/flutter-tp-sdk`. Un lanceur le retrouve automatiquement tant qu'il existe :

```sh
./tool/flutterw analyze
./tool/flutterw test
./tool/flutterw run -d <identifiant-appareil>
```

Le lanceur privilégie une installation Flutter déjà disponible dans le PATH. Le SDK temporaire peut être effacé par macOS : installer ensuite Flutter durablement en suivant la [documentation officielle](https://docs.flutter.dev/install).

## Démonstration dans le navigateur

```sh
./tool/run_web
```

Puis ouvrir http://127.0.0.1:8080. Le script compile une version Web autonome et sert ses fichiers localement. `Ctrl+C` arrête le serveur. Pour développer avec hot reload dans Chrome :

```sh
./tool/flutterw run -d chrome --web-hostname=127.0.0.1 --web-port=8080
```

La base du navigateur est distincte de celle d'un téléphone. Garder la même adresse et le même port pour retrouver ses données. Effacer les données du site les supprime. L'adaptateur `sqflite_common_ffi_web` est expérimental ; la cible Android native reste celle du TP. Les fichiers `web/sqlite3.wasm` et `web/sqflite_sw.js` sont fournis. Après mise à jour de SQLite, les régénérer avec `dart run sqflite_common_ffi_web:setup --force`.

Pour tester cette version sur un iPhone via le réseau Wi-Fi, suivre [le guide Safari](docs/TEST_IPHONE.md). Un APK Android ne peut pas être installé sur iPhone.

## Architecture

```text
lib/
  main.dart                           Racine, thème, cycle de vie et injection
  models/candidature.dart              Modèle immuable, enum, sérialisation
  data/candidature_repository.dart     Contrat, SQLite v2 et migration v1
  data/repository_native.dart          Pilote SQLite pour les cibles natives
  data/repository_web.dart             Pilote SQLite WebAssembly pour le navigateur
  state/candidature_controller.dart    ChangeNotifier, états, filtres et bilan
  ui/accueil_page.dart                 Suivi, navigation et recherche
  ui/bilan_view.dart                   Synthèse sur la liste complète
  ui/candidature_detail_page.dart      Consultation et suppression confirmée
  ui/candidature_form_page.dart        Création / édition et validation
  ui/widgets/presentation.dart         Présentation commune et dates
```

Le flux d'enregistrement est : **Form → contrôleur → repository → SQLite → relecture → notification → widgets**. Les pages n'exécutent aucune requête SQL. La racine crée le contrôleur une seule fois, lance le chargement, puis libère le contrôleur et ferme la base à sa destruction. Les contrôleurs de texte sont libérés par le formulaire.

### Pourquoi ces choix ?

- **SQLite avec sqflite et path** : données structurées et persistantes, transactions de migration, aucune dépendance réseau. Les paramètres SQL sont séparés des valeurs saisies. La version 2 ajoute `date_modification` aux anciennes bases et l'initialise depuis `date_creation`.
- **ChangeNotifier et ListenableBuilder** : mécanisme Flutter suffisant pour partager un petit état entre trois écrans et le bilan ; il évite une dépendance de gestion d'état supplémentaire.
- **sqflite_common_ffi_web** : pilote SQLite navigateur, sans modifier les écrans, le contrôleur, le schéma ni les requêtes du TP. Un import conditionnel choisit le pilote au démarrage.
- **flutter_localizations** : sélecteur de date et composants Material en français.
- **sqflite_common_ffi en dépendance de développement** : tests des véritables requêtes SQLite sur disque, y compris réouverture et migration, sans téléphone. Les tests d'interface utilisent un repository factice injectable.

Compromis : la recherche se fait en mémoire après chargement de la liste entière, ce qui convient à un carnet personnel mais pas à des centaines de milliers de lignes. Les données restent locales, sans synchronisation ni sauvegarde cloud. Le lien d'offre est consultable et copiable dans la fiche ; l'ouverture du navigateur n'est pas implémentée. La date de relance ne déclenche pas de notification.

Une écriture confirmée suivie d'un échec de relecture est traitée séparément : le formulaire se ferme et l'accueil propose de recharger. Réessayer le chargement ne réinsère pas la candidature.

## Contrôles

```sh
flutter analyze
flutter test --reporter expanded
dart run tool/exercice_dart.dart
```

Les tests couvrent la sérialisation, les statuts inconnus, les états de chargement, les filtres, les compteurs, les erreurs d'écriture/suppression, les opérations simultanées, le CRUD SQLite sur disque, la migration, la récupération après échec d'ouverture, le parcours utilisateur complet, la validation, la date, les erreurs visibles et le petit écran.

Voir [la recette manuelle](docs/RECETTE.md), [le parcours pédagogique et les réponses de débogage](docs/TP.md) et [les résultats de vérification](docs/VERIFICATION.md). Les essais sur appareil et les captures de l'émulateur restent à effectuer après configuration du SDK Android.

## Atelier de livraison

La version est `1.0.0+1`, le nom affiché est **Piste** et l'identifiant Android est `fr.nicolasbellina.piste`.

```sh
flutter analyze
flutter test
flutter build apk --release
```

L'APK universel **Piste 1.0.0** est disponible dans la release GitHub `v1.0.0`. Il prend en charge Android 7.0 (API 24) ou supérieur et les architectures ARM 32 bits, ARM 64 bits et x86_64. Il est compilé en mode release et signé avec la clé propre au projet, sans clé de debug. La signature et l'alignement des bibliothèques natives sur 16 Ko ont été vérifiés. Aucun téléphone Android n'était disponible pour un essai physique ; le professeur peut suivre [la notice d'installation](livraison/INSTALLATION.md).

Pour reconstruire l'APK sur le Mac de développement :

```sh
./tool/build_apk
```

Le script utilise le SDK local dans `../.tools/android-sdk` s'il existe, puis copie le résultat dans `livraison/piste-1.0.0.apk`. Sur une autre machine, installer Flutter et le SDK Android, puis configurer sa signature selon la [procédure officielle](https://docs.flutter.dev/deployment/android#sign-the-app).

La clé privée `.private/piste-release.p12` et les mots de passe dans `android/key.properties` restent uniquement sur le Mac et sont ignorés par Git. Les sauvegarder séparément pour signer les mises à jour ; ne pas les joindre aux fichiers transmis au professeur. L'icône native reste celle du template Flutter.

Ce dépôt contient le résultat des TP guidés. Son historique ne prétend pas reproduire des étapes intermédiaires non exécutées. Les dossiers de compilation et les SDK sont exclus ; l'APK est joint à la release pour conserver un dépôt source léger. Ce TP correspond au fil rouge Piste ; le projet final à sujet libre constitue un autre travail.
