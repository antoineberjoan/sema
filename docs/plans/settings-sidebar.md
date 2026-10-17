# Réglages — sidebar et groupes sobres

Statut : en cours, 17 octobre 2026. Antoine demande dans le chat de reprendre l’organisation des réglages de Resurf, à partir de cinq captures. Référence de marque : Notion `3fbd18bb0dea818fa7f4fc7483c767b3`.

## Résultat attendu

Une fenêtre de réglages native avec sidebar fixe et recherche de rubrique, titre de page, groupes de lignes alignées et choix visuels pour le mode et la palette. Général, Apparence, Raccourcis, Sources, Profil et À propos conservent leurs réglages réels. Aucun compte, fournisseur IA, licence ou synchronisation ajouté par imitation de la référence.

Critères : navigation au clic et au clavier, recherche avec état vide et retour ; changement de mode et de palette visible dans les deux surfaces ; accès Sources/Profil depuis le hub conservé ; raccourcis et protection de la clé Webstat inchangés ; lisibilité en clair et sombre ; vérification du bundle natif.

## Mise en œuvre

Base : `codex/keyboard-navigation` (`0716ad6`), dans une branche isolée `codex/settings-sidebar`. Le checkout canonique et les travaux du socle agentique restent intacts. La recherche filtre uniquement les rubriques et leurs mots-clés, sans lire ni indexer la clé API ou les données personnelles.

Une étude de faisabilité distincte répond à la question sur Foundation Models d’Apple. Aucun appel de modèle, compte fournisseur, téléchargement de modèle ou module IA n’est ajouté dans cette refonte des réglages.

## Vérification restante

Bundle debug compilé et signé le 17 octobre avec `scripts/build-app.sh`. La première revue native a conduit à remplacer `NavigationSplitView`, qui ajoutait une grande barre d’outils, par deux colonnes fixes avec liste native. La recherche « grain » + Entrée ouvre bien Apparence. `guardrails.py` et `git diff --check` passent ; les 17 tests Python de `check.sh` passent. Les tests Swift sont empêchés localement par l’absence du module `Testing` dans Command Line Tools ; ils seront contrôlés par la CI macOS.

À terminer : état vide et retour de recherche, navigation des rubriques, comparaison clair/sombre et palettes, capture du rendu final et CI. Aucune publication de version ni fusion vers main couverte par cette demande.

## Faisabilité IA Apple — proposition à arbitrer

Le framework [Foundation Models](https://developer.apple.com/foundation-models-framework/) donne accès au modèle local d’Apple à partir de macOS 26, sans clé API ni facturation par requête. L’app peut conserver son minimum macOS 14 : disponibilité conditionnelle à macOS 26, puis vérification de `SystemLanguageModel.default.availability` et de la langue prise en charge. Aucun de ces appels n’est intégré à l’app dans ce chantier.

Recommandation : commencer par une reformulation courte de la définition officielle d’un repère, à la demande. Une recherche en langage naturel pourrait ensuite traduire une question en filtres du catalogue ; un brouillon d’alerte devrait produire une structure validée par MarketCore et confirmée avant enregistrement. Le modèle ne calcule ni les valeurs, ni les variations, ni les seuils et n’invente pas de série ou de prévision.

Conditions : Mac compatible Apple Intelligence, activation par l’utilisateur, modèle prêt et langue prise en charge. Les Mac de la gamme M sont compatibles à partir de M1 ; 16 Go de RAM ne sont pas une exigence Apple pour ce modèle local. Le stockage nécessaire dépend du système et de la machine ; voir les [conditions Apple actuelles](https://support.apple.com/fr-fr/121115). L’absence du modèle conserve les parcours classiques de sema.

Sonde autonome le 17 octobre 2026, hors du code de l’app : Mac M2, 8 Go, macOS 26.6.2 ; disponibilité `available`. Une reformulation en français d’une définition générique de taux de change a abouti en 9,43 s via `SystemLanguageModel.default`. La première tentative dans le bac à sable a échoué avec ModelManagerServices ; la seconde, hors de ce bac à sable, a réussi. Ce seul essai ne prouve ni la qualité générale ni la réactivité en usage réel. Aucun contenu personnel ni clé API fourni au modèle.

Avant une intégration : valider ce premier usage avec Antoine, mesurer latence et qualité sur plusieurs définitions, limiter le contexte aux métadonnées utiles, gérer annulation/erreur et tester sur macOS 14 ainsi que sur un Mac sans modèle disponible. [Guide Apple de génération](https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models).
