# Les sections repliables s'ouvrent sur toute leur ligne

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine

## Contexte

Une section repliable de sema s'ouvre en cliquant n'importe où sur sa ligne, pas seulement sur la flèche.

## Décision

Le composant est gardé avec cet écart à la référence (SwiftUI).

| Ce que la page de la référence décrit | Ce que le code fait | Pourquoi |
| --- | --- | --- |
| `DisclosureGroupStyle` (https://developer.apple.com/documentation/swiftui/disclosuregroupstyle) : `makeBody(configuration:)`, `isExpanded`, `label`, `content` | Un `DisclosureGroupStyle` dont l'étiquette entière est le bouton, avec la courbe `out` du patron | Le style du système ne rend cliquable que la flèche |

**Ce qui retire l'écart** : un style de la référence qui rend toute la ligne cliquable.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| `DisclosureGroupStyle` sur toute la ligne | Une cible de clic grande | Un style à tenir |
| Style du système | Aucun écart | Une cible de clic réduite à la flèche |

## Conséquences

Lu par l'Explorateur et l'Aperçu.
