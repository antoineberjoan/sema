#!/bin/sh
# Le lanceur unique de sema : les mêmes contrôles à l'édition, avant le push et pour tout agent.
# Il s'arrête au premier échec. Les tests Swift demandent macOS : ailleurs, il le dit et ne les lance pas.
set -eu
cd "$(dirname "$0")"
python3 scripts/guardrails.py
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s scripts/tests -p 'test_*.py'
if [ "$(uname)" = "Darwin" ]; then
    ./scripts/check.sh
else
    echo "Tests Swift non lancés : ils demandent macOS (./scripts/check.sh)."
fi
