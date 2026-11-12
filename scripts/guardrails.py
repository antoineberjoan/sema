#!/usr/bin/env python3
"""Vérifie les contrats mécaniques du dépôt ou de l’index Git, sans modifier les fichiers."""
import argparse
import collections
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
# Une valeur visuelle ou un code de touche se nomme une fois dans une constante `static let` de son propriétaire.
NAMED_CONSTANT = re.compile(r"^\s*(?:@\w+\s+)*(?:(?:private|fileprivate|internal|public|package|nonisolated)\s+)*static\s+(?:let|var)\b")
LAYOUT_LABELS = ("size|cornerRadius|lineWidth|radius|duration|response|dampingFraction|spacing|minLength|padding|width|height|"
                 "minWidth|idealWidth|maxWidth|minHeight|idealHeight|maxHeight|minimum|maximum|min|ideal|max|desiredCount")
VISUAL_ARGUMENT = re.compile(r"(?:[(,]|^)\s*(?:%s):([^,)\n]*)" % LAYOUT_LABELS, re.MULTILINE)
VISUAL_CALL = re.compile(r"(?:\.(?:padding|opacity|offset|tracking|kerning|scaleEffect|blur|lineLimit|minimumScaleFactor|symbolSize)|\bEdgeInsets)\(")
NUMBER = re.compile(r"(?<![\w.])(?:\d+\.\d+|\.\d+|\d+)(?![\w.])")
STRUCTURAL_NUMBERS = {"0", "1"}
# Un fichier Swift porte un seul type visible, à son nom ; un fichier d’extensions se nomme `Type+Rôle.swift`.
TOP_TYPE = re.compile(r"^(?:@\w+(?:\([^)\n]*\))?\s+)*(?P<access>(?:public|internal|package|open|private|fileprivate)\s+)?"
                      r"(?:(?:final|indirect|nonisolated)\s+)*(?:struct|enum|class|actor|protocol)\s+(?P<name>\w+)", re.MULTILINE)
# Une adresse, une locale ou un fuseau se nomme une fois ; une durée d’un jour reste `.day` ; une taille native reste un style.
CONFIG_LITERAL = re.compile(r'\b(?:URL|URLComponents)\(string:\s*"|\b(?:Locale|TimeZone)\(identifier:\s*"')
DAY_SECONDS = re.compile(r"(?<![\w.])86_?400(?![\w.])")
# Typographie : une taille de texte écrite en chiffres vit seulement dans les rôles fabriqués de `SemaDesign`.
NATIVE_TEXT_SIZE = re.compile(r"\.system\(size:\s*\d")
PRIVATE_DECLARATION = re.compile(r"\b(?:private|fileprivate)\s+(?:(?:static|final|lazy|nonisolated|override|mutating|indirect)\s+)*"
                                 r"(?:let|var|func|struct|enum|class|actor|typealias)\s+(\w+)")
IMPLICIT_NAMES = {"CodingKeys", "body", "init"}
GLOSSARY = "docs/lexique.md"
IDENTIFIER = re.compile(r"\b[A-Za-z_]\w*\b")
TOP_EXTENSION = re.compile(r"^(?:@\w+\s+)*(?:(?:public|internal|private|fileprivate)\s+)?extension\s+(?P<name>\w+)", re.MULTILINE)


# Une valeur visuelle du site se nomme une fois dans `site/tokens.json` ; les paliers `@media` ne peuvent pas utiliser de variable.
TOKEN_SOURCE = "site/tokens.json"
CSS_NOISE = re.compile(r"/\*[\s\S]*?\*/|\"[^\"\n]*\"|'[^'\n]*'|url\([^)]*\)|@(?:media|supports)[^{]*")
RAW_STYLE = re.compile(r"#[0-9a-fA-F]{3,8}\b|\brgba?\(|cubic-bezier\(|(?<![\w.#])(?P<number>\d*\.?\d+)(?P<unit>px|ms|s|rem)\b"
                       r"|\b(?:z-index|font-weight|letter-spacing)\s*:\s*-?[.\d]")
