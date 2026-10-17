#!/usr/bin/env python3
"""Vérifie les contrats mécaniques du dépôt ou de l’index Git, sans modifier les fichiers."""
import argparse
import functools
import json
import pathlib
import posixpath
import re
import subprocess
import sys
import urllib.parse


CODE_SUFFIXES = {".swift", ".sh", ".py", ".c", ".rb", ".js", ".css", ".html"}
CORE_IMPORT = re.compile(
    r"(?:^|;)[ \t]*(?:@\w+(?:\([^\n]*?\))?\s+)*(?:(?:public|internal|private|fileprivate|package)\s+)?"
    r"import\s+(?:(?:struct|class|enum|func|var|let|protocol|typealias)\s+)?(SwiftUI|AppKit|UserNotifications)\b",
    re.MULTILINE,
)
LOCAL_LINK = re.compile(
    r"\[[^\]\n]*\]\((?:<(?P<angle>[^>\n]+)>|(?P<plain>[^\s)]+))"
    r'''(?:[ \t]+"[^"\n]*"|[ \t]+'[^'\n]*')?[ \t]*\)'''
)
CONFLICT = re.compile(r"^(?:<{7} |={7}$|>{7} )", re.MULTILINE)
SWIFT_TEXT = re.compile(r'//[^\n]*|/\*|(?P<hashes>\#*)(?P<quote>"""|")')


class Snapshot:
    """Lit le contenu indexé au commit, ou le travail local incluant les nouveaux fichiers."""

    def __init__(self, root, staged=False):
        self.root = pathlib.Path(root)
        self.staged = staged
        if self.git("ls-files", "--unmerged", "-z"):
            raise ValueError("Conflits Git non résolus.")
        args = ["ls-files", "--cached", "-z"]
        if not staged:
            args.extend(["--others", "--exclude-standard"])
        paths = self.git(*args).decode().split("\0")
        self.paths = {path for path in paths if path and (staged or (self.root / path).is_file())}

    def git(self, *args):
        return subprocess.check_output(["git", "-C", str(self.root), *args])

    @functools.lru_cache(maxsize=None)
    def read(self, path):
        if self.staged:
            return self.git("show", ":" + path).decode("utf-8")
        return (self.root / path).read_text(encoding="utf-8")


def has_header(source):
    for line in source.splitlines():
        line = line.strip()
        if not line or line.startswith(("#!", "// swift-tools-version:")):
            continue
        if line.lower().startswith("<!doctype") or line in {'"use strict";', "'use strict';"}:
            continue
        return line.startswith(("//", "/*", "# ", '<!--', '"""', "'''"))
    return False


def swift_code(source):
    """Masque commentaires imbriqués et chaînes, en conservant les lignes des imports."""
    parts = []
    offset = 0
    while match := SWIFT_TEXT.search(source, offset):
        parts.append(source[offset:match.start()])
        end = match.end()
        if match[0] == "/*":
            depth = 1
            end = len(source)
            for marker in re.finditer(r"/\*|\*/", source[match.end():]):
                depth += 1 if marker[0] == "/*" else -1
                if depth == 0:
                    end = match.end() + marker.end()
                    break
        elif match["quote"]:
            closing = match["quote"] + match["hashes"]
            escape = "\\" + match["hashes"]
            tokens = re.compile(re.escape(escape) + r"[\s\S]|" + re.escape(closing))
            end = len(source)
            for token in tokens.finditer(source, match.end()):
                if token[0] == closing:
                    end = token.end()
                    break
        parts.append(re.sub(r"[^\n]", " ", source[match.start():end]))
        offset = end
    parts.append(source[offset:])
    return "".join(parts)


def markdown_prose(source):
    """Écarte les exemples en blocs délimités ou en code en ligne du contrôle des liens."""
    lines = []
    fence = None
    for line in source.splitlines(keepends=True):
        marker = re.match(r" {0,3}(`{3,}|~{3,})(.*)", line)
        if fence:
            if marker and marker[1][0] == fence[0] and len(marker[1]) >= len(fence) and not marker[2].strip():
                fence = None
        elif marker:
            fence = marker[1]
        else:
            lines.append(line)
        if marker or fence:
            lines.append("\n")
    return re.sub(r"(?<!`)(`+)(?!`)(.*?)\1(?!`)", "", "".join(lines), flags=re.DOTALL)


