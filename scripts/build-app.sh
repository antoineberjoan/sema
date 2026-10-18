#!/bin/bash
# Construit le bundle macOS local, ses ressources et sa signature ad hoc.
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_root"
configuration="${SEMA_CONFIGURATION:-release}"
destination="${1:-$project_root/build/Sema.app}"
if [[ "$destination" != *.app ]]; then
    echo "La destination doit se terminer par .app" >&2
    exit 1
fi

export CLANG_MODULE_CACHE_PATH="$project_root/.build/ModuleCache"
export SWIFTPM_MODULECACHE_OVERRIDE="$project_root/.build/ModuleCache"
swift_arguments=(--configuration "$configuration" --disable-sandbox --scratch-path "$project_root/.build" --cache-path "$project_root/.build/cache" --config-path "$project_root/.build/configuration" --security-path "$project_root/.build/security")
swift build "${swift_arguments[@]}"
binary_directory="$(swift build "${swift_arguments[@]}" --show-bin-path)"
mkdir -p "$destination/Contents/MacOS" "$destination/Contents/Resources"
cp "$binary_directory/SemaMac" "$destination/Contents/MacOS/SemaMac"
cp Resources/Info.plist "$destination/Contents/Info.plist"
swift scripts/render-icon.swift "$project_root/.build/Sema.iconset"
iconutil -c icns "$project_root/.build/Sema.iconset" -o "$destination/Contents/Resources/Sema.icns"
if [[ -n "${SEMA_DEVELOPMENT_DATA_DIRECTORY:-}" ]]; then
    /usr/libexec/PlistBuddy -c "Add :SemaDevelopmentDataDirectory string $SEMA_DEVELOPMENT_DATA_DIRECTORY" "$destination/Contents/Info.plist"
fi
codesign --force --sign - "$destination"
echo "App locale créée : $destination"
