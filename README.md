# Sema

**Vos repères, à portée de main.** Une application macOS native pour consulter ses repères économiques, conserver ses favoris et explorer un suivi de fonds.

Sema vient du grec σῆμα, « signe, signal ». Le dépôt est `antoineberjoan/sema`.

## Version 0.1

- Une fenêtre de travail inspirée du mélange Panorama / Atelier : navigation latérale, indicateurs, historiques et détail d’une série.
- Un panneau compact dans la barre de menus, partageant les mêmes données et favoris.
- Treize repères macro réels via Webstat après connexion d’une clé personnelle : Livret A, LDDS, LEP, taux de dépôt BCE, €STR, inflation France et zone euro, quatre changes, crédit immobilier et emprunt français à dix ans.
- Historique jusqu’à cinq ans selon la série, vue annuelle, source, période et date de mise à jour. Cache local conservé hors connexion. Sans clé, la démonstration reste disponible et porte le badge **Démo**.
- Favoris persistants, recherche dans les fonds de démonstration, règles de hausse/baisse sur une part précise.
- Création, pause, suppression et test d’alertes. **Aucune surveillance automatique de fonds n’est active.**

Tous les fonds sont fictifs. Les alertes sont une démonstration explicite ; leurs règles sont sauvegardées, mais aucun service de surveillance ne tourne. Les actions et les données réelles de fonds ne sont pas connectées.

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
    Features/             Panorama, favoris, fonds, alertes, menu et réglages
    Infrastructure/       Fichiers, Trousseau et notifications macOS
Tests/MarketCoreTests/    Règles métier et contrats des données
Resources/               Métadonnées du bundle et logos SVG
scripts/                 Vérification et création de l’app
docs/                    Produit, architecture, sources et décisions
```

Commencer par [le périmètre produit](docs/PRODUCT.md), puis [l’architecture](docs/ARCHITECTURE.md) et [les sources de données](docs/DATA-SOURCES.md). Les instructions de contribution sont dans [AGENTS.md](AGENTS.md).

L’interface utilise **SF Pro**, les contrôles macOS et une palette teal/mint. Le symbole original est disponible en SVG dans `Resources/Brand`. Voir [l’identité visuelle](docs/IDENTITY.md).

## Données locales

Par défaut, les favoris et alertes sont dans `~/Library/Application Support/Sema/preferences.json`. Les observations Webstat sont dans `webstat-cache.json`, sans clé API. L’ancien `ecb-cache.json` reste lisible. Les écritures sont atomiques. Un fichier de préférences illisible ou d’une version inconnue est conservé ; l’app signale le problème et désactive sa sauvegarde.

Pour une session de validation isolée, `SEMA_DEVELOPMENT_DATA_DIRECTORY` peut définir l’emplacement des données lors de la création du bundle. `SEMA_CONFIGURATION=debug` permet de produire une app de développement. Ces valeurs ne sont pas nécessaires à une utilisation normale.

## Bibliothèques

Aucune dépendance externe : SwiftUI, AppKit, Swift Charts, Observation, Foundation, Security et UserNotifications. Les bibliothèques possibles pour des besoins ultérieurs sont documentées dans [les décisions techniques](docs/decisions/001-native-and-dependencies.md).

## Suite

Voir [ROADMAP.md](docs/ROADMAP.md). Les priorités sont l’intégration des autres sources officielles, la validation des droits sur les données de fonds et la préparation d’une bêta signée.
