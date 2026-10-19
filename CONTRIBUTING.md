# Contribuer à sema

Un bug reproductible, une correction de documentation ou une amélioration ciblée sont des contributions utiles. Pour un changement de périmètre ou une dépendance, ouvrir d’abord une issue décrivant le besoin et le résultat attendu.

## Commencer

Lire [AGENTS.md](AGENTS.md), puis les instructions de la zone concernée. Elles restent la source unique des conventions. Les pages privées du mainteneur ne sont pas nécessaires pour signaler un bug ou proposer une correction technique ; décrire le besoin dans l’issue suffit. Le mainteneur arbitre les changements de direction.

Utiliser macOS 14+, Swift 6, Python 3.9+ et Xcode complet pour les tests Swift Testing. Cloner son fork, puis lancer :

```sh
./scripts/setup.sh
./scripts/check.sh
./scripts/build-app.sh
```

Le premier script active les hooks du clone. Les Command Line Tools seuls peuvent compiler l’app, mais leur environnement peut ne pas fournir Swift Testing. Ne pas considérer des tests non exécutés comme réussis.

## Proposer une modification

1. Créer une branche dans son fork et limiter le diff au problème décrit.
2. Ajouter une preuve pertinente pour un comportement corrigé ; pour une simple modification documentaire, lancer `python3 scripts/guardrails.py`.
3. Pour un changement fonctionnel, lancer `./scripts/check.sh`. Si l’app ou sa construction change, lancer aussi `./scripts/build-app.sh` et vérifier le parcours concerné dans le bundle.
4. Ouvrir une pull request avec le problème, le résultat, les commandes exécutées et les limites de vérification. Les captures doivent masquer toute information personnelle.

Ne joindre ni clé API, ni cache personnel, ni données client. Un assistant IA peut aider ; l’auteur de la contribution reste responsable du diff et de sa vérification. Les signalements de sécurité suivent [SECURITY.md](SECURITY.md).
