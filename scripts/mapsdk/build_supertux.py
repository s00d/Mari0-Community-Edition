#!/usr/bin/env python3
"""
Build local mappacks/supertux from a SuperTux data/ tree.

LEGAL:
  - Do NOT copy SuperTux C++/engine (GPL-3) into Mari0 src/
  - Levels/art declaring CC-BY-SA may be converted; LICENSE + AUTHORS.txt written
  - Output mappack is gitignored (like smb3/cavestory) — regenerate locally
  - Raw clone lives under toconvert/supertux/ (also gitignored)

Usage:
  python3 scripts/mapsdk/build_supertux.py \\
      --data toconvert/supertux/data \\
      --out mappacks/supertux \\
      [--world world1] \\
      [--histogram] \\
      [--no-tileset]
"""

from __future__ import annotations

import argparse
import re
import sys
from collections import Counter
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    Image = None  # type: ignore

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

ALLOWED_LICENSES = {
    "cc-by-sa 4.0 international",
    "cc-by-sa 4.0",
    "cc-by-sa 3.0",
    "cc-by-sa-3.0",
    "gpl-2+/cc-by-sa-3.0",
    "gpl 2+ / cc-by-sa 3.0",
    "gpl 2+/cc-by-sa 3.0",
}

ST_OBJECTS = {
    "spawnpoint": ("spawn", None),
    "spawn_point": ("spawn", None),
    "snowball": ("enemy", "goomba"),
    "smartball": ("enemy", "goomba"),
    "bouncingsnowball": ("enemy", "goomba"),
    "mriceblock": ("enemy", "koopa"),
    "smartblock": ("enemy", "koopa"),
    "mrbomb": ("enemy", "beetle"),
    "haywire": ("enemy", "beetle"),
    "stalactite": ("enemy", "thwomp"),
    "yeti_stalactite": ("enemy", "thwomp"),
    "crusher": ("enemy", "thwomp"),
    "flyingsnowball": ("enemy", "koopaflying"),
    "fish": ("enemy", "cheepcheepred"),
    "fish-swimming": ("enemy", "cheepcheepred"),
    "fish-harmless": ("skip", None),
    "dive-mine": ("enemy", "cheepcheepred"),
    "spiky": ("enemy", "spikey"),
    "jumpy": ("enemy", "splitter"),
    "zeekling": ("enemy", "lakito"),
    "dispenser": ("enemy", "lakito"),
    "firefly": ("enemy", "fire"),
    "bonusblock": ("enemy", "mushroom"),
    "coin": ("coin", "manycoins"),
    "trampoline": ("entity", "spring"),
    "platform": ("entity", "platform"),
    "weak_block": ("skip", None),
    "unstable_tile": ("skip", None),
    "infoblock": ("skip", None),
    "invisible_wall": ("skip", None),
    "secretarea": ("skip", None),
    "ambient_sound": ("skip", None),
    "ambient-sound": ("skip", None),
    "scripttrigger": ("skip", None),
    "decal": ("skip", None),
    "torch": ("skip", None),
    "climbable": ("skip", None),
    "background": ("skip", None),
    "camera": ("skip", None),
    "gradient": ("skip", None),
    "path": ("skip", None),
    "tilemap": ("skip", None),
    "music": ("skip", None),
    "ambient-light": ("skip", None),
    "sequencetrigger": ("finish", "flag"),
    "short_fuse": ("enemy", "beetle"),
    "snowman": ("enemy", "goomba"),
    "fish-chasing": ("enemy", "cheepcheepred"),
    "lit-object": ("skip", None),
    "switch": ("skip", None),
    "pushbutton": ("skip", None),
    "init-script": ("skip", None),
    "particles-snow": ("skip", None),
    "rublight": ("skip", None),
    "scriptedobject": ("skip", None),
    "button": ("skip", None),
    "name": ("skip", None),  # sector metadata leak in hist; ignore if seen as head
    "sspiky": ("enemy", "spikey"),
    "captainsnowball": ("enemy", "goomba"),
    "goldbomb": ("enemy", "beetle"),
    "powerup": ("enemy", "mushroom"),
    "flame": ("enemy", "fire"),
    "yeti": ("enemy", "bowser"),
    "wind": ("skip", None),
    "bumper": ("skip", None),
    "circleplatform": ("entity", "platform"),
    "particles-clouds": ("skip", None),
}

