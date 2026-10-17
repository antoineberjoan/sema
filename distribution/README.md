# Distribution publique

Les sources de l’app et du site sont versionnées dans le dépôt privé `antoineberjoan/sema`. Le site public est [getsema.app](https://getsema.app/). Le tap [antoineberjoan/homebrew-sema](https://github.com/antoineberjoan/homebrew-sema) reste public pour permettre les téléchargements et les installations Homebrew sans compte GitHub.

`Casks/sema.rb` est la copie versionnée du cask public. Toute nouvelle version doit mettre à jour les deux dépôts avec le même DMG immuable, le même SHA-256 et le même manifeste `site/dist/download/release.json`. Voir [le guide de distribution](../docs/DISTRIBUTION.md).
