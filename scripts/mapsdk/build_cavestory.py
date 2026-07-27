#!/usr/bin/env python3
"""
Build local mappacks/cavestory from a Cave Story data folder.

LEGAL: Pixel's Cave Story assets must NEVER be committed. Output is gitignored.
Format reference: doukutsu-rs (MIT) — see licenses/doukutsu-rs.MIT

Usage:
  python3 scripts/mapsdk/build_cavestory.py \\
      --data /path/to/CaveStory/data \\
      --out mappacks/cavestory \\
      [--stage Cave]          # default: Cave (First Cave)
      [--all]                 # convert every Stage/*.pxm

Data layout expected (freeware / CSE2 / doukutsu-rs roots):
  data/Stage/*.pxm *.pxe *.pxa
  data/Stage/Prt*.pbm   (BMP with optional BM→BM header quirk)
"""

from __future__ import annotations

import argparse
import struct
import sys
from collections import Counter
from pathlib import Path

from PIL import Image

# Keep in sync with scripts/mapsdk/tileset.lua / build_smb3.py
SMB_TILE_COUNT = (374 // 17) * (102 // 17)  # 132
PORTAL_TILE_COUNT = (374 // 17) * (68 // 17)  # 88
CUSTOM_TILE_BASE = SMB_TILE_COUNT + PORTAL_TILE_COUNT + 1  # 221

BD, LD, CD, MD, EQ = "¤", "×", "¸", "·", "¨"

PROP_ORDER = [
    "collision",
    "invisible",
    "breakable",
    "coinblock",
    "coin",
    "notportalable",
    "slantupleft",
    "slantupright",
    "mirror",
    "grate",
    "platform",
    "water",
    "bridge",
    "spikesleft",
    "spikestop",
    "spikesright",
    "spikesbottom",
]

# NPC_MAP top types (mirrors sources/cavestory.lua)
NPC_MAP = {
    0: None,
    1: None,
    5: "goomba",
    15: None,
    16: None,
    18: "pipe",
    26: "koopaflying",
    27: "fire",
    28: "koopaflying",
    31: "koopaflying",
    32: "mushroom",
    34: None,
    37: None,
    39: None,
    46: None,
    57: "koopaflying",
    59: "pipe",
    60: None,
    64: "goomba",
    65: "koopaflying",
    76: None,
    78: None,
    85: None,
    86: "flower",
    87: "mushroom",
    95: "cheepcheepred",
    97: None,
    125: None,
    147: "goomba",
    153: "beetle",
    173: "beetle",
    175: "goomba",
    196: "koopa",
    204: "fire",
    210: "beetle",
    211: "fire",
    238: "plant",
    241: "goomba",
    245: "fire",
    246: "plant",
    253: "mushroom",
    292: None,
    308: "goomba",
    309: "goomba",
    311: "koopaflying",
    347: "goomba",
    359: None,
}

FLAG_APPEAR = 0x0800
FLAG_HIDE = 0x8000


def read_pxm(data: bytes) -> tuple[list[int], int, int]:
    assert data[:3] == b"PXM" and data[3] == 0x10, "bad PXM"
    w, h = struct.unpack_from("<HH", data, 4)
    tiles = list(data[8 : 8 + w * h])
    assert len(tiles) == w * h
    return tiles, w, h


def read_pxa(data: bytes) -> list[int]:
    a = list(data[:256])
    while len(a) < 256:
        a.append(0)
    return a


def read_pxe(data: bytes) -> list[dict]:
    assert data[:3] == b"PXE", "bad PXE"
    assert data[3] in (0x00, 0x10)
    (n,) = struct.unpack_from("<I", data, 4)
    out = []
    for i in range(n):
        o = 8 + i * 12
        x, y, flag, event, typ, flags = struct.unpack_from("<HHHHHH", data, o)
        out.append(
            {"x": x, "y": y, "flag": flag, "event": event, "type": typ, "flags": flags}
        )
    return out


def pxa_to_props(attrib: int) -> dict:
    a = attrib & 0xFF
    water = bool(a & 0x20)
    key = a & 0xDF
    table = {
        0x00: {},
        0x01: {"collision": True},
        0x02: {"collision": True},
        0x03: {"collision": True},
        0x04: {"collision": True},
        0x05: {"collision": True},
        0x41: {"collision": True},
        0x42: {"collision": True, "spikestop": True},
        0x43: {"collision": True, "breakable": True},
        0x44: {"collision": True},
        0x46: {"collision": True},
        0x4A: {"collision": True, "platform": True},
        0x50: {"collision": True, "slantupright": True, "slopestep": 1},
        0x51: {"collision": True, "slantupright": True, "slopestep": 2},
        0x52: {"collision": True, "slantupright": True, "slopestep": 3},
        0x53: {"collision": True, "slantupright": True, "slopestep": 4},
        0x54: {"collision": True, "slantupleft": True, "slopestep": 4},
        0x55: {"collision": True, "slantupleft": True, "slopestep": 3},
        0x56: {"collision": True, "slantupleft": True, "slopestep": 2},
        0x57: {"collision": True, "slantupleft": True, "slopestep": 1},
        0x5A: {"water": True},
    }
    p = dict(table.get(key, {}))
    if water:
        p["water"] = True
    return p


def load_pbm(path: Path) -> Image.Image:
    """Cave Story .pbm is BMP; some tools use a 2-byte header quirk — try both."""
    raw = path.read_bytes()
    if raw[:2] == b"BM":
        return Image.open(path).convert("RGBA")
    # Some packs store without BM — prepend
    tmp = path.with_suffix(".bmp")
    if raw[:2] != b"BM":
        fixed = b"BM" + raw[2:] if len(raw) > 2 else raw
        tmp.write_bytes(fixed if fixed[:2] == b"BM" else b"BM" + raw)
        try:
            return Image.open(tmp).convert("RGBA")
        finally:
            if tmp.exists() and tmp != path:
                tmp.unlink(missing_ok=True)
    return Image.open(path).convert("RGBA")


def pad17_sheet(img: Image.Image, tiles_per_row: int = 16) -> Image.Image:
    """Convert 16×16 tile sheet to Mari0 17×17 (prop column)."""
    w, h = img.size
    cols = w // 16
    rows = h // 16
    out_cols = tiles_per_row
    out_rows = (cols * rows + out_cols - 1) // out_cols
    out = Image.new("RGBA", (out_cols * 17, out_rows * 17), (0, 0, 0, 0))
    idx = 0
    for ty in range(rows):
        for tx in range(cols):
            tile = img.crop((tx * 16, ty * 16, tx * 16 + 16, ty * 16 + 16))
            ox = (idx % out_cols) * 17
            oy = (idx // out_cols) * 17
            out.paste(tile, (ox, oy))
            idx += 1
    return out


def stamp_props(sheet: Image.Image, props_by_tid: dict[int, dict]) -> Image.Image:
    """Stamp PROP_ORDER (+ slopestep via RGB on slant pixels)."""
    out = sheet.copy()
    px = out.load()
    cols = out.width // 17
    rows = out.height // 17
    for tid, props in props_by_tid.items():
        if tid < 0 or tid >= cols * rows:
            continue
        tx, ty = tid % cols, tid // cols
        prop_x = tx * 17 + 16
        for name, on in props.items():
            if name == "slopestep":
                continue
            if not on or name not in PROP_ORDER:
                continue
            pi = PROP_ORDER.index(name)
            if pi > 16:
                continue
            # Default white flag
            px[prop_x, ty * 17 + pi] = (255, 255, 255, 255)
        step = props.get("slopestep")
        if step and (props.get("slantupleft") or props.get("slantupright")):
            # G=0 marks CS step; R encodes 1..4
            r = int(round(step / 4 * 255))
            for slant_name, pi in (("slantupleft", 6), ("slantupright", 7)):
                if props.get(slant_name):
                    px[prop_x, ty * 17 + pi] = (r, 0, 255, 255)
    return out


def rle_encode(mapped: list[list[int]], ents: dict[tuple[int, int], str]) -> str:
    tokens: list[str] = []
    h, w = len(mapped), len(mapped[0]) if mapped else 0
    for y in range(h):
        for x in range(w):
            tid = mapped[y][x]
            ent = ents.get((x, y))
            tokens.append(f"{tid}{LD}{ent}" if ent else str(tid))
    parts: list[str] = []
    i, n = 0, len(tokens)
    while i < n:
        if LD in tokens[i]:
            parts.append(tokens[i])
            i += 1
            continue
        j = i + 1
        while j < n and tokens[j] == tokens[i] and LD not in tokens[j]:
            j += 1
        run = j - i
        parts.append(f"{tokens[i]}{MD}{run}" if run > 1 else tokens[i])
        i = j
    return BD.join(parts)


def find_stage_dir(data: Path) -> Path:
    for cand in (data / "Stage", data / "stage", data):
        if cand.is_dir() and any(cand.glob("*.pxm")):
            return cand
    raise FileNotFoundError(f"No Stage/*.pxm under {data}")


def convert_stage(stage_dir: Path, name: str, out: Path, unmapped: Counter) -> None:
    pxm = (stage_dir / f"{name}.pxm").read_bytes()
    pxa_path = stage_dir / f"{name}.pxa"
    # Tileset PXA often shares map name; else try Prt prefix convention
    if not pxa_path.exists():
        raise FileNotFoundError(pxa_path)
    pxa = read_pxa(pxa_path.read_bytes())
    pxe_path = stage_dir / f"{name}.pxe"
    pxe = read_pxe(pxe_path.read_bytes()) if pxe_path.exists() else []

    tiles, w, h = read_pxm(pxm)
    props_by_tid = {i: pxa_to_props(pxa[i]) for i in range(256)}

    # Graphics
    prt = stage_dir / f"Prt{name}.pbm"
    if not prt.exists():
        # fallback: any Prt matching
        alts = list(stage_dir.glob(f"Prt{name}.*")) + list(stage_dir.glob("PrtCave.pbm"))
        prt = alts[0] if alts else prt
    if not prt.exists():
        print(f"  WARN: no tileset image for {name}, writing solid placeholder sheet")
        sheet = Image.new("RGBA", (16 * 17, 16 * 17), (80, 80, 80, 255))
    else:
        img = load_pbm(prt)
        sheet = pad17_sheet(img, 16)

    sheet = stamp_props(sheet, props_by_tid)

    # Map tiles: CS index 0 → empty custom base; else base+index
    mapped = []
    for y in range(h):
        row = []
        for x in range(w):
            tid = tiles[y * w + x]
            row.append(CUSTOM_TILE_BASE if tid == 0 else CUSTOM_TILE_BASE + tid)
        mapped.append(row)

    ents: dict[tuple[int, int], str] = {}
    spawn = None
    for e in pxe:
        if (e["flags"] & FLAG_APPEAR) or (e["flags"] & FLAG_HIDE):
            continue
        typ = e["type"]
        if typ not in NPC_MAP:
            unmapped[typ] += 1
            continue
        name_ent = NPC_MAP[typ]
        if not name_ent:
            continue
        x, y = e["x"], e["y"]
        if 0 <= x < w and 0 <= y < h:
            ents[(x, y)] = name_ent

    # Spawn: left solid floor
    if spawn is None:
        for x in range(1, min(12, w)):
            for y in range(h - 2, 1, -1):
                if mapped[y][x] == CUSTOM_TILE_BASE and mapped[y + 1][x] > CUSTOM_TILE_BASE:
                    spawn = (x, y)
                    break
            if spawn:
                break
    if spawn is None:
        spawn = (2, max(1, h - 3))
    ents[spawn] = "spawn"
    # Flag near right
    fx, fy = w - 1, max(1, h - 3)
    for y in range(h - 1, 0, -1):
        if mapped[y][fx] > CUSTOM_TILE_BASE:
            fy = max(0, y - 1)
            break
    ents[(fx, fy)] = "flag"

    body = rle_encode(mapped, ents)
    text = f"{h}{CD}{body}{CD}spriteset{EQ}1{CD}timelimit{EQ}0"

    out.mkdir(parents=True, exist_ok=True)
    # Level naming: First Cave → 1-1
    level_name = "1-1" if name.lower() == "cave" else name
    (out / f"{level_name}.txt").write_text(text, encoding="utf-8")
    # Per-stage tiles — for single stage write tiles.png; multi would need merge
    sheet.save(out / "tiles.png")
    print(f"  wrote {level_name}.txt ({w}x{h}) tiles.png from {prt.name if prt.exists() else 'placeholder'}")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--data", type=Path, required=True, help="Cave Story data root (contains Stage/)")
    ap.add_argument("--out", type=Path, default=Path("mappacks/cavestory"))
    ap.add_argument("--stage", default="Cave", help="Map stem (default First Cave)")
    ap.add_argument("--all", action="store_true", help="Convert all Stage/*.pxm")
    ap.add_argument("--histogram", action="store_true", help="Print PXE type histogram and exit")
    args = ap.parse_args()

    stage_dir = find_stage_dir(args.data)
    print(f"Stage dir: {stage_dir}")

    if args.histogram:
        hist: Counter = Counter()
        for pxe in stage_dir.glob("*.pxe"):
            for e in read_pxe(pxe.read_bytes()):
                hist[e["type"]] += 1
        for typ, n in hist.most_common(40):
            mapped = NPC_MAP.get(typ, "?")
            print(f"  {typ:4d}  {n:5d}  -> {mapped}")
        return 0

    unmapped: Counter = Counter()
    names = [p.stem for p in sorted(stage_dir.glob("*.pxm"))] if args.all else [args.stage]
    args.out.mkdir(parents=True, exist_ok=True)
    (args.out / "settings.txt").write_text(
        "\n".join(
            [
                "name=cave story (local)",
                "author=Pixel — do not redistribute assets",
                "description=Regenerated locally via mapsdk/build_cavestory.py from your CS install",
                "",
            ]
        ),
        encoding="utf-8",
    )

    for name in names:
        if not (stage_dir / f"{name}.pxm").exists():
            print(f"SKIP missing {name}.pxm", file=sys.stderr)
            continue
        print(f"Converting {name} …")
        convert_stage(stage_dir, name, args.out, unmapped)

    if unmapped:
        print("Unmapped NPC types:")
        for typ, n in unmapped.most_common(20):
            print(f"  {typ}: {n}")
    print(f"Done → {args.out} (gitignored; do not commit)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
