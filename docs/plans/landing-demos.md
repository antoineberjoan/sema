# Démonstrations de la landing

Statut : révision au défilement implémentée et vérifiée en aperçu ; publication en attente. Demande d’Antoine du 17 octobre 2026 : mieux montrer sema, avec la retenue de Monocle, Hoy et Resurf. Marque Notion relue : `3fbd18bb0dea818fa7f4fc7483c767b3`.

## Résultat

Antoine demande le 17 octobre une présentation au défilement : texte stable, vues qui évoluent, sans onglets ni libellé technique visible. Le même décor passe du bandeau de quatre favoris à la recherche puis au hub Focus. Le défilement reste natif, réversible et sans clic obligatoire.

Storyboard : favoris jusqu’à 24 %, apparition de la recherche entre 24 et 36 %, saisie de « euro » et pause jusqu’à 60 %, passage au hub entre 60 et 74 %, tracé de la courbe jusqu’à 96 %. Aucun défilement intercepté, aucune boucle autonome. Les seuils sont centralisés dans `product-demo.js`.

Sans JavaScript, avec Réduire les animations ou en fenêtre basse, les trois vues restent dans le flux de lecture. L’illustration est un seul élément accessible, avec une description réservée aux lecteurs d’écran qui identifie les valeurs fictives. Les commandes dessinées ne sont plus de faux contrôles interactifs. Téléchargement, Homebrew, logo tracé, CTA au défilement, Ko-fi et liens légaux sont conservés.

Critères de revue : transitions lisibles en descendant et en remontant ; aucun onglet ni clic dans la démonstration ; pas de débordement sur mobile ; téléchargement accessible au clavier ; absence de mouvement et de longue zone épinglée dans le parcours réduit.
## Preuves

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