SCALE_USE = re.compile(r"var\(--(scale-[\w-]+)")
CSS_SELECTOR = re.compile(r"([^{};]+)\{")
CSS_NAME = re.compile(r"[.#](-?[A-Za-z_][\w-]*)")
CSS_VARIABLE_USE = re.compile(r"var\((--[\w-]+)")
CSS_VARIABLE_DEFINITION = re.compile(r"(?<![\w-])(--[\w-]+)\s*:|setProperty\(\s*[\"'](--[\w-]+)")


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
        self.paths = {path for path in paths if path and (
            staged or (self.root / path).is_file() or (self.root / path).is_symlink()
        )}

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


def call_arguments(line, start):
    """Découpe les arguments d’un appel ouvert à `start`, au premier niveau de parenthèses."""
    arguments, current, depth = [], "", 0
    for character in line[start:]:
        if character in "([{":
            depth += 1
            if depth == 1:
                continue
        elif character in ")]}":
            depth -= 1
            if depth == 0:
                break
        if character == "," and depth == 1:
            arguments.append(current); current = ""
        else:
            current += character
    return arguments + [current]


def literal_values(argument):
    """Garde la valeur d’un argument : sans son libellé ni la condition d’un ternaire."""
    value = re.sub(r"^\s*\w+\s*:", "", argument, count=1)
    if "?" in value:
        value = value.split("?", 1)[1]
    return [number for number in NUMBER.findall(value) if number not in STRUCTURAL_NUMBERS]


def hardcoded(path, source):
    """Signale les valeurs visuelles, ombres et codes de touche écrits en dur dans le code Swift."""
    errors = []
    depth = 0  # Une constante nommée peut s’étendre sur plusieurs lignes jusqu’à la fermeture de ses délimiteurs.
    raw_lines = source.splitlines()
    for number, line in enumerate(swift_code(source).splitlines(), 1):
        if path.startswith("Sources/SemaMac/") and NATIVE_TEXT_SIZE.search(line):
            errors.append(f"{path}:{number} : taille de texte en dur ; utiliser un rôle `.typeRole(…)` .")
            continue  # Une seule erreur par ligne : le rôle remplace la taille entière.
        if depth > 0 or NAMED_CONSTANT.match(line):
            depth = max(0, depth + sum(line.count(c) for c in "([{") - sum(line.count(c) for c in ")]}"))
            continue
        if path.startswith("Sources/SemaMac/"):
            arguments = VISUAL_ARGUMENT.findall(line) + [argument for call in VISUAL_CALL.finditer(line)
                                                         for argument in call_arguments(line, call.end() - 1)]
            if any(literal_values(argument) for argument in arguments):
                errors.append(f"{path}:{number} : valeur visuelle en dur ; la nommer dans un rôle de `SemaDesign` "
                              "ou un `static let` de son propriétaire.")
        raw = raw_lines[number - 1] if number <= len(raw_lines) else ""
        if any(line[m.start():m.start() + 6] == raw[m.start():m.start() + 6] for m in CONFIG_LITERAL.finditer(raw)):
            errors.append(f"{path}:{number} : adresse ou locale en dur ; la nommer une fois dans un `static let` de son propriétaire.")
        if DAY_SECONDS.search(line):
            errors.append(f"{path}:{number} : durée d’un jour en dur ; utiliser `TimeInterval.day`.")
        if "keyCode" in line and any(value not in STRUCTURAL_NUMBERS for value in NUMBER.findall(line)):
            errors.append(f"{path}:{number} : code de touche en dur ; utiliser `kVK_…` ou une constante nommée.")
        if ".shadow(color" in line and path.startswith("Sources/SemaMac/"):
            errors.append(f"{path}:{number} : ombre composée dans l’app ; utiliser `elevation(_:)` avec une élévation de `SemaDesign`.")
    return errors


def misplaced_types(path, source):
    """Vérifie qu’un nom de type suffit à retrouver son fichier."""
    code = swift_code(source)
    stem = pathlib.PurePosixPath(path).stem
    visible = [m["name"] for m in TOP_TYPE.finditer(code) if (m["access"] or "").strip() not in ("private", "fileprivate")]
    if visible:
        if visible != [stem]:
            return [f"{path} : un seul type visible par fichier, nommé comme lui ; trouvé {', '.join(visible)}."]
        return []
    extended = {m["name"] for m in TOP_EXTENSION.finditer(code)}
    if extended and ("+" not in stem or stem.split("+")[0] not in extended):
        return [f"{path} : un fichier d’extensions se nomme `Type+Rôle.swift` d’après le type qu’il étend."]
    return []


