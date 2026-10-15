# Identité de Sema

## Direction

Une petite application Mac calme et précise. Mise en page et contrôles en SwiftUI natif, graphiques avec Swift Charts. Les matières, séparateurs et fonds suivent l’apparence système. Aucun kit de composants externe.

## Typographie

**SF Pro**, via `.system` : aucune police à télécharger ou embarquer. Conserver les styles natifs des contrôles ; utiliser `monospacedDigit()` pour aligner les valeurs financières. Les titres emploient les graisses medium et semibold. Éviter d’ajouter une seconde famille typographique.

## Couleurs

La cinquième référence d’Antoine fournit le bleu profond et le teal, la quatrième les neutres, et la sixième la douceur du mint.

| Usage | Couleur |
| --- | --- |
| Marque, partie sombre de l’icône | `#265073` |
| Teal de marque, partie claire de l’icône | `#2D9596` |
| Actions et courbes en apparence claire | `#1F6F73` |
| Accent en apparence sombre | `#9AD0C2` |
| Textes et surfaces | Couleurs sémantiques macOS |

Le teal de marque est assombri pour les petits textes et actions sur fond clair. Le vert et le rouge liés aux variations restent des informations distinctes de la couleur de marque ; une direction est aussi exprimée par le texte et le signe.

## Symbole original

Un S continu aux extrémités arrondies, accompagné d’un point détaché : le signal qui mérite l’attention. Le symbole fonctionne sans dégradé et en monochrome. Le dégradé est réservé à l’icône d’app, pas aux contrôles.

- `Resources/Brand/sema-symbol.svg` : symbole sur fond transparent, couleur modifiable.
- `Resources/Brand/sema-symbol-mono.svg` : version monochrome.
- `Resources/Brand/sema-icon.svg` : icône avec fond bleu profond / teal et point mint.
- `SemaSymbol` : dessin natif SwiftUI du même symbole.
- `scripts/render-icon.swift` : rendu natif des PNG nécessaires au bundle macOS.

Ces fichiers sont des propositions originales de travail. Ils restent modifiables avant la finalisation de l’identité.