LICENSE_TEXT = """\
Creative Commons Attribution-ShareAlike 4.0 International (CC-BY-SA 4.0)

This mappack contains levels and artwork derived from SuperTux data files
that declare CC-BY-SA (or compatible share-alike) licenses. See AUTHORS.txt
for per-level attribution (author + original license string).

SuperTux game engine code (GPL-3) is NOT included and was NOT used as a
source for the Mari0 CE engine. This directory is data only.

https://creativecommons.org/licenses/by-sa/4.0/
https://www.supertux.org/
"""


# --- sexpr ---


def parse_sexpr(s: str):
    pos = 0
    n = len(s)

    def skip() -> None:
        nonlocal pos
        while pos < n:
            c = s[pos]
            if c == ";":
                nl = s.find("\n", pos)
                pos = n if nl < 0 else nl + 1
            elif c.isspace():
                pos += 1
            else:
                break

    def node():
        nonlocal pos
        skip()
        if pos >= n:
            return None
        c = s[pos]
        if c == "(":
            pos += 1
            t: list = []
            while True:
                skip()
                if pos >= n:
                    return t
                if s[pos] == ")":
                    pos += 1
                    return t
                t.append(node())
        if c == '"':
            pos += 1
            buf: list[str] = []
            while pos < n:
                ch = s[pos]
                if ch == "\\" and pos + 1 < n:
                    buf.append(s[pos + 1])
                    pos += 2
                elif ch == '"':
                    pos += 1
                    return "".join(buf)
                else:
                    buf.append(ch)
                    pos += 1
            return "".join(buf)
        end = pos
        while end < n and s[end] not in " \t\r\n();":
            end += 1
        tok = s[pos:end]
        pos = end
        try:
            if tok.startswith(("+", "-")) and tok[1:].replace(".", "", 1).isdigit():
                return float(tok) if "." in tok else int(tok)
            if tok.replace(".", "", 1).isdigit():
                return float(tok) if "." in tok else int(tok)
        except ValueError:
            pass
        return tok

    return node()


def field(node, name: str):
    if not isinstance(node, list):
        return None, None
    for c in node[1:]:
        if isinstance(c, list) and c and c[0] == name:
            return (c[1] if len(c) > 1 else None), c
    return None, None


def children(node, name: str | None = None):
    if not isinstance(node, list):
        return []
    out = []
    for c in node[1:]:
        if isinstance(c, list) and c and (name is None or c[0] == name):
            out.append(c)
    return out


def as_string(v) -> str | None:
    if isinstance(v, str):
        return v
    if isinstance(v, list) and v and v[0] == "_" and len(v) > 1 and isinstance(v[1], str):
        return v[1]
    if isinstance(v, (int, float)):
        return str(v)
    return None


def is_true(v) -> bool:
    return v is True or v == "#t"


def decode_tiles(tiles_node: list, w: int, h: int) -> list[int]:
    out: list[int] = []
    i = 1
    while i < len(tiles_node):
        v = tiles_node[i]
        if not isinstance(v, (int, float)):
            raise ValueError(f"decode_tiles non-number at {i}")
        v = int(v)
        if v < 0:
            val = int(tiles_node[i + 1])
            out.extend([val] * (-v))
            i += 2
        else:
            out.append(v)
            i += 1
    if len(out) != w * h:
        raise AssertionError(f"tile count {len(out)} != {w}*{h}")
    return out


def normalize_license(s: str | None) -> str | None:
    if not s:
        return None
    return re.sub(r"\s+", " ", s.strip().lower())


def license_ok(root) -> tuple[bool, str | None]:
    lic = as_string(field(root, "license")[0])
    key = normalize_license(lic)
    return (key in ALLOWED_LICENSES if key else False), lic


