# Préparer une version de sema

La construction de l’app et sa distribution sont deux opérations distinctes. Le code source est public sous licence MIT. Ces outils ne créent aucun dépôt distant, aucune release et aucun téléchargement public.

## Construire l’image disque

Pré-requis de construction : macOS avec les Command Line Tools (Swift, clang, SetFile), Python 3 et les outils système `hdiutil`, `ditto` et `tiffutil`. Aucune dépendance supplémentaire n’est installée ou embarquée dans sema.

```sh
./scripts/build-app.sh build/Sema.app
./scripts/package-dmg.sh build/Sema.app build/releases/<version>
```

Le packaging prend le bundle en argument et lit son `Info.plist`. Il ne modifie pas sa version et ne le signe pas à nouveau. Une copie temporaire est vérifiée avant le montage : identifiant de production, absence de chemin de données de développement ou de fichiers personnels, signature valide, architecture arm64 et macOS minimum cohérent avec le binaire.

La version doit suivre `majeur.mineur.correctif` et le build être numérique. `CFBundleShortVersionString`, `CFBundleVersion` et `LSMinimumSystemVersion` se règlent dans `Resources/Info.plist` avant la compilation. La signature actuelle est ad hoc ; la notarisation n’est pas annoncée.

Le script produit :

- `Sema-<version>-arm64.dmg`, compressé en lecture seule, avec `Sema.app` et un lien vers `/Applications` ;
- le fond Retina et standard dans `background-preview/` ;
- `Sema-<version>-arm64.dmg.sha256` ;
- `release.json`, source des métadonnées du site ;
- `sema-app.rb.template`, modèle de cask pour le tap `antoineberjoan/homebrew-sema`.

Un fichier DMG versionné existant n’est jamais écrasé. Pour un nouvel essai du même numéro, utiliser un autre dossier de sortie. Les volumes temporaires sont démontés sur succès, erreur ou interruption. Le script ne retire aucune quarantaine et ne change pas Gatekeeper.

## Fond et disposition Finder

Le fond source est `Resources/DMG/dmg-background.svg` : papier clair `#F5F6F3`, titre encre `#18221D` et courbe sarcelle. Ce fond conserve la lisibilité des vrais noms noirs du Finder sans changer l’apparence de macOS. `scripts/render-dmg.swift` le rend avec AppKit à 640 × 400 pt, en représentations 1× et 2× réunies dans un TIFF HiDPI. La présentation est écrite dans `.DS_Store` sans automatiser le Finder : fenêtre 640 × 400, affichage par icônes, icônes de 96 pt centrées en (164, 226) et (476, 226), noms sous les icônes, barres du Finder masquées.

Le petit outil C `finder-alias.c` utilise l’Alias Manager de macOS pour lier le fond au fichier **sur le volume monté**. Ces API sont dépréciées mais produisent le format `backgroundImageAlias` encore employé par le Finder ; elles ne sont jamais utilisées dans l’app livrée. Le writer Python est volontairement limité à cette disposition : une seule feuille B-tree, aucun éditeur DS_Store générique.

`bless --openfolder` n’est pas utilisé : cette option ne fonctionne pas sur Apple Silicon. Le montage utilisateur du DMG et la lecture de sa disposition doivent être contrôlés dans le Finder réel.

## Alimenter le téléchargement direct

Le site est versionné sous `site/` dans ce même dépôt ; son hébergement reste distinct. Les métadonnées sont générées à partir du manifeste du **même DMG** :

```sh
python3 scripts/distribution/sync-download.py build/releases/<version>/release.json site/dist
```

L'outil utilise l'URL déjà activée dans `release.json`. L'URL publique proposée et la commande Homebrew restent désactivées par défaut. Ne pas activer le site tant qu'un téléchargement Internet sans session développeur et son SHA-256 n'ont pas été vérifiés.

La landing expose le lien direct au DMG et la commande Homebrew copiable. Le générateur écrit le manifeste JSON sous `download/release.json` ; ce chemin est une métadonnée et ne sert aucune page HTML.

## Activer Homebrew

Le dépôt de distribution public est `antoineberjoan/homebrew-sema`. Le cask actif est `Casks/sema-app.rb`, avec une copie identique sous `distribution/`. `cask_renames.json` associe le cask `sema` au cask `sema-app`.

La commande courte est `brew install --cask sema-app` après préparation du tap. Sur un Mac neuf :

```sh
brew tap antoineberjoan/sema
brew trust --cask antoineberjoan/sema/sema-app
brew install --cask sema-app
```

L’approbation porte uniquement sur ce cask tiers. Antoine demande de garder uniquement la commande courte sur la landing ; la préparation reste dans cette documentation technique.

Antoine a choisi de ne pas prendre d’adhésion Apple Developer. La distribution reste signée ad hoc ; aucune intégration au catalogue officiel Homebrew ni notarisation n’est déclarée.

Le manifeste distingue `validation.homebrewInstall`, `validation.homebrewUpgrade` et `validation.internetDownload`. Le générateur de page refuse d’exposer une commande Homebrew active si ces trois valeurs ne sont pas vraies. La désinstallation ne supprime pas les préférences de l’utilisateur ; aucun `zap` automatique n’est défini.

## Vérification avant diffusion

1. Monter le DMG par le Finder, contrôler le fond Retina, les deux icônes, leur nom, les ombres et l’absence d’éléments superflus.
2. Glisser réellement sema dans Applications sur un compte de test, éjecter le disque et ouvrir la copie. Vérifier l’accueil, le parcours passé, la reprise et l’ouverture suivante.
3. Télécharger le fichier via le navigateur sur un autre compte ou Mac pour observer les contrôles de quarantaine et confirmer l’aide Gatekeeper.
4. Vérifier la landing desktop et mobile, le lien direct au DMG, le clavier, la copie Homebrew, Réduire les animations et JavaScript absent.
5. Ne cocher les contrôles de `release.json` qu’après les essais correspondants. Le succès de `hdiutil verify` et de la signature locale ne vaut pas validation de l’installation Internet.

## Versions publiées

La version publiée, son build, la taille du DMG et son SHA-256 sont dans `distribution/release.json`, généré par `scripts/distribution/release-manifest.py` depuis le bundle publié. `site/dist/download/release.json` en est la copie : `scripts/guardrails.py` refuse une différence. L'historique des versions publiées est dans les releases de `antoineberjoan/homebrew-sema`.

`Resources/Info.plist` porte la version en cours de développement. Entre deux publications, elle est plus récente que celle de `distribution/release.json`.
