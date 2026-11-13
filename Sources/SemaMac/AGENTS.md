# App native

- macOS 14+, Swift 6, SwiftUI natif ; AppKit uniquement pour un comportement macOS précis. Préférer les composants Apple.
- Les mises à jour UI ont lieu sur le `MainActor`. Fenêtre et bandeau partagent un seul état : `docs/decisions/2026-11-12-etat-partage.md`.
- `App` orchestre, `Features` présente et émet les actions, `Components` porte les composants partagés, `Common` porte ce que plusieurs écrans partagent (formats d'affichage), `Infrastructure` porte les effets macOS. Les jetons de design viennent du module `SemaDesign`. Ne pas déplacer un calcul métier dans une vue.
- Pour le design, les textes visibles et le mouvement, appliquer le skill `concevoir` de Sophos et lire les décisions de direction visuelle dans `docs/decisions/`.
- Animations à constantes nommées, interruptibles, compatibles avec Réduire les animations. Respecter aussi Réduire la transparence et Augmenter le contraste.
- Notifications désactivées jusqu’à activation par l’utilisateur. Les alertes ne sont pas un service de surveillance : aucune promesse de suivi app quittée ou Mac en veille.
- Vérifier le flux touché dans le bundle natif : sélection, favoris, historique, réglage ou alerte. Une compilation ou une capture seule ne valide pas une interaction.
