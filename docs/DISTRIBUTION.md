# Préparer une version de sema

La construction de l’app et sa distribution sont deux opérations distinctes. Le dépôt source reste privé. Ces outils ne créent aucun dépôt distant, aucune release et aucun téléchargement public.

## Construire l’image disque

Pré-requis de construction : macOS avec les Command Line Tools (Swift, clang, SetFile), Python 3 et les outils système `hdiutil`, `ditto` et `tiffutil`. Aucune dépendance supplémentaire n’est installée ou embarquée dans sema.

```sh
./scripts/build-app.sh dist/Sema.app
./scripts/package-dmg.sh dist/Sema.app dist/releases/0.4.0
```

Le packaging prend le bundle en argument et lit son `Info.plist`. Il ne modifie pas sa version et ne le signe pas à nouveau. Une copie temporaire est vérifiée avant le montage : identifiant de production, absence de chemin de données de développement ou de fichiers personnels, signature valide, architecture arm64 et macOS minimum cohérent avec le binaire.

La version doit suivre `majeur.mineur.correctif` et le build être numérique. `CFBundleShortVersionString`, `CFBundleVersion` et `LSMinimumSystemVersion` se règlent dans `Resources/Info.plist` avant la compilation. La signature actuelle est ad hoc ; la notarisation n’est pas annoncée.

Le script produit :

- `Sema-<version>-arm64.dmg`, compressé en lecture seule, avec `Sema.app` et un lien vers `/Applications` ;
- le fond Retina et standard dans `background-preview/` ;
- `Sema-<version>-arm64.dmg.sha256` ;
- `release.json`, source des métadonnées du site ;
- `sema.rb.template`, modèle de cask pour le futur tap.

Un fichier DMG versionné existant n’est jamais écrasé. Pour un nouvel essai du même numéro, utiliser un autre dossier de sortie. Les volumes temporaires sont démontés sur succès, erreur ou interruption. Le script ne retire aucune quarantaine et ne change pas Gatekeeper.

## Fond et disposition Finder

Le fond source est `Resources/Distribution/dmg-background.svg` : papier clair `#F5F6F3`, titre encre `#18221D` et courbe sarcelle. Ce fond conserve la lisibilité des vrais noms noirs du Finder sans changer l’apparence de macOS. `scripts/render-dmg.swift` le rend avec AppKit à 640 × 400 pt, en représentations 1× et 2× réunies dans un TIFF HiDPI. La présentation est écrite dans `.DS_Store` sans automatiser le Finder : fenêtre 640 × 400, affichage par icônes, icônes de 96 pt centrées en (164, 226) et (476, 226), noms sous les icônes, barres du Finder masquées.

Le petit outil C `finder-alias.c` utilise l’Alias Manager de macOS pour lier le fond au fichier **sur le volume monté**. Ces API sont dépréciées mais produisent le format `backgroundImageAlias` encore employé par le Finder ; elles ne sont jamais utilisées dans l’app livrée. Le writer Python est volontairement limité à cette disposition : une seule feuille B-tree, aucun éditeur DS_Store générique.

`bless --openfolder` n’est pas utilisé : cette option ne fonctionne pas sur Apple Silicon. Le montage utilisateur du DMG et la lecture de sa disposition doivent être contrôlés dans le Finder réel.

## Alimenter la page de téléchargement

Le site est versionné sous `site/` dans ce même dépôt ; son hébergement reste distinct. Les métadonnées sont générées à partir du manifeste du **même DMG** :

```sh
python3 scripts/distribution/sync-download.py \
  dist/releases/0.4.0/release.json site/dist --local-preview
```

`--local-preview` vérifie la taille et le SHA-256, copie le fichier sous `downloads/`, écrit le manifeste de préversion et insère un vrai lien HTML. Le téléchargement fonctionne ainsi même sans JavaScript. Ce mode est prévu pour la prévisualisation ou le site privé ; il ne décide pas de son audience.

Sans cette option, l’outil utilise uniquement l’URL déjà activée dans `release.json`. L’URL publique proposée et la commande Homebrew restent désactivées par défaut. Ne pas activer le site tant qu’un téléchargement Internet sans session développeur et son SHA-256 n’ont pas été vérifiés.

La page contient une démonstration, pas une mesure du téléchargement ou de la copie réelle. Une seule lecture est lancée lorsque la figure entre dans l’écran ; Rejouer reste disponible, y compris au clavier. Réduire les animations conserve la composition et les trois étapes sans déplacement. L’animation se termine proprement si la fenêtre est masquée ou redimensionnée. Sur localhost uniquement, Alt + clic sur Rejouer ouvre les réglages de développement : vitesse, amortissement, hauteur et ombre.

## Activer Homebrew

Le dépôt de distribution public est `antoineberjoan/homebrew-sema`. Le cask se place sous `Casks/sema.rb` dans ce dépôt de distribution ; le code source de sema n’a pas besoin de devenir public. L’adresse immuable de release proposée est inscrite dans le manifeste et dans le modèle de cask.

