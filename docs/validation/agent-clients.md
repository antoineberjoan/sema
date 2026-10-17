# Chargement des instructions et skills

Vérification du 17 octobre 2026, sur `codex/agent-foundation`, avant fusion de la PR nº 3. Scénario en lecture seule : préparer hypothétiquement un changement de copy Mac suivi d’un relais. Aucun changement produit n’a été confié aux clients ; les travaux parallèles restent hors du test.

## Critères et résultats

| Critère | Cursor 3.25.6 | Claude Code 2.1.236 |
| --- | --- | --- |
| Entrée commune | `AGENTS.md` déclaré présent avant les lectures ; règles correctement restituées | `/context` liste `CLAUDE.md` et son import `AGENTS.md` ; application par le modèle non éprouvée |
| Découverte native des trois skills | Les trois sont disponibles ; menu `/sema-` sans doublon après ajout des liens Claude | Absentes avant correction ; `system.init.skills` contient ensuite `sema-change`, `sema-design`, `sema-handoff`, une fois chacune |
| Lecture des trois procédures | Activité : `Used sema-design`, `Used sema-handoff`, `Used sema-change` | Non vérifiée : requête modèle bloquée par l’authentification |
| Instructions Mac | Activité : lecture de `Sources/SemaMac/AGENTS.md` ; frontières correctement restituées | Non vérifiées dans le scénario |
| Autorité et arbitrage | Notion pour l’intention, GitHub pour l’exécution, arbitrage d’Antoine si contradiction | Non éprouvés par le modèle |
| Validation documentaire | `python3 scripts/guardrails.py` correctement identifié, sans exécution revendiquée par Cursor | Non éprouvée par le modèle |

Cursor a utilisé son modèle configuré, Grok 4.6 Medium ; Claude a annoncé `claude-sonnet-5`. Aucun modèle ni réglage global n’a été changé. Les réponses des agents ne suffisent pas seules : les actions de lecture et le catalogue natif ont été inspectés.

Un second chat Cursor a invoqué `/sema-change` depuis son menu après la correction. Il a lu les trois procédures et confirmé les mêmes règles. Le menu contient trois noms uniques ; le catalogue choisit les chemins `.claude/skills`, tandis que le routeur référence `.agents/skills`. Ces deux chemins mènent aux mêmes trois fichiers, sans seconde implémentation. Cela ne prouve pas qu’un modèle ne relira jamais un fichier par l’autre chemin.

## Correction et preuves mécaniques

- `.claude/skills/sema-change`, `sema-design` et `sema-handoff` sont des liens vers les dossiers homonymes de `.agents/skills`. Une seule source de contenu, mêmes noms et aucun script de synchronisation.
- 22 tests Python passent, dont cinq nouveaux cas : lien supprimé, mauvaise cible indexée malgré une correction locale, copie remplaçant un lien, lien matérialisé en texte et lien orphelin.
- Le contrôle de l’index lit le mode Git `120000` et sa cible enregistrée ; il ne suit pas le contenu du disque pour valider le futur commit.
- La découverte native des liens de dossiers est prévue par la [documentation Claude Code](https://code.claude.com/docs/en/skills). Cursor lit les emplacements communs et Claude selon sa [documentation des skills](https://cursor.com/help/customization/skills).

## Limite et reprise

L’appel Claude sort avec `is_error: true` et `OAuth session expired and could not be refreshed`. Son diagnostic local prouve la découverte des fichiers, pas l’application des instructions ni une lecture de skill par le modèle. Le diagnostic `/context` indique des compteurs nuls dans cette session ; ils ne constituent pas une mesure du contexte effectivement transmis.

Après reconnexion par `claude auth login`, relancer dans le dépôt un test limité aux outils `Read`, `Glob`, `Grep` et `Skill`, sans serveur MCP et sans persistance de session. Demander : instructions déjà présentes avant lecture ; skills sema proposées ; lecture des trois procédures et des instructions Mac ; autorité produit, arbitrage et commande de validation documentaire. Vérifier les événements `Skill`/`Read` et un résultat sans erreur. Ne pas conclure à la réussite d’après le seul code de sortie ou le catalogue initial.

Antigravity, les connexions Notion/GitHub dans ces clients et une modification fonctionnelle complète ne sont pas éprouvés par ce test. Les observations portent sur ces versions et ce scénario.
