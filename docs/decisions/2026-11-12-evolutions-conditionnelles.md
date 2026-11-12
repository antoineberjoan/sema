# On n'ajoute un cadre qu'au moment où un besoin réel le demande

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine (reprise d'un document retiré)

## Contexte

sema est petit. Un cadre construit à l'avance coûte de la lecture et de l'entretien sans servir.

## Décision

- Un fournisseur supplémentaire entre seulement quand son contrat de données et ses droits sont validés.
- Une interface commune aux fournisseurs n'est ajoutée que si plusieurs implémentations doivent réellement se remplacer.
- SwiftData n'est envisagé que si le volume ou les requêtes locales le justifient. Une migration devra préserver les préférences existantes.
- Un projet Xcode d'app n'est ajouté que si la distribution, les ressources ou les droits le rendent utile. Le package Swift et le script de bundle sont la source de compilation actuelle.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Attendre le besoin réel | Un code court, proche de l'usage | Un changement plus tard, avec sa migration |
| Construire le cadre d'avance | Prêt pour la suite | Du code sans usage à entretenir |

## Conséquences

Même esprit que la décision `interface-native-et-dependances`.

## Trace

Repris de `docs/ARCHITECTURE.md` à son retrait, le 2026-11-12. La date d'origine n'est pas écrite : le texte complet reste dans l'historique Git.
