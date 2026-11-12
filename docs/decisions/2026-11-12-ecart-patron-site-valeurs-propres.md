# Le site lit les cinq couleurs de la marque dans les jetons et garde ses autres valeurs

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine (arbitrage de l'architecte du 2026-11-12)

## Contexte

Le site est un site statique sombre, avec sa feuille de valeurs écrite à la main (`site/dist/brand/tokens.css`, environ 150 variables : gris, échelle de texte, largeurs, durées des scènes de la landing). Le patron de Sophos veut une seule source de valeurs, `tokens.json`, dont une sortie CSS est fabriquée. Le 9 novembre, Antoine a décidé que seuls le logo et la charte changent sur le site, ni les textes ni la mise en page.

## Décision

- `Resources/Brand/tokens.json` fabrique une sortie CSS, `site/dist/brand/sophos-tokens.css` (`jetons.mjs`, vérifiée par `--verifier` comme la sortie Swift).
- La feuille du site l'importe et lit **les cinq couleurs de la marque** dans ses primitives : Encre, Graphite, Papier, Brume, Sarcelle (claire et profonde). Les valeurs sont identiques à celles écrites avant ; elles n'ont plus qu'une source.
- **Le reste de la feuille du site reste écrit à la main** : les vingt gris, l'échelle de texte, les largeurs et les durées des scènes. Ces valeurs ne sont pas des rôles du patron, et les passer dans `tokens.json` changerait l'apparence du site (les gris du site ne sont pas ceux des échelles de Sophos).
- `guardrails.py` ne lit pas la feuille fabriquée comme une feuille du site (ses variables et ses classes de rôle ne se contrôlent pas de la même manière).

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Lier les cinq couleurs, garder le reste | Une seule source pour la marque, aucune apparence qui change | Une feuille à la main de 140 valeurs reste écrite |
| Tout lire dans `tokens.json` | Le site entier sur les jetons | Des gris, des tailles et des largeurs qui changent : une décision de mise en page d'Antoine |
| Ne rien changer | Aucun risque | Les couleurs de la marque écrites en deux endroits |

**Ce qui retire l'écart** : Antoine ouvre un chantier visuel du site. Ce chantier décide alors de ses gris et de son échelle.

## Conséquences

Un écart reste : le kit de marque téléchargeable (`site/dist/brand/tokens.json`) garde sa propre liste de couleurs, dans un autre format. Il se règle quand le kit est fabriqué depuis la sortie `resolved-json` des jetons. Ce qui retire l'écart du site : une décision d'Antoine sur ses gris et son échelle, puis leur passage dans `tokens.json` (rôles de couleur, jetons de type `css` pour les tailles fluides et les durées).

## Trace

Dernier lot de l'alignement de sema sur Sophos. Les pages de la landing et du guide n'ont pas été rendues ici : la vérification visuelle est à faire dans un navigateur.
