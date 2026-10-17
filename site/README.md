# Landing sema

Site statique HTML, CSS et JavaScript, sans dépendance ni compilation. `dist/` contient le site, l’aide d’installation et le guide de marque. Le CTA de la landing pointe directement vers le DMG publié ; `/download/` reste une aide facultative. `scripts/distribution/sync-download.py` synchronise les deux CTA et leurs métadonnées à partir de `distribution/release.json`. Les liens Homebrew et de première ouverture ciblent les réponses correspondantes de l’aide.

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
