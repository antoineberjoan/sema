# Chargement des instructions et skills

Vérification du 17 octobre 2026, sur `codex/agent-foundation`, avant fusion de la PR nº 3. Premier scénario en lecture seule : préparer hypothétiquement un changement de copy Mac suivi d’un relais. Un second scénario vérifie les connexions et une correction réelle des garde-fous. Aucun comportement produit n’est modifié ; les travaux applicatifs parallèles restent hors du test.

## Critères et résultats

| Critère | Cursor 3.25.6 | Claude Code 2.1.236 |
| --- | --- | --- |
| Entrée commune | `AGENTS.md` déclaré présent avant les lectures ; règles correctement restituées | `CLAUDE.md` et son import `AGENTS.md` déclarés déjà chargés ; règles correctement restituées sans lecture supplémentaire de ces fichiers |
| Découverte native des trois skills | Les trois sont disponibles ; menu `/sema-` sans doublon après ajout des liens Claude | Absentes avant correction ; `system.init.skills` contient ensuite `sema-change`, `sema-design`, `sema-handoff`, une fois chacune |
| Lecture des trois procédures | Activité : `Used sema-design`, `Used sema-handoff`, `Used sema-change` | Trois événements `Read` réussis sur les `SKILL.md` communs ; contraintes distinctives correctement restituées |
| Instructions Mac | Activité : lecture de `Sources/SemaMac/AGENTS.md` ; frontières correctement restituées | Événement `Read` réussi sur `Sources/SemaMac/AGENTS.md` ; exigences de design et de vérification native correctement restituées |
| Autorité et arbitrage | Notion pour l’intention, GitHub pour l’exécution, arbitrage d’Antoine si contradiction | Même distinction ; préserver les deux versions et demander à Antoine laquelle retenir |
| Validation documentaire | `python3 scripts/guardrails.py` correctement identifié, sans exécution revendiquée par Cursor | Même commande, correctement distinguée de `check.sh` ; aucune exécution revendiquée |

Cursor a utilisé son modèle configuré, Grok 4.6 Medium ; Claude a annoncé `claude-sonnet-5`. Aucun modèle ni réglage global n’a été changé. Les réponses des agents ne suffisent pas seules : les actions de lecture et le catalogue natif ont été inspectés.

Un second chat Cursor a invoqué `/sema-change` depuis son menu après la correction. Il a lu les trois procédures et confirmé les mêmes règles. Le menu contient trois noms uniques ; le catalogue choisit les chemins `.claude/skills`, tandis que le routeur référence `.agents/skills`. Ces deux chemins mènent aux mêmes trois fichiers, sans seconde implémentation. Cela ne prouve pas qu’un modèle ne relira jamais un fichier par l’autre chemin.

Une invocation distincte de `/sema-change` dans Claude a aussi chargé la procédure native depuis `.claude/skills/sema-change/SKILL.md`. La réponse restitue trois consignes propres à son contenu : arbitrage des sources, plan unique et revue du diff avant fusion. Ce test utilise le mode de permission `manual` avec les mêmes outils limités à la lecture ; il se termine sans erreur ni refus de permission.

## Correction et preuves mécaniques

