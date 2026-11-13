# Le graphique d'historique assemble Swift Charts avec un survol et une réduction de points

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine

## Contexte

Le graphique montre une série, lit le point le plus proche au survol et borne le nombre de points dessinés pour les longues courbes.

## Décision

Le composant est gardé avec cet écart à la référence (SwiftUI).

| Ce que la page de la référence décrit | Ce que le code fait | Pourquoi |
| --- | --- | --- |
| Swift Charts (https://developer.apple.com/documentation/charts) : `LineMark`, `AreaMark`, `RuleMark`, `chartOverlay` | Les marques documentées, plus un survol qui retrouve l'observation d'origine et une réduction min/max | Une courbe longue doit rester fluide, et le survol doit lire la valeur exacte |

**Ce qui retire l'écart** : une propriété de Swift Charts qui réduit les points d'une série ou lit le point le plus proche.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Charts avec survol et réduction | Une courbe fluide, une lecture exacte | Une logique de survol à tenir |
| Charts seul | Aucun écart | Une courbe lente sur dix ans, sans lecture exacte |

## Conséquences

Lu par le seul détail d'une série : le composant est dans les composants de l'écran Aperçu.
