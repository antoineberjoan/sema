# Landing sema

Site statique HTML, CSS et JavaScript, sans dépendance ni compilation. `dist/` contient le site, le téléchargement et le guide de marque.

## Hébergement Vercel

- Espace : `antoine-berjoan` (`team_Ix6fhFBxNE3JxkJVjHneKDsS`).
- Projet : `sema` (`prj_7UXEqS57A2g9cXkTuvi5LzTllNan`).
- Adresse principale : `https://getsema.app/` ; le domaine reste enregistré chez Namecheap.
- Configuration statique : `vercel.json`, répertoire publié `dist`.
- `.vercel` est local et ignoré ; `.vercelignore` exclut les métadonnées Sites et les documents internes du transfert Vercel.

Depuis ce dossier, vérifier le propriétaire et le projet avant toute publication :

```sh
vercel project inspect --non-interactive
vercel deploy --prod --skip-domain --scope antoine-berjoan
# Vérifier ce déploiement, puis promouvoir son URL exacte :
vercel promote URL_DU_DEPLOIEMENT --scope antoine-berjoan
```

Les prévisualisations et domaines Vercel restent soumis à la protection du compte ; le domaine personnalisé sert la landing publique. Les réglages DNS attendus doivent être relus auprès de Vercel pour ce projet avant modification chez Namecheap ; conserver les enregistrements de messagerie.

## Source existante

Le projet Sites d’origine et son identité `.openai/hosting.json` sont conservés. Ce manifeste ne déploie pas vers Vercel. La source reste dans le dépôt Sites existant ; aucune intégration GitHub automatique n’est créée par le déploiement CLI. Le précédent site Sites conserve sa publication et son audience tant qu’une publication explicite n’y est pas demandée.
