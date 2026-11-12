# L'écran Espace de travail lit les rôles de sens, avec cinq choix à relire

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine

## Contexte

L'espace de travail est la fenêtre principale : la barre latérale (ouverte à demeure ou en aperçu sur du verre), le contenu de chaque rubrique et la barre d'état des données. Les lignes de la barre latérale servent les deux présentations.

## Décision

- **Les lignes de la barre latérale** (rubriques et repères) lisent un seul chemin pour la sélection : `selection` (teinte d'accent). La décision vaut pour toutes les barres latérales. Le survol est le texte à l'opacité `glass-hover`, dans l'aperçu comme dans la barre ouverte.
- **Le champ « Rechercher »** de la barre lit le texte à l'opacité `glass-rest`.
- **Les valeurs et les compteurs** de la barre lisent `text-muted`. C'est un gris opaque, fait pour rester lisible sur la matière.
- **Les marges du contenu** sont de 32 points (`page-inset-narrow`) ; la marge latérale de Focus est de 64 points (`page-inset-wide`) et sa marge haute de 32 points.
- **Le panneau d'aperçu de la barre** a le rayon `window` (14 points) et l'ombre `floating`.
- **Le voile derrière le sélecteur Focus** lit `scrim`, le rôle du voile d'une fenêtre modale. Il est sombre dans les deux modes (32 % en clair, 56 % en sombre).

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Lire le rôle par son sens | Un seul chemin pour la barre ouverte et l'aperçu ; aucune couleur écrite | Une sélection teintée d'accent, un voile marqué, sombre dans les deux modes |
| Écrire une valeur propre à sema | Une sélection neutre, un voile discret | Des rôles propres à sema pour 6, 14 et 48 points, une sélection neutre et un noir écrit |

## Conséquences

Les valeurs et la barre d'état lisent `text-muted` sur une fenêtre opaque. Sur l'aperçu en verre, les valeurs de la barre gardent le même gris.