def attr_to_props(attr: int, data: int = 0) -> dict[str, bool]:
    p: dict[str, bool] = {}
    solid = attr & 1
    unisolid = attr & 2
    brick = attr & 4
    slope = attr & 16
    water = attr & 512
    hurts = attr & 1024
    if solid or unisolid:
        p["collision"] = True
    if unisolid:
        p["platform"] = True
    if brick:
        p["breakable"] = True
        p["collision"] = True
    if water:
        p["water"] = True
    if hurts:
        p["spikestop"] = True
    if slope:
        p["collision"] = True
        form = data & 3
        if form in (1, 3):
            p["slantupleft"] = True
        else:
            p["slantupright"] = True
    return p


def tile_flags_from_node(t: list) -> dict[str, bool]:
    p: dict[str, bool] = {}
    if is_true(field(t, "solid")[0]):
        p["collision"] = True
    if is_true(field(t, "unisolid")[0]):
        p["platform"] = True
        p["collision"] = True
    if is_true(field(t, "hurts")[0]):
        p["spikestop"] = True
    if is_true(field(t, "water")[0]):
        p["water"] = True
    if is_true(field(t, "brick")[0]):
        p["breakable"] = True
        p["collision"] = True
    st = field(t, "slope-type")[0]
    if isinstance(st, (int, float)):
        p["collision"] = True
        if int(st) % 2 == 1:
            p["slantupleft"] = True
        else:
            p["slantupright"] = True
    return p


def first_image(node: list) -> str | None:
    _, imglist = field(node, "images")
    if not imglist:
        return None
    for x in imglist[1:]:
        if isinstance(x, str):
            return x
    return None


def parse_strf(text: str) -> tuple[dict[int, dict[str, bool]], dict[int, object]]:
    root = parse_sexpr(text)
    props: dict[int, dict[str, bool]] = {}
    images: dict[int, object] = {}
    if not isinstance(root, list):
        return props, images
    for t in root[1:]:
        if not isinstance(t, list) or not t:
            continue
        if t[0] == "tile":
            tid = field(t, "id")[0]
            if isinstance(tid, (int, float)) and int(tid) > 0:
                tid = int(tid)
                props[tid] = tile_flags_from_node(t)
                img = first_image(t)
                if img:
                    images[tid] = img
        elif t[0] == "tiles":
            w = int(field(t, "width")[0] or 1)
            h = int(field(t, "height")[0] or 1)
            _, ids_node = field(t, "ids")
            _, attrs_node = field(t, "attributes")
            _, datas_node = field(t, "datas")
            img = first_image(t)
            if not ids_node:
                continue
            idx = 0
            for j in range(1, len(ids_node)):
                tid = ids_node[j]
                if not isinstance(tid, (int, float)):
                    continue
                tid = int(tid)
                idx += 1
                if tid <= 0:
                    continue
                attr = 0
                data = 0
                if attrs_node and j < len(attrs_node) and isinstance(attrs_node[j], (int, float)):
                    attr = int(attrs_node[j])
                if datas_node and j < len(datas_node) and isinstance(datas_node[j], (int, float)):
                    data = int(datas_node[j])
                props[tid] = attr_to_props(attr, data)
                if img:
                    images[tid] = {"sheet": img, "cell": idx - 1, "cols": w, "rows": h}
    return props, images


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


