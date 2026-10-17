---
name: sema-change
description: Réaliser un changement fonctionnel sema ou un chantier à plusieurs étapes, de l’intention aux preuves. Inutile pour une correction typographique isolée.
---

# Réaliser un changement

1. Lire `AGENTS.md`, l’état Git et les instructions de la zone touchée. Identifier l’intention et sa source via `docs/engineering/SOURCES.md`. En cas de versions contradictoires, demander laquelle garder et travailler sur les parties indépendantes.
2. Énoncer le résultat observable et le périmètre. Une petite correction tient dans le chat ou l’issue. Un chantier à plusieurs étapes ou repris par un autre agent utilise un seul plan dans `docs/plans/`, référencé par `docs/PLAN.md` : source, statut, critères, étapes restantes, preuves, prochaine action.
3. Lire les appelants et tests concernés. Reproduire le bug s’il y en a un. Réutiliser les noms du glossaire et les emplacements existants ; appliquer `docs/engineering/CONVENTIONS.md`. Implémenter le changement minimum, supprimer les chemins rendus inutiles.
4. Lancer `./scripts/check.sh` pour une modification fonctionnelle, sinon `python3 scripts/guardrails.py`. Valider le bundle avec `./scripts/build-app.sh` si l’app ou sa construction change. Pour l’UI, appliquer `sema-design` et vérifier le parcours natif ou web.
5. Relire le diff avec les critères : contrat inchangé hors périmètre, une implémentation, données conservées, pas de promesse non observée. Corriger avant d’élargir les vérifications. Ne pas affaiblir un contrôle ; si la même cause empêche deux tentatives de correction, exposer la cause et l’arbitrage nécessaire.
6. Appliquer `sema-handoff`. Une PR donne source, résultat, preuve et limites. Sa publication suit l’autorisation de la tâche ; `main` déclenche la production du site. Ne pas fusionner du seul fait que la CI passe.

Les rôles « cadrer », « construire » et « relire » sont des étapes, pas trois agents obligatoires. Une délégation n’est utile que si elle est autorisée et ses périmètres indépendants. Un seul responsable intègre le résultat ; ne pas faire écrire plusieurs agents dans les mêmes fichiers.
