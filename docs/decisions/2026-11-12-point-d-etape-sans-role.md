# Les points de progression de l'accueil lisent des rôles qui ne disent pas « point d'étape »

Date : 2026-11-12 · Statut : remplacée par [Un point d’étape et un bouton de coin ont chacun leur rôle de jeton](2026-11-13-roles-exacts-point-d-etape-et-bouton-de-coin.md)
Décidé par : à confirmer par Antoine

## Contexte

L'accueil montre trois points de progression. Le patron n'a aucun rôle « point d'étape ».

## Décision

L'écart entre les points lit `icon.gap` (8 points). Le point inactif lit `rule-hover`, une teinte décorative. C'est un écart au patron : ces deux rôles disent autre chose.

## Conséquences

**Condition de retrait** : un second écran a besoin d'un point d'étape. Sophos reçoit alors la demande d'un rôle, et l'accueil le lit.
