# Distribution publique

Les sources de l’app et du site sont versionnées dans le dépôt public `antoineberjoan/sema`. Le site public est [getsema.app](https://getsema.app/). Le tap [antoineberjoan/homebrew-sema](https://github.com/antoineberjoan/homebrew-sema) reste public pour permettre les téléchargements et les installations Homebrew sans compte GitHub.

`Casks/sema-app.rb` est la copie versionnée du cask public. Toute nouvelle version doit mettre à jour les deux dépôts avec le même DMG immuable, le même SHA-256 et le même manifeste `site/dist/download/release.json`. Voir [le guide de distribution](../docs/DISTRIBUTION.md).

Le nom `sema-app` est publié dans ce tap. Sur un Mac neuf, préparer le tap et approuver ce cask une fois avant la commande courte :

```sh
brew tap antoineberjoan/sema
brew trust --cask antoineberjoan/sema/sema-app
brew install --cask sema-app
```

`cask_renames.json` associe l’ancien nom `sema` au nouveau. Il ne s’agit pas d’une inclusion au catalogue officiel Homebrew. La signature ad hoc et les contrôles de macOS restent inchangés.
