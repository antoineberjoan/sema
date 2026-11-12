# Un connecteur par service : la règle de sema

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine (arbitrage de l'architecte du 2026-11-12)

## Contexte

Trois clients de sema parlaient à plusieurs services, et `WebstatClient` décodait lui-même ses réponses. Une première décision gardait ces trois écarts. L'architecte les a refusés : plusieurs hôtes d'un même protocole font un seul connecteur, dont l'hôte est un paramètre ; un service au protocole différent a son connecteur.

## Décision

Sema suit la règle sans écart.

| Cas | Forme | Où |
| --- | --- | --- |
| Cinq hôtes SDMX | Un connecteur, l'hôte en paramètre | `Sdmx`, voir la décision sur les connecteurs statistiques |
| Fed de New York, Banque mondiale, FRED | Un connecteur chacun | `NewYorkFed`, `WorldBank`, `Fred` |
| Twelve Data et Alpha Vantage | Un connecteur chacun | voir la décision sur les fournisseurs de cours |
| Webstat | Un connecteur dont le décodage est dans `Mapping/` | `Webstat/Mapping/WebstatMapping.swift` |

`WebstatClient.ClientError` devient `WebstatError`. Les adresses publiques (`WebstatSite`) et les repères de départ (`WebstatStarter`) quittent le client : la bibliothèque des préférences et celle des séries lisaient le client pour une adresse ou un identifiant, ce qui allait à contresens de la structure.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Garder les trois écarts datés | Aucun refactor | Trois clients hors règle, refusés par l'architecte |
| Appliquer la règle partout | Aucune dette de forme sur les connecteurs | Du code déplacé sans compilateur, relu à l'œil |

## Conséquences

La règle de Sophos sur les hôtes d'un même protocole n'est pas encore écrite dans `patron/structure.md` à la date de cette décision : à vérifier quand elle y sera. Les données de départ restent un écart daté, dans sa propre décision.

## Trace

Troisième lot des connecteurs refaits. Il remplace la décision sur les écarts « un client, plusieurs services ». Le Swift n'est pas compilé.
