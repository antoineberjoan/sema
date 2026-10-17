# Démonstrations de la landing

Statut : implémenté, validation visuelle bloquée par l’accès à l’aperçu privé. Demande d’Antoine du 17 octobre 2026 : mieux montrer sema, en s’alignant sur la retenue de Monocle, Hoy et Resurf. Marque Notion relue : `3fbd18bb0dea818fa7f4fc7483c767b3`.

## Résultat attendu

Une seule scène produit avec trois vues : bandeau de verre, recherche locale de démonstration, historique Focus. Illustrations originales HTML/SVG, sans dépendance ni vidéo lourde. Toutes les valeurs sont fictives et signalées. Aucun appel fournisseur, aucun changement natif, aucune promesse de surveillance automatique.

La landing conserve téléchargement, Homebrew, logo tracé, CTA au défilement, Ko-fi et liens légaux. Les contrôles fonctionnent au clavier et au toucher ; sans animation, la scène reste entièrement utilisable.

## Validation et suite

- Syntaxe JavaScript et inspection des liens et assets.
- Aperçu Vercel : vérifier les trois vues, recherche avec résultat/vide, périodes, clavier, mobile et mouvement réduit.
- Relire puis publier uniquement les changements de landing selon l’autorisation de la tâche. La publication de l’app 0.5.2 reste une action distincte.

Implémentation isolée dans la branche `codex/landing-demos` pour ne pas toucher l’index du chantier de fondation en cours.

## État vérifié et reprise

- PR brouillon : https://github.com/antoineberjoan/sema/pull/2
- Branche : `codex/landing-demos`, code `8937c67`. Syntaxe JS, assets locaux, IDs et références ARIA vérifiés ; Vercel READY.
- Aperçu de ce code : https://sema-9cgzpg11n-antoine-berjoan.vercel.app/ (authentification Vercel).
- Le contrôle automatique a refusé la création d’un lien d’accès temporaire : élargissement d’accès non explicitement autorisé. Une question est en attente auprès d’Antoine pour un lien de 23 heures. Ne pas contourner ce refus.
- Après accord : créer le lien pour le dernier aperçu, vérifier les trois vues, clavier, mobile et mouvement réduit, corriger si nécessaire. La landing n’a pas été fusionnée ni publiée. Le téléchargement natif reste en 0.5.1.
- L’index du checkout canonique et la branche `codex/agent-foundation` ont été préservés. Le worktree temporaire peut être recréé depuis la branche distante ; aucune copie source durable supplémentaire n’est nécessaire.
