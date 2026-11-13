# Le site se limite à une promesse, un téléchargement et trois réponses

Date : 2026-10-17 · Statut : acceptée
Décidé par : Antoine

## Contexte

Antoine a retenu une présentation web très courte.

## Décision

- L'accueil tient en une promesse en deux lignes, un téléchargement, la commande Homebrew copiable, deux scènes animées et trois réponses utiles. Les textes visibles sont en minuscules.
- Les pages du site partagent un en-tête fixe au défilement : le signe à gauche, sans lien « nouveautés ». « télécharger » apparaît seulement quand le bouton principal sort de la zone visible. Masqué, il est inerte et absent du parcours clavier.
- Le pied de page tient sur une ligne : l'auteur, les retours, les mentions légales et la confidentialité. Le soutien Ko-fi est une note discrète avant le pied de page.
- Les deux pages légales sont publiées avec l'e-mail public d'Antoine, sans téléphone personnel. Les points à régulariser sont dans `LEGAL.md`.
- L'accueil affiche la commande Homebrew courte, copiable. La préparation technique est dans `distribution/README.md`.
- Le signe se trace une fois à chaque chargement, après 160 ms et pendant 2 400 ms. « Réduire les animations » l'affiche entier tout de suite. Les durées se règlent dans `site/tokens.json`.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Page courte, une action | Une décision rapide pour la personne | Peu de place pour expliquer |
| Page riche avec démonstrations | Plus d'explications | Du bruit ; des démonstrations simulées |

## Conséquences

Ces règles sont reprises dans `site/AGENTS.md`, ou remplacées par une décision.
