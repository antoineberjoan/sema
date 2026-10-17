# Démonstration de la landing

Statut : nouvelle proposition motion en cours de vérification, publication en attente, 17 octobre 2026. Source : chat d’Antoine ; page Notion Marque `3fbd18bb0dea818fa7f4fc7483c767b3` relue. Branche `codex/landing-demos`, [PR #2](https://github.com/antoineberjoan/sema/pull/2). Checkout canonique et travaux natifs préservés.

## Intention et périmètre

Antoine rejette les trois présentations précédentes, demande la commande Homebrew visible et copiable comme chez Monocle, le retrait de la ligne de compatibilité sous le téléchargement, puis la suppression de la page de téléchargement. Il évoque une vidéo motion comme nouvelle piste. Ces retraits sont demandés ; la vidéo reste une proposition à approuver avant publication.

Le CTA télécharge le DMG existant. Aucun changement de release, de cask, de données natives ou de configuration de sécurité. La commande reste celle du manifeste, qualifiée avec le tap pour fonctionner sur une machine neuve. `/download/` ne sert plus de page ; seul son manifeste JSON existant est conservé.

## Proposition motion

Une seule séquence silencieuse de 18 secondes remplace les trois blocs de démonstration. `scripts/render-demo.swift` dessine les images, encodées en MP4 H.264 ; aucun outil de capture ni nouvelle dépendance de production. Ce sont des illustrations d’interface avec valeurs fixes, pas une captation native.

| Temps | Action |
| --- | --- |
| 0–5 s | Le pointeur ouvre quatre favoris dans le bandeau ; les mini-courbes se tracent. |
| 5–9,4 s | ⌘K, saisie d’euro, apparition des résultats et sélection. |
| 9,4–16 s | Focus, tracé de l’historique, apparition de la sidebar au survol puis fermeture. |
| 16–18 s | Graphique au repos et signature. |

Lecture automatique une fois en vue, sans boucle. Pause hors écran et au masquage. Réduire les animations conserve un poster et les contrôles manuels. Une description accessible raconte toutes les actions et identifie les valeurs fictives. Les chiffres ne simulent pas un flux de marché. La commande Homebrew se copie sans changer de largeur ; un échec de presse-papiers sélectionne le texte pour une copie manuelle. Sans JavaScript, le téléchargement, la commande sélectionnable et la lecture native restent disponibles.

## Critères et preuves

- Commande exacte issue du manifeste, copie au clic et au clavier, retour discret.
- Aucun lien interne vers la page supprimée ; le générateur ne recrée ni cette page ni la ligne sous le CTA.
- Film lisible, sans audio ni boucle, poster correct et contrôles clavier ; interruption et état réduit.
- Largeur mobile 390 px sans débordement, liens de téléchargement identiques dans le hero et le header, FAQ, Ko-fi et liens légaux conservés.
- Diff ciblé, syntaxe, génération reproductible et vérification du manifeste sans altérer l’artefact publié.

Prochaine action : encoder et relire les images du film, vérifier les parcours dans un nouvel aperçu Vercel privé, puis présenter la proposition. La production n’est pas modifiée par cette branche.
