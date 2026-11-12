# Un profil neuf ne suit rien et l'app n'affiche aucune valeur inventée

Date : 2026-10-18 · Statut : acceptée
Décidé par : Antoine

## Contexte

Un repère sans donnée réelle ne doit pas ressembler à une mesure. Une sélection de départ suivie d'office donne l'impression que sema a choisi à la place de la personne.

## Décision

- Un profil neuf ne suit aucun des seize repères de départ : ils sont proposés décochés à l'accueil.
- Aucune valeur fictive n'apparaît dans l'app. Seul l'aperçu du bandeau de l'accueil montre des exemples fictifs, annoncés comme tels.
- Avant connexion, un repère choisi n'a pas d'observation : son détail dit « Pas encore de données » et mène à la connexion Webstat.
- La landing du site n'affiche aucune légende « illustration ».

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Rien de suivi, aucune valeur inventée | Aucune confusion entre exemple et mesure | Un premier écran vide tant que Webstat n'est pas connecté |
| Une sélection suivie d'office, avec des valeurs d'exemple | Un premier écran plein | Des chiffres qui ne sont pas des mesures |

## Conséquences

Les exemples du bandeau d'accueil sont identifiés dans le texte et dans le libellé d'accessibilité.
