# Réglages — sidebar et groupes sobres

Statut : simplification terminée et vérifiée en natif et en CI, 17 octobre 2026. Antoine demande dans le chat de reprendre l’organisation des réglages de Resurf, à partir de cinq captures. Référence de marque : Notion `3fbd18bb0dea818fa7f4fc7483c767b3`, direction reportée le même jour.

## Résultat attendu

Une fenêtre de réglages native avec sidebar fixe et recherche de rubrique, titre de page, groupes de lignes alignées et choix visuels pour le mode et la palette. Général, Apparence, Raccourcis, Sources, Profil et À propos conservent leurs réglages réels. Aucun compte, fournisseur IA, licence ou synchronisation ajouté par imitation de la référence.

Critères : navigation au clic et au clavier, recherche avec état vide et retour ; changement de mode et de palette visible dans les deux surfaces ; accès Sources/Profil depuis le hub conservé ; raccourcis et protection de la clé Webstat inchangés ; lisibilité en clair et sombre ; vérification du bundle natif.

## Mise en œuvre

Base : `codex/keyboard-navigation` (`0716ad6`), dans une branche isolée `codex/settings-sidebar`. Le checkout canonique et les travaux du socle agentique restent intacts. La recherche filtre uniquement les rubriques et leurs mots-clés, sans lire ni indexer la clé API ou les données personnelles.

Une étude de faisabilité distincte répond à la question sur Foundation Models d’Apple. Aucun appel de modèle, compte fournisseur, téléchargement de modèle ou module IA n’est ajouté dans cette refonte des réglages.

## Preuves et limites

