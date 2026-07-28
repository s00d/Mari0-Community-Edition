#!/usr/bin/env python3
"""
Build mappacks/opensyobon from Open Syobon Action (Cat Mario / Syobon).

LEGAL
-----
OpenSyobonAction has **no clear redistributable license** for Chiku's original
art/levels. This converter reads a *local* OpenSyobonAction tree and writes a
gitignored Mari0 pack. Do **not** commit Nintendo dumps or claim this is Cave Story.
Keep README/NOTICE attribution to Chiku + OpenSyobonAction authors.

Usage:
  python3 scripts/mapsdk/build_opensyobon.py \\
      --src /path/to/OpenSyobonAction-master \\
      --out mappacks/opensyobon

Parses stagep() byte arrays from main.cpp (levels are hardcoded, not separate map files).
"""

from __future__ import annotations

import argparse
import re
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

# Syobon tile codes (from stage() comments + stage loader):
# 1 brick, 2 ?-block, 3 empty marker, 4 platform, 5/6 ground, 7 hidden,
# 9 coin, 20-29 spikes, 30 checkpoint, 40-44 pipes, 50-79 enemies,
# 80-89 items/effects, 98 deco, 99 flagpole
SOLID_CODES = {1, 2, 4, 5, 6, 7}
BREAKABLE = {1}
COINBLOCK = {2}
COIN = {9}
SPIKE = set(range(20, 30))
PIPE = {40, 41, 43, 44}
CHECKPOINT = {30}
FLAG = {99}

# Enemy btype = code - 50 → Mari0 entity
ENEMY_MAP = {
    0: "goomba",
    1: "koopa",
    2: "goomba",
    3: "plant",
    4: "koopaflying",
    5: "beetle",
    6: "spikey",
    7: "cheepcheepred",
    8: "hammerbro",
    30: "goomba",  # 80 in map → ntype
    31: "mushroom",
    32: "flower",
    33: "star",
}


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


def parse_c_byte_array(text: str) -> list[list[int]]:
    """Parse `byte stagedatex[H][W] = { {..}, {..}, ... };` into rows."""
    # Find innermost brace groups for rows
    rows: list[list[int]] = []
    # Match each `{ 0, 1, ... }` that looks like a row (has digits/commas)
    for m in re.finditer(r"\{([^{}]*)\}", text):
        body = m.group(1).strip()
        if not body or not re.search(r"\d", body):
            continue
        nums = [int(x) for x in re.findall(r"\d+", body)]
        if len(nums) < 2:
            continue
        rows.append(nums)
    return rows


def extract_stages(main_cpp: str) -> list[dict]:
    """
    Pull stage blocks from stagep(): sta/stb/stc + stagedatex arrays.
    Returns list of {world, level, sub, grid, comment}.
    """
    # Narrow to stagep function
    m = re.search(r"void\s+stagep\s*\(\s*\)\s*\{", main_cpp)
    if not m:
        raise RuntimeError("stagep() not found in main.cpp")
    # Take until a plausible end — next top-level void after a huge chunk, or EOF
    start = m.start()
    # Heuristic: stagep runs until end of file-ish; cut at last stagedatex copy loop region
    body = main_cpp[start:]

    stages: list[dict] = []
    # Split on stage conditionals
    pattern = re.compile(
        r"if\s*\(\s*sta\s*==\s*(\d+)\s*&&\s*stb\s*==\s*(\d+)\s*&&\s*([^)]*)\)\s*\{",
        re.M,
    )
    matches = list(pattern.finditer(body))
    for i, match in enumerate(matches):
        sta, stb = int(match.group(1)), int(match.group(2))
        stc_expr = match.group(3)
        # Parse stc == N or (stc == 0 || ...)
        stc = 0
        sm = re.search(r"stc\s*==\s*(\d+)", stc_expr)
        if sm:
            stc = int(sm.group(1))
        # Only keep primary overworld (stc==0) plus first underground of each
        end = matches[i + 1].start() if i + 1 < len(matches) else len(body)
        chunk = body[match.start() : end]
        arr_m = re.search(
            r"byte\s+stagedatex\[\d+\]\[\d+\]\s*=\s*(\{(?:[^{}]|\{[^{}]*\})*\});",
            chunk,
            re.S,
        )
        if not arr_m:
            # Fallback: from stagedatex to closing `};` before copy loop
            arr_m = re.search(
                r"byte\s+stagedatex\[\d+\]\[\d+\]\s*=\s*\{(.*?)\n\s*\};",
                chunk,
                re.S,
            )
            if not arr_m:
                continue
            arr_text = "{" + arr_m.group(1) + "}"
        else:
            arr_text = arr_m.group(1)

        rows = parse_c_byte_array(arr_text)
        if len(rows) < 10:
            continue
        # Normalize width to max row length (C allows short initializers → zero pad)
        width = max(len(r) for r in rows)
        grid = [r + [0] * (width - len(r)) for r in rows]
        # Trim trailing all-zero columns
        while width > 20 and all(row[width - 1] == 0 for row in grid):
            width -= 1
            grid = [row[:width] for row in grid]
        comment = ""
        cm = re.search(r"//([^\n]*)", chunk[:200])
        if cm:
            comment = cm.group(1).strip()[:60]
        stages.append(
            {
                "world": sta,
                "level": stb,
                "sub": stc,
                "grid": grid,
                "comment": comment,
            }
        )
    return stages


