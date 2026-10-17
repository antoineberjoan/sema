# App native

- macOS 14+, Swift 6, SwiftUI natif ; AppKit uniquement pour un comportement macOS précis. Préférer les composants Apple.
- Les mises à jour UI ont lieu sur le `MainActor`. Fenêtre et bandeau partagent `AppStore`, sans deuxième état métier.
- `App` orchestre, `Features` présente et émet les actions, `DesignSystem` porte les choix et composants partagés, `Infrastructure` porte les effets macOS. Ne pas déplacer un calcul métier dans une vue.
- Pour le design, les textes visibles et le mouvement, appliquer `.agents/skills/sema-design/SKILL.md` et lire `docs/IDENTITY.md`. Interface Craft s’applique sans importer ses dépendances React dans Swift.
- Animations à constantes nommées, interruptibles, compatibles avec Réduire les animations. Respecter aussi Réduire la transparence et Augmenter le contraste.
- Notifications désactivées jusqu’à activation par l’utilisateur. La démonstration des alertes n’est pas un service de surveillance ; aucune promesse de suivi app quittée ou Mac en veille.
- Vérifier le flux touché dans le bundle natif : sélection, favoris, historique, réglage ou alerte. Une compilation ou une capture seule ne valide pas une interaction.
