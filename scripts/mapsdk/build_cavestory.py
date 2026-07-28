#!/usr/bin/env python3
"""
Build local mappacks/cavestory from a Cave Story data folder.

LEGAL: Pixel's Cave Story assets must NEVER be committed. Output is gitignored.
Format reference: doukutsu-rs (MIT) — see licenses/doukutsu-rs.MIT
Do NOT use CSMP source (CC BY-NC-SA) — freeware / CSE2 data only.

Usage:
  python3 scripts/mapsdk/build_cavestory.py \\
      --data /path/to/CaveStory/data \\
      --out mappacks/cavestory \\
      [--stage Cave]          # default: Cave (First Cave)
      [--all]                 # convert every Stage/*.pxm with resolvable tileset

Data layout expected (freeware / CSE2 / doukutsu-rs roots):
  data/Stage/*.pxm *.pxe *.pxa
  data/Stage/Prt*.pbm|*.png
"""

from __future__ import annotations

import argparse
import re
import struct
import sys
from collections import Counter
from pathlib import Path

from PIL import Image

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

# Map stem → tileset stem (freeware stage.tbl knowledge + CSE2 layout).
# Used when Map.pxa is missing (most maps share a tileset PXA).
STAGE_TILESETS: dict[str, str] = {
    "0": "0",
    "Pens1": "Pens",
    "Pens2": "Pens",
    "Eggs": "Eggs",
    "Eggs2": "Eggs",
    "EggX": "EggX",
    "EggX2": "EggX",
    "EggIn": "EggIn",
    "EggR": "Eggs",
    "EggR2": "Eggs",
    "Egg1": "Eggs",
    "Egg6": "Eggs",
    "EgEnd1": "Eggs",
    "EgEnd2": "Eggs",
    "Store": "Store",
    "Weed": "Weed",
    "WeedS": "Weed",
    "WeedD": "Weed",
    "WeedB": "Weed",
    "Barr": "Barr",
    "MazeI": "Maze",
    "MazeH": "Maze",
    "MazeW": "Maze",
    "MazeO": "Maze",
    "MazeD": "Maze",
    "MazeA": "Maze",
    "MazeB": "Maze",
    "MazeS": "Maze",
    "MazeM": "Maze",
    "Sand": "Sand",
    "SandE": "Sand",
    "SandW": "Sand",
    "Mimi": "Mimi",
    "Mimo": "Mimi",
    "Miza": "Mimi",
    "Cave": "Cave",
    "River": "River",
    "Gard": "Gard",
    "Almond": "Almond",
    "Oside": "Oside",
    "Cent": "Cent",
    "CentW": "Cent",
    "Jail1": "Jail",
    "Jail2": "Jail",
    "Jail3": "Jail",
    "White": "White",
    "Fall": "Fall",
    "Hell1": "Hell",
    "Hell2": "Hell",
    "Hell3": "Hell",
    "Hell4": "Hell",
    "Hell42": "Hell",
    "Labo": "Labo",
    "Ballo1": "0",
    "Ballo2": "0",
    "Blcny1": "White",
    "Blcny2": "White",
    "Cemet": "Gard",
    "Chako": "Mimi",
    "Clock": "White",
    "Comu": "Pens",
    "Cook": "Weed",
    "Cthu": "Oside",
    "Cthu2": "Oside",
    "Curly": "Weed",
    "CurlyS": "Weed",
    "Dark": "Maze",
    "Drain": "Gard",
    "Frog": "Weed",
    "Island": "River",
    "Itoh": "Pens",
    "Jenka1": "Sand",
    "Jenka2": "Sand",
    "Kings": "White",
    "Little": "Pens",
    "Lounge": "Pens",
    "Malco": "Weed",
    "Mapi": "Mimi",
    "MiBox": "Mimi",
    "Ring1": "Eggs",
    "Ring2": "Eggs",
    "Ring3": "Eggs",
    "Statue": "Oside",
    "Pool": "Pens",
    "Prefa1": "Weed",
    "Prefa2": "Weed",
    "Priso1": "Jail",
    "Priso2": "Jail",
    "Shelt": "Sand",
    "Start": "Pens",
    "Ostep": "Oside",
    "Pixel": "Pens",
    "e_Blcn": "White",
    "e_Ceme": "Gard",
    "e_Jenk": "Sand",
    "e_Labo": "Labo",
    "e_Malc": "Weed",
    "e_Maze": "Maze",
    "e_Sky": "White",
}

