# Sema

**Vos repères, à portée de main.** Une application macOS native pour consulter ses repères économiques, conserver ses favoris et suivre des seuils sur les taux, l’inflation et les devises.

Sema vient du grec σῆμα, « signe, signal ». Le dépôt est `antoineberjoan/sema`.

## Version 0.2

- Une fenêtre de travail inspirée du mélange Panorama / Atelier : navigation latérale, indicateurs, historiques et détail d’une série.
- Un panneau compact dans la barre de menus, partageant les mêmes données et favoris.
- Catalogue Webstat dynamique avec clé personnelle : rechercher, filtrer et prévisualiser les séries accessibles, puis composer une sélection ordonnée. Les treize repères macro précédents restent une sélection de départ.
- Vues sur 1 mois, 3 mois, 1 an, 3 ans, 5 ans et Tout selon la profondeur disponible ; chargement des périodes anciennes par tranches annulables. Définition, unité, échelle, fréquence, périodes, base des indices et métadonnées officielles. Cache local conservé hors connexion. Sans clé, la démonstration reste disponible et porte le badge **Démo**.
- **⌘K** propose Mes repères et Catalogue Webstat ; recherche par noms ou codes, filtres jeu/zone/fréquence, navigation par flèches puis Entrée. **⌘1/⌘2/⌘3/⌘4** ouvrent Panorama/Favoris/Alertes/Explorer ; **⌘R** actualise Webstat. **⌘⌥↑ / ⌘⌥↓** réordonnent le repère sélectionné.
- Composition native sans contours décoratifs : sidebar sobre, liste de repères et panneau de graphique avec une ombre légère.
- Favoris persistants et six thèmes au choix dans **Réglages → Apparence** : Sarcelle, Menthe, Lavande, Bleu ciel, Bleu polaire et Graphite.
- Alertes de franchissement strict au-dessus ou en dessous d’un seuil, sur les repères dont l’unité et l’échelle sont explicites. Création, pause, suppression et test ; vérification des nouvelles observations à chaque actualisation, sans doublon par date.

Le périmètre est limité aux repères Webstat. Les fonds suivis ont été retirés de l’interface ; les anciennes préférences sont conservées. Aucun minuteur ni service de surveillance en arrière-plan ne tourne : les alertes sont vérifiées à l’actualisation manuelle, pas quand l’app est quittée ou le Mac en veille. Les notifications système restent optionnelles.

## Démarrer

Pré-requis : un Mac sous macOS 14 ou plus récent et un compilateur Swift 6. Xcode complet est recommandé pour le développement visuel. L’app peut être compilée avec les seuls Command Line Tools.

```sh
git clone https://github.com/antoineberjoan/sema.git
cd sema
./scripts/build-app.sh
open dist/Sema.app
```

Le script crée une app locale avec une signature ad hoc. Pour une distribution à des clients, utiliser une signature Developer ID et une notarisation Apple, ou le circuit Mac App Store. La signature ad hoc sert au développement local.

Dans Xcode : ouvrir `Package.swift`. Pour tester les comportements dépendant d’un vrai bundle (dont les notifications), lancer l’app produite par le script.

## Connecter Webstat

1. Créer un compte gratuit sur [Webstat](https://webstat.banque-france.fr/login/), puis générer une clé dans l’espace utilisateur.
2. Ouvrir **Sema → Réglages → Général**, coller la clé dans le champ sécurisé et cliquer sur **Enregistrer et connecter**.
3. Les données sont validées avant l’enregistrement de la clé dans le Trousseau macOS. La clé reste sur ce Mac et est envoyée uniquement à Webstat dans un header HTTP.
4. Utiliser **Actualiser Webstat** pour les mises à jour suivantes. Les données du cache restent consultables sans clé ; **Retirer la clé** supprime uniquement la connexion.

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

Le [guide de distribution](docs/DISTRIBUTION.md) décrit le DMG personnalisé, le manifeste de release, la page de téléchargement et la préparation Homebrew. Le packaging reste local et ne publie aucun artefact.