def px_to_tile(v) -> int:
    return int(float(v or 0) // 32)


def place_spawn(mapped: list[list[int]], base: int) -> tuple[int, int]:
    h, w = len(mapped), len(mapped[0]) if mapped else 0
    for x in range(1, min(12, w)):
        for y in range(h - 2, 1, -1):
            if mapped[y][x] == base and mapped[y + 1][x] > base:
                return x, y
    return 2, max(1, h - 3)


def place_flag(mapped: list[list[int]], base: int) -> tuple[int, int]:
    h, w = len(mapped), len(mapped[0]) if mapped else 0
    x = w - 1
    y = max(1, h - 3)
    for yy in range(h - 1, 0, -1):
        if mapped[yy][x] > base:
            return x, max(0, yy - 1)
    return x, y


def convert_stl(
    text: str,
    tile_remap: dict[int, int],
    unmapped: Counter,
    attribution: list[dict],
    filename: str,
) -> tuple[str, list[list[int]], set[int]] | None:
    root = parse_sexpr(text)
    if not isinstance(root, list) or not root or root[0] != "supertux-level":
        print(f"  SKIP {filename}: not supertux-level", file=sys.stderr)
        return None
    ok, lic = license_ok(root)
    if not ok:
        print(f"  SKIP {filename}: license={lic!r}", file=sys.stderr)
        return None

    sector = None
    for sec in children(root, "sector"):
        sn = as_string(field(sec, "name")[0])
        if sn == "main" or sector is None:
            sector = sec
            if sn == "main":
                break
    if sector is None:
        print(f"  SKIP {filename}: no sector", file=sys.stderr)
        return None

    solid = None
    for tm in children(sector, "tilemap"):
        if is_true(field(tm, "solid")[0]):
            solid = tm
            break
    if solid is None:
        print(f"  SKIP {filename}: no solid tilemap", file=sys.stderr)
        return None

    w = int(field(solid, "width")[0])
    h = int(field(solid, "height")[0])
    _, tiles_node = field(solid, "tiles")
    tiles = decode_tiles(tiles_node, w, h)
    used = {t for t in tiles if t}

    mapped: list[list[int]] = []
    for y in range(h):
        row = []
        for x in range(w):
            tid = tiles[y * w + x]
            if tid == 0:
                row.append(CUSTOM_TILE_BASE)
            else:
                row.append(tile_remap.get(tid, CUSTOM_TILE_BASE + 1))
        mapped.append(row)

    ents: dict[tuple[int, int], str] = {}
    spawn = None
    finish = None
    for obj in children(sector):
        head = obj[0] if obj else None
        if not isinstance(head, str):
            continue
        m = ST_OBJECTS.get(head)
        if m is None:
            unmapped[head] += 1
            continue
        kind, name = m
        if kind == "skip":
            continue
        tx = px_to_tile(field(obj, "x")[0])
        ty = px_to_tile(field(obj, "y")[0])
        tx = max(0, min(w - 1, tx))
        ty = max(0, min(h - 1, ty))
        if kind == "spawn":
            spawn = (tx, ty)
        elif kind == "finish":
            finish = (tx, ty)
            ents[(tx, ty)] = "flag"
        elif kind in ("enemy", "entity", "coin"):
            ents[(tx, ty)] = name  # type: ignore

    if spawn is None:
        spawn = place_spawn(mapped, CUSTOM_TILE_BASE)
    ents[spawn] = "spawn"
    if finish is None:
        finish = place_flag(mapped, CUSTOM_TILE_BASE)
        ents[finish] = "flag"

    body = rle_encode(mapped, ents)
    text_out = f"{h}{CD}{body}{CD}spriteset{EQ}1{CD}timelimit{EQ}0"

    attribution.append(
        {
            "file": filename,
            "name": as_string(field(root, "name")[0]) or filename,
            "author": as_string(field(root, "author")[0]) or "?",
            "license": lic or "?",
        }
    )
    return text_out, mapped, used


def load_tile_rgba(data_images: Path, info, cache: dict) -> Image.Image | None:
    if Image is None:
        return None
    if isinstance(info, str):
        path = data_images / info
        if not path.exists():
            # paths in strf are relative to data/images/
            path = data_images / info.lstrip("/")
        key = str(path)
        if key not in cache:
            if not path.exists():
                cache[key] = None
            else:
                im = Image.open(path).convert("RGBA")
                # single-tile image: take top-left 32×32, NN → 16
                tile = im.crop((0, 0, min(32, im.width), min(32, im.height)))
                if tile.size != (32, 32):
                    canvas = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
                    canvas.paste(tile, (0, 0))
                    tile = canvas
                cache[key] = tile.resize((16, 16), Image.Resampling.NEAREST)
        return cache[key]
    if isinstance(info, dict):
        sheet_path = data_images / info["sheet"]
        key = f"{sheet_path}:{info['cell']}"
        if key not in cache:
            if not sheet_path.exists():
                cache[key] = None
            else:
                sk = str(sheet_path)
                if sk not in cache:
                    cache[sk] = Image.open(sheet_path).convert("RGBA")
                sheet = cache[sk]
                cols = info["cols"]
                cell = info["cell"]
                tx, ty = cell % cols, cell // cols
                tile = sheet.crop((tx * 32, ty * 32, tx * 32 + 32, ty * 32 + 32))
                cache[key] = tile.resize((16, 16), Image.Resampling.NEAREST)
        return cache[key]
    return None


def build_tileset(
    used_ids: set[int],
    props: dict[int, dict[str, bool]],
    images: dict[int, object],
    data_images: Path,
) -> tuple[Image.Image, dict[int, int]]:
    """NN 32→16, pack used tiles into 17-stride sheet; return img + ST→Mari0 remap."""
    assert Image is not None
    ordered = sorted(used_ids)
    # index 0 = empty
    remap = {tid: CUSTOM_TILE_BASE + 1 + i for i, tid in enumerate(ordered)}
    n_tiles = 1 + len(ordered)
    cols = 16
    rows = (n_tiles + cols - 1) // cols
    out = Image.new("RGBA", (cols * 17, rows * 17), (0, 0, 0, 0))
    px = out.load()
    cache: dict = {}

    def paste_at(idx: int, tile: Image.Image | None, prop: dict[str, bool] | None):
        tx, ty = idx % cols, idx // cols
        ox, oy = tx * 17, ty * 17
        if tile is not None:
            out.paste(tile, (ox, oy))
        if prop:
            prop_x = ox + 16
            for name, on in prop.items():
                if not on or name not in PROP_ORDER:
                    continue
                pi = PROP_ORDER.index(name)
                if pi <= 16:
                    px[prop_x, oy + pi] = (255, 255, 255, 255)

    paste_at(0, None, None)  # empty
    for i, tid in enumerate(ordered):
        img = load_tile_rgba(data_images, images.get(tid), cache)
        if img is None:
            # solid placeholder if we know collision
            p = props.get(tid) or {}
            if p.get("collision"):
                img = Image.new("RGBA", (16, 16), (120, 140, 160, 255))
            else:
                img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        paste_at(1 + i, img, props.get(tid))

    return out, remap


def write_authors(path: Path, rows: list[dict]) -> None:
    lines = [
        "SuperTux → Mari0 CE mappack — attribution",
        "Generated by scripts/mapsdk/build_supertux.py",
        "Only levels that passed license_ok (CC-BY-SA allowlist) are listed.",
        "",
        f"{'FILE':<40} {'AUTHOR':<28} LICENSE  NAME",
        "-" * 100,
    ]
    for r in rows:
        lines.append(
            f"{r['file']:<40} {r['author']:<28} {r['license']}  {r['name']}"
        )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def find_data_root(path: Path) -> Path:
    if (path / "levels").is_dir() and (path / "images").is_dir():
        return path
    if (path / "data" / "levels").is_dir():
        return path / "data"
    raise FileNotFoundError(f"No SuperTux data/ under {path}")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--data", type=Path, required=True, help="SuperTux data/ root (or clone root)")
    ap.add_argument("--out", type=Path, default=Path("mappacks/supertux"))
    ap.add_argument("--world", default="world1", help="levels/<world> to convert")
    ap.add_argument("--histogram", action="store_true", help="Print object histogram and exit")
    ap.add_argument("--no-tileset", action="store_true", help="Skip tiles.png (geometry only)")
    args = ap.parse_args()

    data = find_data_root(args.data)
    world = data / "levels" / args.world
    if not world.is_dir():
        print(f"missing {world}", file=sys.stderr)
        return 1

    stls = sorted(world.glob("*.stl"))
    # skip cutscenes by default for playable pack? Keep all licensed levels.
    print(f"Data: {data}  world: {world}  levels: {len(stls)}")

    if args.histogram:
        hist: Counter = Counter()
        for p in stls:
            root = parse_sexpr(p.read_text(encoding="utf-8", errors="replace"))
            for sec in children(root, "sector"):
                for obj in children(sec):
                    if obj and isinstance(obj[0], str):
                        hist[obj[0]] += 1
        for name, n in hist.most_common(50):
            mapped = ST_OBJECTS.get(name, ("?", None))
            print(f"  {n:5d}  {name:<24} -> {mapped}")
        return 0

    strf_path = data / "images" / "tiles.strf"
    props, images = {}, {}
    if strf_path.exists():
        print(f"Parsing {strf_path} …")
        props, images = parse_strf(strf_path.read_text(encoding="utf-8", errors="replace"))
        print(f"  tile defs: {len(props)}  with images: {len(images)}")
    else:
        print("WARN: tiles.strf missing — collision props will be empty", file=sys.stderr)

    # Pass 1: collect used tile ids from licensed levels
    used: set[int] = set()
    licensed_files: list[Path] = []
    for p in stls:
        text = p.read_text(encoding="utf-8", errors="replace")
        root = parse_sexpr(text)
        ok, lic = license_ok(root)
        if not ok:
            print(f"  SKIP {p.name}: license={lic!r}")
            continue
        licensed_files.append(p)
        for sec in children(root, "sector"):
            for tm in children(sec, "tilemap"):
                if not is_true(field(tm, "solid")[0]):
                    continue
                w = int(field(tm, "width")[0])
                h = int(field(tm, "height")[0])
                _, tn = field(tm, "tiles")
                try:
                    tiles = decode_tiles(tn, w, h)
                except Exception as e:
                    print(f"  WARN {p.name} tiles: {e}", file=sys.stderr)
                    continue
                used.update(t for t in tiles if t)

    print(f"Licensed levels: {len(licensed_files)}  unique solid tiles: {len(used)}")

    args.out.mkdir(parents=True, exist_ok=True)
    for old in args.out.glob("*.txt"):
        old.unlink()
    if (args.out / "tiles.png").exists() and not args.no_tileset:
        (args.out / "tiles.png").unlink()

    remap: dict[int, int] = {}
    if not args.no_tileset:
        if Image is None:
            print("FAIL: Pillow required for tileset (pip install Pillow)", file=sys.stderr)
            return 2
        print("Building tiles.png (NN 32→16) …")
        sheet, remap = build_tileset(used, props, images, data / "images")
        sheet.save(args.out / "tiles.png")
        print(f"  wrote tiles.png  remap entries={len(remap)}")
    else:
        # identity-ish packing without graphics
        for i, tid in enumerate(sorted(used)):
            remap[tid] = CUSTOM_TILE_BASE + 1 + i

    unmapped: Counter = Counter()
    attribution: list[dict] = []
    written = 0
    for i, p in enumerate(licensed_files, start=1):
        text = p.read_text(encoding="utf-8", errors="replace")
        result = convert_stl(text, remap, unmapped, attribution, p.name)
        if not result:
            continue
        level_txt, _, _ = result
        # Playable naming: 1-N for world1
        out_name = f"1-{i}.txt"
        (args.out / out_name).write_text(level_txt, encoding="utf-8")
        print(f"  {out_name} ← {p.name}")
        written += 1

    write_authors(args.out / "AUTHORS.txt", attribution)
    (args.out / "LICENSE").write_text(LICENSE_TEXT, encoding="utf-8")
    (args.out / "settings.txt").write_text(
        "\n".join(
            [
                "name=supertux (local)",
                "author=see AUTHORS.txt — CC-BY-SA levels from SuperTux",
                "description=Regenerated via mapsdk/build_supertux.py (engine GPL not included)",
                "",
            ]
        ),
        encoding="utf-8",
    )

    if unmapped:
        print("Unmapped objects:")
        for name, n in unmapped.most_common(30):
            print(f"  {name}: {n}")

    print(f"Done → {args.out} ({written} levels, gitignored; do not commit large art unless intentional)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
