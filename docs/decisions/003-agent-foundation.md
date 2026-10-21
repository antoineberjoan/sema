# ADR 003 — Un socle portable et des contrôles communs

Statut : retenu pour l’implémentation du socle le 17 octobre 2026, dans le cadre demandé par Antoine. La vision produit reste soumise à ses arbitrages.

## Contexte

Plusieurs clients d’agents travaillent sur les mêmes sources. Copier les instructions ou conserver plusieurs roadmaps crée des divergences ; charger tous les documents à chaque tâche consomme du contexte sans améliorer les décisions.

## Décision

Une entrée `AGENTS.md`, des règles de zone, trois skills ciblées dans `.agents/skills` et des contrôles Python sans dépendance externe. `CLAUDE.md` importe l’entrée commune. Trois liens symboliques dans `.claude/skills` permettent la découverte native par Claude Code, sans recopier les procédures ; leur présence et leur cible sont vérifiées dans le travail local et l’index Git. Aucun framework d’agents, nouvelle cible ou serveur.

Cadre harmonisé le 21 octobre 2026 : [Notion Équipe](https://app.notion.com/p/3fbd18bb0dea81c9b117c11a249e57df) pilote les objectifs, les priorités, l’organisation, le suivi et toutes les décisions, y compris techniques ; GitHub les implémente et porte les preuves. Cette note décrit la réalisation du socle, sans créer une seconde source de décision. Une divergence de direction exige de demander à Antoine la version à garder. Les agents poursuivent le travail indépendant sans arbitrer à sa place.

Le hook pre-commit vérifie l’index exact ; la CI appelle le même contrôle par `check.sh`. Complément du 17 octobre 2026 : un hook d’agent unique dans `.claude/settings.json`, lu aussi par Cursor, renvoie les refus pendant le travail ; les valeurs visuelles et codes de touche en dur deviennent un refus mécanique. Les plans et décisions conservent seulement le contexte utile ; les historiques détaillés restent dans Git.

## Conséquences

Les contrôles sont reproductibles ; le jugement du modèle ne l’est pas. Les décisions de nommage, duplication et design restent relues. Les migrations qui protègent des données distribuées ne sont pas supprimées sous prétexte de n’avoir qu’une version active.

L’activation des hooks est locale. La protection serveur de `main` dépend d’une offre GitHub compatible, indisponible lors du contrôle. Les limites et le test d’un nouveau client sont décrits dans [le fonctionnement du socle](../engineering/WORKFLOW.md).
