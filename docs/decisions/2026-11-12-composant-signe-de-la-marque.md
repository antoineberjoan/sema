# Le signe de la marque est dessiné par trois composants propres

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine

## Contexte

Le signe est une courbe qui monte puis se pose en palier, avec un point à la jonction détaché par un anneau. Il est tracé à l'accueil, dans la signature du bandeau et dans les réglages.

## Décision

Le composant est gardé avec cet écart à la référence (SwiftUI).

| Ce que la page de la référence décrit | Ce que le code fait | Pourquoi |
| --- | --- | --- |
| Aucune page de la référence ne couvre un logo ; `Shape` (https://developer.apple.com/documentation/swiftui/shape) donne seulement la forme générique. | Trois composants : `SignalPath` (la courbe), `SignalDot` (le point et l'anneau) et `Symbol` (l'assemblage) | C'est la marque : sa géométrie ne vient pas d'un composant de la référence |

**Ce qui retire l'écart** : un projet de Sophos qui fabrique la forme du signe depuis une source de géométrie, comme les jetons.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Trois composants propres | Le signe identique partout dans l'app | Un tracé à garder aligné avec le fichier de marque |
| Un fichier image | Une seule source | Pas de tracé animé |

## Conséquences

**La géométrie du signe existe en trois copies** : le fichier SVG de marque, ces composants SwiftUI et `scripts/render-icon.swift`. C'est une même connaissance en trois endroits, contraire à « une seule source ». Cette décision le dit sans le résoudre ; la sortie est une génération des trois depuis une seule description.

## Trace

Lot des composants de l'alignement de sema sur Sophos : inventaire de `DesignSystem` avant sa suppression.
