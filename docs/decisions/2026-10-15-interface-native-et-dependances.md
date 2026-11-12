# L'interface est native et sans dépendance de production

Date : 2026-10-15 · Statut : acceptée
Décidé par : Antoine

## Contexte

La première version de sema (0.1) a besoin d'une interface Mac cohérente. Un kit de composants externe ou un framework d'architecture apporterait des pièces toutes faites, mais lierait l'app à leur cycle de vie.

## Décision

sema utilise SwiftUI, AppKit, Swift Charts, Observation, la police système (SF Pro) et SF Symbols. Aucun framework de composants ou d'architecture externe n'est nécessaire. Le logo est un dessin original, distinct des symboles SF Symbols des actions.

La cohérence vient de quelques composants internes partagés : marque, badge de source, tuile, favori, surface et historique. Ils suivent les contrôles et les comportements de macOS.

Toute nouvelle dépendance répond à un besoin observé et reçoit l'accord d'Antoine avant son ajout.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Les frameworks Apple seuls | Une app native, sans dépendance à maintenir | Plus de code à écrire pour un besoin précis |
| Une bibliothèque par besoin (KeyboardShortcuts, Sparkle, SwiftUI Introspect, Settings) | Un raccourci global, des mises à jour ou un réglage AppKit déjà faits | Une dépendance de production à suivre |

## Conséquences

Aucune bibliothèque examinée n'est ajoutée : la scène native `Settings` suffit. Si un besoin réel apparaît, Antoine décide, et cette décision est remplacée par une nouvelle.

## Trace

Reprise d'ADR 001 (statut « retenu pour la version 0.1 »). Date : celle du premier commit qui la porte. Renommée au format de Sophos lors de l'alignement.
