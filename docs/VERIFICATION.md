# Vérification du TP

Vérification effectuée le 5 novembre 2026 avec Flutter stable 3.47.9 et Dart 3.13.7 sur macOS Apple Silicon.

## Contrôles exécutés

- `flutter pub get` : dépendances résolues, versions enregistrées dans `pubspec.lock`.
- `flutter analyze --no-pub` : voir le résultat brut dans [analyze.txt](analyze.txt).
- `flutter test --no-pub --reporter expanded` : **22 tests réussis**, résultat brut dans [tests.txt](tests.txt).
- `dart format lib test tool` : code formaté.
- `dart run tool/exercice_dart.dart` : les deux candidatures d'exemple sont affichées dans le terminal.
- Inspection des écrans accueil vide, formulaire, liste et bilan, rendus par le moteur Flutter de test en 390 × 844 avec les polices réelles chargées. Ces rendus temporaires sont des contrôles de widgets, sans émulateur Android et sans valeur de preuve d'installation mobile.

Répartition : 3 tests du modèle, 8 tests du contrôleur, 4 tests de SQLite sur disque et 7 tests d'interface. Les tests SQLite vérifient des fichiers temporaires réels, la réouverture, la migration v1 → v2 et la récupération après un échec d'ouverture. Les tests d'interface vérifient le parcours CRUD complet, les validations, le sélecteur de date, les erreurs, les doubles appuis, la recherche et les compteurs ; un scénario utilise une largeur de 320 px, un facteur de texte de 1,6 et un clavier simulé.

## État initial de l’environnement constaté avec flutter doctor -v

- Flutter était absent du PATH. Un SDK officiel a été téléchargé dans `/tmp/flutter-tp-sdk` pour générer le projet et réaliser ces contrôles.
- Android Studio est installé, mais le SDK Android complet et les outils `cmdline-tools` ne sont pas configurés. Aucun téléphone ou émulateur Android disponible n'a été détecté.
- Seuls les Command Line Tools Xcode sont sélectionnés. Xcode complet et CocoaPods ne sont pas installés/configurés pour compiler les cibles Apple.
- Par conséquent : aucun lancement sur téléphone/émulateur, aucune capture mobile authentique et aucun APK construit. Le README et `RECETTE.md` donnent les étapes à exécuter sur un environnement mobile configuré.

Le passage des tests widgets et FFI ne constitue pas une validation du plugin natif Android/iOS ni de la signature d'une version de diffusion.

## Ajout du lancement Web

Une cible navigateur a été ajoutée pour la démonstration locale sans SDK mobile. L'import conditionnel de `main.dart` sélectionne SQLite natif ou SQLite WebAssembly ; le contrôleur et les requêtes du repository sont partagés.

- `flutter build web --no-pub --no-web-resources-cdn` : compilation réussie, sortie dans `build/web`.
- Application ouverte dans le navigateur intégré à `http://127.0.0.1:8080` ; lecture initiale de la base aboutie et accueil vide affiché.
- Formulaire de création affiché et saisie interactive disponible. La capture `captures/piste-navigateur.jpg` provient de l'application réellement exécutée dans le navigateur ; elle ne représente pas un émulateur Android.
- Le serveur de débogage Flutter affichait une page blanche dans le navigateur intégré. La démonstration utilise donc la version compilée servie par Python, sans débogueur.
- Le CRUD et la persistance après rechargement n'ont pas été parcourus manuellement dans le navigateur pendant cette démonstration ; les tests du contrôleur, des widgets et de SQLite sur disque restent la preuve automatisée décrite ci-dessus.

Relancer la démonstration avec `./tool/run_web`. Le stockage du navigateur est propre à l'origine (adresse + port) et indépendant du téléphone.

## APK Android release

Le SDK Android a ensuite été installé avec l'accord explicite de l'utilisateur pour sa licence. La version Android a été compilée avec Flutter 3.47.9, Java 21, Gradle 9.3.1, la plateforme Android API 36 et les Build Tools 36.0.0.

- `flutter build apk --release` : compilation réussie, APK universel produit.
- Application : `fr.nicolasbellina.piste`, version `1.0.0`, code `1`, minimum API `24`, cible API `36`.
- Architectures : `armeabi-v7a`, `arm64-v8a`, `x86_64`.
- `apksigner verify --verbose --print-certs` : signature valide, schéma APK v2, clé RSA 2048 propre à Piste. Résultat dans `apk-signature.txt`.
- `zipalign -c -P 16 4` : vérification réussie.
- Empreinte SHA-256 de l'APK dans `livraison/SHA256SUMS.txt`.
- Le fonctionnement sur iPhone via Safari a été confirmé par l'utilisateur. Ce retour ne remplace pas un test natif Android.
- Aucun téléphone Android disponible : la compilation et la signature sont vérifiées, l'essai physique Android reste à réaliser avec `livraison/INSTALLATION.md`.

Les fichiers de signature privés et les SDK restent sur le Mac et sont exclus du dépôt GitHub.
