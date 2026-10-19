# Préparer une version de sema

La construction de l’app et sa distribution sont deux opérations distinctes. Le dépôt source reste privé. Ces outils ne créent aucun dépôt distant, aucune release et aucun téléchargement public.

## Construire l’image disque

Pré-requis de construction : macOS avec les Command Line Tools (Swift, clang, SetFile), Python 3 et les outils système `hdiutil`, `ditto` et `tiffutil`. Aucune dépendance supplémentaire n’est installée ou embarquée dans sema.

```sh
./scripts/build-app.sh build/Sema.app
./scripts/package-dmg.sh build/Sema.app build/releases/0.4.0
```

Le packaging prend le bundle en argument et lit son `Info.plist`. Il ne modifie pas sa version et ne le signe pas à nouveau. Une copie temporaire est vérifiée avant le montage : identifiant de production, absence de chemin de données de développement ou de fichiers personnels, signature valide, architecture arm64 et macOS minimum cohérent avec le binaire.

La version doit suivre `majeur.mineur.correctif` et le build être numérique. `CFBundleShortVersionString`, `CFBundleVersion` et `LSMinimumSystemVersion` se règlent dans `Resources/Info.plist` avant la compilation. La signature actuelle est ad hoc ; la notarisation n’est pas annoncée.

Le script produit :

- `Sema-<version>-arm64.dmg`, compressé en lecture seule, avec `Sema.app` et un lien vers `/Applications` ;
- le fond Retina et standard dans `background-preview/` ;
- `Sema-<version>-arm64.dmg.sha256` ;
- `release.json`, source des métadonnées du site ;
- `sema-app.rb.template`, modèle de cask pour le futur tap.

Un fichier DMG versionné existant n’est jamais écrasé. Pour un nouvel essai du même numéro, utiliser un autre dossier de sortie. Les volumes temporaires sont démontés sur succès, erreur ou interruption. Le script ne retire aucune quarantaine et ne change pas Gatekeeper.

## Fond et disposition Finder

Le fond source est `Resources/DMG/dmg-background.svg` : papier clair `#F5F6F3`, titre encre `#18221D` et courbe sarcelle. Ce fond conserve la lisibilité des vrais noms noirs du Finder sans changer l’apparence de macOS. `scripts/render-dmg.swift` le rend avec AppKit à 640 × 400 pt, en représentations 1× et 2× réunies dans un TIFF HiDPI. La présentation est écrite dans `.DS_Store` sans automatiser le Finder : fenêtre 640 × 400, affichage par icônes, icônes de 96 pt centrées en (164, 226) et (476, 226), noms sous les icônes, barres du Finder masquées.

Le petit outil C `finder-alias.c` utilise l’Alias Manager de macOS pour lier le fond au fichier **sur le volume monté**. Ces API sont dépréciées mais produisent le format `backgroundImageAlias` encore employé par le Finder ; elles ne sont jamais utilisées dans l’app livrée. Le writer Python est volontairement limité à cette disposition : une seule feuille B-tree, aucun éditeur DS_Store générique.

`bless --openfolder` n’est pas utilisé : cette option ne fonctionne pas sur Apple Silicon. Le montage utilisateur du DMG et la lecture de sa disposition doivent être contrôlés dans le Finder réel.

## Alimenter le téléchargement direct

Le site est versionné sous `site/` dans ce même dépôt ; son hébergement reste distinct. Les métadonnées sont générées à partir du manifeste du **même DMG** :

```sh
python3 scripts/distribution/sync-download.py \
  build/releases/0.4.0/release.json site/dist --local-preview
```

`--local-preview` vérifie la taille et le SHA-256, copie le fichier sous `downloads/`, écrit le manifeste de préversion et insère un vrai lien HTML. Le téléchargement fonctionne ainsi même sans JavaScript. Ce mode est prévu pour la prévisualisation ou le site privé ; il ne décide pas de son audience.

Sans cette option, l’outil utilise uniquement l’URL déjà activée dans `release.json`. L’URL publique proposée et la commande Homebrew restent désactivées par défaut. Ne pas activer le site tant qu’un téléchargement Internet sans session développeur et son SHA-256 n’ont pas été vérifiés.

La landing expose le lien direct au DMG et la commande Homebrew copiable, sans page intermédiaire ni ligne de compatibilité sous le CTA. Le générateur conserve le manifeste JSON sous `download/release.json` ; ce chemin est une métadonnée et ne sert aucune page HTML. Il ne doit pas recréer la page supprimée.

La vidéo produit de la landing est indépendante du manifeste de distribution. Son storyboard et sa génération sont décrits dans `site/README.md` ; elle n’illustre pas une installation et ne mesure aucun téléchargement.

## Activer Homebrew

Le dépôt de distribution public est `antoineberjoan/homebrew-sema`. Le cask actif est `Casks/sema-app.rb`, avec une copie identique sous `distribution/`. `cask_renames.json` migre le nom précédent `sema`.

La commande courte est `brew install --cask sema-app` après préparation du tap. Sur un Mac neuf :

```sh
brew tap antoineberjoan/sema
brew trust --cask antoineberjoan/sema/sema-app
brew install --cask sema-app
```

