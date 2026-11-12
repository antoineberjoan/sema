# L'écran Explorateur lit les rôles de sens, avec huit choix à relire

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine

## Contexte

L'écran Explorateur regroupe le choix d'une source, le catalogue, la recherche, l'aperçu avant ajout, le catalogue des cours et la recherche rapide ⌘K. Une partie de ses vues est partagée entre une fenêtre opaque et le panneau de recherche, qui est sur du verre.

## Décision

- **Les lignes de résultat** (jeux, séries, instruments, repères de départ) ont une marge de 8 points (`row-inset`) et un rayon de 10 points. Elles sont séparées de 2 points (`list-gap-dense`). Un titre et son texte sont séparés de 4 points (`title-gap`).
- **Les cartes de source** ont une marge de 16 points (`card-inset`) et un rayon de 10 points.
- **Les champs de recherche** ont une marge de 12 points (`menu-inset`) : ce sont des champs, pas des lignes de liste. Les lignes en dessous sont à 8 points ; l'écart de 4 points entre les deux se voit à l'alignement.
- **Le titre d'un résultat** a un maximum de trois lignes. Ce nombre n'est pas un jeton : il vit dans `ExplorerLayout`, partagé par les trois listes.
- **La sélection d'un résultat** lit `selection` (teinte d'accent de 12 % en clair, 24 % en sombre).
- **Le champ de clé exacte** lit le rôle `code` (monospace, 13 points).
- **Le panneau de recherche rapide et la liste de ses résultats** gardent le texte secondaire du système : ils sont sur la liste fermée des surfaces translucides. La liste des résultats est la même dans le panneau et dans la feuille ⌘K, donc elle garde ce texte dans les deux. Le contour de la touche « esc » lit `rule`.
- **Les marges d'une feuille ou d'une zone de chargement** sont de 32 points (`page-inset-narrow`).

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Lire le rôle par son sens | Aucune valeur recopiée ; une seule marge pour toutes les lignes | Des lignes serrées (8 points), des cartes peu hautes |
| Écrire une valeur propre à sema | Des marges sur mesure | Des rôles propres à sema pour 12, 14, 24 points et pour deux rayons |

## Conséquences

Le même choix de 8 points pour une ligne de liste vaut pour Brief et pour l'écran Alertes. Le changer est un remplacement de `row-inset` dans les fichiers de liste.
