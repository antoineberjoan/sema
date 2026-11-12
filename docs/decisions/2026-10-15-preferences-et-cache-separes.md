# Les préférences et le cache sont deux fichiers

Date : 2026-10-15 · Statut : acceptée
Décidé par : Antoine

## Contexte

SwiftData est une option native pertinente pour un historique important, des relations et des requêtes locales. La première version (0.1) garde seulement une sélection de favoris, quelques règles et un cache remplaçable de trois séries.

## Décision

Les préférences vivent dans un document JSON (`Codable`), versionné, écrit atomiquement. Le cache de la BCE vit dans un autre fichier.

Un fichier de préférences illisible, ou d'une version inconnue, est préservé et signalé. Il n'est jamais traité comme une première installation.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Un document JSON versionné | Un cœur simple, testable, compilable avec les Command Line Tools, sans macro de persistance | Pas de requête ni de relation |
| SwiftData | Historique important, relations, requêtes locales | Un modèle de base prématuré et des macros de persistance |

## Conséquences

La persistance suppose une seule instance de l'app : pas de synchronisation, de requête complexe ni de catalogue massif. Si ces besoins apparaissent, on ajoute SwiftData avec une migration explicite de la version actuelle.

Les noms de fichiers, les clés et les valeurs de ces documents sont un contrat avec la personne qui les a sur son disque. Ils ne changent pas, même si un type Swift est renommé. Une migration de format est une décision d'Antoine.

## Trace

Reprise d'ADR 002 (statut « retenu pour la version 0.1 »). Date : celle du premier commit qui la porte. Renommée au format de Sophos lors de l'alignement.
