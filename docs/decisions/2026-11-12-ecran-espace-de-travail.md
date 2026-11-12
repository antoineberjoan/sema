# L'écran Espace de travail lit les rôles de sens, avec cinq choix à relire

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine

## Contexte

L'espace de travail est la fenêtre principale : la barre latérale (ouverte à demeure ou en aperçu sur du verre), le contenu de chaque rubrique et la barre d'état des données. Les lignes de la barre latérale servent les deux présentations.

## Décision

- **Les lignes de la barre latérale** (rubriques et repères) lisent un seul chemin pour la sélection : `selection` (teinte d'accent), à la place d'une teinte neutre du texte. C'est la décision prise pour toutes les barres latérales. Le survol est le texte à l'opacité `glass-hover`, dans l'aperçu comme dans la barre ouverte.
- **Le champ « Rechercher »** de la barre lit le texte à l'opacité `glass-rest`.
- **Les valeurs et les compteurs** de la barre lisent `text-muted`. C'est un gris opaque, comme l'ancien gris propre à la barre, fait pour rester lisible sur la matière.
- **Les marges du contenu** passent à 32 points (`page-inset-narrow`) ; la marge latérale de Focus passe de 48 points à 64 points (`page-inset-wide`) ; la marge haute de Focus de 24 points à 32 points.
- **Le panneau d'aperçu de la barre** a le rayon `window` (14 points, 16 avant) et l'ombre `floating`.
- **Le voile derrière le sélecteur Focus** lit le texte à l'opacité `glass-rest` à la place d'un noir à 3,5 %. En mode sombre, c'est un voile clair, à peine visible.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Lire le rôle par son sens | Un seul chemin pour la barre ouverte et l'aperçu ; aucune couleur écrite | Une sélection teintée d'accent, un contenu plus encadré de 8 points, un voile sombre devenu clair en mode sombre |
| Garder les valeurs actuelles | Aucun changement visible | Des rôles propres à sema pour 6, 14 et 48 points, une sélection neutre et un noir écrit |

## Conséquences

Les valeurs et la barre d'état lisent `text-muted` sur une fenêtre opaque. Sur l'aperçu en verre, les valeurs de la barre gardent le même gris, comme avant.

## Trace

Neuvième et dernier lot d'écran de l'alignement de sema sur Sophos.
