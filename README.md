<!-- carte:en-tete:debut -->
<!-- carte:en-tete:fin -->

## Ce que c'est

sema est une application macOS native pour consulter des séries économiques publiques (taux, inflation, devises), retrouver ses favoris et suivre des seuils. Chaque série garde sa source, son unité et ses dates. Le détail est dans [docs/fondation.md](docs/fondation.md).

## Démarrer

Pour installer l'app : télécharger le DMG sur [getsema.app](https://getsema.app/download/), ou lancer `brew install --cask antoineberjoan/sema/sema-app`. La version alpha porte une signature ad hoc et n'est pas notarisée par Apple : macOS peut bloquer la première ouverture ([vérifications et limites](docs/validation/distribution-0.7.0.json)).

Pour développer (macOS 14 ou plus, Swift 6, Xcode complet) :

```sh
./scripts/setup.sh
./scripts/check.sh
./scripts/build-app.sh
open build/Sema.app
```

Quand l'app s'ouvre, une icône apparaît dans la barre de menus. Les préférences et caches restent sur le Mac, dans `~/Library/Application Support/Sema/`.

## Organisation du dépôt

- `Sources/MarketCore/` : le cœur. Séries, alertes, préférences, connecteurs aux sources de données.
- `Sources/SemaMac/` : l'app macOS. Écrans, état, design, adaptation au système.
- `Tests/MarketCoreTests/` : les preuves du cœur.
- `Resources/` : métadonnées du bundle et marque.
- `scripts/` : construction, contrôles, distribution.
- `site/` : le site statique.
- `distribution/` : le manifeste de release et le cask public.
- `docs/` : fondation, décisions, lexique, contrats de données, plans.

## Liens avec les autres projets

<!-- carte:liens:debut -->
<!-- carte:liens:fin -->

## Règles et décisions

- Ce qu'est le projet : [docs/fondation.md](docs/fondation.md).
- Les règles pour les agents de code : [AGENTS.md](AGENTS.md).
- Les décisions, une par fichier daté : `docs/decisions/`.
- Pour contribuer : [CONTRIBUTING.md](CONTRIBUTING.md). Pour signaler une faille : [SECURITY.md](SECURITY.md).

## Licence

[MIT](LICENSE), pour le code et la documentation. Elle ne remplace pas les conditions de réutilisation des données des fournisseurs ([sources de données](docs/DATA-SOURCES.md)).
