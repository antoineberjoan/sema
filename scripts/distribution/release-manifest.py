#!/usr/bin/env python3
"""Read release facts from the built bundle and its DMG. Never activate publication."""
import argparse
import datetime
import hashlib
import json
import pathlib
import plistlib
import re
import subprocess
import sys


def bundle_facts(bundle):
    info = plistlib.loads((bundle / "Contents/Info.plist").read_bytes())
    if info.get("CFBundleIdentifier") != "com.antoineberjoan.sema":
        raise ValueError("Le bundle doit être celui de Sema, pas une app de revue.")
    if "SemaDevelopmentDataDirectory" in info:
        raise ValueError("Le bundle contient une configuration de développement.")
    version = info.get("CFBundleShortVersionString", "")
    build = str(info.get("CFBundleVersion", ""))
    if not re.fullmatch(r"\d+\.\d+\.\d+(?:-[a-zA-Z0-9.]+)?", version) or not build.isdecimal():
        raise ValueError("Version ou numéro de build invalide.")
    executable = bundle / "Contents/MacOS" / info["CFBundleExecutable"]
    architecture = subprocess.check_output(["/usr/bin/lipo", "-archs", str(executable)], text=True).strip()
    if architecture != "arm64":
        raise ValueError("Ce packaging a été vérifié pour arm64 uniquement.")
    minimum = info.get("LSMinimumSystemVersion")
    if not minimum:
        raise ValueError("La version minimale de macOS manque au bundle.")
    load_commands = subprocess.check_output(["/usr/bin/vtool", "-show-build", str(executable)], text=True)
    binary_minimums = re.findall(r"\bminos\s+(\d+(?:\.\d+)+)", load_commands)
    version_tuple = lambda value: tuple(int(part) for part in value.split(".")) + (0,) * (3 - len(value.split(".")))
    declared = version_tuple(minimum)
    if not binary_minimums or any(version_tuple(value) > declared for value in binary_minimums):
        raise ValueError("Le macOS minimal du binaire ne correspond pas au Info.plist.")
    for path in bundle.rglob("*"):
        if path.name.startswith(".env") or path.name in {"preferences.json", "webstat-cache.json"}:
            raise ValueError("Le bundle contient un fichier de configuration personnel.")
    subprocess.run(["/usr/bin/codesign", "--verify", "--strict", "--deep", str(bundle)], check=True)
    signature = subprocess.run(["/usr/bin/codesign", "-d", "--verbose=4", str(bundle)],
                               capture_output=True, text=True, check=True).stderr
    return {"version": version, "build": build, "architecture": architecture,
            "minimumMacOS": minimum, "signature": "ad-hoc" if "Signature=adhoc" in signature else "signed",
            "notarized": False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("bundle", type=pathlib.Path)
    parser.add_argument("--dmg", type=pathlib.Path)
    parser.add_argument("--output", type=pathlib.Path)
    args = parser.parse_args()
    facts = bundle_facts(args.bundle.resolve())
    if not args.dmg:
        print(json.dumps(facts, ensure_ascii=False))
        return
    dmg = args.dmg.resolve()
    checksum = hashlib.sha256(dmg.read_bytes()).hexdigest()
    version = facts["version"]
    manifest = {
        "schemaVersion": 1, "product": "Sema", **facts,
        "createdAt": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"),
        "channel": "private-alpha", "download": {"enabled": False, "url": None,
            "filename": dmg.name, "byteSize": dmg.stat().st_size, "sha256": checksum,
            "proposedURL": f"https://github.com/antoineberjoan/homebrew-sema/releases/download/v{version}/{dmg.name}"},
        "homebrew": {"enabled": False, "command": None,
            "proposedCommand": "brew install --cask antoineberjoan/sema/sema"},
        "validation": {"bundleSignature": True, "finderInstall": False,
            "internetDownload": False, "firstLaunch": False, "homebrewInstall": False,
            "homebrewUpgrade": False},
    }
    output = args.output or dmg.with_name("release.json")
    output.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")
    dmg.with_suffix(".dmg.sha256").write_text(f"{checksum}  {dmg.name}\n")
    # This is a template until the versioned URL is published and brew is tested.
    cask = f'''# Modèle de release — URL proposée ; ne pas publier avant les tests indiqués dans release.json.
cask "sema" do
  version "{version}"
  sha256 "{checksum}"

  url "https://github.com/antoineberjoan/homebrew-sema/releases/download/v#{{version}}/Sema-#{{version}}-arm64.dmg"
  name "Sema"
  desc "Vos repères économiques Webstat sur Mac"
  homepage "https://sema.raregoat8192.chatgpt.site/"

  depends_on arch: :arm64
  depends_on macos: ">= :sonoma"

  app "Sema.app"
end
'''
    dmg.with_name("sema.rb.template").write_text(cask)
    print(json.dumps({"manifest": str(output), "dmg": str(dmg), "byteSize": dmg.stat().st_size,
                      "sha256": checksum}, ensure_ascii=False))


if __name__ == "__main__":
    try:
        main()
    except (ValueError, KeyError, OSError, subprocess.CalledProcessError) as error:
        sys.exit(f"Release refusée : {error}")
