# Démonstrations de la landing

Statut : sections successives implémentées ; revue en cours ; publication en attente. Demande d’Antoine du 17 octobre 2026 : mieux montrer sema, avec la retenue de Monocle, Hoy et Resurf. Marque Notion relue : `3fbd18bb0dea818fa7f4fc7483c767b3`.

## Résultat

Antoine précise le 17 octobre dans le chat que les fonctionnalités doivent être affichées **les unes sous les autres**. Cette demande remplace la scène unique épinglée : trois sections indépendantes présentent successivement le bandeau, la recherche et le hub Focus, chacune avec son titre et son visuel. Aucun onglet, défilement intercepté, grand espace de scroll artificiel ou mention technique visible.

Storyboard par section : le visuel apparaît en 650 ms à l’approche de l’écran ; à partir de 240 ms, les courbes se tracent en 1 300 ms ou les résultats apparaissent avec un décalage de 90 ms. Une seule entrée par visite, pas de répétition au retour. Réduire les animations, un onglet masqué ou l’absence de JavaScript donnent les trois visuels complets dans le même flux. Les valeurs fictives restent identifiées dans chaque description accessible.

Critères : trois sections distinctes dans l’ordre du document et à l’écran ; aucun épinglage ; lecture et navigation clavier naturelles ; pas de débordement sur mobile ; aucun contrôle simulé actif. Téléchargement, Homebrew, logo tracé, Ko-fi et liens légaux sont conservés.

## Preuves de la version précédente (à actualiser après revue)

- Code vérifié : `5199896`, branche `codex/landing-demos`, [PR #2](https://github.com/antoineberjoan/sema/pull/2).
- Aperçu Vercel READY : `dpl_3eFQMJMqXaJ57Rxgm2tVwB4VpYTU`, https://sema-4m0m9h6fy-antoine-berjoan.vercel.app/. Il remplace la présentation à onglets du précédent aperçu.
- Accès temporaire repris dans le périmètre des 23 heures autorisées par Antoine ; expiration avant celle de l’autorisation initiale. Le lien d’accès n’est pas conservé dans le dépôt.
- Navigateur à 1280 × 720 : quatre cartes, recherche, courbe progressive, état final, retour en arrière et texte épinglé observés. Le CTA du header apparaît après la sortie du téléchargement principal.
- Mobile 390 × 844 : bandeau de deux cartes lisibles, recherche et hub observés ; largeur du document de 390 px, sans débordement.
- Fenêtre 1280 × 540 : épinglage désactivé, trois vues visibles dans le flux. Les trois vues restent également la présentation HTML/CSS de base sans JS.
- Clavier : téléchargement puis Homebrew puis FAQ, sans arrêt sur les commandes dessinées. Aucun gestionnaire clavier de la démonstration. Aucun message console attribué au code de la landing ; la page de connexion Vercel précédente a émis ses propres messages FedCM.
- Vérification d’exécution JavaScript : progression et retour entre scènes, défilement passif, annulation de frame lorsque l’onglet est masqué ou le mouvement réduit, retour à la lecture statique et requête complète. Réduire les animations testé dans ce contrôle isolé et dans les styles ; la préférence système du Mac n’a pas été changée et ce mode n’a pas été observé dans le navigateur.
- Syntaxe JS, IDs, assets et ARIA vérifiés ; diff sans erreur d’espacement. CI GitHub verte sur `5199896` : run `39020677206`. Garde-fous du checkout canonique vérifiés séparément ; cette branche antérieure ne contient pas encore le script de fondation.
- Captures locales : `sema-landing-scroll-focus-20261017.png` et `sema-landing-scroll-mobile-20261017.png`, dans le dossier d’artefacts du chat.
- Intention de présentation au défilement reportée dans la page Notion Marque le 17 octobre 2026.

## Suite

La PR est prête à présenter. Aucun changement fusionné sur main, aucun changement du site public ni du téléchargement natif 0.5.1. Le checkout canonique et son index `codex/agent-foundation` sont préservés. Après autorisation de publication couvrant cette version : fusionner, contrôler le déploiement et le rendu public. La publication de l’app 0.5.2 reste une action distincte.
