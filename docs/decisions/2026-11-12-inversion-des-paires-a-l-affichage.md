# L'inversion d'une paire de devises change l'affichage, jamais la série publiée

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine

## Contexte

Une personne peut préférer lire « USD pour 1 EUR » ou l'inverse. Le cache, les chargements et les alertes ne doivent pas changer avec cette lecture.

## Décision

- L'inversion ne porte que sur les cotations au comptant contre euro déjà vérifiées par `SeriesEquivalence`, et sur les fixtures identifiées.
- La valeur inversée est `1 / valeur` en `Decimal` pour toutes les observations, avec leurs dates, périodes, statuts et mises à jour. Les variations sont recalculées sur les réciproques, jamais obtenues en changeant le signe.
- Cette lecture sert seulement à l'affichage. Le cache, les chargements et les alertes restent exprimés dans la cotation publiée.
- Le choix est le champ optionnel `invertedCurrencyPairs`, sauvegardé avant d'être appliqué. Un cache en mémoire garde la projection tant que la série source est égale.
- Le bouton d'inversion n'apparaît que sur les cartes de devises reconnues, dans sa zone de 26 points. Son aide dit le sens cible (par exemple « Afficher EUR pour 1 USD »).

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Inverser à l'affichage seulement | Une seule série publiée ; des alertes stables | Un cache de projection à tenir |
| Remplacer la série par son inverse | Un seul chemin | Des alertes qui changent de sens ; un cache faux |

## Conséquences

Les observations inversées ne sont pas écrites sur le disque.