Avant activation : créer le dépôt de distribution avec l’audience décidée, publier exactement le DMG contrôlé et son empreinte, vérifier le téléchargement sans authentification, puis tester installation **et** mise à jour sur un environnement distinct. La commande attendue est `brew install --cask antoineberjoan/sema/sema`. Elle n’est pas opérationnelle tant que ces étapes ne sont pas terminées.

Le manifeste distingue `validation.homebrewInstall`, `validation.homebrewUpgrade` et `validation.internetDownload`. Le générateur de page refuse d’exposer une commande Homebrew active si ces trois valeurs ne sont pas vraies. La désinstallation ne supprime pas les préférences de l’utilisateur ; aucun `zap` automatique n’est défini.

## Vérification avant diffusion

1. Monter le DMG par le Finder, contrôler le fond Retina, les deux icônes, leur nom, les ombres et l’absence d’éléments superflus.
2. Glisser réellement sema dans Applications sur un compte de test, éjecter le disque et ouvrir la copie. Vérifier l’accueil, le parcours passé, la reprise et l’ouverture suivante.
3. Télécharger le fichier via le navigateur sur un autre compte ou Mac pour observer les contrôles de quarantaine et confirmer l’aide Gatekeeper.
4. Vérifier la page desktop et mobile, le clavier, la copie Homebrew, Réduire les animations, JavaScript absent et les relectures rapides.
5. Ne cocher les contrôles de `release.json` qu’après les essais correspondants. Le succès de `hdiutil verify` et de la signature locale ne vaut pas validation de l’installation Internet.

## Alpha 0.2.0 vérifiée le 16 octobre 2026

Le DMG versionné a été publié dans la release `v0.2.0` de `antoineberjoan/homebrew-sema` : 3 064 325 octets, SHA-256 `71660035ef0bcd16ef2006515989ef3ab7abec3b4c8c363576062bbc3016c96e`. Le source de l’app reste privé ; le site conserve son audience privée.

Le téléchargement HTTPS sans authentification et l’installation depuis le vrai cask public ont été vérifiés dans un dossier Applications isolé. Une installation puis une mise à jour 0.1.0 → cet artefact exact ont aussi passé le test sur un tap privé. La signature stricte et la quarantaine restent valides après copie ; aucun lancement ni contournement Gatekeeper n’a été effectué. Le premier lancement Internet sur un autre compte ou Mac reste à valider.

Homebrew 7 peut demander une approbation du cask tiers. Après consultation de `Casks/sema.rb`, `brew trust --cask antoineberjoan/sema/sema` permet de l’approuver explicitement, puis de relancer l’installation. La page conserve Homebrew sous une alternative repliable.

## Alpha 0.4.0 publiée le 17 octobre 2026

Le DMG 0.4.0, build 13, est publié dans le dépôt de distribution : 2 787 414 octets, SHA-256 `81c3c017f8a7356a71abaeaacb7f27b1a48f8b59d28651f2c6ac6fa3e2abe884`. Le cask public et `distribution/Casks/sema.rb` correspondent à cet artefact. Le manifeste source de la page se trouve dans `distribution/release.json`, sa copie publiée dans `site/dist/download/release.json`.

Le téléchargement HTTPS sans session, l’installation depuis le vrai cask public et une mise à jour 0.2.0 → 0.4.0 sur tap privé ont été vérifiés dans un dossier Applications isolé. Les signatures restent valides et la quarantaine est conservée. Le test ne lance pas le binaire téléchargé ; le premier lancement Gatekeeper sur un autre compte ou Mac reste à observer. [Preuves](validation/distribution-0.4.0.json).

La release publique 0.2.0 a été retirée lors du nettoyage GitHub du 17 octobre ; ses fichiers et ses métadonnées restent récupérables dans [l’archive privée](ARCHIVES.md). La 0.4.0 reste la seule version publique active.

## Alpha 0.5.0 publiée le 17 octobre 2026

Focus et sa sidebar au survol sont distribués dans le DMG 0.5.0, build 14 : 2 847 366 octets, SHA-256 `88ca20dc010b33f7132ed0e57902541a612ae7daca31c39c520d4c13e96b7f7d`. Le téléchargement HTTPS sans authentification, une vraie mise à jour du cask public 0.4.0 → 0.5.0, puis une installation neuve ont été vérifiés dans un dossier Applications temporaire. Le binaire installé correspond au bundle de production ; signature stricte valide et quarantaine conservée. Aucun premier lancement Gatekeeper sur un autre compte ou Mac n’est déclaré validé.

La revue native utilise des préférences séparées : sélection, périodes, inversion de devise, recherche et ouverture au clavier, accès puis annulation d’une alerte, profil via « Mon espace », mode sombre et passage bandeau → Focus. Antoine a confirmé le comportement du survol. Les Command Line Tools locaux n’incluent pas Swift Testing ; la suite et le bundle ont passé la CI macOS sur le commit source exact. [Preuves UI](validation/focus-0.5.0.json) · [preuves de distribution](validation/distribution-0.5.0.json).
