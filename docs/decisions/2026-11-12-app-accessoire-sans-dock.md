# sema est une app accessoire : sans Dock, avec un bandeau et un lancement à la demande

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine (reprise d'un document retiré)

## Contexte

sema vit surtout dans la barre des menus. Le système possède l'état de l'ouverture de session.

## Décision

- Le bundle déclare `LSUIElement = true` : l'app est absente du Dock et garde ses fenêtres SwiftUI. Aucun changement dynamique de politique d'activation.
- Le clic droit sur l'icône de la barre des menus affiche trois actions : Réglages…, Rechercher des mises à jour… et Quitter sema. La mise à jour ouvre seulement la page des versions publiques dans le navigateur : aucun jeton, aucun vérificateur périodique, aucun installateur.
- « Lancer à l'ouverture de session » est volontaire et désactivé avant activation. `LoginItem` adapte `SMAppService.mainApp` ; le système possède l'état, relu à l'ouverture des réglages et à la réactivation. L'app ne s'inscrit jamais seule et ne copie pas cet état dans le JSON.
- À l'ouverture de session, les fenêtres initiales sont masquées ; le bandeau, les raccourcis et l'actualisation restent actifs. Fermer la dernière fenêtre ne termine pas le processus. Aucun agent de relance.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| App accessoire, état de session au système | Un comportement attendu d'une app de barre des menus | Aucun contrôle sur l'état hors du système |
| App classique avec Dock et agent de relance | Plus de contrôle | Un helper de plus, et un comportement inattendu |

## Conséquences

La distribution et la mise à jour restent par le cask Homebrew et les versions publiques.

## Trace

Repris de `docs/ARCHITECTURE.md` à son retrait, le 2026-11-12. La date d'origine n'est pas écrite : le texte complet reste dans l'historique Git.
