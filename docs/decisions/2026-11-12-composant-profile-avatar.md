# L'avatar du profil dessine ses initiales à une taille proportionnelle à la sienne

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine

## Contexte

L'avatar du profil local existe en plusieurs tailles : 28 points dans les réglages, 32 points dans la barre latérale, plus grand dans le profil. Ses initiales et son symbole de repli doivent suivre cette taille.

## Décision

Le composant est gardé avec cet écart à la référence (SwiftUI).

| Ce que la page de la référence décrit | Ce que le code fait | Pourquoi |
| --- | --- | --- |
| `Image` (https://developer.apple.com/documentation/swiftui/image) : une image ou un symbole, avec une police de rôle | Un cercle qui montre la photo, sinon les initiales, sinon un symbole, avec une police de **taille proportionnelle** à celle du cercle (34 % et 40 %) | Aucun rôle de texte du patron n'est proportionnel à une taille donnée en paramètre |

**Ce qui retire l'écart** : une taille d'avatar fixe par usage (un rôle de texte chacune), ou un rôle de texte proportionnel dans le patron.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Police proportionnelle écrite dans le composant | Un avatar de n'importe quelle taille | Une police qui n'est pas un rôle |
| Trois tailles fixes avec trois rôles | Que des rôles | Trois cas à tenir, une taille de moins pour l'usage futur |

## Conséquences

C'est le seul `.font(...)` écrit à la main qui reste dans l'app, avec le chevron de `RowDisclosureStyle` qui lit maintenant le rôle `caption`. Le fond du cercle lit le texte à l'opacité `glass-rest` : l'avatar est dans la barre latérale ouverte comme dans son aperçu en verre.

## Trace

Relecture finale de l'alignement de sema sur Sophos.
