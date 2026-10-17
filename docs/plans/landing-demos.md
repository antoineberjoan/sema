# Démonstrations de la landing

Statut : implémenté et vérifié en aperçu ; publication en attente. Demande d’Antoine du 17 octobre 2026 : mieux montrer sema, avec la retenue de Monocle, Hoy et Resurf. Marque Notion relue : `3fbd18bb0dea818fa7f4fc7483c767b3`.

## Résultat

Une scène produit présente trois gestes : bandeau de favoris, recherche locale de démonstration, historique Focus avec choix de série et de période. Illustrations originales HTML/SVG, sans dépendance, appel fournisseur ni préférence persistante. Toutes les valeurs sont fictives et signalées. Téléchargement, Homebrew, logo tracé, CTA au défilement, Ko-fi et liens légaux sont conservés.

L’animation suit une entrée courte par scène, sans boucle automatique. Le CSS et la requête média donnent un état sans mouvement pour « Réduire les animations » ; la préférence système du Mac n’a pas été changée pour cette revue.

## Preuves

- Code vérifié : `f316272`, branche `codex/landing-demos`, [PR #2](https://github.com/antoineberjoan/sema/pull/2).
- Aperçu Vercel READY : `dpl_27WiSckBXBjbPMEw1msZbrP3wnMM`, https://sema-54ypqvdzp-antoine-berjoan.vercel.app/.
- Antoine a autorisé le 17 octobre un lien temporaire de 23 heures pour vérifier et montrer cet aperçu. Le lien d’accès n’est pas conservé dans le dépôt.
- Navigateur : les trois scènes, résultat de recherche et état vide, flèches/Entrée, onglets et tabulation, changement de série et de période, CTA au défilement vérifiés. Aucun message d’erreur console observé.
- Mobile 390 × 844 : cadrage des trois scènes vérifié, largeur du document égale à 390 px ; périodes du bandeau sur une ligne. Format temporaire du navigateur réinitialisé après revue.
- Captures locales : `sema-landing-demos-20261017.png` et `sema-landing-demo-mobile-20261017.png`, dans le dossier d’artefacts du chat.
- Syntaxe JavaScript, IDs, liens/assets locaux et références ARIA vérifiés.

## Suite

La PR est prête à présenter. Aucun changement fusionné sur main, aucun changement du site public ni du téléchargement natif 0.5.1. Le checkout canonique et son index `codex/agent-foundation` sont préservés. Après autorisation de publication couvrant cette version : fusionner, contrôler le déploiement et le rendu public. La publication de l’app 0.5.2 reste une action distincte.
