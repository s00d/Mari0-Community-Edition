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

DECORATIVE = (
    "background cloud",
    "background bush",
    "background coconut",
    "background aquatic",
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


def classify(name: str) -> dict[str, int]:
    n = name.lower().strip()
    if n in ("coins", "frozen coins") or "silver coins" in n or n == "invisible coin":
        out = {"coin": 1, "collision": -5}
        if "invisible" in n:
            out["invisible"] = 1
        return out

    for d in DECORATIVE:
        if d in n:
            if "hill" in n:
                return {"collision": 3}
            return {"collision": -5}

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
    if "platform" in n and "wire" not in n:
        return {"collision": 2, "platform": 2}
    if "note block" in n or "cloud platform" in n:
        return {"collision": 2, "platform": 2}
    return {"collision": 2}


def mari0_entity(name: str) -> str | None:
    key = name.lower().strip()
    if key in ENEMY_MAP:
        return ENEMY_MAP[key]
    for prefix, ent in ENEMY_MAP.items():
        if prefix in key:
            return ent
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


def derive_tile_props(levels: list[dict]) -> dict[tuple[int, int], dict[str, bool]]:
    votes: dict[tuple[int, int], dict[str, int]] = defaultdict(lambda: defaultdict(int))

    for data in levels:
        os_ = data["object_set"]
        tm = data["tilemap"]
        for o in data.get("objects") or []:
            r = o.get("rendered") or {}
            props = classify(o.get("name", ""))
            x0, y0, w, h = r.get("x", 0), r.get("y", 0), r.get("w", 0), r.get("h", 0)
            for dy in range(h):
                for dx in range(w):
                    y, x = y0 + dy, x0 + dx
                    if y < 0 or x < 0 or y >= len(tm) or x >= len(tm[0]):
                        continue
                    tid = tm[y][x] & 0xFF
                    if tid == 0:
                        continue
                    for p, weight in props.items():
                        votes[(os_, tid)][p] += weight

    out: dict[tuple[int, int], dict[str, bool]] = {}
    for key, scores in votes.items():
        out[key] = {p: True for p, s in scores.items() if s > 0}
    return out


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


def build_combined_tiles(tiles_dir: Path) -> tuple[Image.Image, dict[tuple[int, int], int]]:
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
    return pad17_sheet(combined, 16), mapping


def write_tileset_props(
    img: Image.Image,
    mapping: dict[tuple[int, int], int],
    props: dict[tuple[int, int], dict[str, bool]],
) -> Image.Image:
    """Stamp PROP_ORDER flags into the 17th pixel column of each custom tile."""
    out = img.copy()
    px = out.load()
    flag = (255, 0, 0, 255)
    for (os_, tid), mid in mapping.items():
        p = props.get((os_, tid))
        if not p:
            continue
        # mid is 1-based Mari0 tile id; custom index 0-based in sheet:
        idx = mid - CUSTOM_TILE_BASE  # 0-based within custom sheet
        if idx < 0:
            continue
        tx, ty = idx % 16, idx // 16
        prop_x = tx * 17 + 16
        for prop_name, on in p.items():
            if not on or prop_name not in PROP_ORDER:
                continue
            pi = PROP_ORDER.index(prop_name)
            if pi > 16:
                continue
            px[prop_x, ty * 17 + pi] = flag
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


def level_to_txt(data: dict, mapping: dict[tuple[int, int], int], dump: Path) -> str:
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
    enemies_at: dict[tuple[int, int], str] = {}
    for enemy in data.get("enemies") or []:
        ent = mari0_entity(enemy["name"])
        if not ent:
            continue
        x, y = enemy["x"], enemy["y"] - y_offset
        if 0 <= x < w and 0 <= y < h:
            enemies_at[(x, y)] = ent
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


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--dump", type=Path, required=True, help="Path to smb3/dump")
    ap.add_argument("--out", type=Path, required=True, help="Output mappack dir (local)")
    ap.add_argument("--min-solid", type=float, default=0.90)
    args = ap.parse_args()

    dump: Path = args.dump
    out: Path = args.out
    if not (dump / "index.json").exists():
        print("missing dump/index.json", file=sys.stderr)
        return 1

    levels = load_levels(dump / "levels")
    print(f"Loaded {len(levels)} levels")

    print("Deriving tile props …")
    props = derive_tile_props(levels)
    ok, ratio, sb, tot = validate_props(levels, props, args.min_solid)
    print(f"  validate solid_bottom={sb}/{tot} ratio={ratio:.3f} ok={ok}")
    if not ok:
        print("FAIL: solid_bottom ratio below threshold", file=sys.stderr)
        return 2

    print("Building tiles.png …")
    tiles_img, mapping = build_combined_tiles(dump / "tiles")
    tiles_img = write_tileset_props(tiles_img, mapping, props)
    col_n, col_tot = count_collision(tiles_img)
    print(f"  collision flags: {col_n}/{col_tot}")
    if col_n == 0:
        print("FAIL: zero collision flags written", file=sys.stderr)
        return 3

    out.mkdir(parents=True, exist_ok=True)
    # wipe old level files so renames don't leave orphans
    for old in out.glob("*.txt"):
        old.unlink()
    for old in out.glob("*.png"):
        if old.name != "tiles.png":
            old.unlink()

    tiles_img.save(out / "tiles.png")
    (out / "settings.txt").write_text(
        "\n".join(
            [
                "name=super mario bros. 3 (dump)",
                "author=local dump — do not redistribute",
                "description=Regenerated locally from Foundry dump via mapsdk/build_smb3.py",
                "",
            ]
        )
    )

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
        (out / f"{fname}.txt").write_text(level_to_txt(data, mapping, dump))
        written += 1

    (out / "tile_mapping.json").write_text(
        json.dumps(
            {
                "custom_tile_base": CUSTOM_TILE_BASE,
                "collision_flags": col_n,
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