def check(snapshot):
    errors = []
    try:
        structure = json.loads(snapshot.read(".agents/structure.json"))
        if not isinstance(structure, dict) or not structure or not all(
            isinstance(path, str) and path and isinstance(purpose, str) and purpose.strip()
            for path, purpose in structure.items()
        ):
            raise ValueError("Chaque emplacement doit avoir une responsabilité.")
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        return [f".agents/structure.json : carte illisible ({error})."]

    for path in sorted(snapshot.paths):
        if not any(path == route or (route.endswith("/") and path.startswith(route)) for route in structure):
            errors.append(f"{path} : emplacement sans responsabilité dans .agents/structure.json.")
        name = pathlib.PurePosixPath(path).name
        suffix = pathlib.PurePosixPath(path).suffix
        if name == ".env" or (name.startswith(".env.") and name != ".env.example") or suffix in {".key", ".p12", ".p8"}:
            errors.append(f"{path} : fichier de secrets interdit dans Git.")
        if suffix not in CODE_SUFFIXES | {".md", ".json", ".yml", ".yaml"} and not path.startswith(".githooks/"):
            continue
        try:
            source = snapshot.read(path)
        except UnicodeError:
            errors.append(f"{path} : fichier texte non UTF-8.")
            continue
        if CONFLICT.search(source):
            errors.append(f"{path} : marqueur de conflit Git.")
        if (suffix in CODE_SUFFIXES or path.startswith(".githooks/")) and not has_header(source):
            errors.append(f"{path} : ajouter une description de responsabilité en tête du code.")
        if path.startswith("Sources/MarketCore/") and suffix == ".swift":
            # Les imports sont contrôlés ; ce n’est pas une analyse sémantique Swift.
            if CORE_IMPORT.search(swift_code(source)):
                errors.append(f"{path} : le cœur ne dépend pas de SwiftUI, AppKit ou UserNotifications.")
        if suffix == ".json":
            try:
                json.loads(source)
            except ValueError as error:
                errors.append(f"{path} : JSON invalide ({error}).")
        if suffix == ".md":
            for match in LOCAL_LINK.finditer(markdown_prose(source)):
                link = match["angle"] or match["plain"]
                target = urllib.parse.urlsplit(link)
                if target.scheme or target.netloc or not target.path:
                    continue
                target_path = urllib.parse.unquote(target.path)
                resolved = posixpath.normpath(target_path.lstrip("/") if target_path.startswith("/") else
                                              posixpath.join(posixpath.dirname(path), target_path))
                if resolved not in snapshot.paths and not any(p.startswith(resolved.rstrip("/") + "/") for p in snapshot.paths):
                    errors.append(f"{path} : lien local introuvable : {link}.")
        if path.startswith(".agents/skills/") and name == "SKILL.md":
            match = re.match(r"---\nname: ([a-z0-9-]+)\ndescription: (.+)\n---\n", source)
            if not match or match[1] != pathlib.PurePosixPath(path).parent.name:
                errors.append(f"{path} : nom et description de skill invalides.")

    if "CLAUDE.md" not in snapshot.paths or snapshot.read("CLAUDE.md").strip() != "@AGENTS.md":
        errors.append("CLAUDE.md : importer uniquement @AGENTS.md ; règles communes dans AGENTS.md.")
    canonical = "distribution/release.json"
    mirror = "site/dist/download/release.json"
    missing = {canonical, mirror} - snapshot.paths
    errors.extend(f"{path} : manifeste de release manquant." for path in sorted(missing))
    if not missing:
        try:
            if json.loads(snapshot.read(canonical)) != json.loads(snapshot.read(mirror)):
                errors.append(f"{mirror} : différent du manifeste canonique {canonical}.")
        except ValueError:
            pass  # L’erreur JSON a déjà été signalée avec son chemin.
    return errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--staged", action="store_true", help="Vérifier exactement les contenus de l’index Git")
    args = parser.parse_args()
    root = subprocess.check_output(["git", "rev-parse", "--show-toplevel"], text=True).strip()
    errors = check(Snapshot(root, staged=args.staged))
    if errors:
        print("Garde-fous :\n" + "\n".join("- " + error for error in errors), file=sys.stderr)
        return 1
    print("Garde-fous vérifiés (" + ("index Git" if args.staged else "travail local") + ").")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        sys.exit(f"Vérification impossible : {error}")
