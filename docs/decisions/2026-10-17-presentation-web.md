# Le site se limite à une promesse, un téléchargement et trois réponses

Date : 2026-10-17 · Statut : acceptée
Décidé par : Antoine

## Contexte

Le 17 octobre, Antoine a retenu une présentation web très courte. Le site garde son identité actuelle jusqu'à son propre chantier.

## Décision

- L'accueil tient en une promesse en deux lignes, un téléchargement, un lien Homebrew discret, une capture et trois réponses utiles. Les recherches simulées, agrandissements et libellés décoratifs sont retirés. Les textes visibles sont en minuscules.
- L'accueil et la page d'installation partagent un en-tête fixe au défilement : le signe à gauche, sans lien « nouveautés ». « télécharger » apparaît seulement quand le bouton principal sort de la zone visible. Masqué, il est inerte et absent du parcours clavier.
- Le pied de page tient sur une ligne : l'auteur, les retours, les mentions légales et la confidentialité. Le soutien Ko-fi est une note discrète avant le pied de page.
- Les deux pages légales sont publiées avec l'e-mail public d'Antoine, sans téléphone personnel. Les points à régulariser sont dans `LEGAL.md`.
- La commande Homebrew complète reste dans les instructions d'installation. L'accueil dit seulement « installer avec homebrew ».
- La capture du hub vient du bundle natif de revue, en Graphite sombre, avec les valeurs fictives identifiées.
- Le signe se trace une fois à chaque chargement, après 160 ms et pendant 2 400 ms. « Réduire les animations » l'affiche entier tout de suite. Les durées se règlent dans `site/dist/chrome.css`.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Page courte, une action | Une décision rapide pour la personne | Peu de place pour expliquer |
| Page riche avec démonstrations | Plus d'explications | Du bruit ; des démonstrations simulées |

## Conséquences

Ces règles sont reprises dans `site/AGENTS.md`, ou remplacées par une décision.
