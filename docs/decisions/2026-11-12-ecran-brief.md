# L'écran Brief lit les rôles de sens, avec sept choix à relire

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine

## Contexte

L'écran Brief réunit une phrase sur la séance, les mouvements, les faits du jour et l'agenda de la semaine. Sept lectures n'ont pas de rôle exact. La ligne d'agenda sert aussi la carte Agenda du bandeau, qui est sur du verre.

## Décision

- **Les blocs de la page** sont séparés de 48 points (`section-gap`).
- **Les lignes de mouvement** ont une marge verticale de 8 points (`row-inset`) : ce sont des lignes de liste.
- **Le texte discret** (variation de séance, rang) lit `text-muted` : le patron n'a qu'un niveau de texte atténué.
- **La carte Agenda** a une marge de 16 points (`card-inset`) et un fond `surface` plein. Les lignes de l'agenda sont séparées de 16 points (`item-gap`).
- **Le jour choisi** dans la bande de la semaine a le fond `selection` (teinte d'accent) ; la bande est posée sur `surface-raised`.
- **Une ligne d'agenda** lit la même teinte sur la page et sur la carte de verre : un mouvement a le fond `selection`, les autres lignes ont le texte à l'opacité `glass-rest`. C'est la règle « une vue, un chemin » de la décision sur les surfaces translucides. La barre d'une publication ou d'un communiqué lit `text-muted` ou `rule-hover`.
- **Le texte d'action d'une ligne** (« Voir », « Ouvrir ») lit `accent-text`.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Lire le rôle par son sens | Aucune valeur recopiée ; une seule teinte pour la ligne d'agenda | Un seul niveau de gris atténué ; des lignes de 8 points de marge |
| Écrire une valeur propre à sema | Des marges sur mesure et un second gris | Des rôles propres à sema pour 8, 12, 24 et 32 points et pour un second gris |

## Conséquences

La carte Agenda du bandeau lit ces deux fonctions de ligne avec une palette.
