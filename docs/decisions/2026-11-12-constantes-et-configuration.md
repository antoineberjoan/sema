# Chaque valeur a un seul propriétaire, nommé et lisible

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine (reprise d'un document retiré)

## Contexte

Des valeurs écrites en dur dans les vues ou recopiées entre fichiers dérivent. Les conventions de code d'avant l'alignement donnaient un propriétaire à chaque famille de valeurs.

## Décision

| Valeur | Propriétaire |
| --- | --- |
| Règle métier, seuil technique motivé, limite d'un fournisseur | Le type ou le client qui porte le contrat, en constante nommée, avec un test utile |
| Couleur, espace, rayon, texte, mouvement | `Resources/Brand/tokens.json`, lu par `Sources/SemaDesign/` ; jetons CSS pour le site |
| Durée ou distance d'une séquence | Les rôles de mouvement du patron |
| Choix personnel | Le modèle de préférences et sa persistance |
| Environnement, URL publique de configuration | La configuration du bundle ou de l'outil propriétaire |
| Secret | Le Trousseau ou l'environnement autorisé, jamais le dépôt |

- Dans l'app, aucune valeur visuelle n'est écrite dans l'appel (rayon, police, trait, durée, marge, opacité, décalage, approche, échelle). `scripts/guardrails.py` le refuse ; `0` et `1` restent permis.
- Dans le cœur, une règle métier se nomme sur son type : seuils d'alerte, précision des séries, fenêtre d'historique, délais et limites des fournisseurs, versions de schéma.
- Une constante se définit une seule fois, à la portée utile. Une URL de fournisseur peut rester une constante du client : rendre l'hôte configurable sans besoin fragiliserait l'envoi des clés.
- Les textes ne vont pas dans un registre générique ; on mutualise seulement ceux qui portent la même copie.
- Les copies de livraison sont permises avec une source désignée et une vérification de cohérence. `distribution/release.json` fait foi pour son miroir web.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Un propriétaire par famille de valeurs | Chaque valeur se retrouve ; aucune dérive | Un contrôle à tenir (`guardrails.py`) |
| Valeurs libres dans les vues | Aucune règle à suivre | Des écarts entre écrans, des valeurs oubliées |

## Conséquences

Les règles « un concept, un nom, zéro alias » et « zéro code mort » sont dans le skill `construire` de Sophos : elles ne sont pas recopiées ici.

## Trace

Repris de `docs/engineering/CONVENTIONS.md` à son retrait, le 2026-11-12. Le texte complet reste dans l'historique Git.
