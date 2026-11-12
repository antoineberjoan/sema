# Les raccourcis globaux n'exigent aucune permission d'accessibilité

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine

## Contexte

Un observateur global de frappe demande une permission d'accessibilité, ce qui inquiète et ouvre un risque. sema doit pouvoir ouvrir le bandeau, le hub et la recherche depuis n'importe où.

## Décision

- `GlobalShortcuts` réserve les combinaisons par `RegisterEventHotKey` et un gestionnaire Carbon natif. Aucun observateur global de frappe.
- Un remplacement est réservé avant de libérer l'ancien. Une erreur de réservation ou de sauvegarde garde le réglage précédent.
- L'enregistrement suspend les réservations de sema, capture les touches dans son seul champ, puis les rétablit à la sortie, y compris à la fermeture de la fenêtre.
- `FocusKeyboard` observe seulement les événements locaux de la fenêtre principale, hors saisie, contrôle de valeur et feuille. Le choix provisoire du sélecteur Focus n'est validé qu'à l'Entrée ; un changement de fenêtre, une feuille ou Échap l'annule.
- L'ordre des actions (bandeau, hub, recherche) fixe l'identifiant Carbon. Une action explicitement nulle reste désactivée ; un champ absent prend la valeur initiale.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Raccourcis Carbon réservés | Aucune permission ; fonctionne partout | Une API ancienne à garder |
| Observateur global de frappe | Plus de souplesse | Une permission d'accessibilité à demander |

## Conséquences

Le contrat est dans le champ optionnel `shortcuts` du document v2.
