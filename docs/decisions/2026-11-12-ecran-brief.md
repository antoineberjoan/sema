# L'écran Brief lit les rôles de sens, avec sept choix à relire

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine

## Contexte

L'écran Brief réunit une phrase sur la séance, les mouvements, les faits du jour et l'agenda de la semaine. Sept lectures n'ont pas de rôle exact. La ligne d'agenda sert aussi la carte Agenda du bandeau, qui est sur du verre.

## Décision

- **Les blocs de la page** sont séparés de 48 points (`section-gap`, 32 avant).
- **Les lignes de mouvement** ont une marge verticale de 8 points (`row-inset`, 12 avant) : ce sont des lignes de liste.
- **Le texte discret** (variation de séance, rang) lisait le style `tertiary`. Il lit `text-muted` : le patron n'a qu'un niveau de texte atténué, donc deux niveaux de gris deviennent un.
- **La carte Agenda** a une marge de 16 points (`card-inset`, 24 avant) et un fond `surface` plein (3,5 % de la couleur du texte avant). Les lignes de l'agenda sont séparées de 16 points (`item-gap`, 8 avant).
- **Le jour choisi** dans la bande de la semaine a le fond `selection` (teinte d'accent) ; la bande est posée sur `surface-raised`. Le fond du jour choisi était `surface`.
- **Une ligne d'agenda** lit la même teinte sur la page et sur la carte de verre : un mouvement a le fond `selection`, les autres lignes ont le texte à l'opacité `glass-rest`. C'est la règle « une vue, un chemin » de la décision sur les surfaces translucides. La barre d'une publication ou d'un communiqué lit `text-muted` ou `rule-hover`.
- **Le texte d'action d'une ligne** (« Voir », « Ouvrir ») lit `accent-text`.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Lire le rôle par son sens | Aucune valeur recopiée ; une seule teinte pour la ligne d'agenda | Des lignes plus serrées, une carte Agenda plus haute de 8 points par ligne, un gris de moins |
| Garder les valeurs actuelles | Aucun changement visible | Des rôles propres à sema pour 8, 12, 24 et 32 points et pour un second gris |

## Conséquences

La carte Agenda du bandeau lit ces deux fonctions avec une palette. Le reste de la carte est relu au lot du bandeau.

## Trace

Cinquième lot d'écran de l'alignement de sema sur Sophos.
