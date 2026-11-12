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
- **Couleurs écrites dans les vues** : plus aucune, sans exception : l'image de la barre des menus (un modèle, lu par sa seule transparence) lit `DesignColor.text`. Le verre et la signature lisent des rôles de couleur de sema ; le blanc devient papier (`#FAFAFA`) et le noir devient l'encre la plus sombre (`#030303`, `ink.900`) : une teinte à peine différente, listée dans `docs/controle-sur-le-mac.md`.
- **Retiré** : `StatisticalSource.requiresKey`, que rien ne lisait (code mort).
- **Sans objet** : `acceptsFirstResponder` est le nom d'une API d'AppKit qu'on surcharge (`architecture.md`, règle 6, nom imposé).
- **Risque de compilation à regarder** : une propriété `isEnabled`, `isSelected`, `isFocus` ou `isOpaque` dans une vue SwiftUI peut croiser un nom du framework ; les noms de la forme `is…` dans `SourceKeyView`, `WorkspaceScreen`, `SettingsScreen` et `RibbonGlassSettingsView` sont les premiers à relire.

## Écarts de valeurs

Aucun écart daté ne reste. Toute valeur visuelle de l'app et du site se lit dans un fichier de jetons :

- `Resources/Brand/tokens.json` (app) : couleurs, tailles (`layout`), mesures (`measure`), opacités, durées. `jetons.mjs` fabrique le Swift.
- `site/tokens.json` (site) : toutes les variables du site, avec leurs valeurs d'avant (l'apparence ne change pas). `jetons.mjs` fabrique `site/dist/brand/site-tokens.css`.
- Données de départ : JSON dans `Sources/MarketCore/Resources/Starters/`, lu par le connecteur, avec un test.
- Signe de la marque : une source, `SignalPath.swift`. `scripts/export_signe.py` fabrique les SVG et les icônes ; `controler.sh` échoue si un fichier diffère.
- Couleur de la barre du navigateur (`theme-color`) : `guardrails.py` échoue si elle diffère du rôle `page`.

**Sans objet (2026-11-12, arbitrage de l'architecte)** :

- Pourcentages d'étapes des `@keyframes`, `0`, `1`, `scale(0)`, `scale(1)` : la structure d'une animation et des identités mathématiques. CSS n'accepte pas `var()` dans un pourcentage d'étape. Les durées et les courbes de ces animations sont des jetons.
- `.frame(width: 0, height: 0)` des hôtes invisibles (`MenuRibbonAttachment`, `FocusKeyboard`), `.aspectRatio(1, …)`, `.opacity(… ? 1 : 0)`, `.rotationEffect(… : 0)` : des identités (taille nulle, rapport carré, tout ou rien), pas des valeurs de présentation (2026-11-12).
- `ProfilePhoto.maximumFileSize` : une limite de logique (un nombre d'octets), pas une valeur de design.

**Lu par rôle, jamais par marche** : le CSS du site ne lit aucune primitive (`--scale-space-N`, `--scale-text-N`, `--scale-weight-*`). Il lit des rôles nommés par usage (par exemple `--fav-padding`, `--focus-value-text-size`), chacun avec sa `$description` dans `site/tokens.json`. `guardrails.py` échoue si le CSS lit une primitive `--scale-*`.

**Kit de marque fabriqué** : `site/dist/brand/tokens.json` est la sortie `resolved-json` de `Resources/Brand/tokens.json`. `sema-colors.json`, que rien ne lisait, est supprimé : les cinq couleurs sont les ancres de `tokens.json`. `jetons.mjs --verifier` (dans `controler.sh`) échoue si la sortie est périmée.

## Valeurs voisines que le patron pourrait fusionner (information, aucune action)

- Couleurs à moins de 10 par canal : `secondary` `#AAAAAA` et `meta` `#B4B4B4` ; `secondary-light` `#5C5C5C` et `line` `#555555` ; `surface` `#262626`, `surface-deep` `#1F1F1F` et `tile-ink` `#303030` ; `page` `#0E0E0E`, `button-ink` `#171717` et `surface-deep` ; `tile-light` `#E5E5E5`, `text` `#EEEEEE`, `button` `#EFEFEF`, `paper-soft` `#F5F5F5` et `text-strong` `#DBDBDB`.
- Tailles de texte à 1 ou 2 px l'une de l'autre : 10, 11, 12, 13, 14, 16, 18, 20.
- Durées identiques : `scene-step` et `scene-swap` (700 ms) ; `scene-settle`, `scene-lines-start`, `scene-panel-start` (900 ms).
- 24 valeurs de marche sont partagées par plusieurs rôles (par exemple `scale-space-4` par 20 rôles).

Les autres écarts d'avant sont retirés : `Components/Custom` (casse), `Calculations/` (dossier), clients multi-services, `typeRole` et `elevation` (fabriqués par Sophos).

## En attente

La seule ligne qui ne dépend pas de ce dépôt : **compilation et tests sur le Mac d'Antoine**. Condition : `swift build` réussit et tous les tests passent. Tant que ce n'est pas fait, « preuve avant fini » (`construire`, principe 12) est en attente, jamais conforme.

Tout le reste de ce fichier a une preuve d'outil, ou une condition écrite ci-dessus. Les règles de jugement (rendu, hiérarchie, mouvement ressenti, ton) sont dans la liste de contrôle par écran du fichier `docs/controle-sur-le-mac.md`.
