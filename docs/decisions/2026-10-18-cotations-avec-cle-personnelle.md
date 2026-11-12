# Les cours individuels passent par une clé personnelle, jamais par une clé partagée

Date : 2026-10-18 · Statut : acceptée
Décidé par : Antoine

## Contexte

Des cotations d'actions et d'ETF demandent un fournisseur de cours. sema n'a ni serveur ni compte, et ne porte aucune clé partagée.

## Décision

sema intègre les connexions Twelve Data et Alpha Vantage. Chaque personne utilise sa propre clé, validée avant enregistrement dans le Trousseau de son Mac. Une clé refusée ou un quota atteint suspend le fournisseur sans effacer le cache. Les accès refusés ne sont pas contournés.

## Conséquences

Les droits d'affichage dans une application tierce ne sont pas garantis par la clé. Les contrats de chaque fournisseur sont dans `docs/DATA-SOURCES.md`.
