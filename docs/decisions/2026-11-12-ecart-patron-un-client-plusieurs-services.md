# Trois clients parlent encore à plusieurs services : un écart daté au patron

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine (arbitrage de l'architecte du 2026-11-12)

## Contexte

Sophos veut « un service, un connecteur » : un client qui parle à plusieurs services se découpe, et le décodage de leurs réponses va dans `mapping`, jamais dans `client`. L'outil de structure ne voit que des noms de fichiers : il ne voit ni à qui un client parle, ni où est le décodage. Trois clients de sema ne suivent pas encore la règle.

## Décision

Ces trois écarts sont gardés pour l'instant, chacun avec sa raison et ce qui le retire.

| Client | Ce qu'il fait | Pourquoi on le garde | Ce qui le retire |
| --- | --- | --- | --- |
| `StatisticalClient` | parle à cinq services SDMX (Insee, BCE, Eurostat, BRI, OCDE) avec le même code, seul l'hôte change, et à trois services à part (Fed de New York, Banque mondiale, FRED) | le code est le même pour les cinq hôtes : un client par hôte copierait la logique cinq fois (`construire` : une seule implémentation) | un hôte dont les réponses diffèrent assez pour demander son propre décodage devient son connecteur |
| `MarketDataClient` | parle à Twelve Data et à Alpha Vantage, avec un choix de fournisseur à chaque étape | le découpage touche l'acteur, ses tests et ses appelants dans `AppStore` : un refactor, pas un déplacement | un lot qui coupe l'acteur en deux connecteurs, chacun avec son contrat et ses réponses enregistrées |
| `WebstatClient` | décode lui-même les réponses (`parseSeriesPage`, `parseObservations`, `parseCodeLabels`…) | les fonctions de décodage sont des fonctions statiques du client et partagent des types privés avec lui | un fichier `WebstatClient+Mapping.swift` qui porte le décodage |

Les clients des flux de contexte (`PressReleaseClient`, `GDELTClient`, `ClaudeClient`) sont dans la même situation et seront rangés avec l'unité `Context`.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Ranger les fichiers aujourd'hui, garder les trois écarts datés | Le cliquet baisse sans refactor ; chaque écart a sa sortie | Trois clients hors de la règle de relecture |
| Découper les trois clients maintenant | La règle suivie partout | Un refactor de code non compilé sur les trois clients les plus lus du cœur |

## Conséquences

Le rangement des fichiers est fait : `Contract/` porte les types de chaque service, `Mapping/` porte le décodeur SDMX, `XMLTree` est dans `Common/` parce que les flux de contexte le lisent aussi. Les données de départ (`StatisticalStarter`, 184 lignes) restent dans `Contract/` : ce sont des valeurs écrites dans le code, alors que la forme veut les valeurs hors du dossier de code. Les passer en données est un lot sans effet visible, laissé de côté.

## Trace

Quatrième lot de structure du code de l'alignement de sema sur Sophos. Le comptage vient de `structure.mjs` : 85 fautes avant ce lot, 69 après.
