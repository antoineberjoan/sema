# Sources d’autorité

Règle d’Antoine du 21 octobre 2026, commune à tous ses dépôts ([ADR 004](../decisions/004-autorite-notion-github.md)) : **Notion fait foi pour la vision, le ton, le branding, la marque, le business plan et la copy ; GitHub fait foi pour tout le technique** (code, configuration, architecture, conventions, décisions techniques, plans de réalisation, preuves). Les pages Notion sont des décisions et intentions humaines ; leur statut natif « non vérifié » ne constitue ni une approbation ni un rejet. Lire le contenu et l’arbitrage explicite.

| Sujet | Source canonique | Rôle du dépôt |
| --- | --- | --- |
| Navigation | [Accueil](https://app.notion.com/p/f56d18bb0dea83c198de015cb4e36319) | Ce répertoire de liens |
| Vision, public, business, priorités | [Stratégie](https://app.notion.com/p/3fbd18bb0dea819bad4bc31bca0ad436) | Conséquences techniques d’une décision validée |
| Périmètre souhaité, retours | [Produit](https://app.notion.com/p/3fbd18bb0dea81c7add6f4a31d033296) | `PRODUCT.md` décrit le contrat implémenté, pas une seconde roadmap |
| Marque, ton, copy, choix visuels | [Marque](https://app.notion.com/p/3fbd18bb0dea818fa7f4fc7483c767b3) | `IDENTITY.md`, assets et tokens appliquent les décisions |
| Organisation de l’équipe | [Équipe](https://app.notion.com/p/3fbd18bb0dea81c9b117c11a249e57df) | Aucune décision technique : elle vit dans le dépôt |
| Architecture, conventions, décisions techniques | Ce dépôt : `docs/ARCHITECTURE.md`, `docs/engineering/`, `docs/decisions/` | Fait foi ; `AGENTS.md` et les contrôles l’appliquent |
| Réalisation, suivi technique et livraison | Ce dépôt : `docs/plans/`, `docs/PLAN.md`, issues et PR de [GitHub sema](https://github.com/antoineberjoan/sema) | Fait foi ; une issue renvoie à la page Notion quand le besoin vient de la vision ou du produit |
| Données économiques | Producteur officiel référencé dans `DATA-SOURCES.md` | Décodage et calcul ; ne pas réécrire la définition officielle |

Le business plan n’est pas encore établi dans les pages consultées. Ne pas inventer prix, revenus ou décision de monétisation. Les retours et leur qualification restent suivis dans Notion. Une issue GitHub peut porter leur réalisation et renvoyer à cette source, sans créer un second backlog ni recopier les informations personnelles.

## Passage de l’intention à la réalisation

Un besoin de produit, de marque ou de copy part de la page Notion qui le porte : l’issue, la PR ou le plan la cite avec sa date de lecture. Tout le reste de la réalisation (choix techniques, conventions, architecture, suivi des étapes) se décide et se consigne dans le dépôt : plan dans `docs/plans/`, décision durable dans `docs/decisions/`. Un lien ou une courte citation suffit ; ne pas exporter Notion dans Git.

À la livraison, Git garde la preuve et le comportement effectif. Si la livraison change ce que Notion décrit du produit ou de la marque (une fonctionnalité visible, une copy), signaler la page à mettre à jour à Antoine. Pas de synchronisation automatique.

Si Notion est inaccessible, le travail technique continue ; une décision de produit, de marque ou de copy non couverte attend Antoine ou le retour de la page. Un agent ne crée pas une vérité de remplacement.

## Divergences

Présenter les deux versions, leur source et leur impact ; demander **la version à garder** avant d’aligner. Ne pas déduire une priorité de la date ou de l’existence de code. Les écarts en cours d’arbitrage sont consignés dans le plan du chantier, pas recopiés ici.