# Preferred playable order (First Cave first). Remaining maps append alphabetically.
STAGE_PRIORITY = [
    "Cave",
    "Pens1",
    "Pens2",
    "Eggs",
    "EggX",
    "EggIn",
    "Weed",
    "Barr",
    "MazeI",
    "Sand",
    "Mimi",
    "River",
    "Gard",
    "Almond",
    "Oside",
    "Cent",
    "Jail1",
    "Jail2",
    "White",
    "Ballos",
    "Ballo1",
    "Ballo2",
    "Hell1",
    "Hell2",
    "Hell3",
    "Hell4",
]


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


def is_solid_attrib(attrib: int) -> bool:
    return bool(pxa_to_props(attrib).get("collision"))


def load_prt(path: Path) -> Image.Image:
    """Load Prt*.pbm / .bmp / .png (CSE2 quirk: PBM may lack BM magic)."""
    raw = path.read_bytes()
    if path.suffix.lower() in {".png", ".bmp"} or raw[:2] == b"BM":
        return Image.open(path).convert("RGBA")
    tmp = path.with_suffix(".bmp")
    fixed = b"BM" + raw[2:] if len(raw) > 2 else b"BM" + raw
    if fixed[:2] != b"BM":
        fixed = b"BM" + raw
    tmp.write_bytes(fixed)
    try:
        return Image.open(tmp).convert("RGBA")
    finally:
        tmp.unlink(missing_ok=True)


def find_prt(stage_dir: Path, tileset: str) -> Path | None:
    for ext in (".pbm", ".bmp", ".png", ".PBM", ".PNG"):
        p = stage_dir / f"Prt{tileset}{ext}"
        if p.exists():
            return p
    alts = list(stage_dir.glob(f"Prt{tileset}.*"))
    return alts[0] if alts else None


def resolve_tileset(stage_dir: Path, name: str) -> str | None:
    if (stage_dir / f"{name}.pxa").exists():
        return name
    if name in STAGE_TILESETS:
        ts = STAGE_TILESETS[name]
        if (stage_dir / f"{ts}.pxa").exists():
            return ts
    base = re.sub(r"\d+$", "", name)
    if base and (stage_dir / f"{base}.pxa").exists():
        return base
    if base in STAGE_TILESETS:
        ts = STAGE_TILESETS[base]
        if (stage_dir / f"{ts}.pxa").exists():
            return ts
    return None


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


