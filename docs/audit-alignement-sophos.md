# Audit d'alignement de sema sur Sophos

État au 12 novembre 2026, contre Sophos `main` (`fced282`). Ce fichier dit, règle par règle, ce qui est vérifié et ce qui ne l'est pas. Il ne dit jamais « conforme » sans preuve.

## Ce que les outils de Sophos disent

| Contrôle | Résultat | Commande |
| --- | --- | --- |
| Alignement | « Projet aligné sur Sophos. » | `node ../sophos/outils/aligner.mjs --verifier` |
| Structure | 33 unités, 0 faute, cliquet 0 | `./controler.sh` |
| Jetons | 221 jetons, sorties à jour, contrastes `ok` | `./controler.sh` |
| Carte et socle | à jour, complet (dont les 8 en-têtes de `Components/Custom/`, refusés si on les abîme : essai fait) | `./controler.sh` |
| Politique, agents | à jour | `./controler.sh` |
| Garde-fous du dépôt | 34 tests | `./controler.sh` |
| Secrets sur les commits envoyés | aucune fuite | `gitleaks detect --log-opts="origin/main..HEAD"` |

## Skills et patron : règle par règle

| Document | État | Preuve ou raison |
| --- | --- | --- |
| `patron/structure.md` | **conforme** (formes des unités déclarées) | `structure.mjs`, 0 faute |
| `patron/structure.md`, test de chaque fichier | **conforme par construction**, non prouvé par exécution | tests déplacés avec leur unité ; le Swift n'est pas compilé |
| `patron/composants.md`, en-têtes | **conforme** | `carte.mjs`, essai d'un en-tête abîmé refusé |
| `patron/composants.md`, rendu et comportement des composants | **non vérifié** | demande un Mac |
| `patron/architecture.md`, socle | **conforme** | `carte.mjs --verifier` |
| `patron/architecture.md`, décisions (nom, en-tête, sections) | **conforme** | `carte.mjs --verifier` |
| `patron/architecture.md`, « pas de `legacy`, `old`, `new`, `helper`, `utils`… dans un nom » | **conforme**, en attente de compilation | recherche par mot sur `Sources` et `Tests` : aucun reste hors commentaire |
| `patron/architecture.md`, « un booléen a une amorce `is`, `has` ou `can` » | **conforme**, en attente de compilation | recherche des booléens annotés et initialisés ; `acceptsFirstResponder` sans objet |
| `patron/couleur.md`, `espace-forme.md`, `typographie.md`, `mouvement.md` : valeurs | **conforme pour ce qu'un outil lit** | `jetons.mjs --verifier`, `guardrails.py` (valeur visuelle en dur, taille de texte, ombre) |
| mêmes documents : choix de rôle par site, mouvement réel, contraste en situation | **non vérifié** | demande un Mac ; les rôles choisis par le sens sont listés dans chaque décision d'écran |
| `skills/construire` : une source, zéro alias, zéro code mort | **non audité en entier** | pas de `typealias` ; pas de lecteur de code mort exécuté |
| `skills/construire` : preuve avant « fini » | **non conforme** | Swift jamais compilé, tests jamais lancés |
| `skills/concevoir`, `expliquer`, `penser`, `fonder` | **non audités** | règles de jugement, pas de contrôle automatique ; à relire à la main |

## Noms : corrigé, en attente de compilation

Règle : un booléen a une amorce `is`, `has` ou `can` (`architecture.md`) ; un nom ne dit pas d'où vient la chose (`old`, `new`, `legacy`…).

- **Renommés** (une quarantaine) : propriétés, états de vue, variables locales et libellés d'initialiseur, avec tous leurs usages dans le même changement. Exemples : `connected` → `isConnected`, `showsAdvanced` → `isAdvancedShown`, `didCheckWebstatKey` → `hasCheckedWebstatKey`, `old` → `held`, `legacyIDs` → `shortIDs`.
- **Clés écrites sur le disque** : la propriété change, pas la clé. `canNotify` (`notificationsEnabled`), `isOnboardingCompleted` (`onboardingCompleted`), `isWeekdaysOnly` (`weekdaysOnly`), `isWeekly` (`weekly`) portent un `CodingKeys` qui garde le nom du fichier.
- **Retiré** : `StatisticalSource.requiresKey`, que rien ne lisait (code mort).
- **Sans objet** : `acceptsFirstResponder` est le nom d'une API d'AppKit qu'on surcharge (`architecture.md`, règle 6, nom imposé).
- **Risque de compilation à regarder** : une propriété `isEnabled`, `isSelected`, `isFocus` ou `isOpaque` dans une vue SwiftUI peut croiser un nom du framework ; les noms de la forme `is…` dans `SourceKeyView`, `WorkspaceScreen`, `SettingsScreen` et `RibbonGlassSettingsView` sont les premiers à relire.

## Écarts datés

| Écart | Décision | Ce qui le retire |
| --- | --- | --- |
| Données de départ écrites dans le code (`StatisticalStarter`, `WebstatStarter`) | `ecart-patron-donnees-de-depart-dans-le-code` | JSON dans `Resources/` au prochain changement de ces valeurs |
| Site : ≈140 valeurs écrites à la main | `ecart-patron-site-valeurs-propres` | Antoine ouvre un chantier visuel du site |
| Trois copies de la géométrie du signe (SVG, SwiftUI, `render-icon.swift`) | `composant-signe-de-la-marque` | une source unique, à décider |

Les autres écarts d'avant sont retirés : `Components/Custom` (casse), `Calculations/` (dossier), clients multi-services, `typeRole` et `elevation` (fabriqués par Sophos).

## En attente

La seule ligne qui ne dépend pas de ce dépôt : **compilation et tests sur le Mac d'Antoine**. Condition : `swift build` réussit et tous les tests passent. Tant que ce n'est pas fait, « preuve avant fini » (`construire`, principe 12) est en attente, jamais conforme.

Tout le reste de ce fichier a une preuve d'outil, ou une condition écrite ci-dessus. Les règles de jugement (rendu, hiérarchie, mouvement ressenti, ton) sont dans la liste de contrôle par écran du fichier `docs/controle-sur-le-mac.md`.
