# Comprendre un repère

Statut : terminé localement le 18 octobre 2026, en revue dans la [PR nº 5](https://github.com/antoineberjoan/sema/pull/5), branche `codex/ribbon-signature`. Aucune release ni fusion main.

Source : Antoine demande dans le chat des explications sur les données, notamment euro/dollar et inflation, puis valide explicitement une lecture déterministe : définition, variation et effets possibles. Intention reportée dans [Produit](https://app.notion.com/p/3fbd18bb0dea81c7add6f4a31d033296).

## Contrat

- Un accès replié « Comprendre » dans le détail, sans infobulle ni assistant. Trois paragraphes courts au maximum : mesure, lecture de la valeur et implications conditionnelles. Les exemples fictifs restent identifiés.
- Définition et règles vérifiées pour les cotations BCE déjà reconnues et les repères Webstat de départ : inflation annuelle IPCH, taux de dépôt, €STR, emprunt phare, épargne réglementée et crédit immobilier. L’identité et l’unité priment sur le titre.
- Calculs et interprétation dans MarketCore, mêmes observations et période que le graphique. L’inversion EUR/USD change aussi la définition et les effets. Le niveau de la cotation seul ne suffit pas à juger une devise forte ; un ralentissement de l’inflation positive n’est pas une baisse des prix.
- Une série non reconnue conserve seulement une définition officielle disponible, sans conséquence inventée. Aucun classement libre par mots-clés, taux annuel déduit d’un indice, nouvelle requête, modèle IA, dépendance ni changement de stockage.
- Tests sur inversion, hausse/baisse/stabilité, inflation positive/négative, horizon incomplet et métadonnées ambiguës ; bundle et revue native du détail et des aperçus.

## Méthode

Un essai local de reformulation Apple sur cinq cas a notamment inversé une baisse USD/EUR et ajouté une implication commerciale contraire au sens EUR/USD. Cela motive le choix validé des règles déterministes, sans conclure à l’échec général d’Apple Intelligence. Aucun de ces textes générés n’est utilisé dans l’app.

`SeriesExplanation` porte les textes et leurs conditions, avec le formateur numérique existant fourni par l’interface. Les cotations réutilisent `ExchangeRatePair` et sa projection inverse ; les autres correspondances réutilisent les clés canoniques déjà validées dans Webstat. Le composant natif n’effectue aucun calcul financier.

## Références

- [BCE — inflation](https://www.ecb.europa.eu/ecb-and-you/explainers/tell-me-more/html/what_is_inflation.en.html).
- [BCE — cotations de référence](https://data.ecb.europa.eu/methodology/exchange-rates).
- [BCE — taux d’intérêt et facilité de dépôt](https://data.ecb.europa.eu/methodology/what-are-interest-rates).
- [BCE — €STR](https://www.ecb.europa.eu/stats/financial_markets_and_interest_rates/euro_short-term_rate/html/index.en.html).
- [AMF — obligations à taux fixe et taux de marché](https://www.amf-france.org/fr/espace-epargnants/comprendre-les-produits-financiers/actions-obligations/obligations/pourquoi-le-prix-des-obligations-baisse-lorsque-les-taux-montent).
- [Contrats des repères Webstat](../DATA-SOURCES.md), unités et identités déjà vérifiées.

## Preuves et limites

- Les 99 tests Swift passent, dont douze cas sur les explications et une régression sur le titre et l’unité des cotations fictives inversées. Ils couvrent hausse, baisse, stabilité, absence de comparaison, métadonnées contradictoires, période choisie et inflation positive ou négative. `check.sh` réussit les garde-fous et les 17 tests Python ; les chemins explicites du framework Swift Testing des Command Line Tools permettent d’exécuter les tests Swift sur ce Mac. Aucun contrôle n’a été affaibli.
- Bundle debug isolé compilé, signature ad hoc stricte valide. Dans le hub natif : ouverture et repli de Comprendre, repli automatique au changement de série, passage de 1 an à 3 mois, EUR/JPY puis JPY/EUR avec titre, unité, graphique et lecture cohérents. L’inflation fictive affiche la base annuelle, le ralentissement et l’implication conditionnelle sans débordement, au-dessus du graphique.
- Dans Explorer : catalogue BCE EXR, recherche parmi les séries publiées, chargement de la série quotidienne USD/EUR, ouverture de Comprendre puis inversion. Les observations reçues donnent une dépréciation d’EUR et, dans le sens inverse, une appréciation d’USD ; les valeurs, unités et conséquences suivent ce sens. L’aperçu reste non ajouté aux repères.
- Revue visuelle complémentaire du 18 octobre, à la demande d’Antoine : hub natif en clair et en sombre, Comprendre ouvert puis replié, à 1 120 × 760 pt. Valeur et graphique gardent la priorité ; pas de chevauchement ni texte coupé sur cette taille. Apparence et palette Lavande observées en sombre. Les formats de fenêtre plus petits restent à contrôler. Aucun changement UI supplémentaire à l’issue de cette revue.
- La projection inverse d’une démonstration conserve l’identifiant source, mais sa nouvelle unité empêche désormais de la reconnaître à nouveau comme la cotation publiée. Cache et alertes conservent la série source.

La couverture spécialisée reste limitée aux familles reconnues par le contrat ci-dessus ; les catalogues entiers ne sont pas interprétés. Le repli sur une définition officielle et le refus d’inventer une lecture sont testés dans le cœur, sans revue native exhaustive de chaque fournisseur. Aucun modèle IA actif, nouvelle requête pour les explications ou modification des données personnelles.
