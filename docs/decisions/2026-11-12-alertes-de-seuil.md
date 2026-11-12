# Une alerte de seuil se déclenche au franchissement strict, avec un point de départ enregistré avant l'envoi

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine (reprise d'un document retiré)

## Contexte

Une alerte qui se répète ou qui part sur un historique ancien perd la confiance de la personne. Le moteur doit être testable et indépendant de l'envoi de notification.

## Décision

- Le seuil est une valeur absolue dans l'unité du repère : 3,5 % pour un taux, pas une hausse relative de 3,5 %. Zéro et les seuils négatifs sont permis.
- Le franchissement est strict : de ≤ seuil vers > seuil, ou de ≥ seuil vers < seuil. Rester au-delà ne redéclenche pas.
- Une nouvelle règle prend la dernière observation réelle comme point de départ. Une première connexion après création en démonstration établit ce point sans signal historique. La réactivation reprend à la dernière observation.
- Chaque paire d'observations nouvelle depuis `lastEvaluatedAt` est évaluée, franchissements intermédiaires compris. Une révision d'une date déjà traitée n'envoie rien.
- Le point de départ est enregistré avant l'envoi système. Si l'enregistrement échoue, rien n'est envoyé. Aucune nouvelle tentative après un échec de livraison.
- Les mouvements inhabituels et les seuils d'une même vérification partent dans une seule notification groupée. Le brief du matin est noté envoyé avant son envoi.
- La surveillance tourne avec l'app, y compris quand le hub est fermé. Elle est suspendue en veille et arrêtée à la sortie. Aucun serveur, aucun réveil forcé du Mac. Une surveillance indépendante du Mac exigerait un service côté serveur.
- Une simulation explicite reste possible et ne change pas le point de départ réel.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Franchissement strict, point de départ enregistré d'abord | Pas de doublon ; pas de signal sur le passé | Un envoi raté n'est pas rejoué |
| Notifier tant que le seuil est dépassé | Aucun signal manqué | Des alertes répétées |

## Conséquences

La règle est testée dans `Tests/MarketCoreTests` (évaluation pure). `docs/PRODUCT.md` décrit ce que la personne voit.

## Trace

Repris de `docs/ARCHITECTURE.md` à son retrait, le 2026-11-12. La date d'origine n'est pas écrite : le texte complet reste dans l'historique Git.
