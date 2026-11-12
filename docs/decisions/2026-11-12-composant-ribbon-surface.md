# Le verre des cartes du bandeau est un composant propre de sema

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine

## Contexte

Les cartes du bandeau et le panneau de recherche rapide sont réellement translucides : une matière macOS derrière la fenêtre, un voile de contraste, une teinte de la palette, un grain fin et une lumière sur le bord. Ce choix est dans les décisions sur le verre du bandeau et sur les surfaces translucides.

## Décision

Le composant est gardé avec cet écart à la référence (SwiftUI).

| Ce que la page de la référence décrit | Ce que le code fait | Pourquoi |
| --- | --- | --- |
| Pages cherchées : `Material` (https://developer.apple.com/documentation/swiftui/material) et `NSViewRepresentable` (https://developer.apple.com/documentation/swiftui/nsviewrepresentable). `Material` ne donne pas la matière « derrière la fenêtre ». | Un `NSViewRepresentable` autour d'un `NSVisualEffectView` en mode derrière la fenêtre, plus un voile, une teinte, un grain et un bord, et un repli opaque | Les réglages Transparence, Teinte et Grain, et le repli de l'accessibilité, n'existent pas dans la référence |

**Ce qui retire l'écart** : une matière de la référence qui se pose derrière la fenêtre et se règle (voile, teinte, grain).

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Composant propre | Le verre du bandeau, réglable | Un composant AppKit à tenir à chaque version de macOS |
| `Material` seul | Un composant de la référence | Pas de matière derrière la fenêtre, pas de réglages |

## Conséquences

Les opacités du verre (voile, teinte, grain, lumière) restent des constantes nommées de la vue : elles sont propres à cette décision. Le rayon (`radius.card`) et le contour (`border.width`) lisent le patron.

## Trace

Lot des composants de l'alignement de sema sur Sophos : inventaire de `DesignSystem` avant sa suppression.
