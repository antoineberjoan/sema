# Catalogues publics — incrément local du 16 octobre 2026

## Contrat produit

Le catalogue appartient au fournisseur. Sema ne maintient pas une liste autorisée d’indices : l’utilisateur choisit une source, recherche un jeu publié puis une série existante par son libellé, et prévisualise la série avant de la suivre. Antoine précise le 17 octobre que les dimensions et la clé exacte doivent rester facultatives dans Recherche avancée, sans formulaire obligatoire. La liste initiale Webstat et les exemples de ce document ne limitent pas les possibilités.

À la demande d’Antoine, Explorer place aussi vingt références de départ reconnaissables en tête de chaque source statistique publique. Elles ne sont montrées que si leur jeu figure dans le catalogue courant ; leur clic retrouve la clé complète dans le catalogue officiel avant d’ouvrir l’aperçu. Les libellés de départ sont des aides à la navigation, pas des métadonnées officielles. Les changements de version ou de catalogue ne fabriquent pas de série : une référence absente est signalée, et la recherche complète demeure disponible. Les suggestions ne suivent aucune série automatiquement.

Découvrir un catalogue ne télécharge pas toutes ses observations. Chaque combinaison désigne un repère ; une réponse contenant plusieurs séries doit être précisée, sans sélection silencieuse de la première. Une combinaison inexistante ou un format non interprété reste une erreur explicite, sans valeurs de remplacement.

La liste des séries SDMX utilise `detail=nodata` : clés complètes et attributs officiels, sans observations. Un même décodage de descripteur sert au catalogue et à l’historique, afin de conserver les identifiants, unités et échelles. La liste reste en mémoire pendant la consultation du jeu ; les observations sont téléchargées pour la seule série ouverte. New York expose ses mesures publiées et Banque mondiale les pays et agrégats de l’indicateur choisi. Les métadonnées de catalogue SDMX sont limitées à 20 Mio pour borner le transfert et l’arbre XML : un dépassement ou un pied de réponse tronquée produit une erreur explicite, jamais une liste partielle présentée comme complète. Recherche avancée reste accessible dans ce cas.

## Connecteurs disponibles

| Source | Découverte | Observations et particularités |
| --- | --- | --- |
| Webstat | Catalogue et recherche de séries existants, avec clé personnelle | Comportement conservé. |
| Insee | Tous les groupes de séries de l’API BDM SDMX 2.1 ; dimensions et listes de codes référencées | XML structure-specific ; codes IDBANK, définition, statut, période et mise à jour source conservés. |
| BCE | Tous les dataflows publiés par le service SDMX | XML générique ; ce connecteur n’ajoute pas une nouvelle définition aux séries déjà disponibles dans Webstat. |
| Eurostat | Tous les dataflows du point d’accès SDMX principal | Structure `referencepartial`, références `descendants` ; les unités composées, par exemple `MIO_EUR`, expriment déjà l’échelle des valeurs. Les bases Comext/PRODCOM servies par un autre point d’accès ne sont pas incluses dans ce connecteur. |
| BRI | Tous les dataflows du service SDMX v2 | Routes `/structure/dataflow` et `/data/dataflow` ; données XML SDMX 2.1. |
| OCDE | Tous les dataflows publiés par le service SDMX | Agence et version conservées ; les contraintes de disponibilité publiées réduisent les listes de codes, sans sélection éditoriale. Quota actuel : 60 téléchargements de données/heure. |
| Fed de New York | Familles et mesures numériques découvertes par l’API des taux de référence | Taux effectifs, cibles lorsqu’elles sont publiées, percentiles, volumes, moyennes composées et indice SOFR. Les opérations repo, SOMA et autres tables d’opérations ne sont pas intégrées à ce lecteur de séries. |
| Banque mondiale | Catalogue complet des indicateurs de l’API Indicators v2, toutes les pages et bases annoncées ; pays et agrégats | La base productrice est conservée dans l’identifiant. Une unité absente n’est pas déduite du nom : le graphique reste lisible, les alertes sont suspendues. |

Les sept nouveaux accès sont publics et n’utilisent pas de clé Webstat. Les catalogues sont mis en cache dans `statistical-catalogues.json`, avec un bouton d’actualisation explicite. Le cache des observations conserve son nom historique `webstat-cache.json` et sa version 2. `MarketSeries.statisticalDescriptor` est optionnel : les caches précédents restent lisibles.

### Limites explicites

- Un catalogue découvert n’est pas une validation exhaustive de chaque jeu, combinaison, fréquence et droit de réutilisation. Les résultats ne portent pas de badge de validation générale.
- Une période non interprétée, une réponse tronquée ou plusieurs séries dans une réponse ne deviennent pas une courbe présentée comme complète.
- L’exploration révèle les listes de codes de la source. Lorsque celle-ci ne publie pas toutes les contraintes entre dimensions, une combinaison proposée peut ne pas exister ; l’utilisateur peut aussi saisir une clé exacte.
- Les séries numériques à unité non interprétée restent consultables. Une alerte exige une unité et une échelle explicites. Les indices et montants ne reçoivent pas de variation relative inventée.
- Les sources à inscription ou à contrat supplémentaire (BEA, EIA, FRED, FMI, etc.) ne sont pas présentées comme connectées. Aucune clé, aucun compte et aucun accord supplémentaire ne sont créés par cet incrément.
- Pas de cotations d’actions ni de VL ou de collecte d’un fonds individuel. Les flux agrégés d’OPC sont déjà une famille de données Webstat ; une variation d’encours n’est pas une collecte.

