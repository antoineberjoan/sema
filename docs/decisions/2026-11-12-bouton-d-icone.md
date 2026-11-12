# Un bouton d'icône fait 26 points

Date : 2026-11-12 · Statut : acceptée
Décidé par : Antoine

## Contexte

Les boutons d'icône de sema (étoile, inversion d'une devise, actions de la barre d'outils) font 26 points. Le patron donne `target.min`, 44 points : le côté minimal d'une cible au toucher. Il n'a pas de rôle pour la taille d'un bouton d'icône au pointeur.

## Décision

sema ajoute le rôle `icon.button-size`, 26 points, dans son `tokens.json`.

C'est une app Mac au pointeur : la cible au toucher n'est pas applicable. Si une vue accepte un jour le toucher (iPad, Catalyst), elle lit `target.min` et non ce rôle.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Un rôle propre à sema | 26 points, nommés | Un rôle hors du patron, listé par `--ecarts` |
| Lire `target.min` (44) | Aucun rôle ajouté | Des boutons plus grands partout : un changement visible sur une app au pointeur |

## Conséquences

Le rôle `icon.button-size` est lu par les huit endroits qui dessinent un bouton d'icône. Si le patron crée un rôle de taille de bouton d'icône, sema le lira et retire celui-ci.

## Trace

Interprétation de l'architecte du 2026-11-12, validée par Antoine.
