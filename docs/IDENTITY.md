# Identité de Sema

## Direction

Une petite application Mac calme et précise. Mise en page et contrôles en SwiftUI natif, graphiques avec Swift Charts. Les matières, séparateurs et fonds suivent l’apparence système. Aucun kit de composants externe.

### Référence complémentaire : Resurf

Ajoutée par Antoine le 15 octobre 2026. Les vues officielles de [Resurf](https://resurf.so/) servent de référence pour une sidebar compacte, une barre d’outils discrète, des surfaces neutres légèrement chaudes et une distinction claire entre navigation, contenu et inspecteur. Pour Sema, ces principes guideront les prochains ajustements de densité et de hiérarchie ; la typographie système reste retenue et les accents suivent le thème choisi dans les réglages.

## Typographie

**SF Pro**, via `.system` : aucune police à télécharger ou embarquer. Conserver les styles natifs des contrôles ; utiliser `monospacedDigit()` pour aligner les valeurs financières. Les titres emploient les graisses medium et semibold. Éviter d’ajouter une seconde famille typographique.

## Couleurs

Six thèmes sont disponibles dans **Réglages → Apparence**. Sarcelle conserve le choix initial ; Lavande, Bleu polaire et Graphite reprennent les propositions, complétées par Menthe et Bleu ciel.

| Thème | Palette de référence |
| --- | --- |
| Menthe | `#8EC3B0` · `#9ED5C5` · `#BCEAD5` · `#DEF5E5` |
| Lavande | `#D0A2F7` · `#DCBFFF` · `#E5D4FF` · `#F1EAFF` |
| Bleu ciel | `#00A9FF` · `#89CFF3` · `#A0E9FF` · `#CDF5FD` |
| Sarcelle | `#265073` · `#2D9596` · `#9AD0C2` · `#ECF4D6` |
| Bleu polaire | `#053F56` · `#21A5EC` · `#90D2F5` · `#F2F3F7` |
| Graphite | `#333333` · `#707070` · `#D6D6D6` · `#FAFAFA` |

Les références pastel sont conservées dans l’aperçu. Les accents sont approfondis sur fond clair pour les textes, les courbes et les contrôles sélectionnés, puis éclaircis pour les courbes en mode sombre. Surfaces et typographie restent sémantiques macOS. Le choix est local, persistant et partagé par la fenêtre et le panneau. L’icône d’app conserve son identité Sarcelle.

## Symbole original

**Balise**, retenu par Antoine le 15 octobre 2026 : deux angles arrondis encadrent un point central, le repère qui mérite l’attention. Le symbole fonctionne sans dégradé et en monochrome. Le dégradé est réservé à l’icône d’app, pas aux contrôles.

- `Resources/Brand/sema-symbol.svg` : symbole sur fond transparent, couleur modifiable.
- `Resources/Brand/sema-symbol-mono.svg` : version monochrome.
- `Resources/Brand/sema-icon.svg` : icône avec fond bleu profond / teal et point mint.
- `SemaSymbol` : dessin natif SwiftUI du même symbole.
- `scripts/render-icon.swift` : rendu natif des PNG nécessaires au bundle macOS.

Le SVG, le dessin SwiftUI et le rendu de l’icône macOS appliquent la même géométrie.
