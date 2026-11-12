# L'écran Favoris lit les rôles de sens, avec deux lectures à surveiller

Date : 2026-11-12 · Statut : acceptée
Décidé par : Antoine

## Contexte

L'écran Favoris est le premier à lire les jetons de Sophos à la place des valeurs de l'ancien design. Deux lectures n'ont pas de rôle qui les dise exactement, et une troisième change fortement l'écran.

## Décision

- **L'écart entre le nom et la valeur d'une tuile** lit `title-gap` (4 points), parce qu'un titre et sa valeur se lisent ensemble. Il passe de 16 à 4 points : c'est le changement le plus fort de l'écran. Si Antoine le trouve trop serré, c'est le rôle qui change (`field-gap`, 12 points), pas la valeur.
- **La marge d'un bouton posé au coin d'une carte** lit `row-inset` (8 points). Aucun rôle du patron ne dit ce sens : « marge d'un bouton posé au coin d'une carte ». Un écran qui en aurait besoin le signale ; un rôle du patron n'est demandé qu'à partir de deux écrans.
- **La place laissée aux boutons** à droite du titre se calcule : le nombre de boutons (un ou deux) fois `icon.button-size`. Les constantes de 24 et 48 points disparaissent.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Lire le rôle par son sens | Les rôles du patron sans valeur recopiée ; un changement visible assumé | La tuile est plus basse de 12 points |
| Garder les valeurs actuelles | Aucun changement visible | Des rôles propres à sema pour chaque écart actuel : un catalogue de cas |

## Conséquences

Le rôle de la marge d'un bouton reste approximatif jusqu'à ce qu'un second écran en ait besoin. Le contrôle qui fait respecter la décision : aucune valeur de marge ni d'écart n'est écrite dans l'écran (`guardrails.py`).

## Trace

Premier lot d'écran de l'alignement de sema sur Sophos.
