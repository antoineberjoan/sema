# Sources et conventions

## Connexion active : Banque de France / Webstat

- [Guide officiel de l’API](https://webstat.banque-france.fr/pages/guide-migration-api/?flg=fr-fr).
- API Explore 2.1 : `https://webstat.banque-france.fr/api/explore/v2.1/catalog/datasets/`.
- Une clé personnelle est nécessaire. Sema la valide puis la conserve dans le Trousseau local, sans synchronisation iCloud. Aucun secret partagé n’est embarqué dans l’app ou le dépôt.
- Authentification : header `Authorization: Apikey …`, jamais un paramètre d’URL.
- Un export `observations/exports/json` récupère les 13 séries sur les six dernières années, avec des bornes de dates explicites. Cette marge permet une vue complète sur cinq ans même lorsque la dernière publication mensuelle est décalée.
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

Avant connexion, l’interface propose les huit repères fictifs de `DemoCatalog`, avec `isDemo = true`. Après connexion, les 13 repères macro sont remplacés ou ajoutés par Webstat. Les fonds ne sont plus exposés ; leurs anciennes règles et favoris restent conservés sans être actifs. Les alertes de seuil sont vérifiées uniquement sur les observations Webstat réelles à l’actualisation.

L’ancien client public `ECBExchangeRateClient` et son parseur restent présents pour compatibilité. Si aucun cache Webstat n’existe, les trois parités de l’ancien `ecb-cache.json` peuvent encore être consultées. L’interface actuelle n’appelle plus directement le flux BCE de 90 jours.

## Dates et calculs

- Valeurs financières en `Decimal` ; conversion en `Double` uniquement pour le graphique.
- Les valeurs nulles ou marquées manquantes ne sont jamais remplacées par zéro. Les taux négatifs sont valides ; les changes doivent être strictement positifs.
- Date d’observation : `time_period_start`. Pour le mensuel, conserver aussi `time_period_end` et afficher le mois et l’année, distincts de `updated_at`, la mise à jour source.
- Une période mensuelle en cours peut avoir une date de fin future sans constituer une prévision. Sa valeur déjà publiée est conservée si sa date de début est atteinte.
- Les observations sont triées par date ; pour les doublons, la révision la plus récente remplace l’ancienne. Le statut source est conservé et affiché si la dernière valeur n’a pas le statut normal `A`.
- Vues sur 1 mois, 3 mois, 1 an, 3 ans et 5 ans, proposées uniquement si la série couvre la période. Les fenêtres mensuelles et annuelles suivent le calendrier civil ; les fenêtres quotidiennes courtes couvrent 30 ou 90 jours.
- Taux et inflation : variations en points de pourcentage. Devises et VL : variations relatives en pourcentage. Une variation de VL n’est pas une performance avec distributions réinvesties.
- Les jours non ouvrés ne constituent pas de nouvelles observations. L’interface affiche la dernière observation disponible ; aucune surveillance de marché ne tourne en arrière-plan.

## Suites possibles

La collecte agrégée des OPC, les autres repères du catalogue vérifié et les fonds réels restent à intégrer. Les données de fonds nécessitent une part précise, une devise, un calendrier et une source autorisée. Le scraping et les actions ne font pas partie de la connexion actuelle.

## Catalogue candidat — pas encore intégré

Repérage du 16 octobre 2026 à partir du catalogue officiel et de ses fiches. Les séries ci-dessous ne font pas partie des 13 séries connectées. Une fiche disponible ne remplace pas un test d’observations ni la vérification des conventions et droits du producteur.

| Priorité | Repère candidat | Série / fréquence | Intérêt pour un CGP |
| --- | --- | --- | --- |
| Haute | Bund allemand à 10 ans | [FM.M.DE.EUR.FR2.BB.DE10YT_RR.YLD](https://webstat.banque-france.fr/fr/catalogue/fm/FM.M.DE.EUR.FR2.BB.DE10YT_RR.YLD), mensuelle, BdF | Comparaison avec France 10 ans ; écart de taux mensuels à dates et conventions alignées. |
| Haute | États-Unis à 10 ans | [FM.M.US.USD.FR2.BB.US10YT_RR.YLD](https://webstat.banque-france.fr/fr/catalogue/fm/FM.M.US.USD.FR2.BB.US10YT_RR.YLD), mensuelle, BdF | Contexte mondial des taux longs. |
| Haute | BCE refinancement principal | [FM.D.U2.EUR.4F.KR.MRR_FR.LEV](https://webstat.banque-france.fr/fr/catalogue/fm/FM.D.U2.EUR.4F.KR.MRR_FR.LEV), quotidienne, BCE via BdF | Compléter le taux de dépôt déjà présent. |
| Haute | BCE prêt marginal | [FM.D.U2.EUR.4F.KR.MLFR.LEV](https://webstat.banque-france.fr/fr/catalogue/fm/FM.D.U2.EUR.4F.KR.MLFR.LEV), quotidienne, BCE via BdF | Compléter le corridor des taux directeurs. |
| Haute | Crédit immobilier par durée | Famille `MIR1.Q.FR.R.A22FRX`, trimestrielle : durées `<10`, `10–<15`, `15–<20`, `20–<25`, `25+` ans | Comparer les conditions par horizon ; taux effectifs au sens étroit, pas une grille commerciale ni un TAEG. [Exemple 20–<25 ans](https://webstat.banque-france.fr/fr/catalogue/mir1/MIR1.Q.FR.R.A22FRX.Y.R.A.2254FR.EUR.N). |
| Haute | Taux d’usure immobilier | `MIR1.Q.FR.R.A22FRF.W1/W2/W3.U.A.2254FR.EUR.N`, trimestrielle ; vérifier les trois fiches complètes avant intégration | Plafonds réglementaires selon la durée. [Sélection officielle](https://webstat.banque-france.fr/fr/selection/5385584/). Les variantes mensuelles arrêtées ne doivent pas être reprises. |
| Ensuite | Dépôts à terme des ménages et entreprises | [Publication officielle](https://www.banque-france.fr/fr/statistiques/epargne/taux-de-remuneration-des-depots-bancaires-2026-06), mensuelle ; codes à sélectionner | Contexte sur l’épargne bancaire et la trésorerie. |
| Ensuite | Collecte agrégée des OPC par catégorie | [Panorama officiel](https://www.banque-france.fr/fr/statistiques/epargne/panorama-financier-des-opc-france-2024-q4), codes et périodicités à sélectionner | Flux agrégés ; aucun suivi d’un fonds individuel n’est réintroduit. |

Les séries de taux souverains candidates sont à jour dans le catalogue au repérage, depuis janvier 1980 jusqu’à septembre 2026. Les séries de crédit par durée repérées couvrent mars 2004 à juin 2026. Ces profondeurs sont des métadonnées de catalogue, pas un nouvel historique téléchargé et testé dans l’app. Le modèle doit prendre en charge la fréquence trimestrielle avant de brancher les séries `MIR1.Q`.

### États-Unis et autres compléments

L’EFFR (taux effectif des fonds fédéraux) et le SOFR ont une [API officielle New York Fed](https://markets.newyorkfed.org/static/docs/markets-api.html). Leur disponibilité dans un jeu Webstat adapté n’a pas été confirmée. L’EFFR ne doit pas être présenté comme la fourchette cible du FOMC. Tout connecteur complémentaire et ses conditions de réutilisation restent à valider avant intégration.

Le TEC 10 quotidien est distinct de l’emprunt phare mensuel actuellement intégré : [l’AFT rappelle qu’Euronext calcule et administre les indices CNO-TEC](https://www.aft.gouv.fr/fr/oat-tec-10). Aucun ajout du TEC 10 n’est décidé dans ce repérage. Le PIB, le chômage, l’inflation américaine et les prix immobiliers peuvent compléter une vue macro ensuite, avec une source officielle et des définitions vérifiées pour chaque série.