def new_sema_types(path, source):
    """Refuse un nouveau type au préfixe redondant `Sema`."""
    names = {m["name"] for m in TOP_TYPE.finditer(swift_code(source))}
    return [f"{path} : `{name}` répète le nom du projet ; nommer le type sans préfixe `Sema`."
            for name in sorted(names) if name.startswith("Sema")]


def unused_private(path, source):
    """Signale une déclaration privée que son fichier n’utilise jamais."""
    code = swift_code(source)
    names = {m[1] for m in PRIVATE_DECLARATION.finditer(code)} - IMPLICIT_NAMES
    return [f"{path} : `{name}` est privé et jamais utilisé ; le supprimer."
            for name in sorted(names) if len(re.findall(r"\b%s\b" % re.escape(name), source)) == 1]


def glossary_variants(path, source, glossary):
    """Refuse une variante de casse d’un terme du glossaire, comme `seriesId` pour `seriesID`."""
    code = "\n".join(line for line in swift_code(source).splitlines() if not line.lstrip().startswith("import "))
    variants = sorted({word for word in IDENTIFIER.findall(code)
                       if len(word) > 3 and word.lower() in glossary and word not in glossary.values()})
    return [f"{path} : `{word}` s’écrit `{glossary[word.lower()]}` selon le glossaire." for word in variants]


GENERATED = "fabriqué depuis tokens.json par sophos/outils/jetons.mjs"


def is_generated(code):
    return any(GENERATED in line for line in code.splitlines()[:3])


def unused_types(sources):
    """Signale un type visible du code que rien n’utilise, hors point d’entrée `@main` et sortie fabriquée des jetons."""
    usages = collections.Counter(IDENTIFIER.findall("\n".join(sources.values())))
    errors = []
    for path, code in sorted(sources.items()):
        if not path.startswith("Sources/") or "@main" in code or is_generated(code):
            continue
        for match in TOP_TYPE.finditer(swift_code(code)):
            if (match["access"] or "").strip() not in ("private", "fileprivate") and \
                    usages[match["name"]] == 1:
                errors.append(f"{path} : le type `{match['name']}` n’est utilisé nulle part ; le supprimer.")
    return errors


def web_errors(sources):
    """Contrôle les feuilles du site : valeurs en dur, variables inconnues et styles que ni HTML ni JS n’utilisent."""
    errors = []
    styles = {path: re.sub(CSS_NOISE.pattern, lambda m: re.sub(r"[^\n]", " ", m[0]), source)
              for path, source in sources.items() if path.endswith(".css")}
    pages = "\n".join(source for path, source in sources.items() if not path.endswith(".css"))
    defined = {name for source in sources.values() for match in CSS_VARIABLE_DEFINITION.finditer(source) for name in match.groups() if name}
    for path, css in sorted(styles.items()):
        if is_generated(sources[path]):
            continue  # la feuille fabriquée par `jetons.mjs` définit des variables et des classes de rôle : jetons.mjs la contrôle
        for number, line in enumerate(css.splitlines(), 1):
            for match in RAW_STYLE.finditer(line):
                if match["unit"] == "px" and float(match["number"]) in (0, 1):
                    continue
                errors.append(f"{path}:{number} : valeur visuelle en dur `{match[0]}` ; la nommer dans {TOKEN_SOURCE}.")
        errors.extend(f"{path} : lit la primitive `{name}` ; lire un rôle nommé par usage dans {TOKEN_SOURCE}."
                      for name in sorted(set(SCALE_USE.findall(css))))
        errors.extend(f"{path} : `{name}` n’est défini nulle part ; l’ajouter à {TOKEN_SOURCE}."
                      for name in sorted(set(CSS_VARIABLE_USE.findall(css)) - defined))
        names = {name for selector in CSS_SELECTOR.findall(css) for name in CSS_NAME.findall(selector)}
        errors.extend(f"{path} : le sélecteur `{name}` n’apparaît dans aucun HTML ou JS du site ; supprimer le style mort."
                      for name in sorted(names) if not re.search(r"(?<![\w-])%s(?![\w-])" % re.escape(name), pages))
    return errors


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


