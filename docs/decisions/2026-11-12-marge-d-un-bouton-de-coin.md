# La marge d'un bouton posé au coin d'une carte lit un rôle de ligne de liste

Date : 2026-11-12 · Statut : remplacée par [Un point d’étape et un bouton de coin ont chacun leur rôle de jeton](2026-11-13-roles-exacts-point-d-etape-et-bouton-de-coin.md)
Décidé par : à confirmer par Antoine

## Contexte

Les tuiles de l'écran Favoris portent un ou deux boutons d'icône au coin. Aucun rôle du patron ne dit « marge d'un bouton posé au coin d'une carte ».

## Décision

La marge lit `row-inset` (8 points). La place laissée aux boutons à droite du titre se calcule : le nombre de boutons (un ou deux) fois `icon.button-size`. C'est un écart au patron : `row-inset` dit une marge de ligne de liste.

## Conséquences

**Condition de retrait** : un second écran a besoin du même sens. Sophos reçoit alors la demande d'un rôle, et les écrans le lisent. `scripts/guardrails.py` refuse toute valeur de marge écrite dans un écran.
