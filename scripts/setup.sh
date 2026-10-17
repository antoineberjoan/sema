#!/bin/bash
# Active les contrôles Git de ce dépôt sans écraser une configuration de hooks existante.
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_root"
hooks_path="$(git config --get core.hooksPath || true)"
if [[ -n "$hooks_path" && "$hooks_path" != ".githooks" ]]; then
    echo "Hooks existants : $hooks_path. Intégrer le contrôle sema avant de remplacer cette configuration." >&2
    exit 1
fi
git config --local core.hooksPath .githooks
echo "Hook pre-commit activé pour sema. La CI reste indépendante des hooks locaux."
