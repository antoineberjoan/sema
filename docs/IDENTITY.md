# Identité de Sema

## Direction

Une petite application Mac calme et précise. Mise en page et contrôles en SwiftUI natif, graphiques avec Swift Charts. Les matières, séparateurs et fonds suivent l’apparence système. Aucun kit de composants externe.

### Référence complémentaire : Resurf

Ajoutée par Antoine le 15 octobre 2026. Les vues officielles de [Resurf](https://resurf.so/) servent de référence pour une sidebar compacte, une barre d’outils discrète, des surfaces neutres légèrement chaudes et une distinction claire entre navigation, contenu et inspecteur. Pour Sema, ces principes guideront les prochains ajustements de densité et de hiérarchie ; la typographie système reste retenue et les accents suivent le thème choisi dans les réglages.

### Surfaces et hiérarchie

La revue Interface Craft et les visuels publics de [Monocle](https://trymonocle.app/) guident la passe du 16 octobre : liste de repères sobre, graphique dominant, suppression des contours décoratifs des tuiles, badges et panneaux. La surface de détail est légèrement plus claire en mode sombre et porte une ombre de contact courte avec une ombre ambiante discrète. Les autres repères restent sur le plan de fond.

La fenêtre et son séparateur restent un `NavigationSplitView`. Les lignes de sidebar sont des boutons SwiftUI personnalisés avec sélection neutre, icônes SF Symbols, traits d’accessibilité et survol discret. Les actions rejoignent la barre d’outils native. Les ombres ne s’appliquent pas à chaque élément de liste. Les contrôles conservent leur focus clavier natif ; les animations de pression et de survol respectent Réduire les animations.

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

Les références pastel sont conservées dans l’aperçu. Les accents sont approfondis sur fond clair pour les textes, les courbes et les contrôles sélectionnés, puis éclaircis pour les courbes en mode sombre. Surfaces et typographie restent sémantiques macOS. Le choix est local, persistant et partagé par la fenêtre et le panneau. L’icône d’app conserve un fond encre et le symbole en sarcelle claire, indépendamment du thème.

## Symbole — Déploiement D3 · Apaisé

Retenu le 16 octobre 2026. Le dessin d’Antoine est conservé : une boucle, une progression, une sortie calme. Il évoque un signal sans représenter une donnée réelle. Il remplace Balise.

La géométrie est identique en SVG, SwiftUI et Core Graphics. Trois poids optiques dans le kit : Display (trait source 3,6, à partir de 96 px), Standard (6, de 28 à 95 px), Compact (8,5, de 16 à 27 px). Le symbole ne descend pas sous 16 px. L’icône d’app utilise le poids Compact dans un carré encre aux coins arrondis, avec un signe sarcelle claire.

- `Resources/Brand/sema-symbol.svg` : Standard, transparent.
- `Resources/Brand/sema-symbol-mono.svg` : variante renforcée pour la barre de menus, trait source 15,7 (1,50 pt à 18 pt). Le poids Compact général reste inchangé.
- `Resources/Brand/sema-icon.svg` : icône de l’app.
- `SemaSymbol` : géométrie native, poids adapté à la taille.
- `scripts/render-icon.swift` : PNG et icône du bundle.

## Marque et rédaction

Signature : **Gardez vos repères.** La promesse est de réunir les repères économiques du conseiller dans une petite app Mac. Trois qualités guident les choix : calme, précision, attention aux détails. Le ton est direct, posé et concret ; vouvoiement, phrases courtes, vocabulaire financier explicité. Toujours afficher source, période et unité. Une hausse de taux n’est pas automatiquement une bonne nouvelle : garder une couleur neutre et une variation signée.

Le guide de marque v1 et ses démonstrations de mouvement sont accessibles dans le site privé, à `/brand/`. Le kit de livraison comprend les SVG, les tokens JSON/CSS et le guide HTML autonome. Les démonstrations du guide ne changent pas le fonctionnement de l’app. Les animations actuelles restent natives, avec Réduire les animations respecté ; toute nouvelle séquence se valide au clavier, à vitesse normale et en interruption rapide.
