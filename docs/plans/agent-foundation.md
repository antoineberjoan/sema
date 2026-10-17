# Socle agentique

Statut : socle implémenté et contrôles validés, livré dans la [PR nº 3 en brouillon](https://github.com/antoineberjoan/sema/pull/3) le 17 octobre 2026. Scénarios Cursor et Claude validés en lecture seule. Aucune fusion vers `main`. Référence : [Équipe](https://app.notion.com/p/3fbd18bb0dea81c9b117c11a249e57df).

## Résultat

Une entrée commune, des procédures chargées à la demande et les mêmes contrôles exécutables pour Codex, Claude Code, Cursor et Antigravity. Aucun changement de comportement produit ni nouvelle dépendance de production. Le [test des clients](../validation/agent-clients.md) prouve la découverte et la lecture des trois skills, ainsi que la restitution des règles dans Cursor et Claude. Antigravity reste à éprouver.

- Autorité Notion/GitHub explicite et arbitrage humain en cas de divergence.
- Carte des responsabilités, vocabulaire commun et descriptifs des fichiers de code.
- Contrôles locaux et CI testés sur des cas qui doivent échouer, y compris un index Git différent du disque.
- Mémoire courte dans les plans, décisions et PR ; aucun journal automatique.

## Arbitrages et limites

- Arbitrage d’Antoine du 17 octobre : conserver le périmètre actuel de l’app et aligner Notion. Produit décrit Webstat et les sept catalogues publics supplémentaires ; Stratégie y renvoie. Équipe reconnaît les producteurs officiels de toutes les sources retenues. Les limites de couverture et de redistribution restent explicites.
- Les anciens plans et la roadmap restent des historiques à réconcilier avec leurs preuves ; aucun élément non vérifié n’est déclaré terminé.
- GitHub refuse les règles et protections de branche sur ce dépôt privé avec l’offre actuelle (403, contrôle du 17 octobre). CI et hooks ne constituent pas une protection serveur de `main`.
- Le conflit entre les règles Git exigeant une approbation et le mode Codex `never` a été résolu en rétablissant les approbations dans l’interface et en reprenant dans un nouveau tour. Les règles Git ont été conservées.

## Preuves

- Commit d’implémentation : `b6d87ba`, sur `codex/agent-foundation`, base `d7442e7`.
- [CI macOS réussie sur ce commit](https://github.com/antoineberjoan/sema/actions/runs/39017048961) : 12 tests Python et 74 tests Swift passent ; syntaxe shell et plist validés ; bundle `Sema.app` construit et signé.
- Le hook vérifie l’index Git exact et est activé dans ce clone. Garde-fous, liens Markdown et `git diff --check` passent.
- `./scripts/build-app.sh` construit et signe aussi le bundle de production local ; signature vérifiée.
- 69 fichiers applicatifs et supports comparés à leur version précédente : seul un descriptif a été ajouté, corps inchangé. Deux autres en-têtes concernent le manifeste SwiftPM et le script de build. Les fichiers d’instructions sont exclus des cibles SwiftPM.
- Les tests Swift locaux restent indisponibles sur ce Mac équipé seulement des Command Line Tools, sans le module `Testing`. La suite complète a été exécutée en CI ; aucun test n’a été supprimé ni désactivé pour masquer cette limite locale.
- Les trois skills passent le contrôle de frontmatter du dépôt et une relecture de leurs déclencheurs. Le validateur générique de skill-creator reste indisponible faute de PyYAML local ; aucune dépendance ajoutée pour lui.
- Les pages Notion Produit, Stratégie et Équipe portent le cadre de décision et l’arbitrage de périmètre. Les références techniques de Produit pointent vers `main`.
- Aucune modification de rendu ou de comportement UI : pas de nouvelle validation interactive native revendiquée.

## Revue critique du 17 octobre

- Corrigé trois défauts reproduits : suppression d’un manifeste non détectée, faux positifs et import masqué dans l’analyse Swift, exemples Markdown pris pour des liens. Les chemins à espaces, titres et liens depuis la racine sont également vérifiés.
- 17 tests Python passent après correction. Le hook réel accepte un index valide et refuse une erreur indexée malgré une correction non indexée ; l’installation préserve une autre configuration de hooks et reste idempotente.
- Les instructions du site suivent le circuit Vercel déjà documenté ; Sites reste réservé à une demande explicite. Les formats d’instructions et de skills annoncés pour Cursor et Antigravity sont reconfirmés dans leurs documentations officielles, sans prétendre avoir testé leurs clients.
- La revue ne modifie aucun comportement applicatif. La suite Swift locale reste bloquée par l’absence de `Testing` ; les contrôles de la PR portent la validation CI du dernier commit.

## Vérification des clients du 17 octobre

- Cursor 3.25.6 : instructions communes présentes, trois skills découvertes et utilisées, instructions Mac lues, autorité et validation correctement restituées. Les trois entrées du menu restent uniques après la correction Claude.
- Claude Code 2.1.236 : import des instructions reconnu ; absence des skills natives reproduite puis corrigée par trois liens vers les sources communes. Après reconnexion CLI, quatre lectures réussies couvrent les trois skills et les instructions Mac ; autorité, arbitrage et commande documentaire sont correctement restitués. Une invocation distincte de `/sema-change` charge aussi la procédure native. Résultats sans erreur ni refus de permission.
- 22 tests Python passent. Le garde-fou refuse la suppression, la copie, la mauvaise cible et les liens orphelins, dans le travail local et l’index Git.
- Les deux scénarios demandés sont terminés. Ils ne valident ni une implémentation fonctionnelle complète dans chaque client ni leurs connecteurs externes. La fusion reste interdite sans autorisation.

## Livraison

La PR reste volontairement en brouillon. Ses contrôles GitHub font foi pour le dernier commit ; la preuve ci-dessus porte sur le commit d’implémentation. Toute fusion vers `main`, qui déploie le site, nécessite une autorisation couvrant cette publication.

Les modifications parallèles non indexées de la sidebar, de ses contrats produit/identité, du plan de distribution et de `docs/validation/sidebar-0.5.2.json` appartiennent à l’autre chantier et restent hors de cette livraison.
