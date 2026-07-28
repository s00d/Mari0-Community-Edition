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
    # Ice brick tile id 78 (solid+breakable via object-data); painted into grid
    "weak_block": ("tile", 78),
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
    # bowser is a hardcoded CE *entity*, not an enemiesdata JSON base
    "yeti": ("enemy", "boomboom"),
    "ghosttree": ("enemy", "boomboom"),
    "mrtree": ("enemy", "koopa"),
    "fish-jumping": ("enemy", "cheepcheepred"),
    "fishjumping": ("enemy", "cheepcheepred"),
    "wind": ("skip", None),
    "bumper": ("skip", None),
    "circleplatform": ("entity", "platform"),
    "particles-clouds": ("skip", None),
    "owl": ("enemy", "koopaflying"),
    "igel": ("enemy", "spikey"),
    "snail": ("enemy", "koopa"),
    "mole": ("enemy", "goomba"),
    "tarantula": ("enemy", "spikey"),
    "viciousivy": ("enemy", "spikey"),
    "leafshot": ("enemy", "bulletbill"),
    "walkingleaf": ("enemy", "goomba"),
    "crystallo": ("enemy", "goomba"),
    "rcrystallo": ("enemy", "goomba"),
    "scrystallo": ("enemy", "goomba"),
    "granito": ("enemy", "goomba"),
    "darttrap": ("enemy", "plant"),
    "livefire": ("enemy", "fire"),
    "livefireasleep": ("enemy", "fire"),
    "livefiredormant": ("enemy", "fire"),
}