Bundle debug compilé et signé le 17 octobre avec `scripts/build-app.sh`. La première revue native a conduit à remplacer `NavigationSplitView`, qui ajoutait une grande barre d’outils, par deux colonnes fixes avec liste native. `guardrails.py` et `git diff --check` passent ; les 17 tests Python de `check.sh` passent. Les tests Swift sont empêchés localement par l’absence du module `Testing` dans Command Line Tools ; la [CI macOS](https://github.com/antoineberjoan/sema/actions/runs/39035580071) a passé les 77 tests Swift, les 17 tests Python et la construction du bundle.

Parcours natifs observés sur profil de revue isolé : « grain » + Entrée ouvre Apparence ; recherche sans résultat en français, Échap et effacement ; navigation des rubriques au clic et avec les flèches ; accès Mon espace depuis le hub ; clair avec Bleu polaire et sombre avec Graphite ; sélection mode/palette/position conservée après relance ; verre accessible au défilement avec profil toujours fixé en bas ; Sources, connexion Webstat, À propos/Ko-fi visibles ; annulation du recorder par Échap sans changement de combinaison. La version habituelle tournait aussi : sa réservation des accès globaux provoque un conflit correctement affiché dans l’aperçu ; ce test ne revalide donc pas le déclenchement global des raccourcis. Aucune clé enregistrée ou retirée, aucune permission de notification activée, aucun réglage d’accessibilité système modifié.

[PR de revue #4](https://github.com/antoineberjoan/sema/pull/4), basée sur le chantier clavier. Captures clair/sombre conservées comme pièces de revue locales. Aucune publication de version ni fusion vers main couverte par cette demande. L’IA reste une proposition à arbitrer, indépendante de la refonte terminée.

## Faisabilité IA Apple — proposition à arbitrer

Le framework [Foundation Models](https://developer.apple.com/foundation-models-framework/) donne accès au modèle local d’Apple à partir de macOS 26, sans clé API ni facturation par requête. L’app peut conserver son minimum macOS 14 : disponibilité conditionnelle à macOS 26, puis vérification de `SystemLanguageModel.default.availability` et de la langue prise en charge. Aucun de ces appels n’est intégré à l’app dans ce chantier.

Recommandation : commencer par une reformulation courte de la définition officielle d’un repère, à la demande. Une recherche en langage naturel pourrait ensuite traduire une question en filtres du catalogue ; un brouillon d’alerte devrait produire une structure validée par MarketCore et confirmée avant enregistrement. Le modèle ne calcule ni les valeurs, ni les variations, ni les seuils et n’invente pas de série ou de prévision.

Conditions : Mac compatible Apple Intelligence, activation par l’utilisateur, modèle prêt et langue prise en charge. Les Mac de la gamme M sont compatibles à partir de M1 ; 16 Go de RAM ne sont pas une exigence Apple pour ce modèle local. Le stockage nécessaire dépend du système et de la machine ; voir les [conditions Apple actuelles](https://support.apple.com/fr-fr/121115). L’absence du modèle conserve les parcours classiques de sema.

Sonde autonome le 17 octobre 2026, hors du code de l’app : Mac M2, 8 Go, macOS 26.6.2 ; disponibilité `available`. Une reformulation en français d’une définition générique de taux de change a abouti en 9,43 s via `SystemLanguageModel.default`. La première tentative dans le bac à sable a échoué avec ModelManagerServices ; la seconde, hors de ce bac à sable, a réussi. Ce seul essai ne prouve ni la qualité générale ni la réactivité en usage réel. Aucun contenu personnel ni clé API fourni au modèle.

Avant une intégration : valider ce premier usage avec Antoine, mesurer latence et qualité sur plusieurs définitions, limiter le contexte aux métadonnées utiles, gérer annulation/erreur et tester sur macOS 14 ainsi que sur un Mac sans modèle disponible. [Guide Apple de génération](https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models).

## Épure demandée le 17 octobre

Source : nouvelles captures d’Antoine dans le chat. Retirer de Général les lignes Données, Actualisation et Sélection de départ, les accès Démonstration, le nom visible Focus et les aides clavier répétées. Le premier accueil et l’identification des données fictives restent utiles et conservés. Mon espace garde photo, prénom et nom dans une présentation plus compacte. Sources garde les interrupteurs utiles ; la clé et son action sont réunies, avec le même composant sécurisé lors de la première connexion. Aucune clé de test n’est envoyée pour une validation visuelle.

Le raccourci du hub devient ⌃⇧H ; la réservation exclusive réussit sur ce Mac (OSStatus 0), puis est libérée. Seul l’ancien défaut ⌃⌥H est migré ; les choix personnalisés ou désactivés restent inchangés. Le graphique doit grandir avec la fenêtre, avec un défilement de secours si les messages ou une petite hauteur l’exigent.

Critères : aucune mention Focus, Sélection de départ ou tutoriel de maintien de ⌘ dans les parcours touchés ; navigation native, photo annulable, champs du profil et enregistrement conservés ; connexion vide désactivée, clé protégée et effacée à la sortie, erreurs conservées ; petit et grand hub sans grand vide sous le graphique ; compilation et parcours natifs. Le checkout canonique reste intact.

## Vérification de l’épure

Le 17 octobre, bundle natif de revue compilé et signé dans un profil isolé. Le hub utilise la hauteur disponible : valeur, graphique extensible et actions au pied de la fenêtre, sans grande zone vide sous le graphique. Général ne présente plus que les notifications. Raccourcis affiche ⌃⇧H, sans conflit de réservation ni nom Focus ou consigne de maintien. La migration de l’ancien défaut est observée au chargement du profil de revue ; un test vérifie aussi les raccourcis personnalisés et désactivés.

Mon espace : saisie d’un prénom de test, changement de rubrique puis retour avec conservation de la valeur, effacement ; ouverture et annulation du sélecteur de photo sans import. Sources : champ sécurisé vide et bouton désactivé ; saisie d’une chaîne factice sans soumission, bouton actif ; sortie puis retour avec champ vide et bouton désactivé. Aucune connexion réseau ni clé enregistrée pendant cette revue. Captures du hub, du profil et des sources dans les pièces locales du chat.

`guardrails.py` et le diff passent ; les 17 tests Python passent. Swift Testing reste absent du SDK Command Line Tools local ; la [CI du commit de7d0e9](https://github.com/antoineberjoan/sema/actions/runs/39043648277) passe les tests, dont la migration du raccourci, et le bundle. Le bundle de production a aussi été compilé et signé localement sans chemin de développement. La réservation native exclusive de ⌃⇧H réussit, mais le déclenchement global physique n’est pas déclaré observé ; les événements synthétiques du contrôle natif ne constituent pas cette preuve. Le mode sombre, l’accessibilité et le recorder avaient été vérifiés avant cette épure ; aucun changement de matière ou de mouvement dans celle-ci.
