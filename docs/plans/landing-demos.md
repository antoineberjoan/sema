# Démonstration de la landing

Statut : la vidéo est remplacée par deux scènes animées HTML/SVG/CSS (18 octobre 2026, validées par Antoine dans le chat) ; publication en attente. Source : chat d’Antoine ; page Notion Marque `3fbd18bb0dea818fa7f4fc7483c767b3` relue. Branche `codex/landing-demos`, [PR #2](https://github.com/antoineberjoan/sema/pull/2). Checkout canonique et travaux natifs préservés.

## Intention et périmètre

Antoine rejette les trois présentations précédentes, demande la commande Homebrew visible et copiable comme chez Monocle, le retrait de la ligne de compatibilité sous le téléchargement, puis la suppression de la page de téléchargement. Il évoque une vidéo motion comme nouvelle piste, puis choisit des composants animés dans l’esprit de Monocle et Superwhisper plutôt qu’une vidéo (18 octobre 2026). Ces retraits sont demandés.

Le CTA télécharge le DMG existant. La release reste 0.5.1. À la demande suivante d’Antoine, le cask public est renommé `sema-app` et la commande `brew install --cask sema-app` est testée réellement. Sur un Mac neuf, elle nécessite de préparer notre tap et d’approuver ce cask précis ; Antoine demande ensuite de retirer toute cette aide de la landing : seule la commande courte y reste affichée et copiable. La préparation demeure dans la documentation technique. `/download/` ne sert plus de page ; seul son manifeste JSON existant est conservé.

## Scènes animées

Décision du 18 octobre 2026 : la vidéo de 18 secondes est supprimée (MP4, poster et `scripts/render-demo.swift`). La landing montre deux scènes d’interface dessinées en HTML, SVG et CSS.

| Scène | Mise en scène |
| --- | --- |
| Le bandeau | Titre centré. Un pouls part du signe, quatre cartes se déploient depuis lui avec un léger rebond ; chaque courbe se trace dans le ton d’un thème (Bleu ciel, Lavande, Menthe, Sarcelle) et s’achève sur un point. |
| La recherche | Composition inversée. ⌘K en grand s’enfonce, puis la fenêtre jaillit ; saisie d’euro, trois résultats balayés de gauche à droite, sélection en Bleu ciel (sans bordure) qui descend jusqu’à euro / franc suisse, avec les badges ↓ naviguer et ↵ ouvrir, puis la fenêtre cède la place à l’écran du repère, répliqué fidèlement : durées, valeur, variation, courbe et graduations, étoile, bouton d’inversion, alerte. Un pointeur clique l’inversion : l’écran passe de euro / franc suisse (0,9341 CHF) à franc suisse / euro (1,0705 EUR) après une pause de lecture, puis reste affiché environ 3 s avant la boucle. Sans animation, seul l’écran du repère est affiché. |

Chaque scène joue à l’entrée dans l’écran ; la recherche se rejoue en boucle, après une pause et un fondu, tant qu’elle est visible (décision d’Antoine, 18 octobre 2026). « Réduire les animations » ou l’absence de script affichent l’état final. Aucune légende « illustration » (demande d’Antoine, 18 octobre 2026). Description accessible par scène. Les durées vivent dans `tokens.css`. La commande Homebrew se copie sans changer de largeur ; un échec de presse-papiers sélectionne le texte pour une copie manuelle.

## Critères et preuves

- Commande courte exacte issue du manifeste, typographie légère, copie au clic et au clavier avec retour « copié ». Le statut de disponibilité Homebrew reste distinct de la copie du texte.
- Aucun lien interne vers la page supprimée ; le générateur ne recrée ni cette page ni la ligne sous le CTA.
- Scènes lisibles, jouées à l’entrée dans l’écran, la recherche en boucle visible ; état réduit et sans script identiques à l’état final.
- Largeur mobile 390 px sans débordement, liens de téléchargement identiques dans le hero et le header, FAQ, Ko-fi et liens légaux conservés.
- Diff ciblé, syntaxe, génération reproductible et vérification du manifeste sans altérer l’artefact publié.

## Résultats de revue

Ajustement demandé ensuite par Antoine : commande Homebrew en graisse 300 et taille maximale 18 px. Il confirme vouloir afficher `brew install --cask sema-app`. Antoine demande ensuite explicitement le snippet copiable puis son fonctionnement réel. Le cask public est maintenant `sema-app` dans `antoineberjoan/sema`, commit `588119d`, avec un fichier de migration depuis l’ancien nom. Antoine refuse une adhésion Apple Developer : aucune intégration officielle ni notarisation n’est annoncée. Le nom court est opérationnel après préparation de notre tap, pas sur un Mac neuf sans cette préparation. Le manifeste active Homebrew après les essais d’installation 0.5.1 et de mise à jour réelle 0.5.0 → 0.5.1 dans un dossier temporaire. Signature vérifiée, quarantaine préservée ; aucun lancement Internet. [Preuves](../validation/homebrew-sema-app.json).

La copie conserve exactement la commande affichée ; aucune commande de préparation ni nom de compte ne s’ajoute au snippet. Le générateur a été vérifié pour l’idempotence, les commandes du manifeste, le refus d’activation sans preuve et la conservation de la page de téléchargement supprimée.
- Aperçu du commit `7f146cc` READY : déploiement `dpl_GVREFav48TUDvVuai6aD8gdPwNNm`. Copie exacte observée au clic et avec Entrée ; presse-papiers restauré après le test. CTA hero et header pointent vers le même DMG existant.
- Scènes observées dans le navigateur local, 18 octobre 2026 : desktop 1280 px et mobile 390 px sans débordement horizontal ; saisie, résultats et sélection chronométrés ; « réduire les animations » émulé, toutes les scènes déjà terminées et aucune animation active. Vidéo, poster et script de rendu supprimés.
- Contrôles isolés : copie et son repli manuel (revue du 17 octobre 2026). Le macOS Réduire les animations réel n’a pas été activé ; l’émulation navigateur l’a été.
- Générateur : états actif et inactif, idempotence, refus de marqueurs manquants et de Homebrew non validé sans écriture partielle. Aucune page ou ligne de compatibilité recréée. IDs, ARIA, fichiers locaux, syntaxe et diff contrôlés.
- `./scripts/check.sh` local bloqué par l’absence du module Swift Testing dans les Command Line Tools ; aucun réglage modifié. CI du commit `7f146cc` verte, runs `39038508038` et `39038513859` (tests et bundle).
- Captures : `sema-landing-motion-desktop.png`, `sema-landing-motion-mobile.png` dans les artefacts du chat. Décisions de retrait et statut de proposition vidéo reportés dans Notion Marque.

Alignement du 18 octobre 2026 : Notion Marque (vocabulaire métier, deux animations, décisions tranchées) et Produit (13 repères préconfigurés) mis à jour. Le repère `fr10` s’appelle « OAT France · 10 ans » (public CGP) ; les 13 repères de départ sont intacts (`starterIDs`). Boucle de la recherche relue dans le navigateur local : fondu puis relance observés ; mobile et lecture à l’œil restent à vérifier.

Prochaine action : présenter l’aperçu à Antoine ; attendre sa décision de publication. La production n’est pas modifiée par cette branche.

Contrôle du cask actif : aperçu du commit `7ebfcaa`, READY (`dpl_4XNeHnuBEDHYHHMw1mhHdv8xRWHP`). La copie au clic donne exactement `brew install --cask sema-app`, presse-papiers restauré ; le bloc de préparation a ensuite été retiré à la demande d’Antoine. La CI de ce commit passe (runs `39043607398` et `39043603762`).
