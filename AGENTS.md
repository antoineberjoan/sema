# Travailler sur sema

Entrée commune à tous les agents. Lire les sections utiles de `docs/PRODUCT.md`, `docs/ARCHITECTURE.md` et les fichiers concernés avant de coder. Ne charger que les références nécessaires à la tâche.

## Autorité et arbitrage

- Antoine fixe l’intention. **Notion** fait foi sur la vision, le business, le périmètre souhaité, la marque, le ton et la copy. **GitHub** fait foi sur le code, les tâches techniques, les décisions d’architecture et les preuves de livraison. Liens : `docs/engineering/SOURCES.md`.
- Le code prouve ce qui fonctionne ; il ne valide pas une nouvelle intention produit. Une page plus récente n’a pas automatiquement raison.
- Si deux versions se contredisent sur la direction à retenir, présenter l’écart et **demander à Antoine laquelle conserver**. Préserver les deux jusqu’à sa réponse ; avancer sur le travail indépendant. Ne pas choisir silencieusement ni dupliquer une décision pour résoudre le conflit.
- Une intention formulée dans le chat vaut instruction pour la tâche. Reporter sa décision durable dans sa source d’autorité, avec date et référence, sans transformer une hypothèse en décision.

## Code et structure

- Une seule implémentation active par responsabilité. Pas d’alias de compatibilité, de code mort, de branche de secours spéculative ni de copie « v2 », « new » ou « final ». Les migrations de données sont traitées dans `docs/engineering/CONVENTIONS.md`.
- Noms courts et explicites, même terme pour le même concept : `docs/engineering/GLOSSARY.md`. Pas de préfixe `Sema` dans un nouvel identifiant : le projet le dit déjà. Respecter les API natives et les schémas externes.
- Chaque fichier de code commence par une courte description de sa responsabilité, avant les imports et après les directives obligatoires. Expliquer son utilité, sans paraphraser son nom.
- Chaque emplacement a un rôle dans `.agents/structure.json`. Réutiliser la zone existante ; justifier un nouvel emplacement. Pas de dossier fourre-tout. Un fichier Swift porte un seul type visible, à son nom ; ses aides restent `private` et les extensions d’un type vivent dans `Type+Rôle.swift`.
- Centraliser les choix métier, visuels et d’environnement chez leur propriétaire. Pas de valeur en dur ni de secret dans le code ; pas de configuration spéculative. Détails dans `docs/engineering/CONVENTIONS.md`.
- Un système durable qui se réutilise : partir de l’existant (`DesignSystem`, conventions, composants), l’étendre plutôt que réinventer. Changer seulement pour une valeur réelle, jamais pour changer.
- Changements ciblés, patterns existants, aucune abstraction sans usage concret. Ne supprimer que ce qui devient inutile pour la tâche.
- Ne pas ajouter de dépendance de production sans accord. Pas de nouvelle cible, framework d’architecture ou service serveur sans besoin explicite.
- App **sema**, en minuscules dans les textes visibles. Français pour l’interface et la documentation ; anglais pour les identifiants.

## Charger au bon moment

| Travail | Instructions à lire |
| --- | --- |
| Modèles, données, calculs, préférences et leurs tests | `Sources/MarketCore/AGENTS.md` |
| App native, état, design et mouvement | `Sources/SemaMac/AGENTS.md` |
| Site | `site/AGENTS.md` |
| Changement fonctionnel ou chantier à plusieurs étapes | `.agents/skills/sema-change/SKILL.md` |
| Design, texte visible ou mouvement | `.agents/skills/sema-design/SKILL.md` |
| Relais, fin de chantier ou session avec travail restant | `.agents/skills/sema-handoff/SKILL.md` |
| Fonctionnement du dispositif et nouveaux outils d’agent | `docs/engineering/WORKFLOW.md` |

Ces chemins fonctionnent aussi quand l’agent ne découvre pas les skills automatiquement. Ne pas charger toutes les skills au démarrage.

## Validation et autonomie

- Définir une condition de réussite observable avant un gros changement. Lire le diff et exécuter le plus petit contrôle pertinent.
- `python3 scripts/guardrails.py` : structure, descriptifs, frontières, liens, valeurs en dur et cohérence mécanique ; les hooks Claude et Cursor le lancent après chaque édition et en fin de tour. `./scripts/check.sh` : contrôles et tests après modification fonctionnelle. `./scripts/build-app.sh` : validation du bundle.
- Après modification UI, vérifier le parcours dans l’app native ou le navigateur : clavier, états utiles, accessibilité et interruption des animations. Séparer ce qui est observé de ce qui reste à vérifier.
- Les réparations et validations locales dans le périmètre demandé sont autonomes. Ne pas élargir la mission ni modifier les règles pour faire passer un contrôle.
- Publication, fusion vers `main` (qui déploie le site), dépense, suppression irréversible et changement de vision nécessitent une autorisation couvrant l’action. Ne pas redemander un accord déjà donné pour cette action.
- Garder une trace utile : plan actif si nécessaire, décision durable si nécessaire, PR et preuves. Aucune transcription brute ni journal quotidien automatique. Procédure : `sema-handoff`.

## Code Review Rules

Signaler une perte de données, une promesse non tenue, une deuxième implémentation, un contournement de contrôle ou un calcul financier hors du cœur. Vérifier le sens des noms et la valeur de chaque ajout. Les scripts ne prouvent ni l’absence de code mort ni la qualité du design.