# CE entitylist numeric ids (string names also work after levelio fix, but ids are safer)
CE_ENTITY_ID = {
    "spawn": "8",
    "flag": "11",
    "manycoins": "5",
    "platform": "18",
    "spring": "94",
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
    # SuperTux often puts breakable/coin in object-name / object-data, not attributes.
    obj_name = as_string(field(t, "object-name")[0]) or ""
    obj_data = as_string(field(t, "object-data")[0]) or ""
    if obj_name in ("brick", "heavy-brick") or "breakable #t" in obj_data or "(breakable #t)" in obj_data:
        p["breakable"] = True
        p["collision"] = True
    if obj_name == "coin" or obj_name.endswith("coin"):
        p["coin"] = True
        p.pop("collision", None)
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


def encode_entity(name: str) -> str:
    """Prefer CE numeric ids for markers/items; keep enemy JSON basenames as strings."""
    return CE_ENTITY_ID.get(name, name)


def tilemap_z(tm: list) -> float:
    z = field(tm, "z-pos")[0]
    if isinstance(z, (int, float)):
        return float(z)
    return 0.0


def read_tilemap(tm: list) -> tuple[int, int, list[int], bool, float]:
    w = int(field(tm, "width")[0])
    h = int(field(tm, "height")[0])
    _, tiles_node = field(tm, "tiles")
    tiles = decode_tiles(tiles_node, w, h)
    return w, h, tiles, is_true(field(tm, "solid")[0]), tilemap_z(tm)


def air_above_solid(solid_mask: list[list[bool]], x: int, y: int) -> bool:
    h = len(solid_mask)
    if y < 0 or y >= h - 1:
        return False
    return (not solid_mask[y][x]) and solid_mask[y + 1][x]


def place_spawn(_mapped: list[list[int]], solid_mask: list[list[bool]]) -> tuple[int, int]:
    """Air cell above solid near left edge (0-based)."""
    h, w = len(solid_mask), len(solid_mask[0]) if solid_mask else 0
    for x in range(1, min(16, w)):
        for y in range(h - 2, 1, -1):
            if air_above_solid(solid_mask, x, y) and (y == 0 or not solid_mask[y - 1][x]):
                return x, y
    return 2, max(1, h - 3)


def place_flag_at_x(_mapped: list[list[int]], solid_mask: list[list[bool]], x: int) -> tuple[int, int]:
    h, w = len(solid_mask), len(solid_mask[0]) if solid_mask else 0
    x = max(0, min(w - 1, x))
    for yy in range(h - 1, 0, -1):
        if solid_mask[yy][x]:
            return x, max(0, yy - 1)
    return x, max(1, h - 3)


def place_flag(mapped: list[list[int]], solid_mask: list[list[bool]]) -> tuple[int, int]:
    w = len(solid_mask[0]) if solid_mask else 0
    return place_flag_at_x(mapped, solid_mask, w - 1)


def snap_spawn_to_ground(solid_mask: list[list[bool]], tx: int, ty: int) -> tuple[int, int]:
    h, w = len(solid_mask), len(solid_mask[0]) if solid_mask else 0
    tx = max(0, min(w - 1, tx))
    ty = max(0, min(h - 1, ty))
    if air_above_solid(solid_mask, tx, ty):
        return tx, ty
    for y in range(ty, h - 1):
        if air_above_solid(solid_mask, tx, y):
            return tx, y
    for y in range(ty, 0, -1):
        if air_above_solid(solid_mask, tx, y):
            return tx, y
    return place_spawn([], solid_mask)


def tile_collides(tid: int, props: dict[int, dict[str, bool]] | None) -> bool:
    """True if this ST tile should block the player (strf collision/platform)."""
    if not tid:
        return False
    if not props:
        return True
    p = props.get(tid)
    if p is None:
        # Unknown id on a solid layer: keep previous conservative behaviour.
        return True
    return bool(p.get("collision") or p.get("platform"))


def composite_tilemaps(
    sector,
    props: dict[int, dict[str, bool]] | None = None,
) -> tuple[list[list[int]], list[list[bool]], set[int], set[int]]:
    """
    Merge all sector tilemaps into one ST-id grid (0 = empty) + solid mask.
    Solids painted first (visual authority on overlaps), then decorations fill
    empty cells back→front by z-pos so pipes/props on FG/BG still appear.

    Collision matches SuperTux: only tiles that originated on a solid=#t tilemap
    are candidates, and only if tiles.strf marks them solid/unisolid.
    Decorative snow caps (7/8/9), trees on BG, and coin tiles stay non-solid.
    """
    tms = []
    for tm in children(sector, "tilemap"):
        try:
            tms.append(read_tilemap(tm))
        except Exception as e:
            print(f"  WARN tilemap skip: {e}", file=sys.stderr)
    if not tms:
        raise ValueError("no tilemaps")
    solids = [t for t in tms if t[3]]
    if not solids:
        raise ValueError("no solid tilemap")
    solids.sort(key=lambda t: (-t[0] * t[1], t[4]))
    w, h = solids[0][0], solids[0][1]
    grid = [[0 for _ in range(w)] for _ in range(h)]
    from_solid = [[False for _ in range(w)] for _ in range(h)]
    used: set[int] = set()

    def paint(tiles: list[int], tw: int, th: int, only_empty: bool, mark_layer_solid: bool):
        mw, mh = min(w, tw), min(h, th)
        for y in range(mh):
            for x in range(mw):
                tid = tiles[y * tw + x]
                if not tid:
                    continue
                if only_empty and grid[y][x]:
                    continue
                # Non-solid tilemaps in ST do not collide. Skip embedding strf-solid
                # tiles from deco/FG (editor scraps reuse ground ids → floating floors).
                if only_empty and tile_collides(tid, props):
                    continue
                grid[y][x] = tid
                used.add(tid)
                if mark_layer_solid:
                    from_solid[y][x] = True

    for tw, th, tiles, _solid, _z in sorted(solids, key=lambda t: t[4]):
        paint(tiles, tw, th, only_empty=False, mark_layer_solid=True)

    decos = [t for t in tms if not t[3]]
    decos.sort(key=lambda t: t[4])
    for tw, th, tiles, _solid, _z in decos:
        paint(tiles, tw, th, only_empty=True, mark_layer_solid=False)

    solid_mask = [
        [
            bool(from_solid[y][x] and tile_collides(grid[y][x], props))
            for x in range(w)
        ]
        for y in range(h)
    ]
    # Edge case: solid layer had a collidable tile, then a later solid layer painted
    # a non-solid decorative id into the same cell — trust the visible tile's props
    # (from_solid still True, tile_collides False → air). Good.
    #
    # If deco overwrote an empty solid cell with a tree, from_solid is False → air.
    solid_tids = {
        grid[y][x]
        for y in range(h)
        for x in range(w)
        if solid_mask[y][x] and grid[y][x]
    }
    return grid, solid_mask, used, solid_tids


def convert_stl(
    text: str,
    tile_remap: dict[int, int],
    unmapped: Counter,
    attribution: list[dict],
    filename: str,
    props: dict[int, dict[str, bool]] | None = None,
) -> tuple[str, list[list[int]], set[int], set[int]] | None:
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

    try:
        st_grid, solid_mask, used, solid_tids = composite_tilemaps(sector, props)
    except ValueError as e:
        print(f"  SKIP {filename}: {e}", file=sys.stderr)
        return None

    h, w = len(st_grid), len(st_grid[0]) if st_grid else 0

    # Coin tiles (e.g. id 44): collectible via Mari0 coin prop — keep graphic, no collision.
    # Already handled in tileset props; ensure solid_mask doesn't treat them as ground.
    for y in range(h):
        for x in range(w):
            tid = st_grid[y][x]
            if not tid or not props:
                continue
            p = props.get(tid) or {}
            if p.get("coin"):
                solid_mask[y][x] = False

    ents: dict[tuple[int, int], str] = {}
    spawn = None
    finish_xs: list[int] = []
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
            spawn = snap_spawn_to_ground(solid_mask, tx, ty)
        elif kind == "finish":
            finish_xs.append(tx)
        elif kind == "tile":
            # Paint ST tile id into grid (weak_block → ice brick, etc.)
            st_id = int(name)  # type: ignore[arg-type]
            st_grid[ty][tx] = st_id
            used.add(st_id)
            if tile_collides(st_id, props):
                solid_mask[ty][tx] = True
                solid_tids.add(st_id)
        elif kind in ("enemy", "entity", "coin"):
            ents[(tx, ty)] = encode_entity(name)  # type: ignore

    mapped: list[list[int]] = []
    for y in range(h):
        row = []
        for x in range(w):
            tid = st_grid[y][x]
            if tid == 0:
                row.append(CUSTOM_TILE_BASE)
            else:
                row.append(tile_remap.get(tid, CUSTOM_TILE_BASE + 1))
        mapped.append(row)

    if spawn is None:
        spawn = place_spawn(mapped, solid_mask)
    ents[spawn] = encode_entity("spawn")

    if finish_xs:
        fx = max(finish_xs)
        ents[place_flag_at_x(mapped, solid_mask, fx)] = encode_entity("flag")
    else:
        ents[place_flag(mapped, solid_mask)] = encode_entity("flag")

    body = rle_encode(mapped, ents)
    text_out = f"{h}{CD}{body}{CD}spriteset{EQ}1{CD}timelimit{EQ}400"

    attribution.append(
        {
            "file": filename,
            "name": as_string(field(root, "name")[0]) or filename,
            "author": as_string(field(root, "author")[0]) or "?",
            "license": lic or "?",
        }
    )
    return text_out, mapped, used, solid_tids


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
                    px[prop_x, oy + pi] = (255, 0, 0, 255)

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



def force_unknown_solid_collision(
    props: dict[int, dict[str, bool]], solid_tids: set[int]
) -> int:
    """
    Only force collision for solid-layer tile ids that are missing from tiles.strf.
    Never override explicit non-solid defs (snow caps 7/8/9, trees, coin tiles, …).
    """
    n = 0
    for tid in solid_tids:
        if tid in props:
            continue
        props[tid] = {"collision": True}
        n += 1
    return n


def apply_special_tile_props(props: dict[int, dict[str, bool]], images: dict[int, object]) -> None:
    """Post-pass: coin graphics → Mari0 coin (non-solid); brick object-tiles → breakable."""
    for tid, img in images.items():
        name = img if isinstance(img, str) else (
            img.get("sheet") if isinstance(img, dict) else ""
        )
        name = (name or "").replace("\\", "/").lower()
        p = dict(props.get(tid) or {})
        changed = False
        if "objects/coin/" in name or name.endswith("/coin-0.png"):
            p["coin"] = True
            p.pop("collision", None)
            changed = True
        # Scenery sheets must never be solid even if a bad attr sneaks in.
        if any(
            s in name
            for s in (
                "/snowy_tree",
                "/iceshrub",
                "/grass1",
                "/grass2",
                "/branches.png",
            )
        ):
            if p.get("collision") or p.get("platform"):
                p.pop("collision", None)
                p.pop("platform", None)
                changed = True
        if changed:
            props[tid] = p


def find_data_root(path: Path) -> Path:
    if (path / "levels").is_dir() and (path / "images").is_dir():
        return path
    if (path / "data" / "levels").is_dir():
        return path / "data"
    raise FileNotFoundError(f"No SuperTux data/ under {path}")


def worldmap_level_order(world_dir: Path) -> list[Path] | None:
    """Parse worldmap.stwm (level \"file.stl\") order when present."""
    stwm = world_dir / "worldmap.stwm"
    if not stwm.exists():
        return None
    text = stwm.read_text(encoding="utf-8", errors="replace")
    names = re.findall(r'\(level\s+"([^"]+)"', text)
    if not names:
        names = re.findall(r"\(level\s+([^\s\)]+)", text)
    out: list[Path] = []
    seen: set[str] = set()
    for name in names:
        name = name.strip()
        if not name.endswith(".stl"):
            name = name + ".stl"
        if name in seen:
            continue
        seen.add(name)
        p = world_dir / name
        if p.exists():
            out.append(p)
    return out or None



def collect_level_tiles(
    root, props: dict[int, dict[str, bool]] | None = None
) -> tuple[set[int], set[int]]:
    used: set[int] = set()
    solid_tids: set[int] = set()
    for sec in children(root, "sector"):
        for tm in children(sec, "tilemap"):
            try:
                tw, th, tiles, is_solid, _z = read_tilemap(tm)
            except Exception:
                continue
            for tid in tiles:
                if not tid:
                    continue
                used.add(tid)
                if is_solid and tile_collides(tid, props):
                    solid_tids.add(tid)
        # Object-painted tiles (weak_block → brick, …)
        for obj in children(sec):
            head = obj[0] if obj else None
            if not isinstance(head, str):
                continue
            m = ST_OBJECTS.get(head)
            if not m or m[0] != "tile":
                continue
            st_id = int(m[1])  # type: ignore[arg-type]
            used.add(st_id)
            if tile_collides(st_id, props):
                solid_tids.add(st_id)
    return used, solid_tids




def convert_world(
    data: Path,
    world_name: str,
    out: Path,
    world_index: int,
    props: dict,
    images: dict,
    remap: dict[int, int],
    attribution: list[dict],
    unmapped: Counter,
    no_tileset: bool,
) -> tuple[int, set[int]]:
    world = data / "levels" / world_name
    if not world.is_dir():
        print(f"missing {world}", file=sys.stderr)
        return 0, set()

    ordered = worldmap_level_order(world)
    stls = ordered if ordered else sorted(world.glob("*.stl"))
    print(f"World {world_name}: {len(stls)} stl (worldmap={'yes' if ordered else 'alpha'})")

    used: set[int] = set()
    licensed: list[Path] = []
    for p in stls:
        text = p.read_text(encoding="utf-8", errors="replace")
        root = parse_sexpr(text)
        ok, lic = license_ok(root)
        if not ok:
            print(f"  SKIP {p.name}: license={lic!r}")
            continue
        licensed.append(p)
        u, s = collect_level_tiles(root, props); used |= u

    written = 0
    for i, p in enumerate(licensed, start=1):
        text = p.read_text(encoding="utf-8", errors="replace")
        result = convert_stl(text, remap, unmapped, attribution, p.name, props)
        if not result:
            continue
        level_txt, _, level_used, level_solid = result
        used |= level_used
        out_name = f"{world_index}-{i}.txt"
        (out / out_name).write_text(level_txt, encoding="utf-8")
        print(f"  {out_name} ← {p.name}")
        written += 1
    return written, used


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--data", type=Path, required=True, help="SuperTux data/ root (or clone root)")
    ap.add_argument("--out", type=Path, default=Path("mappacks/supertux"))
    ap.add_argument("--world", default="world1", help="levels/<world> to convert (ignored with --all-worlds)")
    ap.add_argument("--all-worlds", action="store_true", help="Convert world1..worldN present under levels/")
    ap.add_argument("--histogram", action="store_true", help="Print object histogram and exit")
    ap.add_argument("--no-tileset", action="store_true", help="Skip tiles.png (geometry only)")
    args = ap.parse_args()

    data = find_data_root(args.data)

    if args.all_worlds:
        worlds = sorted(
            p.name
            for p in (data / "levels").iterdir()
            if p.is_dir() and p.name.startswith("world") and list(p.glob("*.stl"))
        )
        # natural world1, world2, … then extras
        def wkey(n: str):
            m = re.match(r"world(\d+)$", n)
            return (0, int(m.group(1))) if m else (1, n)

        worlds = sorted(worlds, key=wkey)
    else:
        worlds = [args.world]

    if args.histogram:
        hist: Counter = Counter()
        for wn in worlds:
            world = data / "levels" / wn
            for p in world.glob("*.stl"):
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
        apply_special_tile_props(props, images)
        print(f"  tile defs: {len(props)}  with images: {len(images)}")
    else:
        print("WARN: tiles.strf missing — collision props will be empty", file=sys.stderr)

    # Pass 1: collect used tile ids + truly-solid tids from licensed levels
    used: set[int] = set()
    solid_tids: set[int] = set()
    for wn in worlds:
        world = data / "levels" / wn
        if not world.is_dir():
            print(f"missing {world}", file=sys.stderr)
            continue
        ordered = worldmap_level_order(world) or sorted(world.glob("*.stl"))
        for p in ordered:
            text = p.read_text(encoding="utf-8", errors="replace")
            root = parse_sexpr(text)
            ok, _lic = license_ok(root)
            if not ok:
                continue
            u, s = collect_level_tiles(root, props)
            used |= u
            solid_tids |= s

    forced = force_unknown_solid_collision(props, solid_tids)
    print(
        f"Worlds: {worlds}  unique tiles: {len(used)}  "
        f"strf-solid: {len(solid_tids)}  unknown-forced: {forced}"
    )

    args.out.mkdir(parents=True, exist_ok=True)
    for old in args.out.glob("*.txt"):
        old.unlink()
    # Drop broken custom enemy overlays (CE bases used by name instead)
    enemies_dir = args.out / "enemies"
    if enemies_dir.is_dir():
        for old in enemies_dir.iterdir():
            old.unlink()
        try:
            enemies_dir.rmdir()
        except OSError:
            pass
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
        for i, tid in enumerate(sorted(used)):
            remap[tid] = CUSTOM_TILE_BASE + 1 + i

    unmapped: Counter = Counter()
    attribution: list[dict] = []
    written = 0
    for wi, wn in enumerate(worlds, start=1):
        n, _ = convert_world(
            data,
            wn,
            args.out,
            wi,
            props,
            images,
            remap,
            attribution,
            unmapped,
            args.no_tileset,
        )
        written += n

    write_authors(args.out / "AUTHORS.txt", attribution)
    (args.out / "LICENSE").write_text(LICENSE_TEXT, encoding="utf-8")
    (args.out / "settings.txt").write_text(
        "\n".join(
            [
                "name=supertux (local)",
                "author=see AUTHORS.txt — CC-BY-SA levels from SuperTux",
                "description=Regenerated via mapsdk/build_supertux.py (engine GPL not included)",
                "lives=4",
                "",
            ]
        ),
        encoding="utf-8",
    )
    gaps = args.out / "GAPS.md"
    gaps.write_text(
        "# SuperTux → Mari0 gaps (honest)\n\n"
        "Imported: solid+decorative tile layers (composited), CC-BY-SA levels,\n"
        "badguys→CE enemy JSON names, trampolines→spring, platforms, coin tiles,\n"
        "weak_block→ice brick, flags via sequencetrigger X snapped to ground,\n"
        "spawn snapped to floor. Collision from tiles.strf (not “any solid-layer tile”).\n"
        "Entity markers use CE numeric ids (spawn=8, flag=11, spring=94, …).\n\n"
        "Still missing / stubbed:\n"
        "- Scripting (.nut), scripttrigger, init-script, sequencetrigger cutscenes\n"
        "- Pushable rocks, fallblocks, unstable/magicblock, climbable, infoblock text\n"
        "- Wind, bumper, doors as warps; tutorial decals/billboards\n"
        "- Worldmap UI / hub progression (flat W-N level list instead)\n"
        "- True badguy AI (snowball etc. use Mari0 goomba/koopa/… behaviour)\n"
        "- Tux physics (ice friction), music, parallax backgrounds\n",
        encoding="utf-8",
    )

    if unmapped:
        print("Unmapped objects:")
        for name, n in unmapped.most_common(30):
            print(f"  {name}: {n}")

    print(f"Done → {args.out} ({written} levels)")
    print("Rebuild: python3 scripts/mapsdk/build_supertux.py --data toconvert/supertux/data --out mappacks/supertux --all-worlds")
    return 0


if __name__ == "__main__":
    sys.exit(main())
