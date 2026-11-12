# L'écran Favoris lit les rôles de sens, avec deux lectures à surveiller

Date : 2026-11-12 · Statut : acceptée
Décidé par : Antoine

## Contexte

L'écran Favoris lit les jetons de Sophos. Deux lectures n'ont pas de rôle qui les dise exactement.

## Décision

- **L'écart entre le nom et la valeur d'une tuile** lit `title-gap` (4 points), parce qu'un titre et sa valeur se lisent ensemble. Si Antoine le trouve trop serré, c'est le rôle qui change (`field-gap`, 12 points), pas la valeur.
- **La marge d'un bouton posé au coin d'une carte** lit `row-inset` (8 points). Aucun rôle du patron ne dit ce sens : « marge d'un bouton posé au coin d'une carte ». Un écran qui en aurait besoin le signale ; un rôle du patron n'est demandé qu'à partir de deux écrans.
- **La place laissée aux boutons** à droite du titre se calcule : le nombre de boutons (un ou deux) fois `icon.button-size`.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Lire le rôle par son sens | Les rôles du patron sans valeur recopiée | Une tuile basse : 4 points entre le nom et la valeur |
| Écrire une valeur propre à sema | Un écart sur mesure | Des rôles propres à sema pour chaque écart : un catalogue de cas |

## Conséquences

Le rôle de la marge d'un bouton reste approximatif jusqu'à ce qu'un second écran en ait besoin. Le contrôle qui fait respecter la décision : aucune valeur de marge ni d'écart n'est écrite dans l'écran (`guardrails.py`).
