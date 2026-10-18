#!/bin/bash
# Build a versioned private alpha from a validated .app. This does not publish it.
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Usage : ./scripts/package-dmg.sh /chemin/Sema.app [dossier-sortie]" >&2
    exit 1
fi
bundle="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
output_directory="${2:-$project_root/build/releases}"
mkdir -p "$output_directory"
output_directory="$(cd "$output_directory" && pwd)"

staging="$(mktemp -d "${TMPDIR:-/tmp}/sema-dmg.XXXXXX")"
mount_point="$staging/volume"
mounted=0
cleanup() {
    if [[ "$mounted" == 1 ]]; then
        if ! hdiutil detach "$mount_point" -force -quiet; then
            echo "Volume temporaire encore monté : $mount_point. Dossier conservé pour un démontage manuel." >&2
            return
        fi
    fi
    rm -rf "$staging"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Snapshot first: a concurrent build cannot change the version being packaged.
ditto "$bundle" "$staging/Sema.app"
release_bundle="$staging/Sema.app"
facts="$(python3 "$project_root/scripts/distribution/release-manifest.py" "$release_bundle")"
version="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["version"])' <<< "$facts")"
filename="Sema-$version-arm64.dmg"
if [[ -e "$output_directory/$filename" ]]; then
    echo "Ce DMG versionné existe déjà. Utilisez un autre dossier ou une nouvelle version." >&2
    exit 1
fi


# Build-only helpers: SVG rendering and a native Finder alias on the mounted volume.
mkdir -p "$project_root/.build/ModuleCache"
CLANG_MODULE_CACHE_PATH="$project_root/.build/ModuleCache" swiftc \
    "$project_root/scripts/render-dmg.swift" -o "$staging/render-dmg"
clang -framework CoreServices -Wno-deprecated-declarations \
    "$project_root/scripts/distribution/finder-alias.c" -o "$staging/finder-alias"
"$staging/render-dmg" "$project_root/Resources/DMG/dmg-background.svg" "$staging/background"
mkdir -p "$output_directory/background-preview"
cp "$staging/background/"*.png "$output_directory/background-preview/"
tiffutil -cathidpicheck "$staging/background/background@1x.png" \
    "$staging/background/background@2x.png" -out "$staging/background.tiff" >/dev/null

bundle_kilobytes="$(du -sk "$release_bundle" | awk '{print $1}')"
size_megabytes="$((bundle_kilobytes / 1024 + 40))"
hdiutil create -size "${size_megabytes}m" -fs HFS+ -volname "Sema" \
    "$staging/Sema-writable.dmg"
mkdir -p "$mount_point"
hdiutil attach -nobrowse -noverify -mountpoint "$mount_point" "$staging/Sema-writable.dmg"
mounted=1

ditto "$release_bundle" "$mount_point/Sema.app"
ln -s /Applications "$mount_point/Applications"
mkdir -p "$mount_point/.background"
cp "$staging/background.tiff" "$mount_point/.background/background.tiff"
"$staging/finder-alias" "$mount_point/.background/background.tiff" "$staging/background.alias"
python3 "$project_root/scripts/distribution/finder-layout.py" "$mount_point" "$staging/background.alias"
SetFile -a V "$mount_point/.background"
cp "$release_bundle/Contents/Resources/Sema.icns" "$mount_point/.VolumeIcon.icns"
SetFile -a C "$mount_point"
# Never add FinderInfo to the signed bundle; validate the exact app on the volume.
codesign --verify --strict --deep "$mount_point/Sema.app"
# bless --openfolder is unavailable on Apple Silicon. Finder reads .DS_Store on mount.
hdiutil detach "$mount_point" -quiet
mounted=0
hdiutil convert "$staging/Sema-writable.dmg" -format UDZO \
    -imagekey zlib-level=9 -o "$output_directory/$filename"
hdiutil verify "$output_directory/$filename"
python3 "$project_root/scripts/distribution/release-manifest.py" "$release_bundle" \
    --dmg "$output_directory/$filename" --output "$output_directory/release.json"