## Persistance, historique et alertes

L’identifiant d’une nouvelle série comprend la source, l’agence, le jeu, la version et la clé. Il ne peut pas écraser une clé Webstat ni une autre mesure. Les bornes de la cible Fed, le taux EFFR et son volume sont trois repères distincts.

Un aperçu charge les six dernières années lorsque la source le permet. « Tout » et « Recharger l’historique complet » interrogent les observations disponibles sans la borne récente. Pour les taux de référence de New York, la requête commence en 2000, début de la couverture EFFR observée dans ce service ; les autres familles commencent plus tard. La couverture affichée vient des observations effectivement reçues.

Les valeurs restent des `Decimal`, dans l’unité et l’échelle de publication. Un volume de 100 milliards de dollars reste 100, avec l’échelle affichée ; il n’est pas multiplié une seconde fois. Les valeurs manquantes ne deviennent pas zéro. Les dates trimestrielles et annuelles conservent leur intervalle civil.

Favoris, ordre, alertes et cache sont partagés avec Webstat. L’actualisation peut fonctionner sans clé Webstat pour les repères publics. Un changement d’unité, d’échelle ou de base ne fusionne pas les anciennes valeurs : les règles sont mises en pause avant toute évaluation. Le chargement d’un historique ancien ne déclenche pas rétroactivement des alertes. Le fonctionnement reste manuel, sans surveillance quand Sema est quittée ou le Mac en veille.

## Apport réel par rapport à Webstat

La comparaison a porté sur le catalogue et les métadonnées publics déjà conservés pendant les validations Webstat. Aucun nouveau test n’a réutilisé la clé Rheos. Ce relevé ne suffit pas à affirmer l’absence absolue d’une série de tout Webstat.

- Webstat possède déjà des taux souverains étrangers, dont le taux de l’emprunt phare américain à dix ans mensuel, des indices immobiliers, des séries d’inflation et des statistiques d’OPC. Une connexion supplémentaire n’est pas automatiquement une nouvelle donnée.
- Insee apporte l’accès direct à ses groupes de loyers, construction, comptes, emploi et revenus ; les quatre indices IRL/ILC/ILAT/ICC sont des exemples pratiques, pas une sélection imposée.
- New York apporte un accès direct aux publications de taux monétaires américains et aux mesures associées. Un taux effectif EFFR n’est pas la fourchette cible du FOMC ; SOFR est encore une autre mesure.
- OCDE et BRI permettent de chercher des ratios immobiliers et des séries internationales comparables. BCE et Eurostat donnent accès directement à leurs catalogues, y compris au-delà des familles reprises par Webstat.
- Banque mondiale sert surtout aux comparaisons de pays et aux historiques économiques longs, généralement annuels.

## Exemples personnels, sans préconfiguration imposée

1. **Immobilier** : épingler les taux de crédit Webstat, les indices de loyers Insee pertinents pour ses baux et les ratios prix/revenus ou prix/loyers OCDE. Les ratios nationaux ne sont pas une estimation du prix d’un bien précis.
2. **Contexte d’investissement** : réunir taux BCE/€STR, EFFR, bornes de cible Fed, SOFR et taux longs déjà accessibles dans Webstat. Les dates, devises, fréquences et définitions restent visibles pour éviter les comparaisons trompeuses.
3. **Épargne et rendez-vous client** : consulter les taux réglementés, l’inflation et les flux agrégés d’OPC. Les seuils portent sur les valeurs choisies ; les écarts entre deux séries et les ratios dérivés ne sont pas de nouvelles règles d’alerte implémentées dans cet incrément.

## Références et droits

- [Insee : API BDM](https://www.insee.fr/en/information/2868055), [Licence Ouverte et exceptions](https://www.insee.fr/fr/information/2008466).
- [BCE : API](https://data.ecb.europa.eu/help/api/data), [réutilisation des statistiques ESCB](https://www.ecb.europa.eu/stats/ecb_statistics/governance_and_quality_framework/html/usage_policy.en.html).
- [Eurostat : API](https://ec.europa.eu/eurostat/web/user-guides/data-browser/api-data-access/api-introduction), [droits et exceptions](https://ec.europa.eu/eurostat/help/copyright-notice).
- [BRI : API v2](https://stats.bis.org/api-doc/v2/), [conditions de réutilisation](https://www.bis.org/about/legal/permitted-use-statistics).
- [OCDE : API](https://www.oecd.org/en/data/insights/data-explainers/2024/09/api.html), [quota](https://www.oecd.org/en/data/insights/data-explainers/2024/11/Api-best-practices-and-recommendations.html), [conditions](https://www.oecd.org/en/about/terms-conditions.html).
- [New York Fed : API](https://markets.newyorkfed.org/static/docs/markets-api.html), [mentions obligatoires](https://www.newyorkfed.org/privacy/termsofuse.html).
- [Banque mondiale : API](https://datahelpdesk.worldbank.org/knowledgebase/articles/889392), [conditions](https://data.worldbank.org/summary-terms-of-use).

Ces conditions n’équivalent pas à une autorisation universelle de redistribuer commercialement toutes les données de tiers présentes dans tous les catalogues. La fiche de chaque repère renvoie vers sa source et les conditions correspondantes.
