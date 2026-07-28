#!/usr/bin/env python3
"""
Build local mappacks/smb3 from an SMB3 Foundry dump.

Writes collision (and other) flags into tiles.png property column so floors
are solid. Output is gitignored — never commit Nintendo ROM assets.

Usage:
  python3 scripts/mapsdk/build_smb3.py \\
      --dump /path/to/smb3/dump \\
      --out mappacks/smb3
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

from PIL import Image

# Mari0 DEFAULT tile layout
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

# Scenery / BG objects — never solid. Real hills are "Flat Land - Hilly",
# "Hilly Wall", "Upper Left Hill Corner", etc. (no "background" prefix).
DECORATIVE = (
    "background cloud",
    "background bush",
    "background coconut",
    "background aquatic",
    "background hills",
    "small background hills",
    "cloud background",
    "oval background",
    "swirly background",
    "starry background",
    "clouds a",
    "clouds b",
    "clouds c",
    "cloud-colored",
    "white mushrooms, flowers",
    "palm tree",
    "sets background",
    "blank background",
    "plain background",
    "background pillar",
    "wooden background",
    "ship background line",
    "background wooden",
    "background for pipe",
    "background like at bottom",
    "background used in",
    "background pyramid",
    "background mountain",
    "blue background",
    "castle room background",
    "dungeon background",
    "dark dungeon background",
    "underground background under",
    "black boss room",
    "gap",
    "msg_nothing",
    "porthole",
    "railing",
    "dungeon lamp",
    "dungeon window",
    "hot foot",
    "blue gear",
    "background pole",
    "bottom of background",
    "background pipe",
    "jelectro",
)

# Overworld hubs live in world 10 so they never collide with dump worlds 1–9.
MAP_WORLD = 10
MAP_FIRST_VALID_ROW = 2  # smb3parse FIRST_VALID_ROW — pointer rows are 2..10
MAP_PALETTE_COUNT = 8
WARPPIPE_ENTITY_ID = "82"  # entitylist warppipe (see entitylist.tl)
SKY_TILE = 1

ENEMY_MAP = {
    "goomba": "goomba",
    "red koopa troopa": "koopa",
    "green koopa troopa": "koopa",
    "red para-goomba": "paragoomba",
    "para-goomba": "paragoomba",
    "red para-troopa": "parakoopa",
    "green para-troopa": "parakoopa",
    "buzzy beetle": "beetle",
    "spiny": "spiny",
    "piranha plant": "plant",
    "venus fire trap": "plant",
    "cheep-cheep": "cheep",
    "blooper": "squid",
    "hammer bro": "hammerbro",
    "boomerang bro": "hammerbro",
    "fire bro": "hammerbro",
    "sledge bro": "hammerbro",
    "lakitu": "lakitu",
    "bullet bill": "bulletbill",
}


def classify_at(name: str, dy: int, height: int) -> dict[str, int]:
    """Per-cell props: extend-to-ground pillars are pass-through except the top row."""
    n = name.lower().strip()
    if "extends to ground" in n and "platform" in n:
        if dy == 0:
            return {"collision": 2, "platform": 2}
        # Body tiles are pass-through. Solidness is handled by a veto in
        # effective_cell_props (so we can override overlapping tiles).
        return {}

    # Pipe mouths draw in front of piranha plants (Mari0 foreground layer).
    if "pipe" in n and "background" not in n:
        props = dict(classify(name))
        if "downward" in n and dy == 0:
            props["foreground"] = 2
        elif "upward" in n and height > 0 and dy == height - 1:
            props["foreground"] = 2
        return props

    return classify(name)


def classify(name: str) -> dict[str, int]:
    n = name.lower().strip()
    if n in ("coins", "frozen coins") or "silver coins" in n or n == "invisible coin":
        out = {"coin": 1}
        if "invisible" in n:
            out["invisible"] = 1
        return out

    for d in DECORATIVE:
        if d in n:
            # Background Hills / bushes / clouds are scenery — walk through.
            return {}

    if "water" in n and "underwater" not in n and "waterfall" not in n:
        return {"water": 2, "collision": -2}
    if "waterfall" in n:
        return {"water": 1, "collision": 1}
    if "lava" in n:
        return {"spikestop": 1, "collision": -1}
    if "?" in n:
        return {"collision": 3, "coinblock": 3}
    if "brick" in n:
        return {"collision": 3, "breakable": 3}
    if "spike" in n:
        return {"collision": 2, "spikestop": 2}
    if "note block" in n or "cloud platform" in n:
        return {"collision": 2, "platform": 2}
    if "platform" in n and "floating" in n and "wire" not in n:
        return {"collision": 2, "platform": 2}
    if "platform" in n and "wire" not in n:
        return {"collision": 2, "platform": 2}
    return {"collision": 2}


CELL_BOOL_PROPS = (
    "collision",
    "platform",
    "coin",
    "breakable",
    "coinblock",
    "invisible",
    "water",
    "spikestop",
    "foreground",
)


def props_equal(have: dict[str, bool], want: dict[str, bool]) -> bool:
    for p in CELL_BOOL_PROPS:
        if bool(have.get(p)) != bool(want.get(p)):
            return False
    return True


def resolve_cell_props(scores: dict[str, int]) -> dict[str, bool]:
    props: dict[str, bool] = {}
    collision_score = scores.get("collision", 0)
    for prop, score in scores.items():
        if score <= 0 or prop == "coin":
            continue
        if prop == "platform" and collision_score > 0 and score < collision_score * 0.5:
            continue
        props[prop] = True
    if collision_score > 0:
        props["collision"] = True
    if scores.get("coin", 0) > 0 and collision_score <= 0:
        props["coin"] = True
    return props


def effective_cell_props(data: dict, x: int, y: int) -> dict[str, bool]:
    scores: dict[str, int] = defaultdict(int)
    pillar_body_any = False

    for o in data.get("objects") or []:
        r = o.get("rendered") or {}
        x0, y0, w, h = r.get("x", 0), r.get("y", 0), r.get("w", 0), r.get("h", 0)
        if not (x0 <= x < x0 + w and y0 <= y < y0 + h):
            continue

        name_l = (o.get("name", "") or "").lower().strip()
        dy = y - y0

        if "extends to ground" in name_l and "platform" in name_l:
            if dy > 0:
                pillar_body_any = True

        for prop, weight in classify_at(o.get("name", ""), dy, h).items():
            if weight > 0:
                scores[prop] += weight

    props = resolve_cell_props(scores)
    # If we're on the pillar body, force pass-through even if other objects
    # share the same CHR/tile id and voted collision/platform.
    if pillar_body_any:
        props.pop("collision", None)
        props.pop("platform", None)
    return props


def is_decorative(name: str) -> bool:
    n = name.lower().strip()
    return any(d in n for d in DECORATIVE)


def is_solid_object(name: str) -> bool:
    return classify(name).get("collision", 0) > 0


def object_cells(o: dict, tm: list[list[int]]) -> set[tuple[int, int]]:
    r = o.get("rendered") or {}
    cells: set[tuple[int, int]] = set()
    for dy in range(r.get("h", 0)):
        for dx in range(r.get("w", 0)):
            y, x = r.get("y", 0) + dy, r.get("x", 0) + dx
            if 0 <= y < len(tm) and 0 <= x < len(tm[0]) and (tm[y][x] & 0xFF):
                cells.add((x, y))
    return cells


def decorative_only_cells(data: dict) -> set[tuple[int, int]]:
    """Cells painted by BG scenery and not by any solid object (shared CHR ids)."""
    tm = data["tilemap"]
    deco: set[tuple[int, int]] = set()
    solid: set[tuple[int, int]] = set()
    for o in data.get("objects") or []:
        name = o.get("name", "")
        cells = object_cells(o, tm)
        if is_decorative(name):
            deco |= cells
        elif is_solid_object(name):
            solid |= cells
    return deco - solid


def parse_level_ref(fname: str) -> tuple[int, int, int] | None:
    """`1-3` → (1,3,0); `1-1_4` → (1,1,4)."""
    m = re.fullmatch(r"(\d+)-(\d+)(?:_(\d+))?", fname)
    if not m:
        return None
    return int(m.group(1)), int(m.group(2)), int(m.group(3) or 0)


def mari0_entity(name: str) -> str | None:
    key = name.lower().strip()
    if key in ENEMY_MAP:
        return ENEMY_MAP[key]
    for prefix, ent in ENEMY_MAP.items():
        if prefix in key:
            return ent
    return None


def powerup_from_block_object(name: str) -> str | None:
    """
    Returns a Mari0 CE "block content marker" to be stored in map[x][y][2].

    mario:hitblock spawns block contents like this:
    - if map[x][y][2] is a string that exists in `enemies`, it spawns that item directly
      (e.g. leaf/mushroom/flower/star/oneup).
    - if it's numeric and refers to entitylist slots, it follows the entitylist path.

    For SMB3 we prefer direct item names for accurate bonuses.
    """
    n = name.lower().strip()

    # SMB3 dump may contain a 3-wide composite object without the '?' character:
    # "White Mushrooms, Flowers and Stars"
    if "white mushrooms" in n and "flowers" in n and "stars" in n:
        # Composite object: decided cell-by-cell in level_to_txt via dx.
        return "__wfstar__"

    # SMB3parse has multiple variants like:
    #  - "'?' Blocks with single coins"
    #  - "'?' with Leaf"
    #  - "Brick with 1-up"
    if "?" in n:
        if "coin" in n and ("single" in n or "coins" in n):
            return None
        if "leaf" in n:
            return "leaf"
        if "mushroom" in n:
            return "mushroom"
        if "flower" in n:
            return "flower"
        if "fire" in n:
            return "flower"
        if "star" in n:
            return "star"

    if "1-up" in n or "one-up" in n:
        return "oneup"

    if "mushroom" in n or "flower" in n or "fire" in n or "star" in n:
        # Fallback: attempt to pick a dominant item type.
        if "mushroom" in n:
            return "mushroom"
        if "flower" in n or "fire" in n:
            return "flower"
        if "star" in n:
            return "star"

    return None


def level_filename(data: dict) -> str:
    world = int(data["world"])
    name = data.get("name") or ""
    lid = data.get("id") or ""

    m = re.fullmatch(r"Level\s+(\d+)", name, re.I)
    if m:
        return f"{world}-{m.group(1)}"

    m = re.search(r"level_(\d+)_(.+)$", lid, re.I)
    if m:
        lvl, kind = m.group(1), m.group(2).lower()
        sub = 2 if "ending" in kind else 1
        return f"{world}-{lvl}_{sub}"

    m = re.fullmatch(r"(\d+)-(\d+)_(.+)", lid)
    if m:
        w, n, suffix = m.group(1), m.group(2), m.group(3).lower()
        base = suffix.split("_", 1)[0]
        mainish = {
            "dungeon",
            "ship",
            "quicksand",
            "pyramid",
            "tank",
            "battleship",
        }
        if (
            base in mainish
            and "boss" not in suffix
            and "spike" not in suffix
            and "water" not in suffix
            and "pipe" not in suffix
            and "bonus" not in suffix
        ):
            return f"{w}-{n}"
        ni = int(n)
        if ni > 9:
            parent = 7 if "dungeon" in suffix else 8 if "ship" in suffix else 1
            return f"{w}-{parent}_{(ni % 5) + 1}"
        return f"{w}-{n}_1"

    m = re.match(r"(\d+)-(\d+)", lid)
    if m:
        return f"{m.group(1)}-{m.group(2)}"
    return re.sub(r"[^\w\-]", "_", lid)


def load_tile_opaque(tiles_dir: Path) -> dict[tuple[int, int], bool]:
    """True when the ROM tile graphic has any opaque pixel (not empty/sky filler)."""
    opaque: dict[tuple[int, int], bool] = {}
    for os_ in range(1, 16):
        png = tiles_dir / f"object_set_{os_}.png"
        if not png.exists():
            continue
        sheet = Image.open(png).convert("RGBA")
        cols = sheet.width // 16
        for tid in range(256):
            tx, ty = tid % cols, tid // cols
            tile = sheet.crop((tx * 16, ty * 16, tx * 16 + 16, ty * 16 + 16))
            opaque[(os_, tid)] = any(p[3] > 0 for p in tile.getdata())
    return opaque


def resolve_props(votes: dict[tuple[int, int], dict[str, int]]) -> dict[tuple[int, int], dict[str, bool]]:
    return {key: resolve_cell_props(scores) for key, scores in votes.items()}


def derive_tile_props(
    levels: list[dict],
    opaque: dict[tuple[int, int], bool] | None = None,
) -> dict[tuple[int, int], dict[str, bool]]:
    votes: dict[tuple[int, int], dict[str, int]] = defaultdict(lambda: defaultdict(int))

    for data in levels:
        os_ = data["object_set"]
        tm = data["tilemap"]
        for o in data.get("objects") or []:
            r = o.get("rendered") or {}
            x0, y0, w, h = r.get("x", 0), r.get("y", 0), r.get("w", 0), r.get("h", 0)
            for dy in range(h):
                props = classify_at(o.get("name", ""), dy, h)
                for dx in range(w):
                    y, x = y0 + dy, x0 + dx
                    if y < 0 or x < 0 or y >= len(tm) or x >= len(tm[0]):
                        continue
                    tid = tm[y][x] & 0xFF
                    if tid == 0:
                        continue
                    if opaque is not None and not opaque.get((os_, tid), True):
                        continue
                    for p, weight in props.items():
                        if weight > 0:
                            votes[(os_, tid)][p] += weight

    return resolve_props(votes)


def validate_props(levels: list[dict], props: dict[tuple[int, int], dict[str, bool]], min_ratio: float = 0.90):
    solid_bottom = total = 0
    for data in levels:
        if data["header"].get("is_vertical"):
            continue
        os_ = data["object_set"]
        tm = data["tilemap"]
        mh = data["header"]["height"]
        for o in data.get("objects") or []:
            if classify(o.get("name", "")).get("collision", 0) <= 0:
                continue
            r = o.get("rendered") or {}
            y1 = r.get("y", 0) + r.get("h", 0) - 1
            if y1 < mh - 1:
                continue
            for dx in range(r.get("w", 0)):
                x = r.get("x", 0) + dx
                if not (0 <= x < len(tm[0])):
                    continue
                tid = tm[mh - 1][x] & 0xFF
                if tid == 0:
                    continue
                total += 1
                if props.get((os_, tid), {}).get("collision"):
                    solid_bottom += 1
    ratio = solid_bottom / total if total else 0.0
    return ratio >= min_ratio, ratio, solid_bottom, total


def pad17_sheet(src: Image.Image, tiles_per_row: int = 16) -> Image.Image:
    src = src.convert("RGBA")
    cols, rows = src.width // 16, src.height // 16
    n = cols * rows
    out_rows = (n + tiles_per_row - 1) // tiles_per_row
    out = Image.new("RGBA", (tiles_per_row * 17, out_rows * 17), (0, 0, 0, 0))
    for i in range(n):
        sx, sy = (i % cols) * 16, (i // cols) * 16
        tile = src.crop((sx, sy, sx + 16, sy + 16))
        dx, dy = (i % tiles_per_row) * 17, (i // tiles_per_row) * 17
        out.paste(tile, (dx, dy))
    return out


def build_combined_tiles(tiles_dir: Path) -> tuple[Image.Image, dict[tuple[int, int], int], int]:
    """Returns padded sheet, (os,tid)→mid mapping, and next free custom index."""
    mapping: dict[tuple[int, int], int] = {}
    strips: list[Image.Image] = []
    next_index = 0
    for os_ in range(1, 16):
        png = tiles_dir / f"object_set_{os_}.png"
        if not png.exists():
            continue
        sheet = Image.open(png).convert("RGBA")
        for tid in range(256):
            mapping[(os_, tid)] = CUSTOM_TILE_BASE + next_index
            next_index += 1
        strips.append(sheet)
    if not strips:
        raise SystemExit("No tile sheets in dump/tiles")
    width = max(s.width for s in strips)
    height = sum(s.height for s in strips)
    combined = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    y = 0
    for s in strips:
        combined.paste(s, (0, y))
        y += s.height
    return pad17_sheet(combined, 16), mapping, next_index


class PropCloner:
    """Duplicate custom tiles with per-level property overrides (shared CHR ids)."""

    def __init__(self, img: Image.Image, next_index: int):
        self.img = img
        self.next_index = next_index
        self.variants: dict[tuple[int, tuple[tuple[str, bool], ...]], int] = {}
        self.mid_props: dict[int, dict[str, bool]] = {}

    def _grow(self, new_idx: int) -> None:
        cols = self.img.width // 17
        rows = self.img.height // 17
        needed_rows = (new_idx // cols) + 1
        if needed_rows > rows:
            bigger = Image.new("RGBA", (self.img.width, needed_rows * 17), (0, 0, 0, 0))
            bigger.paste(self.img, (0, 0))
            self.img = bigger

    def _stamp(self, sheet_idx: int, props: dict[str, bool]) -> None:
        cols = self.img.width // 17
        tx, ty = sheet_idx % cols, sheet_idx // cols
        stamp_props_on_tile(self.img.load(), tx, ty, props)

    def ensure(self, mid: int, want: dict[str, bool]) -> int:
        if mid < CUSTOM_TILE_BASE:
            return mid
        key = (mid, tuple(sorted(want.items())))
        if key in self.variants:
            return self.variants[key]
        src_idx = mid - CUSTOM_TILE_BASE
        cols = self.img.width // 17
        rows = self.img.height // 17
        sx, sy = src_idx % cols, src_idx // cols
        if sy >= rows:
            return mid
        tile = self.img.crop((sx * 17, sy * 17, sx * 17 + 16, sy * 17 + 16))
        new_idx = self.next_index
        self.next_index += 1
        self._grow(new_idx)
        dx, dy = (new_idx % cols) * 17, (new_idx // cols) * 17
        self.img.paste(tile, (dx, dy))
        self._stamp(new_idx, want)
        clone_mid = CUSTOM_TILE_BASE + new_idx
        self.variants[key] = clone_mid
        self.mid_props[clone_mid] = dict(want)
        return clone_mid


def stamp_props_on_tile(px, tx: int, ty: int, props: dict[str, bool]) -> None:
    """Write Mari0 tile property pixels (see world/quad.tl getquadprops)."""
    flag = (255, 0, 0, 255)
    prop_x = tx * 17 + 16
    base_y = ty * 17
    for prop_name, on in props.items():
        if not on:
            continue
        if prop_name == "foreground":
            px[tx * 17 + 15, base_y + 16] = flag
        elif prop_name in PROP_ORDER:
            pi = PROP_ORDER.index(prop_name)
            if pi <= 16:
                px[prop_x, base_y + pi] = flag


def write_tileset_props(
    img: Image.Image,
    mapping: dict[tuple[int, int], int],
    props: dict[tuple[int, int], dict[str, bool]],
) -> Image.Image:
    """Stamp PROP_ORDER flags into the 17th pixel column of each custom tile."""
    out = img.copy()
    px = out.load()
    for (os_, tid), mid in mapping.items():
        p = props.get((os_, tid))
        if not p:
            continue
        # mid is 1-based Mari0 tile id; custom index 0-based in sheet:
        idx = mid - CUSTOM_TILE_BASE  # 0-based within custom sheet
        if idx < 0:
            continue
        tx, ty = idx % 16, idx // 16
        stamp_props_on_tile(px, tx, ty, p)
    return out


def count_collision(img: Image.Image) -> tuple[int, int]:
    w, h = img.size
    cols, rows = w // 17, h // 17
    n = 0
    px = img.load()
    for ty in range(rows):
        for tx in range(cols):
            if px[tx * 17 + 16, ty * 17][3] > 127:
                n += 1
    return n, cols * rows


def rle_encode(tilemap: list[list[int]], enemies_at: dict[tuple[int, int], str]) -> str:
    tokens: list[str] = []
    for y, row in enumerate(tilemap):
        for x, tid in enumerate(row):
            ent = enemies_at.get((x, y))
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


def bg_color(data: dict, dump: Path) -> tuple[int, int, int]:
    os_ = data["object_set"]
    pal_i = data["header"]["object_palette"]
    pal_path = dump / "palettes" / f"object_set_{os_}.json"
    if pal_path.exists():
        groups = json.loads(pal_path.read_text())["groups"]
        for g in groups:
            if g["index"] == pal_i and g.get("rgb"):
                return tuple(g["rgb"][0][0])  # type: ignore
    return (92, 148, 252)


def music_for(data: dict) -> str:
    m = data["header"].get("music", "overworld")
    return {
        "overworld": "overworld.ogg",
        "underground": "underground.ogg",
        "underwater": "underwater.ogg",
        "fortress": "castle.ogg",
        "boss": "castle.ogg",
        "airship": "overworld.ogg",
        "hammer_bros": "overworld.ogg",
    }.get(m, "overworld.ogg")


def spriteset_for(data: dict) -> int:
    os_ = data["object_set"]
    if os_ == 2:
        return 3
    if os_ in (3, 14):
        return 2
    return 1


def props_for_mid(
    mapping: dict[tuple[int, int], int],
    props: dict[tuple[int, int], dict[str, bool]],
) -> dict[int, dict[str, bool]]:
    return {mid: props.get(key, {}) for key, mid in mapping.items()}


def tile_collides(mid: int, mid_props: dict[int, dict[str, bool]]) -> bool:
    return bool(mid_props.get(mid, {}).get("collision"))


def place_spawn(mapped: list[list[int]], mid_props: dict[int, dict[str, bool]]) -> tuple[int, int]:
    """First open cell above solid ground near the left edge (0-based)."""
    h, w = len(mapped), len(mapped[0]) if mapped else 0
    for x in range(0, min(12, w)):
        for y in range(h - 2, 0, -1):
            here, below = mapped[y][x], mapped[y + 1][x]
            if tile_collides(below, mid_props) and not tile_collides(here, mid_props):
                return x, y
    return 1, max(0, h - 3)


def level_to_txt(
    data: dict,
    mapping: dict[tuple[int, int], int],
    dump: Path,
    mid_props: dict[int, dict[str, bool]],
    cloner: PropCloner | None = None,
) -> str:
    os_ = data["object_set"]
    raw = data["tilemap"]
    height = data["header"]["height"]
    is_vert = data["header"]["is_vertical"]
    if not is_vert and height > 15:
        rows = raw[-15:]
        y_offset = height - 15
    else:
        rows = raw
        y_offset = 0
    h, w = len(rows), len(rows[0]) if rows else 0
    mapped = [[mapping.get((os_, tid & 0xFF), CUSTOM_TILE_BASE) for tid in row] for row in rows]

    if cloner is not None:
        for yy in range(h):
            fy = yy + y_offset
            for x in range(w):
                want = effective_cell_props(data, x, fy)
                mid = mapped[yy][x]
                have = mid_props.get(mid, {})
                if not props_equal(have, want):
                    mapped[yy][x] = cloner.ensure(mid, want)

    enemies_at: dict[tuple[int, int], str] = {}
    for enemy in data.get("enemies") or []:
        ent = mari0_entity(enemy["name"])
        if not ent:
            continue
        x = enemy["x"]
        y = enemy["y"] - y_offset
        if 0 <= x < w and 0 <= y < h:
            enemies_at[(x, y)] = ent

    # Question blocks / bricks that contain powerups:
    # encode a second layer marker so mario:hitblock spawns the right item.
    for o in data.get("objects") or []:
        base_name = o.get("name", "")
        drop = powerup_from_block_object(base_name)
        if not drop:
            continue
        rendered = o.get("rendered") or {}
        base_x = rendered.get("x", 0)
        # Place marker for every tile cell painted by this object.
        for x_cell, y_cell in object_cells(o, raw):
            y_m = y_cell - y_offset
            if 0 <= x_cell < w and 0 <= y_m < h:
                if drop == "__wfstar__":
                    # "White Mushrooms, Flowers and Stars" is a composite 3-wide object in SMB3 dumps.
                    # Map left/middle/right cells to mushroom/flower/star.
                    dx = x_cell - base_x
                    cell_drop = "mushroom" if dx <= 0 else ("flower" if dx == 1 else "star")
                else:
                    cell_drop = drop
                enemies_at.setdefault((x_cell, y_m), cell_drop)
    spawn_props = mid_props
    if cloner is not None and cloner.mid_props:
        spawn_props = dict(mid_props)
        spawn_props.update(cloner.mid_props)
    sx, sy = place_spawn(mapped, spawn_props)
    enemies_at[(sx, sy)] = "spawn"
    body = rle_encode(mapped, enemies_at)
    br, bg, bb = bg_color(data, dump)
    timelimit = data["header"].get("time_limit") or 400
    options = [
        f"backgroundr{EQ}{br}",
        f"backgroundg{EQ}{bg}",
        f"backgroundb{EQ}{bb}",
        f"spriteset{EQ}{spriteset_for(data)}",
        f"music{EQ}{music_for(data)}",
        f"timelimit{EQ}{timelimit}",
        f"scrollfactor{EQ}0",
        f"fscrollfactor{EQ}0",
    ]
    return f"{h}{CD}{body}{CD}" + CD.join(options)


def load_levels(levels_dir: Path) -> list[dict]:
    out = []
    for path in sorted(levels_dir.glob("*.json")):
        if path.name == "index.json":
            continue
        data = json.loads(path.read_text())
        if isinstance(data, dict) and data.get("tilemap"):
            out.append(data)
    return out


# World-map tile ids that are walkable (from smb3parse TILE_NAMES + special nodes).
_PATH_TILES = {
    68, 69, 70, 71, 72, 73, 74, 75, 87, 88, 89, 91, 92,
    102, 170, 171, 172, 174, 175, 176, 181, 182, 183, 184, 185, 186,
    217, 218, 219, 220, 221, 222, 229, 230,
}
_LEVEL_NODE_TILES = set(range(3, 13)) | set(range(13, 22))
_SPECIAL_NODE_TILES = {
    0x50, 0x55, 0x5F, 0x67, 0x68, 0x69, 0x80, 0x95, 0xBC, 0xBF,
    0xC9, 0xCC, 0xDF, 0xE0, 0xE6, 0xE8, 0xE9, 0xEB, 0x103, 0x105, 0x188, 0x225, 0x232,
}


def is_map_walkable(tid: int) -> bool:
    tid &= 0xFF
    if tid in (0, 0xFE, 0xB4, 0x2, 0x4E):
        return False
    return tid in _PATH_TILES or tid in _LEVEL_NODE_TILES or tid in _SPECIAL_NODE_TILES


def ensure_map_tiles(dump: Path, foundry: Path | None, rom: Path | None) -> Path:
    map_dir = dump / "worlds" / "map_tiles"
    if (map_dir / "palette_0.png").exists():
        return map_dir
    if foundry and rom and rom.is_file():
        script = Path(__file__).resolve().parent / "export_smb3_map_tiles.py"
        print("Exporting overworld map tiles from ROM …")
        subprocess.run(
            [
                sys.executable,
                str(script),
                "--rom",
                str(rom),
                "--foundry",
                str(foundry),
                "--out",
                str(map_dir),
            ],
            check=True,
        )
        if (map_dir / "palette_0.png").exists():
            return map_dir
    raise SystemExit(
        "missing dump/worlds/map_tiles — run export_smb3_map_tiles.py or pass --rom --foundry"
    )


def append_map_tiles(
    img: Image.Image,
    next_index: int,
    map_dir: Path,
) -> tuple[Image.Image, dict[tuple[int, int], int], int]:
    out = img.copy()
    px = out.load()
    flag = (255, 0, 0, 255)
    mid_for: dict[tuple[int, int], int] = {}
    cols = out.width // 17

    def grow_rows(needed: int) -> None:
        nonlocal out, px, cols
        rows = out.height // 17
        if needed <= rows:
            return
        bigger = Image.new("RGBA", (out.width, needed * 17), (0, 0, 0, 0))
        bigger.paste(out, (0, 0))
        out = bigger
        px = out.load()
        cols = out.width // 17

    for pal in range(MAP_PALETTE_COUNT):
        png = map_dir / f"palette_{pal}.png"
        if not png.exists():
            raise SystemExit(f"missing map tile sheet: {png}")
        sheet = Image.open(png).convert("RGBA")
        for tid in range(256):
            tx, ty = tid % 16, tid // 16
            tile = sheet.crop((tx * 16, ty * 16, tx * 16 + 16, ty * 16 + 16))
            idx = next_index
            next_index += 1
            grow_rows(idx // cols + 1)
            dx, dy = (idx % cols) * 17, (idx // cols) * 17
            out.paste(tile, (dx, dy))
            mid = CUSTOM_TILE_BASE + idx
            mid_for[(pal, tid)] = mid
            if is_map_walkable(tid):
                px[dx + 16, dy] = flag

    return out, mid_for, next_index


def map_bg_color(dump: Path, palette_index: int) -> tuple[int, int, int]:
    pal_path = dump / "palettes" / "object_set_0.json"
    if pal_path.exists():
        groups = json.loads(pal_path.read_text()).get("groups") or []
        for g in groups:
            if g.get("index") == palette_index and g.get("rgb"):
                return tuple(g["rgb"][0][0])  # type: ignore
    return (92, 148, 252)


def build_worldmap_level(
    world_data: dict,
    levels_by_layout: dict[int, dict],
    map_mids: dict[tuple[int, int], int],
    dump: Path,
) -> str:
    """Top-down overworld from dump tile_data + authentic map CHR."""
    screens = int(world_data.get("screen_count") or 1)
    palette_index = int(world_data.get("palette_index") or 0) % MAP_PALETTE_COUNT
    raw = world_data.get("tile_data") or []
    map_w, map_h = 16 * screens, 9
    if len(raw) < map_w * map_h:
        raw = list(raw) + [0xFE] * (map_w * map_h - len(raw))

    out_w, out_h = map_w, map_h
    mapped = [[SKY_TILE for _ in range(out_w)] for _ in range(out_h)]
    enemies_at: dict[tuple[int, int], str] = {}

    def mid_for(tid: int) -> int:
        return map_mids.get((palette_index, tid & 0xFF), SKY_TILE)

    for row in range(map_h):
        for col in range(map_w):
            tid = raw[row * map_w + col] & 0xFF
            if tid in (0, 0xFE):
                continue
            mapped[row][col] = mid_for(tid)

    def place_warp(col: int, row: int, ww: int, ll: int, sub: int) -> None:
        if not (0 <= col < out_w and 0 <= row < out_h):
            return
        key = (col, row)
        if key in enemies_at:
            prev = enemies_at[key]
            if prev != "spawn" and prev.count(LD) <= 2 and sub:
                return
        if sub:
            enemies_at[key] = f"{WARPPIPE_ENTITY_ID}{LD}{ww}{LD}{ll}{LD}{sub}"
        else:
            enemies_at[key] = f"{WARPPIPE_ENTITY_ID}{LD}{ww}{LD}{ll}"

    for ptr in world_data.get("level_pointers") or []:
        data = levels_by_layout.get(ptr.get("layout_address"))
        if not data:
            continue
        ref = parse_level_ref(level_filename(data))
        if not ref:
            continue
        ww, ll, sub = ref
        col = int(ptr.get("column") or 0) + int(ptr.get("screen") or 0) * 16
        row = int(ptr.get("row") or 0) - MAP_FIRST_VALID_ROW
        place_warp(col, row, ww, ll, sub)

    spawn_x, spawn_y = 1, 0
    for i, tid in enumerate(raw):
        if (tid & 0xFF) == 0xE8:  # START tile
            spawn_x = i % map_w
            spawn_y = i // map_w
            break
    else:
        world_n = int(world_data.get("world") or 1)
        for ptr in world_data.get("level_pointers") or []:
            data = levels_by_layout.get(ptr.get("layout_address"))
            if not data:
                continue
            ref = parse_level_ref(level_filename(data))
            if ref and ref == (world_n, 1, 0):
                spawn_x = int(ptr.get("column") or 0) + int(ptr.get("screen") or 0) * 16
                spawn_y = int(ptr.get("row") or MAP_FIRST_VALID_ROW) - MAP_FIRST_VALID_ROW
                break
        else:
            ptrs = world_data.get("level_pointers") or []
            if ptrs:
                spawn_x = int(ptrs[0].get("column") or 0) + int(ptrs[0].get("screen") or 0) * 16
                spawn_y = int(ptrs[0].get("row") or MAP_FIRST_VALID_ROW) - MAP_FIRST_VALID_ROW

    spawn_x = max(0, min(out_w - 1, spawn_x))
    spawn_y = max(0, min(out_h - 1, spawn_y))
    if (spawn_x, spawn_y) in enemies_at:
        for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nx, ny = spawn_x + dx, spawn_y + dy
            if 0 <= nx < out_w and 0 <= ny < out_h and (nx, ny) not in enemies_at:
                spawn_x, spawn_y = nx, ny
                break
    enemies_at[(spawn_x, spawn_y)] = "spawn"

    br, bg, bb = map_bg_color(dump, palette_index)
    body = rle_encode(mapped, enemies_at)
    options = [
        f"backgroundr{EQ}{br}",
        f"backgroundg{EQ}{bg}",
        f"backgroundb{EQ}{bb}",
        f"spriteset{EQ}1",
        f"music{EQ}overworld.ogg",
        f"timelimit{EQ}0",
        f"scrollfactor{EQ}0",
        f"fscrollfactor{EQ}0",
        f"mapmode{EQ}true",
    ]
    return f"{out_h}{CD}{body}{CD}" + CD.join(options)


def write_worldmaps(
    dump: Path,
    out: Path,
    levels: list[dict],
    map_mids: dict[tuple[int, int], int],
) -> int:
    worlds_dir = dump / "worlds"
    if not worlds_dir.exists():
        print("  WARN: no dump/worlds — skipping world map hubs")
        return 0
    by_layout = {d["layout_address"]: d for d in levels if "layout_address" in d}
    written = 0
    for path in sorted(worlds_dir.glob("world_*.json")):
        data = json.loads(path.read_text())
        world_n = int(data.get("world") or 0)
        if world_n < 1 or world_n > 8:
            continue
        text = build_worldmap_level(data, by_layout, map_mids, dump)
        (out / f"{MAP_WORLD}-{world_n}.txt").write_text(text)
        written += 1
    return written


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--dump", type=Path, required=True, help="Path to smb3/dump")
    ap.add_argument("--out", type=Path, required=True, help="Output mappack dir (local)")
    ap.add_argument("--min-solid", type=float, default=0.90)
    ap.add_argument("--rom", type=Path, default=None, help="SMB3 ROM (auto-export map tiles if missing)")
    ap.add_argument("--foundry", type=Path, default=None, help="SMB3-Foundry vendor root")
    args = ap.parse_args()

    dump: Path = args.dump
    out: Path = args.out
    if not (dump / "index.json").exists():
        print("missing dump/index.json", file=sys.stderr)
        return 1

    levels = load_levels(dump / "levels")
    print(f"Loaded {len(levels)} levels")

    print("Deriving tile props …")
    opaque = load_tile_opaque(dump / "tiles")
    props = derive_tile_props(levels, opaque)
    ok, ratio, sb, tot = validate_props(levels, props, args.min_solid)
    print(f"  validate solid_bottom={sb}/{tot} ratio={ratio:.3f} ok={ok}")
    if not ok:
        print("FAIL: solid_bottom ratio below threshold", file=sys.stderr)
        return 2

    print("Building tiles.png …")
    tiles_img, mapping, next_index = build_combined_tiles(dump / "tiles")
    tiles_img = write_tileset_props(tiles_img, mapping, props)
    cloner = PropCloner(tiles_img, next_index)

    out.mkdir(parents=True, exist_ok=True)
    # wipe old level files so renames don't leave orphans
    for old in out.glob("*.txt"):
        old.unlink()
    for old in out.glob("*.png"):
        if old.name != "tiles.png":
            old.unlink()

    mid_props = props_for_mid(mapping, props)

    written = 0
    names: dict[str, int] = {}
    for data in levels:
        fname = level_filename(data)
        # disambiguate collisions
        if fname in names:
            names[fname] += 1
            fname = f"{fname}_{names[fname]}"
        else:
            names[fname] = 1
        (out / f"{fname}.txt").write_text(level_to_txt(data, mapping, dump, mid_props, cloner))
        written += 1

    # Persist sheet after clones may have grown it.
    tiles_img = cloner.img

    col_n, col_tot = count_collision(tiles_img)
    print(f"  collision flags: {col_n}/{col_tot} (tile variants: {len(cloner.variants)})")
    if col_n == 0:
        print("FAIL: zero collision flags written", file=sys.stderr)
        return 3
    tiles_img.save(out / "tiles.png")

    # SMB3 pipes are 2 tiles wide; center plant in the mouth and keep default Y offset.
    enemies_dir = out / "enemies"
    enemies_dir.mkdir(parents=True, exist_ok=True)
    (enemies_dir / "plant.json").write_text(
        json.dumps(
            {
                "base": "plant",
                "spawnoffsetx": 1.0,
            },
            indent="\t",
        )
        + "\n"
    )

    (out / "settings.txt").write_text(
        "\n".join(
            [
                "name=super mario bros. 3 (dump)",
                "author=local dump — do not redistribute",
                "description=Regenerated locally from Foundry dump. Starts at 1-1; normal level progression.",
                "start=1-1",
                "",
            ]
        )
    )

    (out / "tile_mapping.json").write_text(
        json.dumps(
            {
                "custom_tile_base": CUSTOM_TILE_BASE,
                "collision_flags": col_n,
                "nonsolid_clones": len(cloner.variants),
                "solid_bottom_ratio": ratio,
                "entries": {f"{os_}:{tid}": mid for (os_, tid), mid in mapping.items()},
            }
        )
        + "\n"
    )
    print(f"Done. Wrote {written} levels + tiles.png → {out}")
    print("NOTE: mappacks/smb3 is gitignored. Do not commit ROM assets.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
