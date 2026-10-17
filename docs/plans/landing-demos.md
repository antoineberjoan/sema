# Démonstrations de la landing

Statut : sections successives implémentées et vérifiées en aperçu ; publication en attente. Demande d’Antoine du 17 octobre 2026 : mieux montrer sema, avec la retenue de Monocle, Hoy et Resurf. Marque Notion relue : `3fbd18bb0dea818fa7f4fc7483c767b3`.

## Résultat

Antoine précise le 17 octobre dans le chat que les fonctionnalités doivent être affichées **les unes sous les autres**. Cette demande remplace la scène unique épinglée : trois sections indépendantes présentent successivement le bandeau, la recherche et le hub Focus, chacune avec son titre et son visuel. Aucun onglet, défilement intercepté, grand espace de scroll artificiel ou mention technique visible.

Storyboard par section : le visuel apparaît en 650 ms à l’approche de l’écran ; à partir de 240 ms, les courbes se tracent en 1 300 ms ou les résultats apparaissent avec un décalage de 90 ms. Une seule entrée par visite, pas de répétition au retour. Réduire les animations, un onglet masqué ou l’absence de JavaScript donnent les trois visuels complets dans le même flux. Les valeurs fictives restent identifiées dans chaque description accessible.

Critères : trois sections distinctes dans l’ordre du document et à l’écran ; aucun épinglage ; lecture et navigation clavier naturelles ; pas de débordement sur mobile ; aucun contrôle simulé actif. Téléchargement, Homebrew, logo tracé, Ko-fi et liens légaux sont conservés.

## Preuves

- Code vérifié : `7b66a05`, branche `codex/landing-demos`, [PR #2](https://github.com/antoineberjoan/sema/pull/2).
- Aperçu Vercel READY : `dpl_5Sj8sGG4oDrz8mUrZGr55b9kss5D`, https://sema-r7r6ax9c3-antoine-berjoan.vercel.app/.
- Accès temporaire de dix heures dans le périmètre de la revue autorisée par Antoine, sans extension au-delà de son autorisation initiale. Le lien d’accès n’est pas conservé dans le dépôt.
- Navigateur 1280 × 720 : trois sections successives en position statique, chacune avec son titre et son visuel ; quatre cartes dans le bandeau ; recherche avec apparition ordonnée des trois résultats ; hub complet et courbe finale. Retour en arrière sans rejouer l’animation. Aucun épinglage ni onglet.
- Mobile 390 × 844 : trois sections observées, deux cartes lisibles dans le bandeau, recherche et hub cadrés ; document de 390 px sans débordement.
- Syntaxe JS, attributs HTML uniques, IDs, références ARIA, assets locaux, absence de faux contrôles et diff vérifiés. Aucune dépendance ajoutée.
- Contrôle d’exécution isolé : révélations indépendantes, observation interrompue après la première entrée, arrêt des animations à la réduction du mouvement et au masquage de l’onglet. La préférence système du Mac n’a pas été changée ; le mode réduit n’a pas été observé dans le navigateur.
- CI GitHub verte sur `7b66a05` : run `39030004436`.
- Captures locales : `sema-features-desktop-20261017.png` et `sema-features-mobile-20261017.png`, dans le dossier d’artefacts du chat.
- Précision d’Antoine reportée dans la page Notion Marque : la présentation verticale remplace la scène unique au texte fixe.

## Téléchargement — proposition en aperçu

Antoine questionne le 17 octobre l’utilité de la page de téléchargement et son écart de sobriété avec la landing. Proposition préparée pour revue : le CTA de la landing télécharge directement le DMG publié ; `/download/` devient une aide facultative, sans nouvelle présentation du produit, démonstration ni replay. Trois étapes, puis aide macOS, Homebrew et mises à jour repliées. Cette proposition n’est pas encore une décision produit validée par Antoine.

La landing conserve la compatibilité et la mention de préversion non notarisée près du téléchargement. `sync-download.py` génère les deux CTA et les informations de version à partir du seul manifeste publié 0.5.1 ; la version native et son artefact ne changent pas. Le header reprend le lien principal et reste inerte si aucun téléchargement n’est actif.

Critères : téléchargement direct fonctionnel ; aide lisible sur ordinateur et mobile ; liens d’ancre ouvrant la bonne réponse ; parcours clavier ; copie Homebrew ; manifeste et SHA-256 de la release inchangés. Synchronisation idempotente et désactivation des CTA déjà vérifiées localement. Revue navigateur et CI en cours.

## Suite

La PR est prête à présenter. Aucun changement fusionné sur main, aucun changement du site public ni du téléchargement natif 0.5.1. Le checkout canonique et son index `codex/agent-foundation` sont préservés. Après autorisation de publication couvrant cette version : fusionner, contrôler le déploiement et le rendu public. La publication de l’app 0.5.2 reste une action distincte.