def place_spawn(
    tiles: list[int], w: int, h: int, pxa: list[int]
) -> tuple[int, int]:
    """Stand on solid floor with 2-tile air column and side clearance (Mario width)."""

    def solid(x: int, y: int) -> bool:
        if not (0 <= x < w and 0 <= y < h):
            return True
        return is_solid_attrib(pxa[tiles[y * w + x]])

    def air(x: int, y: int) -> bool:
        return not solid(x, y)

    # Prefer left third; two passes — both sides clear, then one side.
    x_order = list(range(1, min(w - 1, max(16, w // 3)))) + list(
        range(min(w - 1, max(16, w // 3)), w - 1)
    )

    def candidates(need_both: bool):
        for x in x_order:
            for y in range(h - 2, 1, -1):
                if not (air(x, y) and solid(x, y + 1) and air(x, y - 1)):
                    continue
                left_ok = air(x - 1, y) and air(x - 1, y - 1)
                right_ok = air(x + 1, y) and air(x + 1, y - 1)
                if need_both and left_ok and right_ok:
                    return x, y
                if not need_both and (left_ok or right_ok):
                    return x, y
        return None

    hit = candidates(True) or candidates(False)
    if hit:
        return hit
    for x in range(1, w - 1):
        for y in range(h - 2, 1, -1):
            if air(x, y) and solid(x, y + 1) and air(x, y - 1):
                return x, y
    return 2, max(1, h - 3)


def place_flag(tiles: list[int], w: int, h: int, pxa: list[int]) -> tuple[int, int]:
    fx = w - 2
    for y in range(h - 1, 0, -1):
        if is_solid_attrib(pxa[tiles[y * w + fx]]):
            return fx, max(0, y - 1)
    return fx, max(1, h - 3)


def stamp_props_on_sheet(
    sheet: Image.Image, props_by_local: dict[int, dict], sheet_base: int
) -> None:
    """Stamp props for local indices 0..n onto sheet starting at sheet_base tile index."""
    px = sheet.load()
    cols = sheet.width // 17
    rows = sheet.height // 17
    for local, props in props_by_local.items():
        tid = sheet_base + local
        if tid < 0 or tid >= cols * rows:
            continue
        tx, ty = tid % cols, tid // cols
        prop_x = tx * 17 + 16
        for name, on in props.items():
            if name == "slopestep" or not on or name not in PROP_ORDER:
                continue
            pi = PROP_ORDER.index(name)
            if pi <= 16:
                px[prop_x, ty * 17 + pi] = (255, 255, 255, 255)
        step = props.get("slopestep")
        if step and (props.get("slantupleft") or props.get("slantupright")):
            r = int(round(int(step) / 4 * 255))
            for slant_name, pi in (("slantupleft", 6), ("slantupright", 7)):
                if props.get(slant_name):
                    px[prop_x, ty * 17 + pi] = (r, 0, 255, 255)


def paste_prt_tiles(sheet: Image.Image, prt: Image.Image, sheet_base: int) -> int:
    """Paste 16×16 Prt tiles into 17-stride sheet at sheet_base; return tile count."""
    cols_src = prt.width // 16
    rows_src = prt.height // 16
    n = cols_src * rows_src
    out_cols = sheet.width // 17
    for i in range(n):
        tid = sheet_base + i
        sx, sy = i % cols_src, i // cols_src
        tile = prt.crop((sx * 16, sy * 16, sx * 16 + 16, sy * 16 + 16))
        # Force index 0 (air) fully transparent — Prt often stores opaque black.
        if i == 0:
            tile = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        ox = (tid % out_cols) * 17
        oy = (tid // out_cols) * 17
        sheet.paste(tile, (ox, oy))
    return n


def convert_all(stage_dir: Path, out: Path, unmapped: Counter) -> int:
    names = [p.stem for p in sorted(stage_dir.glob("*.pxm"))]
    # Order: priority first, then rest alpha
    pri = [n for n in STAGE_PRIORITY if n in names]
    rest = sorted(n for n in names if n not in pri)
    ordered = pri + rest

    # Pass 1: resolve tilesets + collect unique tileset stems
    resolved: list[tuple[str, str]] = []
    tilesets_needed: list[str] = []
    for name in ordered:
        ts = resolve_tileset(stage_dir, name)
        if not ts:
            print(f"  SKIP {name}: no tileset/pxa", file=sys.stderr)
            continue
        if find_prt(stage_dir, ts) is None:
            print(f"  SKIP {name}: missing Prt{ts}", file=sys.stderr)
            continue
        resolved.append((name, ts))
        if ts not in tilesets_needed:
            tilesets_needed.append(ts)

    if not resolved:
        print("FAIL: no stages resolved", file=sys.stderr)
        return 1

    # Build unified sheet: each tileset gets a contiguous block of local tiles
    # Estimate capacity
    total_tiles = 0
    ts_info: dict[str, tuple[Image.Image, list[int], int]] = {}
    for ts in tilesets_needed:
        prt_path = find_prt(stage_dir, ts)
        assert prt_path
        prt = load_prt(prt_path)
        pxa = read_pxa((stage_dir / f"{ts}.pxa").read_bytes())
        n = (prt.width // 16) * (prt.height // 16)
        ts_info[ts] = (prt, pxa, n)
        total_tiles += n

    cols = 16
    rows = (total_tiles + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * 17, rows * 17), (0, 0, 0, 0))
    ts_base: dict[str, int] = {}
    cursor = 0
    for ts in tilesets_needed:
        prt, pxa, n = ts_info[ts]
        ts_base[ts] = cursor
        paste_prt_tiles(sheet, prt, cursor)
        props = {i: pxa_to_props(pxa[i]) for i in range(min(256, n))}
        props[0] = {}  # air never collides
        stamp_props_on_sheet(sheet, props, cursor)
        cursor += n

    out.mkdir(parents=True, exist_ok=True)
    for old in out.glob("*.txt"):
        old.unlink()
    sheet.save(out / "tiles.png")
    print(f"  tiles.png {sheet.size}  tilesets={len(tilesets_needed)}  tiles={cursor}")

    # Pass 2: emit levels as 1-1, 1-2, …
    manifest: list[str] = []
    for idx, (name, ts) in enumerate(resolved, start=1):
        level_name = f"1-{idx}"
        pxm = (stage_dir / f"{name}.pxm").read_bytes()
        tiles, w, h = read_pxm(pxm)
        pxa = ts_info[ts][1]
        base = CUSTOM_TILE_BASE + ts_base[ts]
        mapped: list[list[int]] = []
        for y in range(h):
            row = []
            for x in range(w):
                tid = tiles[y * w + x]
                # CS 0 → air at tileset local 0
                row.append(base if tid == 0 else base + tid)
            mapped.append(row)

        ents: dict[tuple[int, int], str] = {}
        pxe_path = stage_dir / f"{name}.pxe"
        if pxe_path.exists():
            for e in read_pxe(pxe_path.read_bytes()):
                if (e["flags"] & FLAG_APPEAR) or (e["flags"] & FLAG_HIDE):
                    continue
                ent = NPC_MAP.get(e["type"], "?")
                if ent == "?":
                    unmapped[e["type"]] += 1
                    continue
                if not ent:
                    continue
                x, y = e["x"], e["y"]
                if 0 <= x < w and 0 <= y < h:
                    ents[(x, y)] = ent

        sx, sy = place_spawn(tiles, w, h, pxa)
        ents[(sx, sy)] = "spawn"
        fx, fy = place_flag(tiles, w, h, pxa)
        ents[(fx, fy)] = "flag"

        body = rle_encode(mapped, ents)
        text = f"{h}{CD}{body}{CD}spriteset{EQ}1{CD}timelimit{EQ}0"
        (out / f"{level_name}.txt").write_text(text, encoding="utf-8")
        manifest.append(f"{level_name}={name} tileset={ts} {w}x{h} spawn={sx},{sy}")
        print(f"  wrote {level_name}.txt ← {name} ({w}x{h}) spawn=({sx},{sy})")

    (out / "STAGES.txt").write_text(
        "Cave Story → Mari0 CE level map (local rebuild)\n"
        + "\n".join(manifest)
        + "\n",
        encoding="utf-8",
    )
    return 0


def convert_one(stage_dir: Path, name: str, out: Path, unmapped: Counter) -> None:
    ts = resolve_tileset(stage_dir, name)
    if not ts:
        raise FileNotFoundError(f"No tileset for {name}")
    pxa_path = stage_dir / f"{ts}.pxa"
    pxa = read_pxa(pxa_path.read_bytes())
    pxm = (stage_dir / f"{name}.pxm").read_bytes()
    tiles, w, h = read_pxm(pxm)
    pxe_path = stage_dir / f"{name}.pxe"
    pxe = read_pxe(pxe_path.read_bytes()) if pxe_path.exists() else []

    prt_path = find_prt(stage_dir, ts)
    if prt_path is None:
        print(f"  WARN: no Prt{ts}, placeholder sheet")
        n = 256
        sheet = Image.new("RGBA", (16 * 17, 16 * 17), (0, 0, 0, 0))
        # solid placeholders for colliding tiles
        for i in range(1, n):
            if is_solid_attrib(pxa[i]):
                tx, ty = i % 16, i // 16
                Image.Image.paste(
                    sheet,
                    Image.new("RGBA", (16, 16), (90, 100, 110, 255)),
                    (tx * 17, ty * 17),
                )
    else:
        prt = load_prt(prt_path)
        n = (prt.width // 16) * (prt.height // 16)
        cols = 16
        rows = max(1, (n + cols - 1) // cols)
        sheet = Image.new("RGBA", (cols * 17, rows * 17), (0, 0, 0, 0))
        paste_prt_tiles(sheet, prt, 0)

    props = {i: pxa_to_props(pxa[i]) for i in range(min(256, n))}
    props[0] = {}
    stamp_props_on_sheet(sheet, props, 0)

    mapped: list[list[int]] = []
    for y in range(h):
        row = []
        for x in range(w):
            tid = tiles[y * w + x]
            row.append(CUSTOM_TILE_BASE if tid == 0 else CUSTOM_TILE_BASE + tid)
        mapped.append(row)

    ents: dict[tuple[int, int], str] = {}
    for e in pxe:
        if (e["flags"] & FLAG_APPEAR) or (e["flags"] & FLAG_HIDE):
            continue
        ent = NPC_MAP.get(e["type"], "?")
        if ent == "?":
            unmapped[e["type"]] += 1
            continue
        if not ent:
            continue
        x, y = e["x"], e["y"]
        if 0 <= x < w and 0 <= y < h:
            ents[(x, y)] = ent

    sx, sy = place_spawn(tiles, w, h, pxa)
    ents[(sx, sy)] = "spawn"
    fx, fy = place_flag(tiles, w, h, pxa)
    ents[(fx, fy)] = "flag"

    body = rle_encode(mapped, ents)
    text = f"{h}{CD}{body}{CD}spriteset{EQ}1{CD}timelimit{EQ}0"
    out.mkdir(parents=True, exist_ok=True)
    level_name = "1-1" if name.lower() == "cave" else name
    # Prefer N-M naming even for single non-Cave
    if not re.match(r"^\d+-\d+$", level_name):
        level_name = "1-1"
    (out / f"{level_name}.txt").write_text(text, encoding="utf-8")
    sheet.save(out / "tiles.png")
    print(
        f"  wrote {level_name}.txt ({w}x{h}) spawn=({sx},{sy}) "
        f"tiles.png from {prt_path.name if prt_path else 'placeholder'}"
    )


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    ap.add_argument("--data", type=Path, required=True, help="Cave Story data root")
    ap.add_argument("--out", type=Path, default=Path("mappacks/cavestory"))
    ap.add_argument("--stage", default="Cave", help="Map stem (default First Cave)")
    ap.add_argument("--all", action="store_true", help="Convert all Stage/*.pxm")
    ap.add_argument("--histogram", action="store_true", help="PXE type histogram")
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

    if args.all:
        rc = convert_all(stage_dir, args.out, unmapped)
    else:
        if not (stage_dir / f"{args.stage}.pxm").exists():
            print(f"missing {args.stage}.pxm", file=sys.stderr)
            return 1
        print(f"Converting {args.stage} …")
        convert_one(stage_dir, args.stage, args.out, unmapped)
        rc = 0

    if unmapped:
        print("Unmapped NPC types:")
        for typ, n in unmapped.most_common(20):
            print(f"  {typ}: {n}")
    print(f"Done → {args.out} (gitignored; do not commit)")
    return rc


if __name__ == "__main__":
    sys.exit(main())
