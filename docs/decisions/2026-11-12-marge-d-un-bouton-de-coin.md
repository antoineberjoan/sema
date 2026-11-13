# La marge d'un bouton posé au coin d'une carte lit un rôle de ligne de liste

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine

## Contexte

Les tuiles de l'écran Favoris portent un ou deux boutons d'icône au coin. Aucun rôle du patron ne dit « marge d'un bouton posé au coin d'une carte ».

## Décision

La marge lit `row-inset` (8 points). La place laissée aux boutons à droite du titre se calcule : le nombre de boutons (un ou deux) fois `icon.button-size`. C'est un écart au patron : `row-inset` dit une marge de ligne de liste.

## Conséquences

**Condition de retrait** : un second écran a besoin du même sens. Sophos reçoit alors la demande d'un rôle, et les écrans le lisent. `scripts/guardrails.py` refuse toute valeur de marge écrite dans un écran.
