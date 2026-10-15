# ADR 001 — Interface native et dépendances ciblées

Statut : retenu pour la version 0.1.

## Décision

Utiliser SwiftUI, AppKit, Swift Charts, Observation, SF Pro via la police système et SF Symbols. Aucun framework de composants ou d’architecture externe n’est nécessaire à cette version. Le logo est un dessin original, distinct des SF Symbols utilisés pour les actions.

La cohérence vient de quelques composants internes utilisés dans plusieurs fonctionnalités : marque, badge de source, tuile, favori, surface et historique. Ils suivent les contrôles et comportements macOS.

## Bibliothèques examinées pour la suite

| Bibliothèque | Usage précis possible | État |
| --- | --- | --- |
| [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) | Raccourci global personnalisable avec composant natif d’enregistrement. | Non ajoutée. |
| [Sparkle](https://github.com/sparkle-project/Sparkle) | Mises à jour d’une distribution directe macOS. | Non ajoutée. |
| [SwiftUI Introspect](https://github.com/siteline/swiftui-introspect) | Ajustement ponctuel d’un composant AppKit sous-jacent si SwiftUI ne donne pas accès au comportement nécessaire. | Non ajoutée. |
| [Settings](https://github.com/sindresorhus/Settings) | Fenêtres de réglages AppKit/SwiftUI plus spécifiques. | La scène native `Settings` suffit actuellement. |

Toute nouvelle dépendance doit répondre à un besoin observé et être approuvée avant son ajout.
