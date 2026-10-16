#!/usr/bin/env python3
"""Write the fixed Finder layout for Sema's read-only DMG, using stdlib only.

The file contains one B-tree leaf, not a general-purpose DS_Store editor.
Format reference: https://metacpan.org/dist/Mac-Finder-DSStore/view/DSStoreFormat.pod
The background alias is produced by macOS Alias Manager for the mounted volume.
"""
import pathlib
import plistlib
import struct
import sys


def uint(*values):
    return struct.pack(">" + "I" * len(values), *values)


def record(name, key, kind, value):
    encoded = name.encode("utf-16be")
    prefix = uint(len(encoded) // 2) + encoded + key.encode("ascii") + kind.encode("ascii")
    if kind == "blob":
        return prefix + uint(len(value)) + value
    if kind == "long":
        return prefix + uint(value)
    if kind == "type":
        return prefix + value
    raise ValueError("Type DS_Store non pris en charge")


def write_layout(mount, alias_path):
    background_alias = alias_path.read_bytes()
    window = {
        "WindowBounds": "{{180, 160}, {640, 400}}",
        "ShowSidebar": False, "ShowToolbar": False, "ShowStatusBar": False,
        "ShowTabView": False, "ShowPathbar": False, "ShowPreviewPane": False,
        "SidebarWidth": 0, "ContainerShowSidebar": False,
    }
    icons = {
        "viewOptionsVersion": 1, "backgroundType": 2,
        "backgroundImageAlias": background_alias,
        "backgroundColorRed": 0.0863, "backgroundColorGreen": 0.1020,
        "backgroundColorBlue": 0.0941,
        "iconSize": 96.0, "textSize": 13.0, "gridSpacing": 100.0,
        "gridOffsetX": 0.0, "gridOffsetY": 0.0, "arrangeBy": "none",
        "labelOnBottom": True, "showIconPreview": True, "showItemInfo": False,
        "scrollPositionX": 0.0, "scrollPositionY": 0.0,
    }
    entries = [
        (".", "bwsp", "blob", plistlib.dumps(window, fmt=plistlib.FMT_BINARY)),
        (".", "icvp", "blob", plistlib.dumps(icons, fmt=plistlib.FMT_BINARY)),
        (".", "icvl", "type", b"icnv"),
        (".", "vSrn", "long", 1),
        (".", "vstl", "type", b"icnv"),
        ("Applications", "Iloc", "blob", uint(476, 226, 0xFFFFFFFF, 0xFFFF0000)),
        ("Sema.app", "Iloc", "blob", uint(164, 226, 0xFFFFFFFF, 0xFFFF0000)),
    ]
    entries.sort(key=lambda entry: (entry[0].lower(), entry[1]))
    leaf = uint(0, len(entries)) + b"".join(record(*entry) for entry in entries)
    if len(leaf) > 4096:
        raise ValueError("La disposition dépasse la feuille DS_Store prévue")

    # Logical offsets are relative to byte 4: header [0,32), tree header [32,64),
    # buddy metadata [2048,4096), tree leaf [4096,8192).
    blocks = [2048 | 11, 32 | 5, 4096 | 12]
    metadata = uint(len(blocks), 0) + uint(*blocks) + bytes((256 - len(blocks)) * 4)
    metadata += uint(1) + bytes([4]) + b"DSDB" + uint(1)
    for width in range(32):
        free = [1 << width] if 6 <= width <= 10 or 13 <= width <= 30 else []
        metadata += uint(len(free)) + uint(*free)
    if len(metadata) > 2048:
        raise ValueError("Métadonnées DS_Store trop grandes")
    data = bytearray(8196)
    data[:36] = struct.pack(">I4sIII16s", 1, b"Bud1", 2048, 2048, 2048, bytes(16))
    data[36:56] = uint(2, 0, len(entries), 1, 4096)
    data[2052:2052 + len(metadata)] = metadata
    data[4100:4100 + len(leaf)] = leaf
    (mount / ".DS_Store").write_bytes(data)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("Usage : finder-layout.py volume-monté alias-du-fond")
    write_layout(pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]))
