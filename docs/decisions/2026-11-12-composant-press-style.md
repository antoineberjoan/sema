# Le retour d'appui des boutons reprend ButtonStyle avec une échelle

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine

## Contexte

Les boutons de sema réduisent légèrement à l'appui, sauf quand les animations sont réduites.

## Décision

Le composant est gardé avec cet écart à la référence (SwiftUI).

| Ce que la page de la référence décrit | Ce que le code fait | Pourquoi |
| --- | --- | --- |
| `ButtonStyle` (https://developer.apple.com/documentation/swiftui/buttonstyle) : `makeBody(configuration:)` et `configuration.isPressed` | Un `ButtonStyle` qui applique l'échelle `press-scale` du patron à l'appui, sans mouvement avec « Réduire les animations » | La référence ne donne pas de retour d'appui par défaut pour un bouton sans bordure |

**Ce qui retire l'écart** : un style de bouton du système qui donne ce retour d'appui.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| `ButtonStyle` avec échelle | Un retour d'appui uniforme | Un style à tenir |
| Styles du système seuls | Aucun écart | Aucun retour d'appui sur les cartes cliquables |

## Conséquences

Huit fichiers le lisent (cartes, lignes, tuiles). La durée et l'échelle lisent `DesignDuration` et `DesignMotion`.

## Trace

Lot des composants de l'alignement de sema sur Sophos : inventaire de `DesignSystem` avant sa suppression.
