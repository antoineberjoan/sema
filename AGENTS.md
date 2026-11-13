# AGENTS.md

Lis ce fichier en entier avant toute action. En cas de doute ou de contradiction, arrête-toi et demande.

## Skills Sophos actifs

Référence : dépôt `antoineberjoan/sophos`. Lire le `SKILL.md` d'un skill à sa source avant le travail correspondant. Ne pas recopier ses règles ici.

<!-- carte:skills:debut — fabriqué depuis projet.yml par sophos/outils/carte.mjs ; ne pas modifier à la main -->
| Skill | Version |
| --- | --- |
| [penser](https://antoineberjoan.github.io/sophos/skills/penser/SKILL.html) | 1.4.0 |
| [construire](https://antoineberjoan.github.io/sophos/skills/construire/SKILL.html) | 0.9.0 |
| [expliquer](https://antoineberjoan.github.io/sophos/skills/expliquer/SKILL.html) | 0.3.0 |
| [concevoir](https://antoineberjoan.github.io/sophos/skills/concevoir/SKILL.html) | 0.5.0 |
<!-- carte:skills:fin -->

- `penser` : la façon de travailler avec Antoine. Une direction qu'il tranche est une décision de ce dépôt, dans `docs/decisions/`.
- `construire` : une seule implémentation par responsabilité, aucun alias ni code mort, preuve avant de dire « fini ». Les valeurs financières restent en `Decimal`.
- `expliquer` : français simple pour toute explication, avec ce qui n'est pas vérifié.
- `concevoir` : interface, texte visible et mouvement. Les choix de direction visuelle de sema sont des décisions datées dans `docs/decisions/`.

Une recherche de fond avec des sources ne reste pas dans une conversation. Avant la fin de la session, propose la note ou la fiche de lecture, et son coffre (`cristalliser`) : la finance et le patrimoine dans Épistémè, le sport et la physiologie dans Ponos, la façon de penser, d'écrire ou de travailler dans la bibliothèque de Sophos. Une direction que je tranche est une décision de ce dépôt, pas une note.

## Ce que fait le projet

sema est une app macOS native (SwiftUI, Swift 6, macOS 14 et plus) pour consulter des séries économiques publiques, suivre ses favoris et définir des seuils. Le détail est dans `docs/fondation.md` et `docs/PRODUCT.md`.

- Dedans : le cœur (`Sources/MarketCore`), les jetons de design (`Sources/SemaDesign`), l'app (`Sources/SemaMac`), leurs tests (`Tests/MarketCoreTests`, `Tests/SemaDesignTests`, `Tests/SemaMacTests`), le site (`site/`), la distribution (`distribution/`).
- Dehors : un serveur, un compte, une clé fournisseur partagée.
- Nom : **sema**, en minuscules dans les textes visibles. Français pour l'interface, la documentation et les commentaires du code ; anglais pour les identifiants et les rôles. Aucun préfixe de projet dans un identifiant (les noms de cibles `SemaMac` et `SemaDesign` sont les seuls).

Charger au bon moment, sans tout lire au démarrage :

| Travail | À lire |
| --- | --- |
| Modèles, données, calculs, préférences et leurs tests | `Sources/MarketCore/AGENTS.md` |
| App native, état, design et mouvement | `Sources/SemaMac/AGENTS.md` |
| Site | `site/AGENTS.md` |

## Structure du code

Référence : `patron/structure.md` de Sophos. Chaque sorte de code a une forme fermée. `projet.yml` déclare les unités ; `structure.mjs` refuse ce qui sort de la forme, et un cliquet compte l'existant hors forme (il ne peut que baisser, jusqu'à 0).

| Sorte | Unités de sema |
| --- | --- |
| Bibliothèque de règles | `Sources/MarketCore/Series`, `Moves`, `Alerts`, `Context` |
| Dépôt de données | `Sources/MarketCore/Preferences`, `Sources/SemaMac/Infrastructure/Storage` |
| Connecteur | `Sources/MarketCore/Webstat`, `Sdmx`, `NewYorkFed`, `WorldBank`, `Fred`, `TwelveData`, `AlphaVantage`, `Claude`, `Gdelt`, `CentralBankFeeds` ; `Sources/SemaMac/Infrastructure/Keychain`, `Notifications`, `LoginItem`, `GlobalShortcuts`, `AppleIntelligence`, `Feedback` |
| Module d'écran | `Sources/SemaMac/Features/*` |

En Swift, un rôle qui porte plusieurs types est un dossier du nom du rôle (`Model/`, `Contract/`), un fichier par type. Un rôle qui porte un seul type est un fichier dont le nom finit par le rôle (`WebstatClient.swift`, `AlertsScreen.swift`). Cette forme est celle de `patron/structure.md` de Sophos. La racine de l'app (`Sources/SemaMac/App`) et ses composants ne sont pas déclarés. Les dossiers `Common/` de `MarketCore` et de `SemaMac` sont au niveau du domaine, hors unité : ils portent ce que plusieurs unités partagent.

## Bibliothèque de composants

Référence : **SwiftUI** (macOS 14). AppKit seulement pour un comportement macOS précis.

On assemble ses composants avant d'écrire. Un composant propre, ou qui reprend la référence, va dans `Sources/SemaMac/Components/Custom/`, avec `@documentation` et `@decision` en en-tête. Un composant qui assemble la référence avec un écart reste dans son module d'écran, avec les mêmes deux lignes d'en-tête (`Features/Overview/Components/HistoryChart.swift`). Un composant qu'on ne peut pas assembler suit sa structure et déclare la page suivie : la méthode est dans `patron/composants.md` de Sophos.

## Sources de vérité

Une information vit à un seul endroit. Si deux sources se contredisent, arrête-toi et demande.

| Domaine | Source |
| --- | --- |
| Règles du projet | `AGENTS.md` |
| Ce qu'est le projet | `docs/fondation.md` |
| Périmètre du produit | `docs/PRODUCT.md` |
| Décisions | `docs/decisions/` |
| Sources de données, catalogues publics, personnalisation | `docs/DATA-SOURCES.md`, `docs/PUBLIC-CATALOGUES.md`, `docs/PERSONALIZATION.md` |
| Mentions légales, retours, distribution | `docs/LEGAL.md`, `docs/FEEDBACK.md`, `docs/DISTRIBUTION.md` |
| Mots du métier | `docs/lexique.md` |
| Marque | `Resources/Brand/` |
| Carte du dépôt | `projet.yml` |

Une intention formulée dans le chat vaut instruction pour la tâche ; sa décision durable s'écrit dans `docs/decisions/`, avec sa date. Le dépôt suit Sophos.

## Validation et autonomie

- `./controler.sh` : contrôles rapides, sur toute machine. `./scripts/check.sh` : suite Swift. `./scripts/build-app.sh` : le bundle. La suite Swift et le bundle demandent macOS et un Swift complet ; la CI les lance.
- Après une modification d'interface, vérifie le parcours dans l'app native : clavier, états utiles, accessibilité, interruption des animations. Sépare ce qui est observé de ce qui reste à vérifier.
- Les réparations et validations locales dans le périmètre demandé sont autonomes. Ne contourne jamais un contrôle ni un hook.
- La publication, la fusion vers `main` (qui déploie le site), une dépense et une suppression irréversible demandent une autorisation qui couvre l'action.
- Ne change pas le nom d'un fichier, d'une clé ou d'une valeur que la personne a déjà sur son disque (préférences, alertes, profil, cache). Une migration de format est une décision d'Antoine.

## Contrôles

Le lanceur unique est nommé dans `projet.yml` (`politique.controle`). Il passe avant chaque envoi. Il lance les outils de Sophos depuis un clone de Sophos : `../sophos` à côté de ce dépôt, ou la variable `SOPHOS`. Un clone absent est un échec, jamais un contrôle sauté.

## Revue de code

Signaler une perte de données, une promesse non tenue, une deuxième implémentation, un contournement de contrôle ou un calcul financier hors du cœur. Vérifier le sens des noms et la valeur de chaque ajout.
