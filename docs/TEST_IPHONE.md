# Tester Piste sur un iPhone dans Safari

Un APK est une application Android : il ne peut pas être installé sur iPhone. Pour essayer Piste immédiatement sans Xcode, utiliser sa cible Web.

## Démonstration locale

1. Connecter le Mac et l'iPhone au même réseau Wi-Fi.
2. Démarrer la version compilée sur l'adresse Wi-Fi du Mac :

   ```sh
   cd "/Users/nicolasbellina/Documents/ESGI M2/Flutter/piste"
   ./tool/flutterw build web --no-web-resources-cdn
   ipconfig getifaddr en0
   python3 -m http.server 8081 --bind <adresse-IP-du-Mac> --directory build/web
   ```

3. Dans Safari sur l'iPhone, ouvrir `http://<adresse-IP-du-Mac>:8081/`.
4. Garder le Mac allumé et le terminal serveur ouvert pendant le test. `Ctrl+C` arrête ce serveur.

Ne pas utiliser `localhost` ni `127.0.0.1` sur l'iPhone : ces adresses désignent l'iPhone lui-même. Le câble USB ne remplace pas la connexion Wi-Fi pour cette méthode.

Si Safari ne parvient pas à se connecter : vérifier le Wi-Fi commun et l'adresse du Mac. Si macOS affiche une demande de connexion réseau pour Python, l'autoriser pour ce serveur. Certains réseaux d'école ou d'entreprise isolent les appareils ; essayer alors un réseau personnel ou le partage de connexion de l'iPhone, puis relever à nouveau l'adresse IP du Mac.

## Parcours à vérifier

1. Créer une candidature avec entreprise et poste ; laisser les champs obligatoires vides une première fois pour vérifier les erreurs.
2. Ouvrir sa fiche, modifier son statut et ajouter une note.
3. Revenir au suivi, rechercher l'entreprise et appliquer un filtre.
4. Ouvrir Bilan et vérifier les compteurs.
5. Actualiser Safari à la même adresse pour vérifier que les données sont conservées.

Les données sont stockées dans ce navigateur et pour cette adresse/ce port. Elles ne sont pas partagées avec la version ouverte sur le Mac. Un changement d'adresse, de port ou l'effacement des données du site donne accès à un autre stockage ou le supprime. Utiliser une fenêtre Safari normale pour tester la conservation des données.

## Application iPhone native

Elle nécessite Xcode complet, l'iPhone approuvé par le Mac, le mode développeur et une signature Apple configurée. Le projet contient déjà le dossier `ios/`. La version Safari ne valide pas le plugin SQLite natif iOS.

Procédure officielle : https://docs.flutter.dev/platform-integration/ios/setup
