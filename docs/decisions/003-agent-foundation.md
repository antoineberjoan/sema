# ADR 003 — Un socle portable et des contrôles communs

Statut : retenu pour l’implémentation du socle le 17 octobre 2026, dans le cadre demandé par Antoine. La vision produit reste soumise à ses arbitrages.

## Contexte

Plusieurs clients d’agents travaillent sur les mêmes sources. Copier les instructions ou conserver plusieurs roadmaps crée des divergences ; charger tous les documents à chaque tâche consomme du contexte sans améliorer les décisions.

## Décision

Une entrée `AGENTS.md`, des règles de zone, trois skills ciblées dans `.agents/skills` et des contrôles Python sans dépendance externe. `CLAUDE.md` importe l’entrée commune. Aucun framework d’agents, nouvelle cible ou serveur.

Notion porte l’intention ; GitHub porte l’exécution et ses preuves. Une divergence de direction exige de demander à Antoine la version à garder. Les agents poursuivent le travail indépendant sans arbitrer à sa place.

Le hook pre-commit vérifie l’index exact ; la CI appelle le même contrôle par `check.sh`. Les plans et décisions conservent seulement le contexte utile ; les historiques détaillés restent dans Git.

## Conséquences

Les contrôles sont reproductibles ; le jugement du modèle ne l’est pas. Les décisions de nommage, duplication et design restent relues. Les migrations qui protègent des données distribuées ne sont pas supprimées sous prétexte de n’avoir qu’une version active.

L’activation des hooks est locale. La protection serveur de `main` dépend d’une offre GitHub compatible, indisponible lors du contrôle. Les limites et le test d’un nouveau client sont décrits dans [le fonctionnement du socle](../engineering/WORKFLOW.md).
