#!/usr/bin/env python3
"""Exporte les SVG de la marque depuis le code : la géométrie vient de `SignalPath.swift`, les couleurs de `DesignPrimitive.swift`.

Aucun SVG de la marque ne s'écrit à la main. `--verifier` échoue si un fichier diffère de ce que ce script produit.
Le mot « sema » du lockup est un dessin (`Resources/Brand/sema-wordmark.svg`), repris tel quel.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SIGNAL = ROOT / "Sources/SemaMac/Components/Custom/SignalPath.swift"
PRIMITIVES = ROOT / "Sources/SemaDesign/DesignPrimitive.swift"
WORDMARK = ROOT / "Resources/Brand/sema-wordmark.svg"
NUMBER = r"-?[0-9]+(?:\.[0-9]+)?"


def number(text):
    value = float(text)
    return str(int(value)) if value == int(value) else str(value)


def geometry(source):
    found = {}
    for name, kind, args in re.findall(r"static let (\w+)(?:: CGFloat)? = (CGPoint|CGRect)?\(?([^\n)]*)\)?\s*$", source, re.M):
        values = [number(v) for v in re.findall(NUMBER, args)]
        found[name] = values if kind else values[0]
    return found


def palette(source):
    colors = {name: "#%06X" % int(value, 16) for name, value in re.findall(r"static let (\w+): UInt32 = 0x([0-9A-Fa-f]{6})", source)}
    for step in ("200", "500"):
        block = re.search(r"static func accent" + step + r"\(.*?case \.brand: return 0x([0-9A-Fa-f]{6})", source, re.S)
        colors["accent" + step] = "#" + block.group(1).upper()
    return colors


def files():
    g, c = geometry(SIGNAL.read_text()), palette(PRIMITIVES.read_text())
    ox, oy = g["appIconOffset"]
    ink, paper, teal, teal_light = c["ink800"], c["paper0"], c["accent500"], c["accent200"]
    (sx, sy), (c1x, c1y), (c2x, c2y), (dx, dy), (ex, _) = (g[k] for k in ("start", "control1", "control2", "dotCenter", "end"))
    p = lambda x, y: (number(float(x) + float(ox)), number(float(y) + float(oy)))
    path = "M%s %s C%s %s %s %s %s %s H%s" % (*p(sx, sy), *p(c1x, c1y), *p(c2x, c2y), *p(dx, dy), p(ex, 0)[0])
    cx, cy = p(dx, dy)
    ring = number((float(g["dotRadius"]) + float(g["gapRadius"])) / 2)
    gap = number(float(g["gapRadius"]) - float(g["dotRadius"]))
    stroke = number(g["stroke"])
    line = lambda color: '<path d="%s" stroke="%s" stroke-width="%s" fill="none" stroke-linecap="round"/>' % (path, color, stroke)
    dot = lambda fill, edge: '<circle cx="%s" cy="%s" r="%s" fill="%s"%s/>' % (cx, cy, ring, fill, ' stroke="%s" stroke-width="%s"' % (edge, gap) if edge else "")
    svg = lambda box, w, h, title, body, extra="": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="%s" width="%s" height="%s"%s><title>%s</title>%s</svg>\n' % (box, w, h, extra, title, body)
    ax, ay, aw, ah = (number(v) for v in g["artboard"])
    box = "%s %s %s %s" % (ax, ay, aw, ah)
    size = number(g["appIconSize"])
    inset, tile = number(g["appIconInset"]), number(float(g["appIconSize"]) - 2 * float(g["appIconInset"]))
    tile_shape = lambda fill, edge="": '<rect x="%s" y="%s" width="%s" height="%s" rx="%s" fill="%s"%s/>' % (inset, inset, tile, tile, number(g["appIconCorner"]), fill, edge)
    icon = svg("0 0 %s %s" % (size, size), size, size, "sema", tile_shape(ink) + line(paper) + dot(teal, ink))
    dark_fill, dark_edge = c["ink750"], c["ink700"]
    icon_dark = svg("0 0 %s %s" % (size, size), size, size, "sema",
                    tile_shape(dark_fill, ' stroke="%s" stroke-width="%s"' % (dark_edge, number(g["appIconEdge"]))) + line(paper) + dot(teal, dark_fill))
    standard = svg(box, aw, ah, "sema — repère", line(ink) + dot(teal, paper))
    white = svg(box, aw, ah, "sema — repère, sur fond sombre", line(paper) + dot(teal_light, ink))
    menubar = svg(box, aw, ah, "sema — repère, barre de menus", line("currentColor") + dot("currentColor", ""), ' color="%s"' % ink)
    word = WORDMARK.read_text()
    outer = re.match(r'<svg [^>]*viewBox="([^"]+)" width="([^"]+)" height="([^"]+)"><title>[^<]*</title>(.*)</svg>\s*$', word, re.S)
    inner = '<svg x="0" y="0" width="440" height="300" viewBox="%s"><title>sema</title>%s%s</svg>' % (box, line(ink), dot(teal, paper))
    lockup = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="%s" width="%s" height="%s"><title>sema</title>%s%s</svg>\n' % (outer.group(1), outer.group(2), outer.group(3), inner, outer.group(4))
    return {
        "Resources/Brand/sema-app-icon.svg": icon, "site/dist/brand/assets/sema-app-icon.svg": icon, "site/dist/assets/sema.svg": icon,
        "Resources/Brand/sema-app-icon-dark.svg": icon_dark,
        "Resources/Brand/sema-logo.svg": standard, "site/dist/brand/assets/sema-symbol-standard.svg": standard,
        "site/dist/brand/assets/sema-symbol-white.svg": white, "site/dist/brand/assets/sema-symbol-menubar.svg": menubar,
        "Resources/Brand/sema-lockup.svg": lockup, "site/dist/brand/assets/sema-lockup.svg": lockup,
    }


def main(arguments):
    expected = files()
    stale = [name for name, text in expected.items() if not (ROOT / name).exists() or (ROOT / name).read_text() != text]
    if "--verifier" in arguments:
        if stale:
            print("Export du signe périmé : " + ", ".join(stale) + ". Lancer python3 scripts/export_signe.py.")
            return 1
        print("Export du signe à jour (%d fichiers)." % len(expected))
        return 0
    for name in stale:
        (ROOT / name).write_text(expected[name])
    print("Écrit : " + (", ".join(stale) if stale else "rien, tout est à jour."))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
