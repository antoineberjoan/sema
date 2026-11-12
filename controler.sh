#!/bin/sh
# Le lanceur unique de sema : les contrôles rapides, à l'édition, avant le push et pour tout agent.
# Il s'arrête au premier échec. La suite Swift (swift test, build-app.sh) tourne en CI, pas ici.
# Les outils de Sophos se lancent depuis un clone de Sophos : la variable SOPHOS, ../sophos par défaut.
set -eu
cd "$(dirname "$0")"
sophos="${SOPHOS:-../sophos}"
if [ ! -f "$sophos/outils/jetons.mjs" ]; then
    echo "Sophos absent : cloner antoineberjoan/sophos à côté de ce dépôt, ou définir SOPHOS." >&2
    exit 1
fi
python3 scripts/guardrails.py
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s scripts/tests -p 'test_*.py'
node "$sophos/outils/jetons.mjs" Resources/Brand/tokens.json --verifier
node "$sophos/outils/carte.mjs" --verifier
node "$sophos/outils/structure.mjs"
node "$sophos/outils/politique.mjs" --verifier
node .claude/sophos/garde.mjs --verifier
