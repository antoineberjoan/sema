# ADR 004 — Notion pour l’intention, GitHub pour le technique ; un socle portable

Statut : retenu le 21 octobre 2026 sur règle d’Antoine, commune à tous ses dépôts. Remplace l’[ADR 003](003-agent-foundation.md), dont il reprend le socle et corrige le partage d’autorité.

## Contexte

L’ADR 003 confiait à Notion « toutes les décisions, y compris techniques ». Une décision technique écrite hors du dépôt n’est ni relue avec le code, ni vérifiée par les contrôles, ni versionnée avec lui ; les agents devaient lire Notion pour une convention de code. Antoine fixe une règle unique pour tous ses dépôts.

## Décision

**Notion fait foi pour la vision, le ton, le branding, la marque, le business plan et la copy** : [Stratégie](https://app.notion.com/p/3fbd18bb0dea819bad4bc31bca0ad436) (vision, public, business, priorités produit), [Produit](https://app.notion.com/p/3fbd18bb0dea81c7add6f4a31d033296) (périmètre souhaité, retours), [Marque](https://app.notion.com/p/3fbd18bb0dea818fa7f4fc7483c767b3) (marque, ton, copy, choix visuels).

**GitHub fait foi pour tout le technique** : code, configuration, architecture (`docs/ARCHITECTURE.md`), conventions (`docs/engineering/`), décisions techniques (`docs/decisions/`, ces ADR), plans de réalisation (`docs/plans/`), validations et preuves. Une décision technique ne se consigne pas dans Notion ; si une page en contient une, elle est signalée à Antoine et reportée ici.

Deux versions qui se contredisent sur un même sujet : présenter l’écart et demander à Antoine laquelle garder ; travailler sur l’indépendant entre-temps.

Le socle de l’ADR 003 reste : une entrée `AGENTS.md`, des règles de zone, trois skills dans `.agents/skills` (liées dans `.claude/skills` et vérifiées), des contrôles Python sans dépendance (`scripts/guardrails.py`) lancés par le hook d’agent unique de `.claude/settings.json` (lu aussi par Cursor), le pre-commit sur l’index exact et la CI via `check.sh`. Valeurs visuelles et codes de touche en dur restent un refus mécanique. Aucun framework d’agents, nouvelle cible ou serveur.

## Conséquences

- La page Notion Équipe ne porte plus de décision technique ; ce qui y relève du technique se reporte dans ce dépôt.
- `AGENTS.md`, `docs/engineering/SOURCES.md`, `WORKFLOW.md` et les skills appliquent ce partage.
- Les contrôles sont reproductibles ; le jugement du modèle ne l’est pas. Nommage, duplication et design restent relus. Les migrations qui protègent des données distribuées ne sont pas supprimées.
- L’activation des hooks est locale ; la protection serveur de `main` dépend d’une offre GitHub compatible (voir [WORKFLOW](../engineering/WORKFLOW.md)).
