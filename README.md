# sema

**Vos repères, à portée de main.** Une application macOS native pour consulter ses repères économiques, conserver ses favoris et suivre des seuils sur les taux, l’inflation et les devises.

sema vient du grec σῆμα, « signe, signal ». Le dépôt est `antoineberjoan/sema`.

## Travailler avec un agent

Antoine fixe l’intention. **Notion** fait foi sur la vision, le périmètre souhaité, le business, la marque et la copy ; **GitHub** porte le code, les décisions techniques et les preuves. La [carte des sources](docs/engineering/SOURCES.md) donne les références. Une divergence de direction se résout avec Antoine.

Quel que soit l’agent utilisé, commencer par [AGENTS.md](AGENTS.md), l’entrée commune du projet, puis charger uniquement les instructions utiles au travail :

- **Règles et rangement** : instructions de la zone touchée, [responsabilité des emplacements](.agents/structure.json), [conventions](docs/engineering/CONVENTIONS.md) et [vocabulaire partagé](docs/engineering/GLOSSARY.md).
- **Procédures à la demande** : [sema-change](.agents/skills/sema-change/SKILL.md) pour réaliser un changement, [sema-design](.agents/skills/sema-design/SKILL.md) pour Interface Craft, [sema-handoff](.agents/skills/sema-handoff/SKILL.md) pour transmettre le contexte utile.
- **Contrôles et mémoire** : mêmes scripts en local, au commit et en CI ; revue du diff, preuves dans la PR, plans et décisions conservés sous forme condensée. Le [fonctionnement du socle](docs/engineering/WORKFLOW.md) décrit ce circuit et les adaptateurs des clients.

Après un clone, lancer `./scripts/setup.sh` pour activer le hook local. Les contrôles demandent Python 3.9 ou plus récent, sans module externe.

Le système partage les règles et les contrôles ; il ne rend pas les modèles déterministes. Le chargement effectif doit être vérifié dans chaque client : voir les [essais et leurs limites](docs/validation/agent-clients.md). Le README oriente ; les fichiers liés restent les références à maintenir.

## Version 0.4

- Un hub Focus : un repère et son grand historique, une sidebar repliable qui apparaît au survol de son icône, et « Mon espace » fixé en bas. Le bandeau de favoris en verre reste accessible depuis la barre de menus.
- Catalogue Webstat dynamique avec clé personnelle : rechercher, filtrer et prévisualiser les séries accessibles, puis composer une sélection ordonnée. Les treize repères macro précédents restent une sélection de départ.
- Catalogues publics Insee, BCE, Eurostat, BRI et OCDE, indicateurs Banque mondiale et taux de référence de la Fed de New York : jeux et dimensions provenant des sources, sans liste fermée d’indices. Voir [le périmètre précis et les limites](docs/PUBLIC-CATALOGUES.md).
- Sources activables dans les réglages, profil local avec prénom, nom et photo facultatifs, lien discret pour soutenir sema sur Ko-fi. Les équivalences vérifiées entre Webstat et la BCE évitent les doublons ; le choix du fournisseur reste explicite. Voir [la personnalisation](docs/PERSONALIZATION.md).
- Vues sur 1 mois, 3 mois, 1 an, 3 ans, 5 ans et Tout selon la profondeur disponible ; chargement des périodes anciennes par tranches annulables. Définition, unité, échelle, fréquence, périodes, base des indices et métadonnées officielles. Cache local conservé hors connexion. Sans clé, la démonstration reste disponible et porte le badge **Démo**.
- Un bandeau natif translucide affiche les favoris, leurs valeurs, variations, courbes et dates. Sa position se choisit dans Réglages → Apparence : haut, bas, gauche ou droite ; un encart trace le signe sema puis révèle sa signature. Clic sur une carte pour approfondir dans le hub ; défilement horizontal quand nécessaire et fermeture avec Échap ou clic extérieur. **⌘⇧B** permet aussi de l’ouvrir dans sema.
- **⌘K** propose Mes repères et Catalogue Webstat ; recherche par noms ou codes, filtres jeu/zone/fréquence, navigation par flèches puis Entrée. **⌘1/⌘2/⌘3/⌘4** ouvrent Mes repères/Favoris/Alertes/Explorer ; **⌘R** actualise Webstat. **⌘⌥↑ / ⌘⌥↓** réordonnent le repère sélectionné.
- Composition native sans contours décoratifs : sidebar sobre, liste de repères et panneau de graphique avec une ombre légère.
- Favoris persistants et six thèmes au choix dans **Réglages → Apparence** : Graphite par défaut, puis Sarcelle, Menthe, Lavande, Bleu ciel et Bleu polaire. La marque et l’icône d’app restent monochromes.
- Alertes de franchissement strict au-dessus ou en dessous d’un seuil, sur les repères dont l’unité et l’échelle sont explicites. Création, pause, suppression et test ; vérification des nouvelles observations à chaque actualisation, sans doublon par date.

Les séries publiques partagent favoris, historiques et alertes avec Webstat. Les fonds individuels restent hors de l’interface ; les anciennes préférences sont conservées. Aucun minuteur ni service de surveillance en arrière-plan ne tourne : les alertes sont vérifiées à l’actualisation manuelle, pas quand l’app est quittée ou le Mac en veille. Les notifications système restent optionnelles.

## Démarrer

Pré-requis : un Mac sous macOS 14 ou plus récent et un compilateur Swift 6. Xcode complet est recommandé pour le développement visuel. L’app peut être compilée avec les seuls Command Line Tools.

```sh
git clone https://github.com/antoineberjoan/sema.git
cd sema
./scripts/build-app.sh
open dist/Sema.app
```

