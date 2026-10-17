#!/usr/bin/env python3
"""Synchronise les liens de téléchargement et l’aide depuis le manifeste, sans publication."""
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
    landing_page = args.site_dist / "index.html"
    landing = landing_page.read_text()
    escape = lambda value: html.escape(str(value), quote=True)
    if download["enabled"]:
        icon = '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.5 7.59 9.04 7.31c1.35.07 2.29.76 3.08.82 1.18-.24 2.31-.94 3.57-.85 1.51.12 2.65.72 3.4 1.8-3.11 1.87-2.37 5.98.48 7.13-.57 1.5-1.31 2.99-2.53 4.08ZM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25Z"/></svg>'
        primary = f'<a class="button" href="{escape(download["url"])}" download="{escape(download["filename"])}" data-download>{icon}télécharger</a>'
    else:
        primary = '<span class="button download-pending">préversion en préparation</span>'
    source = replace_block(source, "primary", primary)
    landing = replace_block(landing, "primary", primary)
    megabytes = f'{download["byteSize"] / 1000000:.1f}'.replace(".", ",")
    fields = [f'version {escape(manifest["version"])}', f'{megabytes} Mo', 'puce apple', f'macos {escape(manifest["minimumMacOS"])}+']
    metadata = '<p class="release-metadata">' + '<span class="separator" aria-hidden="true">·</span>'.join(f'<span>{field}</span>' for field in fields) + '</p>'
    source = replace_block(source, "metadata", metadata)
    label = "préversion privée" if manifest["channel"] == "private-preview" else "préversion"
    trust_label = label if manifest["notarized"] else label + " non notarisée"
    trust = f'<p class="release-trust">{trust_label} · <a href="#premiere-ouverture">aide à la première ouverture</a></p>'
    source = replace_block(source, "trust", trust)
    requirements = f'<p class="download-requirements">macos {escape(manifest["minimumMacOS"])}+ · puce apple · <a href="/download/#premiere-ouverture">{trust_label}</a></p>'
    landing = replace_block(landing, "requirements", requirements)
    brew = manifest["homebrew"]
    if brew["enabled"]:
        if not brew.get("command") or not all(manifest["validation"].get(key) for key in ("homebrewInstall", "homebrewUpgrade", "internetDownload")):
            raise ValueError("La commande Homebrew ne peut être activée avant les tests d’installation et de mise à jour")
        markup = f'<div class="brew-command"><code id="homebrew-command">{escape(brew["command"])}</code><button type="button" id="copy-homebrew" hidden>copier</button></div><p class="sr-only" id="homebrew-copy-status" role="status"></p><p>si une approbation est demandée, consultez <a href="https://github.com/antoineberjoan/homebrew-sema/blob/main/Casks/sema.rb" target="_blank" rel="noopener noreferrer">le cask sema</a> avant d’accepter. les contrôles de sécurité de macos s’appliquent aussi à cette installation.</p>'
    else:
        markup = '<p>homebrew sera proposé après les tests d’installation et de mise à jour.</p>'
    source = replace_block(source, "homebrew", markup)
    update_method = "en téléchargeant une nouvelle version, ou avec Homebrew" if brew["enabled"] else "en téléchargeant une nouvelle version"
    source = replace_block(source, "updates", f'<p class="alpha-note">les mises à jour se font {update_method}. vos préférences restent sur votre mac.</p>')
    page.write_text(source)
    landing_page.write_text(landing)
    (args.site_dist / "download/release.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")
    print(f'Page synchronisée : sema {manifest["version"]} · {megabytes} Mo · {manifest["architecture"]} · {manifest["channel"]}')


if __name__ == "__main__":
    try:
        main()
    except (ValueError, KeyError, OSError) as error:
        sys.exit(f"Synchronisation refusée : {error}")
