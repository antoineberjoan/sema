---
name: sema-handoff
description: Préserver le contexte utile à la fin d’un chantier sema, lors d’un relais ou d’une interruption avec travail restant. Ne pas créer un journal pour chaque échange.
---

# Transmettre sans bruit

1. Lire le diff, les résultats réellement obtenus et le plan actif s’il existe. Ne pas relancer une suite déjà passée sans nouvelle modification ou doute concret.
2. Mettre à jour la source existante : contrat technique dans sa documentation, arbitrage produit dans Notion, raison d’architecture durable dans `docs/decisions/`. Une décision note contexte, choix, conséquences et statut ; une décision remplacée renvoie à sa remplaçante.
3. S’il reste du travail, mettre à jour le plan existant avec état vérifié, blocage précis, fichiers utiles, commandes et prochaine action. Pour une reprise, nommer la branche ou le commit, sans créer une copie du code. Si aucun plan n’existe et que le relais en a besoin, en créer un puis l’indexer dans `docs/PLAN.md`.
4. Si le chantier est terminé, garder seulement résultat, arbitrages, preuves et limites dans le plan ; retirer ses étapes devenues inutiles. Mettre son statut à terminé et le classer dans l’historique de l’index. Les détails de changements restent dans Git et la PR.
5. Restituer ce qui a changé, pourquoi, comment cela a été vérifié et ce qui n’a pas été publié ou observé. Une tâche bloquée ne devient pas terminée parce que la session s’arrête.

Pas de transcript, de raisonnement privé, de logs bruts, de secret, de copie de tout Notion ou de bilan quotidien vide. Un hook Git vérifie des faits mécaniques ; il ne peut pas décider quel apprentissage mérite d’être conservé. Ne pas automatiser une réécriture de mémoire ou de règles sans besoin et autorisation.