L’approbation porte uniquement sur ce cask tiers. Antoine demande de garder uniquement la commande courte sur la landing ; la préparation reste dans cette documentation technique. Ce parcours a été testé le 17 octobre sur les artefacts publics 0.5.0 puis 0.5.1, dans un dossier temporaire : installation neuve et vraie mise à jour réussies, signature valide et quarantaine conservée. Aucun lancement Internet ni contournement Gatekeeper. [Preuves](validation/homebrew-sema-app.json).

Antoine a choisi de ne pas prendre d’adhésion Apple Developer. La distribution reste signée ad hoc ; aucune intégration au catalogue officiel Homebrew ni notarisation n’est déclarée.

Le manifeste distingue `validation.homebrewInstall`, `validation.homebrewUpgrade` et `validation.internetDownload`. Le générateur de page refuse d’exposer une commande Homebrew active si ces trois valeurs ne sont pas vraies. La désinstallation ne supprime pas les préférences de l’utilisateur ; aucun `zap` automatique n’est défini.

## Vérification avant diffusion

1. Monter le DMG par le Finder, contrôler le fond Retina, les deux icônes, leur nom, les ombres et l’absence d’éléments superflus.
2. Glisser réellement sema dans Applications sur un compte de test, éjecter le disque et ouvrir la copie. Vérifier l’accueil, le parcours passé, la reprise et l’ouverture suivante.
3. Télécharger le fichier via le navigateur sur un autre compte ou Mac pour observer les contrôles de quarantaine et confirmer l’aide Gatekeeper.
4. Vérifier la landing desktop et mobile, le lien direct au DMG, le clavier, la copie Homebrew, Réduire les animations et JavaScript absent.
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


## Alpha 0.5.1 publiée le 17 octobre 2026

Focus ne présente plus de ligne de source ni d’accordéons techniques permanents. La date discrète ouvre un popover natif contenant la provenance, la définition et les métadonnées ; les données fictives restent identifiées. Échap ferme uniquement ce popover. La sélection, les périodes et le contexte d’une cotation inversée ont été vérifiés dans le bundle natif ; les 74 tests et le bundle ont passé la CI macOS sur le commit source exact.

Le DMG 0.5.1, build 15, contient 2 863 197 octets, SHA-256 `762e891f57f26db57c222f78c899e1d58bf432ef6b72a2623eda196bbf4c526d`. Le téléchargement public sans authentification, la mise à jour Homebrew 0.5.0 → 0.5.1 et l’installation neuve ont été vérifiés dans un dossier Applications temporaire, sans lancer le binaire téléchargé. Signature stricte valide, quarantaine conservée, binaire identique à la production. [Preuves UI](validation/focus-0.5.1.json) · [preuves de distribution](validation/distribution-0.5.1.json).

## Version 0.6.0 — actualisation quotidienne

Build 17, DMG de 3 008 614 octets, SHA-256 `a7e6abc3112a8fd40c7df2e043a3650c02e0ffd25d825bc33aee184d84da150b`. Le même artefact public sert le site et le cask `sema-app`. Téléchargement sans authentification, mise à jour Homebrew 0.5.1 → 0.6.0 et installation neuve vérifiés dans un dossier temporaire, puis retirés. Signature stricte valide, quarantaine conservée, binaire identique à la production. Aucun lancement du binaire téléchargé ni contournement Gatekeeper. [Preuves](validation/distribution-0.6.0.json).

Le lancement, le réveil et l’échéance quotidienne partagent le contrôleur natif. Les données synchronisées depuis moins de 24 h sont conservées sans nouvelle requête ; ⌘R reste une actualisation forcée. Les alertes sont évaluées sur les nouvelles observations. L’app doit rester active, même sans hub ; aucun contrôle pendant la veille ou après sortie. Le contrôleur a été exercé sans fenêtre et le bundle a réellement actualisé une série BCE au lancement. La veille matérielle et une attente réelle de 24 h ne sont pas revendiquées.

## Version 0.7.0 — accueil et lisibilité

Publiée le 19 octobre 2026 à la demande explicite d’Antoine : build 18, DMG de 3 299 046 octets, SHA-256 `b89dcc970ffa8f2c4df7c97de25684cae64748a23987855d5d236111d9dd4e4e`. Le code source `c5336795bc1d735ad032fecb3662f81408f88caa` a passé la CI macOS : 115 tests Swift, 42 tests Python et construction du bundle.

Le téléchargement public sans authentification, une vraie mise à jour Homebrew 0.6.0 → 0.7.0 et une installation neuve ont été vérifiés dans des dossiers Applications temporaires, puis retirés. Signature stricte valide, quarantaine conservée, exécutable identique au bundle de production. Le cask et le site utilisent le même artefact immuable. [Preuves](validation/distribution-0.7.0.json).

L’accueil étape 1 sur 3 a été observé dans une copie locale à profil isolé. Le contrôle natif a répondu après un délai anormal ; les étapes suivantes et le premier lancement du binaire téléchargé restent non vérifiés. Aucune notarisation ni désactivation de Gatekeeper.
