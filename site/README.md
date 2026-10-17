# Landing sema

Site statique HTML, CSS et JavaScript, sans dépendance ni compilation. `dist/` contient la landing et le guide de marque. Le CTA télécharge directement le DMG publié ; aucune page de téléchargement intermédiaire. `scripts/distribution/sync-download.py` synchronise ce lien, la commande Homebrew copiable et le manifeste JSON `download/release.json` à partir de `distribution/release.json`. Le dossier `download/` ne contient que cette métadonnée. Une commande `proposedCommand` non activée est affichée sans copie ; l’activation exige le cask opérationnel et ses validations.

## Démonstration motion

Une proposition vidéo silencieuse de 18 secondes montre le bandeau, la recherche et Focus, avec des valeurs d’illustration fixes. Les images sont dessinées par `scripts/render-demo.swift` ; ce ne sont pas des captures de l’app. Le MP4 et son poster sont versionnés dans `dist/assets/`. Leur génération utilise AppKit et ffmpeg en outils de développement, sans dépendance pour le site :

```sh
swiftc -O scripts/render-demo.swift -o /tmp/sema-render-demo
/tmp/sema-render-demo --poster /tmp/sema-demo-poster.png
ffmpeg -y -i /tmp/sema-demo-poster.png -q:v 2 site/dist/assets/sema-demo-poster.jpg
set -o pipefail
/tmp/sema-render-demo | ffmpeg -y -framerate 30 -f image2pipe -vcodec png -i - -an -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p -movflags +faststart site/dist/assets/sema-demo.mp4
```

Commandes depuis la racine du dépôt. Lecture automatique une seule fois à l’entrée dans l’écran, sans boucle ; pause à la sortie ou au masquage de la page. Réduire les animations conserve le poster et les contrôles natifs de lecture. La description textuelle accessible raconte la séquence et identifie les valeurs fictives.

## Hébergement Vercel

- Espace : `antoine-berjoan` (`team_Ix6fhFBxNE3JxkJVjHneKDsS`).
- Projet : `sema` (`prj_7UXEqS57A2g9cXkTuvi5LzTllNan`).
- Adresse principale : `https://getsema.app/` ; le domaine reste enregistré chez Namecheap.
- Configuration statique : `vercel.json`, répertoire publié `dist`.
- `.vercel` est local et ignoré ; `.vercelignore` exclut les métadonnées Sites et les documents internes du transfert Vercel.

Le site est désormais versionné dans `site/` du dépôt privé `antoineberjoan/sema`, sur `origin/main`. L’historique Sites est conservé dans Git.

Le projet Vercel est relié à `antoineberjoan/sema`, branche de production `main`, avec **Root Directory = `site`**. Chaque push sur `origin/main` déclenche le déploiement du site depuis `site/vercel.json` et publie `site/dist/`. Vérifier les tests et le contenu avant de pousser.

Les prévisualisations et domaines Vercel restent soumis à la protection du compte ; le domaine personnalisé sert la landing publique. Les réglages DNS attendus doivent être relus auprès de Vercel pour ce projet avant modification chez Namecheap ; conserver les enregistrements de messagerie.

## Source existante

Le projet Sites d’origine et son identité `.openai/hosting.json` sont conservés. Ce manifeste ne déploie pas vers Vercel. La source de référence est `origin/main` du dépôt sema. L’identité du projet Sites existant est conservée pour une reprise éventuelle ; ce transfert de sources ne modifie pas sa publication. Le déploiement Vercel utilise l’intégration GitHub de `main` avec le dossier racine `site/`. Le précédent site Sites conserve sa publication et son audience tant qu’une publication explicite n’y est pas demandée.
