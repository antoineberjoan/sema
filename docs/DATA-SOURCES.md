# Sources et conventions

## Connexion active : Banque de France / Webstat

- [Guide officiel de l’API](https://webstat.banque-france.fr/pages/guide-migration-api/?flg=fr-fr).
- API Explore 2.1 : `https://webstat.banque-france.fr/api/explore/v2.1/catalog/datasets/`.
- Une clé personnelle est nécessaire. Sema la valide puis la conserve dans le Trousseau local, sans synchronisation iCloud. Aucun secret partagé n’est embarqué dans l’app ou le dépôt.
- Authentification : header `Authorization: Apikey …`, jamais un paramètre d’URL.
- Un export `observations/exports/json` récupère les 13 séries sur les cinq dernières années, avec des bornes de dates explicites.
- Actualisation manuelle après connexion initiale. Le quota documenté est de 10 000 requêtes par jour et par compte. Aucun nouvel essai automatique n’est lancé après une erreur.
- En cas d’erreur d’accès, de quota, de réseau ou d’export incomplet : les dernières données sont conservées. Le cache est séparé des préférences et ne contient jamais la clé.

### Séries intégrées

| Identifiant Sema | Série Webstat | Fréquence / convention |
| --- | --- | --- |
| `livreta` | `MIR1.M.FR.B.L23FRLA.D.R.A.2230U6.EUR.O` | Mensuelle ; taux du Livret A. |
| `ldds` | `MIR1.M.FR.B.L23FRLD.D.R.A.2254U6.EUR.O` | Mensuelle ; taux du LDDS. |
| `lep` | `MIR1.M.FR.B.L23FRLP.H.R.A.2250U6.EUR.O` | Mensuelle ; taux du LEP. |
| `ecb` | `FM.D.U2.EUR.4F.KR.DFR.LEV` | Quotidienne ; facilité de dépôt BCE. |
| `estr` | `ESTR.B.EU000A2X2A25.WT` | Jours ouvrés ; taux monétaire overnight, pas le rendement net d’un fonds. |
| `inflation` | `HICP.M.FR.N.000000.4D0.ANR` | Mensuelle ; IPCH France, variation annuelle, données brutes. |
| `inflation-euro` | `HICP.M.U2.N.000000.4D0.ANR` | Mensuelle ; même définition pour la zone euro. |
| `eurusd` | `EXR.D.USD.EUR.SP00.A` | Référence quotidienne ; USD pour 1 EUR. |
| `eurjpy` | `EXR.D.JPY.EUR.SP00.A` | Référence quotidienne ; JPY pour 1 EUR. |
| `eurchf` | `EXR.D.CHF.EUR.SP00.A` | Référence quotidienne ; CHF pour 1 EUR. |
| `eurgbp` | `EXR.D.GBP.EUR.SP00.A` | Référence quotidienne ; GBP pour 1 EUR. |
| `mortgage-fr` | `MIR1.M.FR.B.A22HR.A.R.A.2254U6.EUR.N` | Mensuelle ; nouveaux crédits à l’habitat hors renégociations, pas un TAEG ni une offre bancaire. |
| `fr10` | `FM.M.FR.EUR.FR2.BB.FR10YT_RR.YLD` | Publication mensuelle de l’emprunt phare français à dix ans. Aucun cours en direct. |

Les anciennes séries `ICP…` d’inflation s’arrêtent fin 2025. Le flux actuel est `HICP…`. L’IPCH harmonisé ne doit pas être confondu avec l’IPC national de l’Insee.

Le repère `fr10` n’est pas le TEC 10 quotidien : celui-ci est un indice à maturité constante interpolé. [L’AFT indique des restrictions Euronext sur sa redistribution et son usage commercial](https://www.aft.gouv.fr/fr/oat-tec-10) ; il reste hors de l’app.

### Provenance et réutilisation

La source est conservée par série : Banque de France, BCE via Banque de France, ou Eurostat via Banque de France. Le lien ouvre la fiche officielle. Le badge « BdF » indique le portail d’accès ; le producteur exact figure dans le détail.

- Les [mentions légales Banque de France](https://www.banque-france.fr/fr/infos-legales) permettent la réutilisation de ses données propres, y compris commercialement, sauf spécification contraire, avec respect de leur intégrité et mention de source et de date.
- Les [conditions Webstat](https://webstat.banque-france.fr/terms/terms-and-conditions/?flg=fr-fr) demandent de respecter les licences particulières des jeux de données et les droits des tiers. Une clé personnelle ne remplace pas ces droits.
- La [BCE](https://www.ecb.europa.eu/services/using-our-site/disclaimer/html/index.en.html) demande notamment l’attribution, l’identification des modifications et l’information sur la disponibilité gratuite à la source pour un contenu vendu. Les réglages Sema indiquent cette disponibilité gratuite ; les variations affichées sont des calculs de Sema.
- Vérifier les conditions des producteurs pour tout ajout ou changement de source et pour la distribution commerciale finale. Aucune autorisation Morningstar, Leeway ou de place boursière n’est déduite de cet accès Webstat.

## Démonstration et compatibilité

Avant connexion, `DemoCatalog` fournit huit repères et quatre fonds fictifs à date fixe, avec `isDemo = true`. Après connexion, les repères macro sont remplacés ou ajoutés par Webstat ; les quatre fonds et les alertes restent en démonstration.

L’ancien client public `ECBExchangeRateClient` et son parseur restent présents pour compatibilité. Si aucun cache Webstat n’existe, les trois parités de l’ancien `ecb-cache.json` peuvent encore être consultées. L’interface actuelle n’appelle plus directement le flux BCE de 90 jours.

## Dates et calculs

- Valeurs financières en `Decimal` ; conversion en `Double` uniquement pour le graphique.
- Les valeurs nulles ou marquées manquantes ne sont jamais remplacées par zéro. Les taux négatifs sont valides ; les changes doivent être strictement positifs.
- Date d’observation : `time_period_start`. Pour le mensuel, conserver aussi `time_period_end` et afficher le mois et l’année, distincts de `updated_at`, la mise à jour source.
- Une période mensuelle en cours peut avoir une date de fin future sans constituer une prévision. Sa valeur déjà publiée est conservée si sa date de début est atteinte.
- Les observations sont triées par date ; pour les doublons, la révision la plus récente remplace l’ancienne. Le statut source est conservé et affiché si la dernière valeur n’a pas le statut normal `A`.
- Fenêtres mensuelles en mois calendaires ; fenêtres quotidiennes en jours calendaires selon le sélecteur existant. La vue annuelle n’est proposée que si l’historique couvre au moins 365 jours.
- Taux et inflation : variations en points de pourcentage. Devises et VL : variations relatives en pourcentage. Une variation de VL n’est pas une performance avec distributions réinvesties.
- Les jours non ouvrés ne constituent pas de nouvelles observations. L’interface affiche la dernière observation disponible ; aucune surveillance de marché ne tourne en arrière-plan.

## Suites possibles

La collecte agrégée des OPC, les autres repères du catalogue vérifié et les fonds réels restent à intégrer. Les données de fonds nécessitent une part précise, une devise, un calendrier et une source autorisée. Le scraping et les actions ne font pas partie de la connexion actuelle.
