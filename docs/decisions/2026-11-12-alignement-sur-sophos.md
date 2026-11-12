# sema suit Sophos en copie conforme

Date : 2026-11-12 · Statut : acceptée
Décidé par : Antoine

## Contexte

sema avait son propre système : règles d'agents, contrôles Python, conventions, décisions pilotées depuis Notion. Sophos décrit une méthode commune à tous les projets d'Antoine : socle de fichiers, jetons de design, structure du code, contrôles et garde des agents.

## Décision

sema reprend Sophos à l'identique, sans compromis. Une chose qui existe déjà ne reste pas par habitude. Seuls restent le nom, la marque (palettes, icône, police) et le comportement du produit.

- **Qui décide.** Les décisions vivent dans ce dépôt (`docs/decisions/`, `docs/fondation.md`). Notion ne pilote plus sema. Antoine a décidé de quitter Notion le 2026-11-10.
- **Les six palettes** que la personne choisit dans les réglages restent. C'est un réglage visible du produit. Chaque palette est un jeu des mêmes rôles de couleur.
- **Les fichiers de la personne** ne changent pas : noms, clés et valeurs restent, même si le type Swift est renommé.
- **Le code** s'écrit en anglais. L'interface et ce qu'un fichier persistant porte restent tels quels.
- L'ADR 003 (socle agentique en Python) est retirée : la garde, les skills et le hook Git de Sophos la remplacent.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Copie conforme de Sophos | Un seul système, le même dans tous les projets | Une refonte de tout l'existant, par lots |
| Garder le système de sema et en reprendre une partie | Moins de travail tout de suite | Deux systèmes à maintenir et des exceptions |

## Conséquences

Le travail se fait par lots, chacun en brouillon, avec un cliquet qui descend jusqu'à 0. Aucune fusion sans l'accord d'Antoine. Aucun alias, aucune couche de compatibilité, aucun code mort, aucune exception sans décision datée.

## Trace

Lot 1a (socle texte) : PR `claude/sophos-socle`. Les lots suivants sont listés dans cette PR et dans les suivantes.
