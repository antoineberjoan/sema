#!/bin/bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_root"
export CLANG_MODULE_CACHE_PATH="$project_root/.build/ModuleCache"
export SWIFTPM_MODULECACHE_OVERRIDE="$project_root/.build/ModuleCache"
test_arguments=(--disable-xctest --disable-sandbox --scratch-path "$project_root/.build" --cache-path "$project_root/.build/cache" --config-path "$project_root/.build/configuration" --security-path "$project_root/.build/security")
swift test "${test_arguments[@]}"
bash -n scripts/build-app.sh
plutil -lint Resources/Info.plist
