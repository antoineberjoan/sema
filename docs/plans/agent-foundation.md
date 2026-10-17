# Socle agentique

Statut : socle implémenté ; commit, branche distante et PR en brouillon autorisés par Antoine le 17 octobre 2026, mais leur exécution reste bloquée par le contrôle automatique d’approbation. Validation Swift en CI à réaliser ; aucune fusion autorisée. Référence : [Équipe](https://app.notion.com/p/3fbd18bb0dea81c9b117c11a249e57df).

## Résultat attendu

La même intention peut être réalisée avec Codex, Claude Code, Cursor ou Antigravity à partir d’une seule entrée, de procédures chargées à la demande et des mêmes contrôles exécutables. Aucun changement de comportement produit ni nouvelle dépendance de production.

## Critères

- Une source par décision, liens Notion réels et arbitrage humain en cas de divergence.
- Carte des responsabilités, vocabulaire commun et descriptifs des fichiers de code.
- Contrôles locaux et CI testés sur des cas qui doivent échouer, y compris un index Git différent du disque.
- Tests Swift et bundle validés ; absence de modification fonctionnelle dans les fichiers recevant un en-tête.
- Mémoire courte et navigable ; aucun journal automatique.

## Arbitrages et limites

- Arbitrage d’Antoine du 17 octobre : conserver le périmètre actuel de l’app et aligner Notion. Produit décrit Webstat et les sept catalogues publics supplémentaires ; Stratégie y renvoie. Équipe reconnaît les producteurs officiels de toutes les sources retenues. Les limites de couverture et de redistribution restent explicites.
- Les anciens plans et la roadmap comportent des étapes déjà réalisées. Ils restent conservés comme historiques à réconcilier ; aucun élément non vérifié n’est déclaré terminé.
- GitHub refuse les règles et protections de branche sur ce dépôt privé avec l’offre actuelle (403, contrôle du 17 octobre). CI et hooks ne constituent pas une protection serveur de `main`.

## Travail restant

- Faire exécuter les tests Swift par la CI et relire le résultat de la PR.

## Preuves locales

- 12 tests des garde-fous passent ; le hook vérifie l’index Git exact et est activé dans ce clone.
- Garde-fous locaux, liens Markdown, syntaxe shell, plist et `git diff --check` passent.
- `./scripts/build-app.sh` construit et signe le bundle de production local.
- 69 fichiers applicatifs et supports comparés à leur version précédente : seul un descriptif a été ajouté, corps inchangé. Deux autres en-têtes concernent le manifeste SwiftPM et le script de build. Les fichiers d’instructions sont exclus explicitement des cibles SwiftPM.
- `./scripts/check.sh` passe les contrôles Python puis échoue localement sur `no such module 'Testing'` : ce Mac dispose seulement des Command Line Tools, sans Xcode. La CI macOS doit valider la suite Swift ; aucun test n’est supprimé ni désactivé pour masquer ce défaut d’environnement.
- Les trois skills passent le contrôle de frontmatter du dépôt et une relecture de leurs déclencheurs. Le validateur générique de skill-creator n’a pas pu s’exécuter faute de PyYAML local ; aucune dépendance n’est installée pour le contourner.
- Les pages Notion Produit, Stratégie et Équipe portent le cadre de décision et l’arbitrage de périmètre. Les références techniques de Produit pointent vers `main`.
- Aucune modification de rendu ou de comportement UI : pas de nouvelle validation interactive native revendiquée.

## Reprise

Branche : `codex/agent-foundation`, base `d7442e7`. L’autorisation humaine de commit, push et PR en brouillon est acquise : ne pas la redemander. Les tentatives ont été rejetées avant exécution avec « approval required by policy, but AskForApproval is set to Never ». Diagnostic confirmé le 17 octobre : les règles locales exigent `prompt` pour le commit, le push et la création de PR, alors que le chat applique `never`, malgré une configuration utilisateur `on-request`. Antoine a confirmé avoir rétabli les permissions par défaut dans l’interface ; la tentative suivante pendant le même tour a encore été rejetée avec `Never`. Reprendre dans un nouveau tour avec les approbations actives ; conserver les règles Git. Aucun commit du socle, push ou PR n’a été créé.

Une fois ce blocage levé, indexer uniquement la version courante de ce plan en complément du socle déjà indexé, créer le commit, pousser la branche, publier la PR en brouillon et vérifier la CI macOS. Ne pas fusionner vers `main` sans autorisation couvrant la publication. Les modifications parallèles non indexées de la sidebar, de ses contrats produit/identité, du plan de distribution et de `docs/validation/sidebar-0.5.2.json` appartiennent à l’autre chantier ; elles restent hors de ce commit.
