# La signature du bandeau pose son texte sur un dégradé dont le contraste n'est pas mesuré

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine

## Contexte

La signature du bandeau est un dégradé fait de pas de l'accent, avec du texte, un tracé et un bord posés dessus. La mesure de contraste de Sophos compare deux couleurs unies ; elle ne couvre pas un dégradé.

## Décision

Le texte, le tracé et le bord lisent `on-accent`, le rôle « texte posé sur un aplat d'accent ». Les opacités du dégradé et du texte sont six rôles de `Resources/Brand/tokens.json` (`opacity.signature-…`). C'est un écart au patron : le contraste des deux extrémités du dégradé n'est mesuré par aucun outil.

## Conséquences

Le contraste se regarde sur le Mac, aux deux extrémités du dégradé, en clair et en sombre. **Condition de retrait** : Sophos mesure le contraste d'un texte sur un dégradé, ou la signature devient un aplat.