- `.claude/skills/sema-change`, `sema-design` et `sema-handoff` sont des liens vers les dossiers homonymes de `.agents/skills`. Une seule source de contenu, mêmes noms et aucun script de synchronisation.
- 22 tests Python passent, dont cinq nouveaux cas : lien supprimé, mauvaise cible indexée malgré une correction locale, copie remplaçant un lien, lien matérialisé en texte et lien orphelin.
- Le contrôle de l’index lit le mode Git `120000` et sa cible enregistrée ; il ne suit pas le contenu du disque pour valider le futur commit.
- La découverte native des liens de dossiers est prévue par la [documentation Claude Code](https://code.claude.com/docs/en/skills). Cursor lit les emplacements communs et Claude selon sa [documentation des skills](https://cursor.com/help/customization/skills).

## Protocole et limites

Une reconnexion de l’installation CLI a résolu le blocage OAuth initial. Le scénario Claude se termine avec `subtype: success`, `is_error: false`, quatre résultats de lecture sans erreur et aucun refus de permission. Le catalogue initial contient chaque skill sema une fois. Les réponses ont été comparées aux fichiers lus ; le succès ne repose pas sur le seul code de sortie ni sur le catalogue.

Pour reproduire : lancer dans le dépôt un test limité aux outils `Read`, `Glob`, `Grep` et `Skill`, sans serveur MCP et sans persistance de session. Demander : instructions déjà présentes ; skills sema proposées ; lecture des trois procédures et des instructions Mac ; autorité produit, arbitrage et commande de validation documentaire. Vérifier les événements `Skill`/`Read` et un résultat sans erreur. Une connexion réussie dans une autre application ne prouve pas que cette installation CLI est connectée.

Ce premier scénario ne prouve ni les connexions externes ni une réalisation fonctionnelle. Antigravity reste non testé. Les observations portent sur ces versions et ces scénarios.

## Connexions et changement réel

Demande complémentaire d’Antoine : tester chaque client depuis la source d’intention jusqu’au changement vérifié, en gardant la PR nº 3 en brouillon. Critère concret : protéger le fichier racine `AGENTS.md`, dont la suppression était acceptée avant correction. Claude traite l’absence ; le scénario prévu pour Cursor porte sur le contenu vide, séquentiellement dans les mêmes deux fichiers Python.

| Étape observée | Claude Code 2.1.236 | Cursor 3.25.6 |
| --- | --- | --- |
| Notion | `mcp__claude_ai_Notion__notion-fetch` lit en direct la page [Équipe](https://app.notion.com/p/3fbd18bb0dea81c9b117c11a249e57df) ; titre et règle d’arbitrage restitués | Après autorisation d’Antoine, le panneau MCP affiche `notion` connecté, 65 outils et 8 ressources ; la lecture de page reste non vérifiée, bloquée par le quota Agent |
| GitHub | `gh api repos/antoineberjoan/sema/pulls/3` renvoie la PR privée ouverte, `draft: true`, tête `41410a9`, `merged_at: null` | Même réponse distante après autorisation réseau du terminal ; aucune connexion MCP GitHub revendiquée |
| Changement | Deux éditions ciblées : refus d’`AGENTS.md` absent et test de régression | Lectures préparatoires effectuées ; arrêt « You've hit your usage limit » avant toute édition |
| Validation | Test rouge observé, puis 23 tests Python verts, garde-fous locaux et diff valides ; skills `sema-change` et `sema-handoff` invoquées | Pas de changement ni de test avant/après attribué à Cursor |

La correction Claude couvre la suppression locale, l’index intact malgré cette suppression, puis la suppression indexée. Le diff ne touche que `scripts/guardrails.py` et `scripts/tests/test_guardrails.py`. `./scripts/check.sh` a été exécuté une fois : Swift échoue sur le module `Testing` absent de ce Mac. La CI de la PR vérifie la suite Swift et le bundle du commit intégré ; aucun contrôle n’est désactivé. Codex relit, intègre et pousse le changement ; les agents testés n’ont reçu aucune autorisation de fusion.

Antoine a autorisé le 17 octobre la connexion Notion de Cursor à l’espace « Antoine Berjoan », au-delà de la seule page sema : lecture, actions selon ses droits, utilisateurs et applications connectées. Le panneau MCP confirme ensuite la connexion ; aucun jeton n’est copié entre clients. Malgré le rétablissement de l’accès Agent signalé par Antoine, le compte affiché `Antoine_Berjoan` refuse encore Grok 4.6 Medium avec « You've hit your usage limit », après rechargement de la fenêtre et nouvel essai dans un chat neuf. Antoine confirme ensuite qu’aucun autre accès n’est disponible et demande de poursuivre sans Cursor. Le scénario reste non terminé ; aucun achat ni changement d’abonnement n’est effectué.

Reprise éventuelle, uniquement après un changement d’accès signalé : terminer la lecture de la page Équipe dans le chat Cursor « Notion connection test report », puis reprendre « Sema change and testing » pour le cas `AGENTS.md` vide. L’autorisation Notion est acquise ; ne pas la redemander à périmètre inchangé. Vérifier test rouge, correction, tests verts, diff et relais ; intégrer seulement les fichiers concernés et attendre la CI. Les connexions sont testées en lecture ; aucun essai d’écriture Notion n’est revendiqué.

## Hooks d’agent

Ajout du 17 octobre 2026, sur la même branche. Dans Claude Code (application de bureau), le hook `PostToolUse` s’est déclenché pendant la session qui l’installait : chaque édition a renvoyé au modèle les refus de `guardrails.py`, puis seulement ceux du fichier édité après filtrage. Les réponses Claude et Cursor, la relance unique de fin de tour et l’arrêt après abandon sont couverts par `scripts/tests/test_agent_hook.py`. Le hook de fin de tour n’a pas encore été observé dans un tour réel. Cursor n’est pas éprouvé : sa documentation annonce la lecture de `.claude/settings.json` par défaut, mais le quota Agent bloque l’essai.
