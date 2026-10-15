# Sources et conventions

## Intégrées

### BCE — devises

- Page officielle : https://www.ecb.europa.eu/stats/policy_and_exchange_rates/euro_reference_exchange_rates/html/index.en.html
- Flux : https://www.ecb.europa.eu/stats/eurofxref/eurofxref-hist-90d.xml
- Séries utilisées : USD, JPY, CHF, exprimées **en unités de devise pour un euro**.
- Rythme : publications de taux de référence, pas temps réel.
- Période fournie : 90 jours environ ; la vue annuelle est désactivée pour ces séries.
- Origine : BCE, conservée avec la série ; date d’observation toujours affichée.
- En cas d’échec : aucune valeur n’est inventée. Le cache et les données déjà présentes sont conservés avec un message explicite.

### Démonstration

Toutes les autres valeurs et tous les fonds viennent de `DemoCatalog`. Leur date de référence est fixe. Ils portent `isDemo = true` et ne représentent aucun produit commercial réel.

Le « France · 10 ans » de démonstration n’engage aucun choix de série de production. Identifier précisément l’indice, le fournisseur et ses droits avant l’intégration.

## À intégrer après validation

| Donnée | Source envisagée | Point à résoudre |
| --- | --- | --- |
| Épargne réglementée | Banque de France / source officielle de la décision | Série correcte, date d’effet, accès API. |
| Taux directeur | BCE | Choix du taux et date d’effet distincte de la date de décision. |
| Inflation | Insee | Indice, périmètre, glissement annuel et révisions. |
| Repère obligataire | Fournisseur autorisé | Ne pas confondre TEC 10 et obligation OAT ; les conditions Euronext peuvent s’appliquer au TEC. |
| Fonds | Fournisseur à confirmer, éventuellement Morningstar | Licence, stabilité de l’API, identifiants des parts, devise, fréquence et historique. |

La gratuité de l’accès technique à une URL ne suffit pas à établir un droit de redistribution. Aucune clé fournisseur partagée ne doit être embarquée dans l’app.

## Conventions

- Les observations sont triées par date et dédupliquées à la construction de la série.
- Une publication de fonds conserve la part exacte et sa devise ; aucun ISIN fictif n’est présenté comme un identifiant réel.
- Les valeurs financières utilisent `Decimal`. Les graphiques convertissent ces valeurs en `Double` pour le dessin.
- Les taux varient en points de pourcentage ; les VL et parités en pourcentage relatif.
- La variation de VL n’est pas assimilée à une performance avec distributions réinvesties.
- Les dates de publication et d’effet devront être distinctes lorsque la source les fournit ; le modèle actuel décrit la date d’observation.
