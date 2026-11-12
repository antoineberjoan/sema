# Le texte sur le verre garde le style système ; les fonds d'état lisent des opacités

Date : 2026-11-12 · Statut : acceptée
Décidé par : Antoine

## Contexte

Les couleurs de sema lisent les jetons de Sophos, fixes en clair et en sombre. Leur contraste se mesure sur des fonds pleins. Quelques surfaces de sema sont translucides : une matière floute le bureau derrière elle. Une couleur fixe n'y a plus de contraste garanti, et un fond de survol plein y cacherait la matière.

## Décision

Sur une surface translucide, deux écarts sont permis, et seulement là.

- **Le texte secondaire garde le style système** (`.secondary`). Il suit la matière, comme le fait le système.
- **Un fond de repos ou de survol** est `DesignColor.text` à une opacité lue dans un rôle de sema : `opacity.glass-rest` (0,035) et `opacity.glass-hover` (0,04). Aucune valeur n'est écrite dans une vue.

Le reste lit les jetons : la sélection (`selection`, déjà une teinte translucide), les fonds pleins de repli (`surface`), tous les textes sur fond plein.

**Une vue, un chemin.** Quand une même vue sert une surface opaque et une surface translucide (la ligne et le champ de la barre latérale, docked ou en aperçu), elle lit le rôle translucide dans les deux cas, sans branche « si aperçu ». Sur un fond opaque, une teinte à 4 % se voit presque comme le fond plein.

### La liste fermée

Les surfaces translucides de sema sont ces quatre, et aucune autre.

| Surface | Fichier, vue | Matière |
| --- | --- | --- |
| a | `Components/Custom/RibbonSurface.swift`, posé sur les cartes du bandeau (`RibbonCard`, `AgendaCard`, `MenuRibbonView`) et le panneau de recherche (`SearchPanelView`) | `NSVisualEffectView` et voile de contraste |
| b | `Overview/FocusSwitcherView.swift` | `.regularMaterial` |
| c | `Workspace/WorkspaceView.swift`, barre latérale en aperçu | `.regularMaterial` |
| d | `Ribbon/MenuRibbonView.swift`, bouton de réglages | `.regularMaterial` dans un cercle |

Les fonds de repos et de survol concernés : le badge de comparaison de `RibbonCard`, le rail de jours d'`AgendaCard`, le champ de recherche et la ligne survolée de la barre latérale. Ajouter une surface à cette liste est une décision datée.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Deux écarts bornés à une liste fermée | Un texte lisible sur le verre ; des jetons partout ailleurs | Une liste à tenir à jour |
| Jetons fixes partout | Aucun écart | Un contraste non garanti sur le verre, un survol plein qui cache la matière |
| Couleurs système partout | Le rendu actuel | Plus de jetons de couleur : contraire à Sophos |

## Conséquences

Les opacités `glass-rest` et `glass-hover` sont des valeurs de marque de sema : `jetons.mjs --ecarts` les liste, c'est normal. Une surface translucide qui n'est pas dans la liste lit les jetons de plein.

## Trace

Règle de l'architecte du 2026-11-12, validée par Antoine ; `patron/couleur.md` 1.1 (surfaces translucides).