# Un chemin du dépôt cité entre apostrophes inverses dans un texte existe : un document ne renvoie pas à un fichier disparu.
CITED_ROOTS = {"Sources", "Tests", "docs", "scripts", "site", "distribution", "Resources", ".github", ".claude", ".githooks"}
PARTIAL_FILE = re.compile(r"^[A-Z][\w.-]*(?:/[\w.-]+)+\.(?:swift|md|json|py|sh|css|js|html)$")
BACKTICK_SPAN = re.compile(r"`([^`\n]+)`")
UNCHECKED_PATH = re.compile(r"[\s*<>{}()$~@|]|://|^-")


def cited_path_errors(snapshot):
    errors = []
    for path in sorted(snapshot.paths):
        name = pathlib.PurePosixPath(path).name
        if not (path.endswith(".md") and (path.startswith("docs/") or name in {"AGENTS.md", "README.md", "CONTRIBUTING.md", "SECURITY.md"})):
            continue
        for number, line in enumerate(snapshot.read(path).splitlines(), 1):
            for span in BACKTICK_SPAN.findall(line):
                cited = span.rstrip("/") if span.endswith("/") else span
                if "/" not in span or UNCHECKED_PATH.search(span):
                    continue
                if cited.split("/")[0] not in CITED_ROOTS:
                    # Un chemin partiel (`App/Store.swift`) se termine un chemin du dépôt.
                    if PARTIAL_FILE.match(span) and not any(other == span or other.endswith("/" + span) for other in snapshot.paths):
                        errors.append(f"{path}:{number} : le fichier cité `{span}` n’existe pas.")
                    continue
                if cited not in snapshot.paths and not any(other.startswith(cited + "/") for other in snapshot.paths):
                    errors.append(f"{path}:{number} : le chemin cité `{span}` n’existe pas.")
    return errors


META_THEME_COLOR = re.compile(r'<meta\s+name="theme-color"\s+content="([^"]*)"', re.IGNORECASE)


def theme_color_errors(snapshot):
    """La couleur de la barre du navigateur est celle du rôle `page` de `site/tokens.json` : un HTML ne l'écrit pas à part."""
    if TOKEN_SOURCE not in snapshot.paths:
        return []
    try:
        page = json.loads(snapshot.read(TOKEN_SOURCE))["page"]["$value"]["hex"].lower()
    except (ValueError, KeyError, TypeError):
        return []  # Le JSON invalide est déjà signalé ; `jetons.mjs` contrôle la forme des jetons.
    errors = []
    for path in sorted(snapshot.paths):
        if path.startswith("site/dist/") and path.endswith(".html"):
            errors.extend(f"{path} : `theme-color` vaut `{value}` ; le rôle `page` de {TOKEN_SOURCE} vaut `{page}`."
                          for value in META_THEME_COLOR.findall(snapshot.read(path)) if value.lower() != page)
    return errors


def check(snapshot):
    errors = []
    glossary = {}
    if GLOSSARY in snapshot.paths:
        for row in snapshot.read(GLOSSARY).splitlines():
            cells = row.split("|")
            if len(cells) > 3:
                glossary.update({name.lower(): name for name in re.findall(r"`(\w+)`", cells[2])})
    swift_sources = {}
    web_sources = {}

    for path in sorted(snapshot.paths):
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
        if path.startswith("Sources/") and suffix == ".swift":
            errors.extend(hardcoded(path, source))
            errors.extend(misplaced_types(path, source))
            errors.extend(new_sema_types(path, source))
            errors.extend(unused_private(path, source))
            errors.extend(glossary_variants(path, source, glossary))
        if path.startswith(("Sources/", "Tests/")) and suffix == ".swift":
            swift_sources[path] = source
        if path.startswith("site/dist/") and suffix in {".css", ".html", ".js"}:
            web_sources[path] = source
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

    errors.extend(unused_types(swift_sources))
    errors.extend(web_errors(web_sources))
    errors.extend(theme_color_errors(snapshot))
    errors.extend(cited_path_errors(snapshot))
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
