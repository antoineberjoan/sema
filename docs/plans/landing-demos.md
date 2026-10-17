# Démonstrations de la landing

Statut : révision au défilement en cours ; publication en attente. Demande d’Antoine du 17 octobre 2026 : mieux montrer sema, avec la retenue de Monocle, Hoy et Resurf. Marque Notion relue : `3fbd18bb0dea818fa7f4fc7483c767b3`.

## Résultat

Antoine demande le 17 octobre une présentation au défilement : texte stable, vues qui évoluent, sans onglets ni libellé technique visible. Le même décor passe du bandeau de quatre favoris à la recherche puis au hub Focus. Le défilement reste natif, réversible et sans clic obligatoire.

Storyboard : favoris jusqu’à 24 %, apparition de la recherche entre 24 et 36 %, saisie de « euro » et pause jusqu’à 60 %, passage au hub entre 60 et 74 %, tracé de la courbe jusqu’à 96 %. Aucun défilement intercepté, aucune boucle autonome. Les seuils sont centralisés dans `product-demo.js`.

Sans JavaScript, avec Réduire les animations ou en fenêtre basse, les trois vues restent dans le flux de lecture. L’illustration est un seul élément accessible, avec une description réservée aux lecteurs d’écran qui identifie les valeurs fictives. Les commandes dessinées ne sont plus de faux contrôles interactifs. Téléchargement, Homebrew, logo tracé, CTA au défilement, Ko-fi et liens légaux sont conservés.

Critères de revue : transitions lisibles en descendant et en remontant ; aucun onglet ni clic dans la démonstration ; pas de débordement sur mobile ; téléchargement accessible au clavier ; absence de mouvement et de longue zone épinglée dans le parcours réduit.
## Preuves de la version précédente (à actualiser après revue)

- Code vérifié : `f316272`, branche `codex/landing-demos`, [PR #2](https://github.com/antoineberjoan/sema/pull/2).
- Aperçu Vercel READY : `dpl_27WiSckBXBjbPMEw1msZbrP3wnMM`, https://sema-54ypqvdzp-antoine-berjoan.vercel.app/.
- Antoine a autorisé le 17 octobre un lien temporaire de 23 heures pour vérifier et montrer cet aperçu. Le lien d’accès n’est pas conservé dans le dépôt.
- Navigateur : les trois scènes, résultat de recherche et état vide, flèches/Entrée, onglets et tabulation, changement de série et de période, CTA au défilement vérifiés. Aucun message d’erreur console observé.
- Mobile 390 × 844 : cadrage des trois scènes vérifié, largeur du document égale à 390 px ; périodes du bandeau sur une ligne. Format temporaire du navigateur réinitialisé après revue.
- Captures locales : `sema-landing-demos-20261017.png` et `sema-landing-demo-mobile-20261017.png`, dans le dossier d’artefacts du chat.
- Syntaxe JavaScript, IDs, liens/assets locaux et références ARIA vérifiés.

## Suite

La PR est prête à présenter. Aucun changement fusionné sur main, aucun changement du site public ni du téléchargement natif 0.5.1. Le checkout canonique et son index `codex/agent-foundation` sont préservés. Après autorisation de publication couvrant cette version : fusionner, contrôler le déploiement et le rendu public. La publication de l’app 0.5.2 reste une action distincte.
