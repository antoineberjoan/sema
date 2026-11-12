# L'écran Réglages lit les rôles de sens, avec six choix à relire

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine

## Contexte

La fenêtre de Réglages réunit les onglets, le choix de la palette et du mode, la position du bandeau, les raccourcis, les clés de source et le profil. Elle est dans une fenêtre opaque. Six lectures n'ont pas de rôle exact.

## Décision

- **Le repère « Mon espace »** de la barre latérale a le fond `selection` (teinte d'accent). Le patron n'a pas de sélection neutre ; la décision vaut pour toutes les barres latérales.
- **Les marges de la page** (titre de l'onglet) sont de 32 points (`page-inset-narrow`).
- **Les marges de la zone de recherche** lisent des rôles : 14 points sur les côtés (`panel-inset-inline`, exact), 16 en haut (`card-inset`), 12 en bas (`menu-inset`).
- **Le champ de recherche et les tuiles de choix** (mode, position) lisent `surface-raised` et `surface`. Ils sont sur une fenêtre opaque.
- **Les écarts** sont de 12 points (`field-gap`), 10 points (`frame-inset`) ou 4 points (`title-gap`) selon ce qu'ils séparent ; les 8 points d'une icône et de son texte lisent `icon.gap`.
- **Les interrupteurs et les choix** utilisent `accent-control` comme couleur de contrôle ; le texte « Connecté » lit `accent-text`.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Lire le rôle par son sens | Aucune valeur recopiée ; une sélection d'accent partout | Une barre « Mon espace » teintée d'accent |
| Écrire une valeur propre à sema | Une sélection neutre et des marges sur mesure | Des rôles propres à sema pour 6, 14, 18, 26 et 28 points et une sélection neutre |

## Conséquences

Les cases de la palette ont leurs aperçus dans `palette-preview-1` et `palette-preview-2`. Les deux sont des couleurs du patron.
