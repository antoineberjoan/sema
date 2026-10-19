# Landing sema

Site statique HTML, CSS et JavaScript, sans dépendance ni compilation. `dist/` contient la landing et le guide de marque. Le CTA télécharge directement le DMG publié ; aucune page de téléchargement intermédiaire. `scripts/distribution/sync-download.py` synchronise ce lien, la commande Homebrew copiable et le manifeste JSON `download/release.json` à partir de `distribution/release.json`. Le dossier `download/` ne contient que cette métadonnée. Le cask `sema-app` est publié et testé dans notre tap. La commande courte est seule affichée et copiable, à la demande d’Antoine. Sur un Mac neuf, elle nécessite notre tap ; la préparation technique reste documentée dans `distribution/README.md`. Aucune présence dans le catalogue officiel n’est annoncée.

## Scènes de présentation

La landing présente le produit avec deux mises en scène différentes, sans vidéo ni outil de rendu : le bandeau (les cartes se déploient depuis le signe de la barre des menus, chaque courbe prend le ton d’un thème sema), la recherche (⌘K, puis la fenêtre jaillit, la saisie, la sélection qui descend jusqu’à euro / franc suisse, puis l’écran du repère qui s’ouvre avec sa valeur et sa courbe). Chaque `[data-scene]` est armée par le script puis jouée quand 35 % de sa hauteur est visible ; la recherche (`data-loop`) se rejoue après une pause (`--scene-loop`) tant qu’elle reste à l’écran. Durées, délais, courbes et tons viennent de `dist/brand/tokens.css` (`--scene-*`, `--motion-*`, `--tone-*`). Avec « réduire les animations », sans script ou sans `IntersectionObserver`, tout s’affiche déjà terminé. Une description textuelle (`role="img"`) raconte chaque scène.

## Hébergement Vercel

- Espace : `antoine-berjoan` (`team_Ix6fhFBxNE3JxkJVjHneKDsS`).
- Projet : `sema` (`prj_7UXEqS57A2g9cXkTuvi5LzTllNan`).
- Adresse principale : `https://getsema.app/` ; le domaine reste enregistré chez Namecheap.
- Configuration statique : `vercel.json`, répertoire publié `dist`.
- `.vercel` est local et ignoré ; `.vercelignore` exclut les métadonnées Sites et les documents internes du transfert Vercel.

Le site est désormais versionné dans `site/` du dépôt public `antoineberjoan/sema`, sur `origin/main`. L’historique Sites est conservé dans Git.

Le projet Vercel est relié à `antoineberjoan/sema`, branche de production `main`, avec **Root Directory = `site`**. Chaque push sur `origin/main` déclenche le déploiement du site depuis `site/vercel.json` et publie `site/dist/`. Vérifier les tests et le contenu avant de pousser.

Les prévisualisations et domaines Vercel restent soumis à la protection du compte ; le domaine personnalisé sert la landing publique. Les réglages DNS attendus doivent être relus auprès de Vercel pour ce projet avant modification chez Namecheap ; conserver les enregistrements de messagerie.

## Source existante

Le projet Sites d’origine et son identité `.openai/hosting.json` sont conservés. Ce manifeste ne déploie pas vers Vercel. La source de référence est `origin/main` du dépôt sema. L’identité du projet Sites existant est conservée pour une reprise éventuelle ; ce transfert de sources ne modifie pas sa publication. Le déploiement Vercel utilise l’intégration GitHub de `main` avec le dossier racine `site/`. Le précédent site Sites conserve sa publication et son audience tant qu’une publication explicite n’y est pas demandée.
