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
| Trois composants propres | Le signe identique partout dans l'app ; une source pour les SVG et l'icône | Un export à relancer quand la géométrie change |
| Un fichier image | Une seule source | Pas de tracé animé |

## Conséquences

**Une seule source.** La géométrie du signe est écrite une fois, dans `SignalPath.swift` (points, trait, rayons, géométrie de l'icône d'app). Les fichiers SVG de la marque sont exportés par `scripts/export_signe.py`, et `controler.sh` échoue si l'un d'eux diffère de l'export. Les tailles d'icône du bundle sont dessinées par `scripts/render-icon/main.swift`, compilé avec `SignalPath.swift` et les couleurs générées. Le mot « sema » du lockup est un dessin (`Resources/Brand/sema-wordmark.svg`), repris tel quel.

## Trace

Lot des composants de l'alignement de sema sur Sophos : inventaire de `DesignSystem` avant sa suppression.
