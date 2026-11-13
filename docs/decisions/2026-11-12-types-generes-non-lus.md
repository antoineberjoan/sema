# Un type fabriqué par les jetons peut attendre son premier lecteur

Date : 2026-11-12 · Statut : acceptée
Décidé par : Antoine

## Contexte

`scripts/guardrails.py` refuse un type écrit à la main que rien n'utilise. Sophos fabrique tous les jetons : une famille de valeurs (bordure, icône, couche, cible tactile) existe dans `Sources/SemaDesign/` même quand l'app ne l'emploie pas encore.

## Décision

Le contrôle des types inutilisés ne lit pas un fichier dont l'une des trois premières lignes dit « fabriqué depuis tokens.json par sophos/outils/jetons.mjs ». Cette exception est étroite : un type écrit à la main reste refusé, même dans `Sources/SemaDesign/`.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Exclure la seule sortie fabriquée des jetons | Des jetons complets, comme Sophos les fabrique ; `jetons.mjs --verifier` garde la sortie à jour octet pour octet | Une exception écrite dans le contrôle |
| Contrôler aussi les types fabriqués | Aucune exception | Il faut brancher chaque famille à une vue, ou retirer des types de la sortie fabriquée, qui n'est alors plus celle de Sophos |

## Conséquences

Un type fabriqué que personne ne lit n'est pas du code mort écrit à la main : il vient d'un outil. Ce qui reste à vérifier : que `jetons.mjs --verifier` passe, car c'est lui qui garde ces fichiers.
