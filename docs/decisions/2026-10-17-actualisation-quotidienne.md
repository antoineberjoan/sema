# Les séries suivies se rafraîchissent chaque jour, sans service en arrière-plan

Date : 2026-10-17 · Statut : acceptée
Décidé par : Antoine

## Contexte

Une personne ouvre sema pour voir des repères à jour. Le produit n'a ni serveur ni compte : seule l'app, quand elle tourne, peut récupérer des données.

## Décision

- Au lancement et au réveil, un contrôle de fraîcheur porte sur les séries suivies et connectées. Seules celles synchronisées depuis au moins 24 h sont récupérées.
- L'échéance suivante reste active avec le hub fermé, tant que sema tourne. Fermer puis rouvrir ne réinitialise pas la fraîcheur gardée dans le cache.
- Un repère surveillé pour ses mouvements est aussi actualisé dès qu'une clôture de Paris ou de New York est passée. ⌘R force une actualisation.
- Les nouvelles observations passent par le moteur d'alertes. Les notifications restent désactivées jusqu'à activation explicite.
- Un échec garde les données ; le prochain essai est quotidien ou manuel.

## Conséquences

La règle de fraîcheur est dans `RefreshPolicy` et testée par `RefreshPolicyTests`. Aucune promesse de suivi app quittée ou Mac en veille.
