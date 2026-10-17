---
name: sema-design
description: Appliquer Interface Craft à une interface, une copy ou un mouvement sema, sur Mac et ses supports web. Ne pas charger pour un changement purement interne au cœur.
---

# Concevoir et vérifier

Lire `docs/IDENTITY.md` et la décision Notion pertinente via `docs/engineering/SOURCES.md`. Si la skill Interface Craft est disponible, consulter sa partie utile ; ces critères locaux restent utilisables par tout agent sans installation supplémentaire.

- Définir l’action principale et l’information qui mérite le premier regard. Chaque texte, contrôle, surface ou animation sert cette tâche ; retirer les répétitions.
- Séparer la revue du parcours, de l’apparence et du mouvement. Couleur intentionnelle, typographie système, espaces cohérents, ombres discrètes pour les surfaces flottantes. Sur Mac, SwiftUI, SF Symbols et conventions natives avant un composant personnalisé.
- Réutiliser les choix partagés de `DesignSystem`. Garder une valeur propre à une séquence près de son propriétaire. Pas de bibliothèque React, DialKit ou autre dépendance importée dans l’app pour appliquer une méthode de design.
- Avant une séquence complexe, écrire ses étapes et constantes nommées. Une seule orchestration, annulation explicite, reprise et interruption cohérentes. Réduire les animations donne directement l’état utile ; pas de boucle décorative permanente.
- Vérifier au clavier, à taille réaliste, avec les états vide, chargement et erreur concernés. Pour une modification de matière ou mouvement, vérifier aussi contraste, transparence et réduction des animations. Comparer dans l’app native ou le navigateur ; une capture ne prouve pas le comportement.

Restituer le problème observé, son effet sur l’usage et la correction. Distinguer rendu observé, déduction du code et contrôle restant ; ne pas annoncer une validation native si l’accès est bloqué.