def level_filename(st: dict) -> str:
    if st["sub"] == 0:
        return f"{st['world']}-{st['level']}.txt"
    return f"{st['world']}-{st['level']}_{st['sub']}.txt"


def build_tilesheet(res: Path) -> tuple[Image.Image, dict[int, int]]:
    """
    Build Mari0 17-stride sheet from brock.PNG / brock2.PNG / item.PNG / teki.PNG.
    Returns (sheet, code→mari0_tile_id) for solid/decor tile codes.
    """
    brock = Image.open(res / "brock.PNG").convert("RGBA")
    # Tiles are 30×30 at 33px stride (see loadg.cpp DerivationGraph)
    def cell(img: Image.Image, col: int, row: int) -> Image.Image:
        x, y = 33 * col, 33 * row
        tile = img.crop((x, y, min(x + 30, img.width), min(y + 30, img.height)))
        if tile.size != (30, 30):
            canvas = Image.new("RGBA", (30, 30), (0, 0, 0, 0))
            canvas.paste(tile, (0, 0))
            tile = canvas
        return tile.resize((16, 16), Image.Resampling.NEAREST)

    # Local index layout:
    # 0 air, 1 brick, 2 ?, 3 unused, 4 platform, 5 ground top, 6 ground fill,
    # 7 hidden, 8 spike, 9 pipe, 10 coin deco
    sprites = {
        0: Image.new("RGBA", (16, 16), (0, 0, 0, 0)),
        1: cell(brock, 0, 0),  # brick-ish
        2: cell(brock, 1, 0),
        3: Image.new("RGBA", (16, 16), (0, 0, 0, 0)),
        4: cell(brock, 3, 0),
        5: cell(brock, 4, 0),
        6: cell(brock, 5, 0),
        7: cell(brock, 6, 0),
        8: cell(brock, 2, 1) if brock.height >= 66 else cell(brock, 2, 0),
        9: cell(brock, 7, 0) if brock.width >= 33 * 8 else cell(brock, 3, 0),
        10: cell(brock, 1, 1) if brock.height >= 66 else cell(brock, 1, 0),
    }

    code_to_local = {
        0: 0,
        1: 1,
        2: 2,
        3: 0,
        4: 4,
        5: 5,
        6: 6,
        7: 7,
        9: 10,  # coin as deco tile; also entity
    }
    for c in SPIKE:
        code_to_local[c] = 8
    for c in PIPE:
        code_to_local[c] = 9

    props_local = {
        0: {},
        1: {"collision": True, "breakable": True},
        2: {"collision": True, "coinblock": True},
        3: {},
        4: {"collision": True, "platform": True},
        5: {"collision": True},
        6: {"collision": True},
        7: {"collision": True, "invisible": True},
        8: {"collision": True, "spikestop": True},
        9: {"collision": True},
        10: {"coin": True},
    }

    n = max(sprites) + 1
    cols = 16
    rows = (n + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * 17, rows * 17), (0, 0, 0, 0))
    px = sheet.load()
    for i, tile in sprites.items():
        ox = (i % cols) * 17
        oy = (i // cols) * 17
        sheet.paste(tile, (ox, oy))
        prop = props_local.get(i, {})
        prop_x = ox + 16
        for name, on in prop.items():
            if on and name in PROP_ORDER:
                pi = PROP_ORDER.index(name)
                if pi <= 16:
                    px[prop_x, oy + pi] = (255, 255, 255, 255)

    code_to_mid = {
        code: CUSTOM_TILE_BASE + local for code, local in code_to_local.items()
    }
    return sheet, code_to_mid


def convert_grid(
    grid: list[list[int]], code_to_mid: dict[int, int]
) -> tuple[list[list[int]], dict[tuple[int, int], str]]:
    h = len(grid)
    w = max(len(r) for r in grid) if grid else 0
    mapped = [[CUSTOM_TILE_BASE for _ in range(w)] for _ in range(h)]
    ents: dict[tuple[int, int], str] = {}

    for y in range(h):
        row = grid[y]
        for x in range(min(w, len(row))):
            code = row[x]
            if code in code_to_mid:
                mapped[y][x] = code_to_mid[code]
            elif code in SOLID_CODES:
                mapped[y][x] = CUSTOM_TILE_BASE + 5  # ground fallback
            else:
                mapped[y][x] = CUSTOM_TILE_BASE

            if code in FLAG:
                ents[(x, y)] = "flag"
            elif code in CHECKPOINT:
                ents[(x, y)] = "spawn"  # mid-checkpoint as extra spawn marker later filtered
            elif code in PIPE:
                ents[(x, y)] = "pipe"
            elif code in COIN:
                ents[(x, y)] = "coin"
            elif 50 <= code <= 79:
                btype = code - 50
                ents[(x, y)] = ENEMY_MAP.get(btype, "goomba")
            elif 80 <= code <= 89:
                ents[(x, y)] = ENEMY_MAP.get(code - 50, "mushroom")

    return mapped, ents


def place_spawn(mapped: list[list[int]], ents: dict[tuple[int, int], str]) -> tuple[int, int]:
    h, w = len(mapped), len(mapped[0]) if mapped else 0
    base = CUSTOM_TILE_BASE

    def solid(x: int, y: int) -> bool:
        if not (0 <= x < w and 0 <= y < h):
            return True
        return mapped[y][x] > base

    def air(x: int, y: int) -> bool:
        return not solid(x, y)

    # Prefer left side
    for x in range(1, min(20, w - 1)):
        for y in range(h - 2, 1, -1):
            if air(x, y) and solid(x, y + 1) and air(x, y - 1):
                if air(x - 1, y) or air(x + 1, y):
                    return x, y
    return 2, max(1, h - 3)


def place_flag(mapped: list[list[int]]) -> tuple[int, int]:
    h, w = len(mapped), len(mapped[0]) if mapped else 0
    base = CUSTOM_TILE_BASE
    for x in range(w - 1, max(0, w // 2), -1):
        for y in range(h - 2, 0, -1):
            if mapped[y][x] == base and mapped[y + 1][x] > base:
                return x, y
    return w - 2, max(1, h - 3)


def write_notice(out: Path, src: Path) -> None:
    out.write_text(
        "\n".join(
            [
                "Open Syobon Action → Mari0 CE (opensyobon)",
                "==========================================",
                "",
                "Original game: Syobon Action / しょぼんのアクション by Chiku (ちく).",
                "Open-source SDL port: Open Syobon Action (Mathew Velasquez / angelXwind et al.).",
                f"Source tree used: {src}",
                "",
                "License note: OpenSyobonAction does not ship a clear OSS license for Chiku's",
                "original graphics/levels. This mappack is regenerated locally for personal use.",
                "Do not redistribute the art/levels without rights. Converter scripts are OK to share.",
                "This is NOT Cave Story (doukutsu) — see mappacks/cavestory for that pack.",
                "",
            ]
        ),
        encoding="utf-8",
    )


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    ap.add_argument(
        "--src",
        type=Path,
        required=True,
        help="OpenSyobonAction root (contains main.cpp + res/)",
    )
    ap.add_argument("--out", type=Path, default=Path("mappacks/opensyobon"))
    ap.add_argument(
        "--include-sub",
        action="store_true",
        help="Also emit pipe sublevels as N-M_S.txt (default: stc==0 only + 1 underground sample)",
    )
    args = ap.parse_args()

    src: Path = args.src
    main_cpp = src / "main.cpp"
    res = src / "res"
    if not main_cpp.exists():
        print(f"missing {main_cpp}", file=sys.stderr)
        return 1
    if not (res / "brock.PNG").exists():
        print(f"missing {res / 'brock.PNG'}", file=sys.stderr)
        return 1

    text = main_cpp.read_text(encoding="utf-8", errors="replace")
    stages = extract_stages(text)
    print(f"Parsed {len(stages)} stage arrays from main.cpp")

    # Filter: all stc==0; optionally sublevels
    selected = []
    for st in stages:
        if st["sub"] == 0:
            selected.append(st)
        elif args.include_sub:
            selected.append(st)
        elif st["sub"] == 1 and st["world"] == 1 and st["level"] == 2:
            # Keep classic 1-2 underground as 1-2_1
            selected.append(st)

    # Deduplicate by filename (first wins)
    seen: set[str] = set()
    unique: list[dict] = []
    for st in selected:
        fn = level_filename(st)
        if fn in seen:
            continue
        seen.add(fn)
        unique.append(st)
    print(f"Emitting {len(unique)} levels")

    sheet, code_to_mid = build_tilesheet(res)
    args.out.mkdir(parents=True, exist_ok=True)
    for old in args.out.glob("*.txt"):
        if old.name not in {"settings.txt", "NOTICE.txt", "STAGES.txt"}:
            old.unlink()

    sheet.save(args.out / "tiles.png")
    enemy_counts: Counter = Counter()
    manifest: list[str] = []

    for st in unique:
        grid = st["grid"]
        mapped, ents = convert_grid(grid, code_to_mid)
        # Remove checkpoint→spawn noise; place real spawn
        ents = {k: v for k, v in ents.items() if v != "spawn"}
        sx, sy = place_spawn(mapped, ents)
        ents[(sx, sy)] = "spawn"
        if not any(v == "flag" for v in ents.values()):
            fx, fy = place_flag(mapped)
            ents[(fx, fy)] = "flag"
        for v in ents.values():
            if v not in {"spawn", "flag", "pipe", "coin"}:
                enemy_counts[v] += 1

        h = len(mapped)
        body = rle_encode(mapped, ents)
        text_out = f"{h}{CD}{body}{CD}spriteset{EQ}1{CD}timelimit{EQ}0"
        fn = level_filename(st)
        (args.out / fn).write_text(text_out, encoding="utf-8")
        w = len(mapped[0]) if mapped else 0
        manifest.append(
            f"{fn}  {st['world']}-{st['level']}/{st['sub']}  {w}x{h}  "
            f"spawn={sx},{sy}  //{st['comment']}"
        )
        print(f"  wrote {fn} ({w}x{h}) spawn=({sx},{sy})")

    (args.out / "settings.txt").write_text(
        "\n".join(
            [
                "name=opensyobon (local)",
                "author=Chiku / OpenSyobonAction — local rebuild only",
                "description=Syobon Action (Cat Mario) via mapsdk/build_opensyobon.py — NOT Cave Story",
                "",
            ]
        ),
        encoding="utf-8",
    )
    write_notice(args.out / "NOTICE.txt", src.resolve())
    (args.out / "STAGES.txt").write_text("\n".join(manifest) + "\n", encoding="utf-8")

    # Optional: copy player/teki reference into enemies note (not full enemy defs)
    print("Enemy entity remap counts:", dict(enemy_counts))
    print(f"Done → {args.out}  levels={len(unique)}  (gitignored recommended)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
