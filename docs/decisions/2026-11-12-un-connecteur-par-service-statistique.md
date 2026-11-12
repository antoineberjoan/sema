# Un connecteur par service statistique

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine (arbitrage de l'architecte du 2026-11-12)

## Contexte

Huit services statistiques sont servis. Cinq parlent SDMX (Insee, BCE, Eurostat, BRI, OCDE). Trois ont leur propre format : la Fed de New York, la Banque mondiale, FRED. Sophos veut « un service, un connecteur », avec le décodage dans `Mapping`.

## Décision

Quatre connecteurs servent les huit services.

| Connecteur | Services | Particularité |
| --- | --- | --- |
| `Sdmx` | Insee, BCE, Eurostat, BRI, OCDE | L'hôte est un paramètre (`SdmxClient(source:)`). Les hôtes servis sont `StatisticalSource.sdmxSources`. |
| `NewYorkFed` | Fed de New York | Les mesures viennent du catalogue : aucun appel de structure. |
| `WorldBank` | Banque mondiale | Catalogue paginé. |
| `Fred` | FRED | Reçoit la clé personnelle en paramètre ; elle part seulement vers FRED. |

Trois choix en découlent.

- Les types partagés (`StatisticalSource`, `StatisticalDataset`, `StatisticalStructure`…) vont dans `Series/Model/` : ce sont des types du domaine.
- L'erreur, le transport HTTP, la lecture des nombres et des périodes, et le protocole `StatisticalConnector` vont dans `Common/` : plusieurs connecteurs les lisent, dont ceux du contexte.
- Le choix du connecteur par source est dans `App/StatisticalConnectors.swift`, à la racine de l'app : il assemble, il ne décode rien.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Un connecteur par hôte SDMX | Aucune ambiguïté sur l'hôte | Cinq copies du même code (`construire` : une seule implémentation) |
| Un client unique pour les huit services | Un seul fichier | Une règle de Sophos non suivie |
| Un connecteur SDMX à hôte en paramètre, un connecteur par autre service | La règle suivie, une seule implémentation du protocole SDMX | Un aiguilleur côté app |

## Conséquences

`PublicDataError` est l'erreur commune des connecteurs : `GdeltClient`, `PressReleaseClient` et `XMLTree` la lisent aussi, sans parler à un service statistique. `AppStore.statisticalConnectors()` choisit le connecteur de chaque source. Les données de départ sont dans `Sources/MarketCore/Resources/Starters/statistical.json`.

## Trace

Arbitrage de l'architecte du 2026-11-12.
