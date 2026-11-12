# Le badge de l'écart à l'habituel est un composant propre de sema

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine

## Contexte

Un mouvement se lit en multiple de l'habituel. Le badge intensifie sa teinte avec ce multiple, sans jamais dire hausse ou baisse. Il est lu par l'écran Alertes, l'Aperçu et les cartes du bandeau.

## Décision

Le composant est gardé avec cet écart à la référence (SwiftUI).

| Ce que la page de la référence décrit | Ce que le code fait | Pourquoi |
| --- | --- | --- |
| Pages cherchées : `Text`, `Label`, `Gauge` (https://developer.apple.com/documentation/swiftui/gauge). Aucune ne décrit un badge à zones d'intensité. | Un `Text` à fond teinté, cinq zones : sous 1×, 1 à 2×, 2 à 3×, 3 à 5×, au-dessus de 5× | L'intensité porte le sens à elle seule ; une jauge dessinerait une échelle, pas une pastille |

**Ce qui retire l'écart** : une page de la référence qui décrit un badge à teinte graduée.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Composant propre | Une pastille lisible à côté d'un chiffre | Un écart de plus à relire à chaque mise à jour de la référence |
| `Gauge` | Un composant de la référence | Une jauge n'est pas une pastille |

## Conséquences

Le fond de la zone calme est le texte à l'opacité `glass-rest` : le même sur une page opaque et sur une carte de verre.
