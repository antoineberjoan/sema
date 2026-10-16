# Identité de sema

## Direction

Une petite application Mac calme et précise. Mise en page et contrôles en SwiftUI natif, graphiques avec Swift Charts. Les matières, séparateurs et fonds suivent l’apparence système. Aucun kit de composants externe.

### Référence complémentaire : Resurf

Ajoutée par Antoine le 15 octobre 2026. Les vues officielles de [Resurf](https://resurf.so/) servent de référence pour une sidebar compacte, une barre d’outils discrète, des surfaces neutres légèrement chaudes et une distinction claire entre navigation, contenu et inspecteur. Pour sema, ces principes guideront les prochains ajustements de densité et de hiérarchie ; la typographie système reste retenue et les accents suivent le thème choisi dans les réglages.

### Surfaces et hiérarchie

La revue Interface Craft et les visuels publics de [Monocle](https://trymonocle.app/) guident la passe du 16 octobre : liste de repères sobre, graphique dominant, suppression des contours décoratifs des tuiles, badges et panneaux. La surface de détail est légèrement plus claire en mode sombre et porte une ombre de contact courte avec une ombre ambiante discrète. Les autres repères restent sur le plan de fond.

La fenêtre et son séparateur restent un `NavigationSplitView`. Les lignes de sidebar sont des boutons SwiftUI personnalisés avec sélection neutre, icônes SF Symbols, traits d’accessibilité et survol discret. Les actions rejoignent la barre d’outils native. Les ombres ne s’appliquent pas à chaque élément de liste. Les contrôles conservent leur focus clavier natif ; les animations de pression et de survol respectent Réduire les animations.

### Verre et signature du bandeau

Les captures de Monocle fournies par Antoine guident la matière : des cartes macOS réellement translucides, une mince lumière sur leur bord et des coins continus. Aucun grand fond ne les encadre ; les espaces entre les cartes restent transparents. Les sept périodes restent visibles directement dans une seule barre native, à côté des réglages. Le bord du panneau est à 8 pt de la zone visible ; le contenu commence à 6 pt et 6 pt séparent la barre des cartes. Le fond reste neutre en Graphite ; sa couleur perçue vient aussi du contenu derrière le panneau. Le flou repose sur [NSVisualEffectView](https://developer.apple.com/documentation/appkit/nsvisualeffectview), en mode derrière la fenêtre, sans dépendance externe ni imitation d’un fond d’écran. Le voile de contraste laisse passer la matière et protège la lecture des chiffres. Réduire la transparence ou Augmenter le contraste impose une surface opaque.

Le cartouche dit **« L’économie bouge. Gardez vos repères. »**. Le tracé Palier commence après 300 ms et dure 1 800 ms ; le contexte apparaît à 1 250 ms, puis la signature à 1 850 ms, avec des fondus de 800 ms. Ces valeurs sont centralisées dans `SignatureMotion`. Une séquence à chaque présentation, aucune boucle ni bouton Rejouer. Le nom n’est pas répété au-dessus du signe ; 18 pt séparent la mission du bouton de retour. Réduire les animations affiche directement le résultat. Les données restent accessibles pendant toute la séquence. Ce cartouche est intégré au bandeau natif. Son fond bleu ardoise (`#355A80`) constitue l’unique surface éditoriale colorée en Graphite ; les thèmes personnels réemploient leur accent approfondi. Un fond noir sous le dégradé et des textes blancs préservent le contraste. Le bouton « Une idée ou un bug ? » ouvre le formulaire Notion public, sans accès aux réponses. La marque et l’icône restent monochromes.

## Typographie

**SF Pro**, via `.system` : aucune police à télécharger ou embarquer. Conserver les styles natifs des contrôles ; utiliser `monospacedDigit()` pour aligner les valeurs financières. Les titres emploient les graisses medium et semibold. Éviter d’ajouter une seconde famille typographique.

## Couleurs

Graphite est le thème par défaut : noir, blanc et gris. Six thèmes restent disponibles dans **Réglages → Apparence** ; les choix enregistrés sont conservés. Sarcelle, Menthe, Lavande, Bleu ciel et Bleu polaire sont des personnalisations facultatives.

| Thème | Palette de référence |
| --- | --- |
| Menthe | `#8EC3B0` · `#9ED5C5` · `#BCEAD5` · `#DEF5E5` |
| Lavande | `#D0A2F7` · `#DCBFFF` · `#E5D4FF` · `#F1EAFF` |
| Bleu ciel | `#00A9FF` · `#89CFF3` · `#A0E9FF` · `#CDF5FD` |
| Sarcelle | `#265073` · `#2D9596` · `#9AD0C2` · `#ECF4D6` |
| Bleu polaire | `#053F56` · `#21A5EC` · `#90D2F5` · `#F2F3F7` |
| Graphite | `#333333` · `#707070` · `#D6D6D6` · `#FAFAFA` |

Les références pastel sont conservées dans l’aperçu. Les accents sont approfondis sur fond clair pour les textes, les courbes et les contrôles sélectionnés, puis éclaircis pour les courbes en mode sombre. Surfaces et typographie restent sémantiques macOS. Le choix est local, persistant et partagé par la fenêtre et le panneau. La marque, le site, la page de téléchargement et l’icône d’app sont monochromes. L’icône présente le signe blanc sur un fond graphite, indépendamment du thème personnel.

## Symbole — Palier · Référence

Retenu le 16 octobre 2026. Le dessin « Palier — Référence » d’Antoine remplace Déploiement D3 · Apaisé. La courbe du SVG fourni est conservée exactement : une boucle élancée, un passage et une sortie en palier. Seuls le centrage uniforme et les épaisseurs optiques changent selon le support. Le signe évoque un repère sans représenter une donnée réelle.

La géométrie est identique en SVG, SwiftUI et Core Graphics. Trois poids optiques dans le kit : Display (trait source 3,6, à partir de 96 px), Standard (6, de 28 à 95 px), Compact (8,5, de 16 à 27 px). Le symbole ne descend pas sous 16 px. L’icône d’app utilise le poids Compact dans un carré encre aux coins arrondis, avec un signe blanc.

- `Resources/Brand/sema-symbol.svg` : Standard, transparent.
- `Resources/Brand/sema-symbol-mono.svg` : variante renforcée pour la barre de menus, trait source 20,915033 (2 pt à 18 pt). Le poids Compact général reste inchangé.
- `Resources/Brand/sema-icon.svg` : icône de l’app.
- `SemaSymbol` : géométrie native, poids adapté à la taille.
- `scripts/render-icon.swift` : PNG et icône du bundle.

## Marque et rédaction

Le nom s’écrit **sema**, toujours en minuscules, y compris en début de phrase et dans le mot-symbole. Les noms techniques des cibles Swift, des fichiers distribués et du dossier de stockage existant restent stables.

Signature : **Gardez vos repères.** La promesse est de réunir les repères économiques du conseiller dans une petite app Mac. Trois qualités guident les choix : calme, précision, attention aux détails. Le ton est direct, posé et concret ; vouvoiement, phrases courtes, vocabulaire financier explicité. Toujours afficher source, période et unité. Une hausse de taux n’est pas automatiquement une bonne nouvelle : garder une couleur neutre et une variation signée.

Le guide de marque v1.3 et ses démonstrations de mouvement sont accessibles dans le site privé, à `/brand/`. Le kit de livraison comprend les SVG, les tokens JSON/CSS et le guide HTML autonome. Les démonstrations du guide ne changent pas le fonctionnement de l’app. Les animations actuelles restent natives, avec Réduire les animations respecté ; toute nouvelle séquence se valide au clavier, à vitesse normale et en interruption rapide.
