# Un connecteur par service statistique

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine (arbitrage de l'architecte du 2026-11-12)

## Contexte

`StatisticalClient` parlait à huit services avec un seul fichier de 410 lignes. Cinq parlent SDMX (Insee, BCE, Eurostat, BRI, OCDE). Trois ont leur propre format : la Fed de New York, la Banque mondiale, FRED. Sophos veut « un service, un connecteur », avec le décodage dans `Mapping`.

## Décision

Quatre connecteurs remplacent le client unique.

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
| Garder le client unique | Aucun changement | Une règle de Sophos non suivie |
| Un connecteur SDMX à hôte en paramètre, un connecteur par autre service | La règle suivie, une seule implémentation du protocole SDMX | Un aiguilleur côté app |

## Conséquences

`StatisticalClient.ClientError` devient `PublicDataError` : `GdeltClient`, `PressReleaseClient` et `XMLTree` le lisaient déjà, alors qu'ils ne parlent pas à un service statistique. `AppStore.statisticalClient()` devient `statisticalConnectors()`. Les données de départ (`StatisticalStarter`) restent un écart daté : voir la décision sur les écarts de forme.

## Trace

Premier lot des connecteurs refaits conformes à l'arbitrage de l'architecte du 2026-11-12. Le Swift n'est pas compilé : l'aiguilleur `any StatisticalConnector`, les valeurs par défaut des extensions du protocole et `precondition` dans `SdmxClient.init` sont à compiler.
