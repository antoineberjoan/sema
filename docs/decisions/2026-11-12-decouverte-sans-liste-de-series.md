# L'interface lit les catalogues publics ; elle n'a pas de liste autorisée de séries

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine (reprise d'un document retiré)

## Contexte

sema consulte des séries publiées par des producteurs (Insee, BCE, Eurostat, BRI, OCDE, Banque de France, FRED, Banque mondiale, New York). La liste évolue chez eux.

## Décision

- L'app découvre les catalogues, leur structure et leurs séries publiées, puis charge un seul repère à la fois. Aucune liste de séries n'est écrite dans le code, hors les séries de départ et les fixtures identifiées.
- Une clé personnelle est ajoutée seulement à l'envoi de la requête (en-tête `Authorization`, ou `api_key` pour FRED). Elle ne va jamais dans un fichier, un cache, une URL ou le binaire. Aucun secret Webstat n'est transmis à une autre source.
- Les observations restent en `Decimal`, avec leur échelle source. Les unités inconnues restent consultables, mais un seuil exige une unité explicitement traduite et son échelle.
- Un changement d'unité, de multiplicateur ou de base d'indice empêche de fusionner l'ancien et le nouvel historique : les alertes concernées sont mises en pause avant toute évaluation.
- Les contrats de chaque source sont dans `docs/DATA-SOURCES.md`, `docs/PUBLIC-CATALOGUES.md` et `docs/PERSONALIZATION.md`.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Lire les catalogues, charger un repère | Aucune liste à tenir ; le producteur reste la source | Des réponses de catalogue à valider et à borner |
| Liste fixe de séries autorisées | Un contrôle total | Une liste à tenir à jour sans fin |

## Conséquences

Les réponses de catalogue sont bornées (20 Mio en lecture progressive) et refusées si elles sont tronquées. Les détails de code restent dans les fichiers concernés.

## Trace

Repris de `docs/ARCHITECTURE.md` à son retrait, le 2026-11-12. La date d'origine n'est pas écrite : le texte complet reste dans l'historique Git.
