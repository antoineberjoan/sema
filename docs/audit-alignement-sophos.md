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
| `patron/architecture.md`, « pas de `legacy`, `old`, `helper`, `utils`… dans un nom » | **non conforme** | `old` et `legacy` comme noms locaux, voir plus bas |
| `patron/architecture.md`, « un booléen a une amorce `is`, `has` ou `can` » | **non conforme** | 17 noms, voir plus bas |
| `patron/couleur.md`, `espace-forme.md`, `typographie.md`, `mouvement.md` : valeurs | **conforme pour ce qu'un outil lit** | `jetons.mjs --verifier`, `guardrails.py` (valeur visuelle en dur, taille de texte, ombre) |
| mêmes documents : choix de rôle par site, mouvement réel, contraste en situation | **non vérifié** | demande un Mac ; les rôles choisis par le sens sont listés dans chaque décision d'écran |
| `skills/construire` : une source, zéro alias, zéro code mort | **non audité en entier** | pas de `typealias` ; pas de lecteur de code mort exécuté |
| `skills/construire` : preuve avant « fini » | **non conforme** | Swift jamais compilé, tests jamais lancés |
| `skills/concevoir`, `expliquer`, `penser`, `fonder` | **non audités** | règles de jugement, pas de contrôle automatique ; à relire à la main |

## Non-conformités trouvées et pas corrigées

**Booléens sans amorce** (17). Classement :

- Clés écrites sur le disque de la personne : `notificationsEnabled`, `onboardingCompleted` (préférences), `weekly` (cache des séries de cours). Les renommer demande de garder la clé écrite et donc un `CodingKeys` ; c'est un choix pour Antoine (`AGENTS.md` : une migration de format est sa décision).
- Nom imposé par AppKit : `acceptsFirstResponder`. Hors règle (`architecture.md`, règle 6).
- À renommer : `compact`, `connected`, `connecting`, `enabled`, `focus`, `focused`, `needsApproval`, `needsWebstatKey`, `opaque`, `previewRequiresRefresh`, `requiresKey`, `searchFocused`, `selected`. Non fait : plusieurs noms (`selected`, `enabled`, `focus`) sont aussi des noms non booléens ailleurs, et sans compilateur un renommage par recherche peut casser silencieusement.

**Noms d'origine** : `old` (quatre fichiers de l'app) et `legacy` (`LocalRepository`, lecture de l'ancien cache). À renommer en nommant ce que la chose est.

## Écarts datés

| Écart | Décision | Ce qui le retire |
| --- | --- | --- |
| Données de départ écrites dans le code (`StatisticalStarter`, `WebstatStarter`) | `ecart-patron-donnees-de-depart-dans-le-code` | JSON dans `Resources/` au prochain changement de ces valeurs |
| Site : ≈140 valeurs écrites à la main | `ecart-patron-site-valeurs-propres` | Antoine ouvre un chantier visuel du site |
| Trois copies de la géométrie du signe (SVG, SwiftUI, `render-icon.swift`) | `composant-signe-de-la-marque` | une source unique, à décider |

Les autres écarts d'avant sont retirés : `Components/Custom` (casse), `Calculations/` (dossier), clients multi-services, `typeRole` et `elevation` (fabriqués par Sophos).

## Ce qui reste avant de dire « 100 % »

1. Compiler et lancer les tests sur un Mac. Rien de ce qui précède ne remplace cette preuve.
2. Renommer les booléens et les noms d'origine, avec le compilateur.
3. Décider du sort des trois clés enregistrées (`notificationsEnabled`, `onboardingCompleted`, `weekly`).
4. Relire à la main les règles de jugement de `concevoir`, `expliquer`, `penser`, `fonder`.
