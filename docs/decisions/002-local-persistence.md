# ADR 002 — Préférences et cache séparés

Statut : retenu pour la version 0.1.

## Contexte

SwiftData est une option native pertinente pour un historique important, des relations et des requêtes locales. La première version conserve seulement une sélection de favoris, quelques règles et un cache remplaçable de trois séries.

## Décision

Conserver les préférences dans un document Codable JSON versionné et écrit atomiquement. Conserver le cache BCE dans un autre fichier.

Cela maintient le cœur simple, testable et compilable avec les Command Line Tools, sans macros de persistance ni modèle de base prématuré.

Un fichier de préférences illisible ou d’une version inconnue est préservé et signalé. Il n’est pas traité comme une première installation.

## Conséquences

La persistance est conçue pour une seule instance d’app. Pas de synchronisation, de requêtes complexes ni de catalogue massif. Si ces besoins apparaissent, ajouter SwiftData avec une migration explicite de la version actuelle.
