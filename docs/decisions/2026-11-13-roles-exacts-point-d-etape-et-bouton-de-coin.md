# Un point d'étape et un bouton de coin ont chacun leur rôle de jeton

Date : 2026-11-13 · Statut : proposée
Décidé par : à confirmer par Antoine

## Contexte

Deux décisions du 12 novembre lisaient un rôle qui disait autre chose faute d'un rôle exact : `2026-11-12-point-d-etape-sans-role.md` (écart entre les points de l'accueil, point inactif) et `2026-11-12-marge-d-un-bouton-de-coin.md` (marge d'un bouton au coin d'une carte). Un rôle détourné est un défaut : la valeur change le jour où le rôle d'origine change pour sa propre raison.

## Décision

`Resources/Brand/tokens.json` porte trois rôles propres à sema, chacun avec son usage :

- `space.step-dot-gap` : écart entre deux points d'un indicateur de progression (8 points) ;
- `color.step-dot-idle` : point d'étape pas encore atteint ;
- `space.corner-button-inset` : marge d'un bouton d'icône posé au coin d'une carte ou d'une surface (8 points).

L'accueil lit les deux premiers. Les tuiles de l'écran Favoris et le bouton de réglages du bandeau lisent le troisième. Cette décision remplace les deux décisions citées plus haut : il n'y a plus d'écart au patron.

## Options

| Option | Effet | Coût |
| --- | --- | --- |
| Garder les rôles détournés | Aucun jeton à ajouter | Le sens se perd à la prochaine modification du rôle d'origine |
| Un rôle exact par usage (retenue) | Le nom dit l'usage ; une valeur change à un seul endroit | Trois jetons de plus à entretenir |
| Demander les rôles à Sophos d'abord | Un patron commun | Bloque deux écrans sur un second besoin qui n'existe pas |

## Conséquences

Si le patron de Sophos reçoit un jour un rôle équivalent, sema le lit et retire le sien. Les trois jetons sont lus par au moins un écran ; `jetons.mjs` refuse un rôle sans description d'usage.
