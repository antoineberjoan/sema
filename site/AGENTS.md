# Site sema

- Lire aussi l’entrée commune `../AGENTS.md`. Pour un design, un texte visible ou un mouvement, appliquer le skill `concevoir` de Sophos ; les décisions de marque sont dans `../docs/fondation.md` et `../docs/decisions/`.

- Le circuit de publication courant est GitHub `main` vers Vercel, décrit dans `README.md`. Une fusion ou un push vers `main` publie le site et exige une autorisation couvrant cette action.
- Appliquer Interface Craft aux choix de design et de mouvement via `concevoir` ; lire aussi le guide `dist/brand/` avant une modification visuelle.
- Toute valeur visuelle du site vit dans `tokens.json` (ce dossier). `dist/brand/site-tokens.css` en est fabriquée par `jetons.mjs` : ne pas la modifier à la main. Les cinq couleurs de la marque se lisent dans `dist/brand/sophos-tokens.css`, fabriquée depuis `../Resources/Brand/tokens.json`. Ajouter une valeur : la nommer par son usage dans `tokens.json`, puis lancer `jetons.mjs`. `<meta name="theme-color">` vaut le rôle `page`.
- La charte du 8 novembre est l’identité du site : Encre, Graphite, Papier, Brume et Sarcelle profonde, avec le logo « repère » (une ligne qui se pose sur un point sarcelle). Le site reste sombre ; son accent est la Sarcelle claire. Les six palettes personnelles restent proposées dans le guide. Décision d’Antoine du 9 novembre : seuls le logo et la charte changent, ni textes ni mise en page.
- Hiérarchie nette, espaces cohérents, ombres discrètes et typographie système. Les animations ont des constantes nommées, restent interruptibles et respectent Réduire les animations.
- Garder les noms financiers précis, avec source et fréquence. L’OAT française à dix ans (emprunt phare, publié mensuellement) est distincte du TEC 10. Dans l’app, les exemples fictifs restent identifiés ; la landing n’affiche aucune légende « illustration » (décision d’Antoine, 18 octobre 2026).
- Vérifier au clavier et dans le navigateur lorsque l’accès est disponible ; ne pas présenter un contrôle bloqué comme réalisé.
