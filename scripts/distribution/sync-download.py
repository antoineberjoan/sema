#!/usr/bin/env python3
"""Prepare static download HTML from an actual release manifest; no remote publication."""
import argparse
import hashlib
import html
import json
import pathlib
import re
import shutil
import sys
import urllib.parse


def replace_block(source, name, markup):
    pattern = rf"<!-- release:{name}:start -->.*?<!-- release:{name}:end -->"
    result, count = re.subn(pattern, lambda _: f"<!-- release:{name}:start -->\n{markup}\n          <!-- release:{name}:end -->", source, flags=re.DOTALL)
    if count != 1:
        raise ValueError(f"Bloc HTML {name} introuvable ou dupliqué")
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", type=pathlib.Path)
    parser.add_argument("site_dist", type=pathlib.Path)
    parser.add_argument("--local-preview", action="store_true", help="Copier le DMG et activer un lien relatif pour la préversion privée")
    args = parser.parse_args()
    manifest = json.loads(args.manifest.read_text())
    download = manifest["download"]
    artifact = args.manifest.parent / download["filename"]
    if args.local_preview:
        if not artifact.is_file() or artifact.stat().st_size != download["byteSize"]:
            raise ValueError("Le DMG local ne correspond pas au manifeste")
        if hashlib.sha256(artifact.read_bytes()).hexdigest() != download["sha256"]:
            raise ValueError("Le SHA-256 du DMG local ne correspond pas au manifeste")
        destination = args.site_dist / "downloads" / artifact.name
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(artifact, destination)
        shutil.copyfile(artifact.with_suffix(".dmg.sha256"), destination.with_suffix(".dmg.sha256"))
        download["enabled"] = True
        download["url"] = "/downloads/" + urllib.parse.quote(artifact.name)
        manifest["channel"] = "private-preview"
    if download["enabled"] and not download.get("url"):
        raise ValueError("Téléchargement actif sans URL")
    if download.get("url") and not (download["url"].startswith("/") or urllib.parse.urlparse(download["url"]).scheme == "https"):
        raise ValueError("URL de téléchargement non prise en charge")
    page = args.site_dist / "download/index.html"
    source = page.read_text()
    escape = lambda value: html.escape(str(value), quote=True)
    if download["enabled"]:
        source = replace_block(source, "primary", f'<a class="button" href="{escape(download["url"])}" download="{escape(download["filename"])}" data-download><svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="M12 3v12m-4-4 4 4 4-4M5 16v4h14v-4" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/></svg>Télécharger Sema</a>')
    else:
        source = replace_block(source, "primary", '<span class="button download-pending">Préversion en préparation</span>')
    megabytes = f'{download["byteSize"] / 1000000:.1f}'.replace(".", ",")
    fields = [f'Version {escape(manifest["version"])}', f'{megabytes} Mo', 'Puce Apple', f'macOS {escape(manifest["minimumMacOS"])}+']
    metadata = '<p class="release-metadata">' + '<span class="separator" aria-hidden="true">·</span>'.join(f'<span>{field}</span>' for field in fields) + '</p>'
    source = replace_block(source, "metadata", metadata)
    label = "Préversion privée" if manifest["channel"] == "private-preview" else "Version alpha"
    trust = f'<p class="release-trust">{label} · Non notarisée · <a href="#premiere-ouverture">Aide à la première ouverture</a></p>'
    source = replace_block(source, "trust", trust)
    brew = manifest["homebrew"]
    if brew["enabled"]:
        if not brew.get("command") or not all(manifest["validation"].get(key) for key in ("homebrewInstall", "homebrewUpgrade", "internetDownload")):
            raise ValueError("La commande Homebrew ne peut être activée avant les tests d’installation et de mise à jour")
        markup = f'<div class="brew-command"><code id="homebrew-command">{escape(brew["command"])}</code><button type="button" id="copy-homebrew" hidden>Copier</button></div><p id="homebrew-copy-status" role="status"></p><p>Les contrôles de sécurité de macOS s’appliquent aussi à cette installation.</p>'
    else:
        markup = '<p>Le tap Homebrew sera proposé après les tests d’installation et de mise à jour.</p>'
    source = replace_block(source, "homebrew", markup)
    update_method = "en téléchargeant une nouvelle version, ou avec Homebrew" if brew["enabled"] else "en téléchargeant une nouvelle version"
    source = replace_block(source, "updates", f'<p class="alpha-note">Les mises à jour se feront pour l’instant {update_method}. Vos préférences restent sur votre Mac.</p>')
    page.write_text(source)
    (args.site_dist / "download/release.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")
    print(f'Page synchronisée : Sema {manifest["version"]} · {megabytes} Mo · {manifest["architecture"]} · {manifest["channel"]}')


if __name__ == "__main__":
    try:
        main()
    except (ValueError, KeyError, OSError) as error:
        sys.exit(f"Synchronisation refusée : {error}")