Le script crée une app avec une signature ad hoc. L’alpha distribuée conserve cette signature et reste non notarisée : macOS peut demander une autorisation manuelle à la première ouverture. Une signature Developer ID et une notarisation Apple permettront de fluidifier une distribution ultérieure.

Dans Xcode : ouvrir `Package.swift`. Pour tester les comportements dépendant d’un vrai bundle (dont les notifications), lancer l’app produite par le script.

## Connecter Webstat

1. Créer un compte gratuit sur [Webstat](https://webstat.banque-france.fr/login/), puis générer une clé dans l’espace utilisateur.
2. Ouvrir **sema → Réglages → Sources**, coller la clé dans le champ sécurisé et cliquer sur **Enregistrer et connecter**.
3. Les données sont validées avant l’enregistrement de la clé dans le Trousseau macOS. La clé reste sur ce Mac et est envoyée uniquement à Webstat dans un header HTTP.
4. Utiliser **Actualiser les repères** pour les mises à jour suivantes. Les données du cache restent consultables sans clé ; **Retirer la clé** supprime uniquement la connexion Webstat. Les autres sources publiques restent accessibles dans Explorer, sans cette clé.

Ne jamais ajouter une clé personnelle au code ou au dépôt. Les données sources sont accessibles gratuitement auprès de leurs producteurs ; l’accès par clé personnelle ne remplace pas leurs conditions de réutilisation.

## Vérifier

```sh
./scripts/check.sh
```

La CI utilise macOS avec Xcode et lance la même suite. Les tests couvrent aussi le JSON Webstat, les erreurs d’accès et de quota, la précision des nombres, les valeurs absentes ou futures, les périodes mensuelles, les révisions et la compatibilité des anciens caches.

La suite utilise Swift Testing. Xcode complet est nécessaire si les seuls Command Line Tools installés ne fournissent pas son environnement d’exécution.

## Structure

```text
Sources/
  MarketCore/             Modèles, calculs, clients Webstat/BCE, préférences
  SemaMac/
    App/                  Cycle de vie et état partagé
    DesignSystem/         Couleurs, typographie, composants et graphiques
    Features/             Catalogue, aperçu, panorama, favoris, alertes, menu et réglages
    Infrastructure/       Fichiers, Trousseau et notifications macOS
Tests/MarketCoreTests/    Règles métier et contrats des données
Resources/               Métadonnées du bundle et logos SVG
scripts/                 Vérification et création de l’app
docs/                    Produit, architecture, sources et décisions
site/                    Landing, téléchargement et guide de marque statiques
distribution/            Copie du cask public et métadonnées de release
```

Commencer par [le périmètre produit](docs/PRODUCT.md), puis [l’architecture](docs/ARCHITECTURE.md) et [les sources de données](docs/DATA-SOURCES.md). Les instructions de contribution sont dans [AGENTS.md](AGENTS.md).

L’interface utilise **SF Pro**, les contrôles macOS et six palettes avec des accents adaptés aux modes clair et sombre. Le symbole original est disponible en SVG dans `Resources/Brand`. Voir [l’identité visuelle](docs/IDENTITY.md).

## Données locales

Par défaut, les favoris et alertes sont dans `~/Library/Application Support/Sema/preferences.json`. Les observations Webstat sont dans `webstat-cache.json`, sans clé API. L’ancien `ecb-cache.json` reste lisible. Les préférences et le cache v1 migrent vers v2 avec copie du fichier original. Les écritures sont atomiques. Un fichier de préférences illisible ou d’une version inconnue est conservé ; l’app signale le problème et désactive sa sauvegarde.

Pour une session de validation isolée, `SEMA_DEVELOPMENT_DATA_DIRECTORY` peut définir l’emplacement des données lors de la création du bundle. `SEMA_CONFIGURATION=debug` permet de produire une app de développement. Ces valeurs ne sont pas nécessaires à une utilisation normale.

## Bibliothèques

Aucune dépendance externe : SwiftUI, AppKit, Swift Charts, Observation, Foundation, Security et UserNotifications. Les bibliothèques possibles pour des besoins ultérieurs sont documentées dans [les décisions techniques](docs/decisions/001-native-and-dependencies.md).

## Suite

Voir [ROADMAP.md](docs/ROADMAP.md). Les priorités sont l’intégration des autres sources officielles, la validation des droits sur les données de fonds et la préparation d’une bêta signée.

## Distribution

Le [guide de distribution](docs/DISTRIBUTION.md) décrit le DMG personnalisé, le manifeste de release, la page de téléchargement et la préparation Homebrew. Les scripts de packaging restent locaux et ne publient aucun artefact. Le dépôt public [homebrew-sema](https://github.com/antoineberjoan/homebrew-sema) ne contient que le cask et les versions binaires ; ce dépôt source reste privé.

## Retours

Le bouton « Une idée ou un bug ? » du bandeau ouvre le [formulaire public](https://antoineberjoan.notion.site/5e95023c58754a8990fd16f5fd1ad5f2). Les réponses sont privées ; [configuration et vérification](docs/FEEDBACK.md).

## Source de référence

`origin/main` réunit les sources de l’app, le site et son guide de marque. L’historique du dépôt Sites a été importé dans `site/` sans modifier son identité ni son audience. Le site public reste sur [getsema.app](https://getsema.app/) ; voir [site/README.md](site/README.md) pour le déploiement du site. Les essais et livrables historiques sont inventoriés dans [docs/ARCHIVES.md](docs/ARCHIVES.md). Les clés, préférences personnelles, caches et liens locaux Vercel restent hors de Git.
