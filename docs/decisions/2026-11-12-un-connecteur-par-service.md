# Un connecteur par service : la règle de sema

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine (arbitrage de l'architecte du 2026-11-12)

## Contexte

Plusieurs hôtes d'un même protocole font un seul connecteur, dont l'hôte est un paramètre. Un service au protocole différent a son connecteur. Un connecteur décode ses réponses dans `Mapping/`.

## Décision

Chaque service a la forme suivante.

| Cas | Forme | Où |
| --- | --- | --- |
| Cinq hôtes SDMX | Un connecteur, l'hôte en paramètre | `Sdmx`, voir la décision sur les connecteurs statistiques |
| Fed de New York, Banque mondiale, FRED | Un connecteur chacun | `NewYorkFed`, `WorldBank`, `Fred` |
| Twelve Data et Alpha Vantage | Un connecteur chacun | voir la décision sur les fournisseurs de cours |
| Webstat | Un connecteur dont le décodage est dans `Mapping/` | `Webstat/Mapping/WebstatMapping.swift` |

`WebstatError` est l'erreur du connecteur Webstat. Les adresses publiques (`WebstatSite`) et les repères de départ (`WebstatStarter`) sont hors du client : la bibliothèque des préférences et celle des séries ne lisent pas un client pour une adresse ou un identifiant.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Des clients à plusieurs services, un écart daté chacun | Aucun refactor | Des clients hors règle |
| Appliquer la règle partout | Aucune dette de forme sur les connecteurs | Un connecteur par service à maintenir |

## Conséquences

Les données de départ sont dans `Sources/MarketCore/Resources/Starters/`.

## Trace

Arbitrage de l'architecte du 2026-11-12.
