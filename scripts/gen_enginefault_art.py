#!/usr/bin/env python3
"""Generate ENGINE FAULT mappack art: tiles, icon, enemies, handcrafted levels.

Glitch/debug aesthetic. Limited NES-ish palette. No anti-alias. Hard alpha.
"""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "mappacks" / "enginefault"
ENEMY_OUT = OUT / "enemies"

# --- F0 palette (16 colors) — constant FIRST, everything else derives ---
PALETTE = [
    (0, 0, 0, 255),        # 0 black
    (252, 252, 252, 255),  # 1 white
    (40, 40, 56, 255),     # 2 void
    (72, 80, 104, 255),    # 3 panel
    (120, 130, 160, 255),  # 4 panel hi
    (200, 60, 80, 255),    # 5 fault red
    (80, 200, 120, 255),  # 6 ok green
    (248, 200, 40, 255),  # 7 warn yellow
    (60, 160, 220, 255),  # 8 debug cyan
    (160, 80, 200, 255),  # 9 purple gel-ish
    (40, 200, 200, 255),  # 10 ice
    (180, 100, 40, 255),  # 11 rust
    (100, 100, 110, 255), # 12 mid gray
    (220, 140, 160, 255), # 13 pink err
    (30, 90, 40, 255),    # 14 dark green
    (255, 0, 0, 255),     # 15 prop flag (prop column only)
]

BLK, WHT, VOID, PANEL, PANEL_HI = PALETTE[0], PALETTE[1], PALETTE[2], PALETTE[3], PALETTE[4]
FAULT, OK, WARN, CYAN, PRP = PALETTE[5], PALETTE[6], PALETTE[7], PALETTE[8], PALETTE[9]
ICE, RUST, GRY, PNK, DGRN, FLAG = (
    PALETTE[10], PALETTE[11], PALETTE[12], PALETTE[13], PALETTE[14], PALETTE[15]
)

CUSTOM_TILE_BASE = 221  # smbtilecount(132)+portaltilecount(88)+1
BD, LD, CD, MD, EQ = "¤", "×", "¸", "·", "¨"

PROP_ORDER = [
    "collision", "invisible", "breakable", "coinblock", "coin",
    "notportalable", "slantupleft", "slantupright", "mirror", "grate",
    "platform", "water", "bridge", "spikesleft", "spikestop",
    "spikesright", "spikesbottom",
]

MASK_FLY = [True] * 31
MASK_NORMAL = [
    True,
    False, False, False, False, True,
    False, True, False, True, False,
    False, False, False, False, False,
    True, True, False, False, False,
    False, True, True, False, False,
    True, False, True, True, True,
]


def px(d: ImageDraw.ImageDraw, x: int, y: int, c, w: int = 1, h: int = 1) -> None:
    d.rectangle([x, y, x + w - 1, y + h - 1], fill=c)


def hard_alpha(im: Image.Image) -> Image.Image:
    """Alpha < 128 → 0, else 255. Quantize stray colors to nearest palette."""
    out = im.convert("RGBA")
    data = out.load()
    w, h = out.size
    opaque = [(c[0], c[1], c[2]) for c in PALETTE[:15]]

    def nearest(rgb):
        best, bd = opaque[0], 1e18
        for p in opaque:
            dist = (rgb[0] - p[0]) ** 2 + (rgb[1] - p[1]) ** 2 + (rgb[2] - p[2]) ** 2
            if dist < bd:
                best, bd = p, dist
        return best

    for y in range(h):
        for x in range(w):
            r, g, b, a = data[x, y]
            if a < 128:
                data[x, y] = (0, 0, 0, 0)
            else:
                nr, ng, nb = nearest((r, g, b))
                data[x, y] = (nr, ng, nb, 255)
    return out


def stamp_props(img: Image.Image, tx: int, ty: int, props: dict[str, bool]) -> None:
    data = img.load()
    prop_x = tx * 17 + 16
    for name, on in props.items():
        if not on or name not in PROP_ORDER:
            continue
        pi = PROP_ORDER.index(name)
        if pi > 16:
            continue
        data[prop_x, ty * 17 + pi] = FLAG


def tile_cell(img: Image.Image, tx: int, ty: int, drawer, props: dict[str, bool] | None = None) -> None:
    ox, oy = tx * 17, ty * 17
    cell = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(cell)
    drawer(d)
    cell = hard_alpha(cell)
    img.paste(cell, (ox, oy))
    if props:
        stamp_props(img, tx, ty, props)


# --- tile drawers (16×16) ---

def draw_air(_d):
    pass


def draw_void(d):
    px(d, 0, 0, VOID, 16, 16)
    for i in range(0, 16, 4):
        px(d, i, (i * 3) % 16, BLK, 1, 1)


def draw_floor(d):
    px(d, 0, 0, PANEL, 16, 16)
    px(d, 0, 0, PANEL_HI, 16, 2)
    px(d, 0, 14, BLK, 16, 2)
    px(d, 2, 4, CYAN, 1, 1)
    px(d, 10, 8, FAULT, 1, 1)


def draw_wall(d):
    px(d, 0, 0, PANEL, 16, 16)
    for y in range(0, 16, 4):
        px(d, 0, y, PANEL_HI, 16, 1)
        px(d, 0, y + 1, BLK, 16, 1)
    px(d, 7, 7, WARN, 2, 2)


def draw_breakable(d):
    px(d, 0, 0, RUST, 16, 16)
    px(d, 1, 1, WARN, 14, 14)
    px(d, 3, 3, RUST, 10, 10)
    px(d, 5, 6, BLK, 6, 1)
    px(d, 6, 8, BLK, 4, 1)
    # crack
    px(d, 8, 2, BLK, 1, 12)


def draw_platform(d):
    px(d, 0, 4, PANEL_HI, 16, 4)
    px(d, 0, 4, CYAN, 16, 1)
    px(d, 0, 7, BLK, 16, 1)


def draw_spike(d):
    for i in range(4):
        x = i * 4
        px(d, x + 1, 8, FAULT, 2, 8)
        px(d, x + 1, 6, WHT, 2, 2)


def draw_grate(d):
    px(d, 0, 0, GRY, 16, 16)
    for i in range(0, 16, 2):
        px(d, i, 0, VOID, 1, 16)
        px(d, 0, i, VOID, 16, 1)


def draw_pipe(d):
    px(d, 2, 0, OK, 12, 16)
    px(d, 3, 0, DGRN, 10, 16)
    px(d, 4, 2, OK, 8, 2)


def draw_warn(d):
    px(d, 0, 0, WARN, 16, 16)
    px(d, 2, 2, BLK, 12, 12)
    px(d, 7, 4, WARN, 2, 6)
    px(d, 7, 11, WARN, 2, 2)


def draw_bug(d):
    px(d, 0, 0, VOID, 16, 16)
    px(d, 3, 5, FAULT, 10, 6)
    px(d, 5, 3, FAULT, 6, 2)
    px(d, 5, 7, WHT, 2, 2)
    px(d, 9, 7, WHT, 2, 2)
    px(d, 1, 6, PNK, 2, 1)
    px(d, 13, 6, PNK, 2, 1)


def draw_null_tile(d):
    # "0x0" stamp
    px(d, 0, 0, VOID, 16, 16)
    for x, y in ((2, 4), (3, 4), (4, 4), (2, 5), (2, 6), (2, 7), (2, 8), (3, 8), (4, 8),
                 (7, 4), (8, 4), (9, 4), (7, 5), (9, 5), (7, 6), (9, 6), (7, 7), (9, 7),
                 (7, 8), (8, 8), (9, 8), (12, 4), (13, 4), (12, 5), (12, 6), (12, 7),
                 (12, 8), (13, 8)):
        px(d, x, y, CYAN, 1, 1)


def draw_mem(d):
    px(d, 0, 0, PRP, 16, 16)
    px(d, 1, 1, VOID, 14, 14)
    for i in range(4):
        px(d, 2 + i * 3, 4 + (i % 2), OK if i % 2 == 0 else FAULT, 2, 8)


def draw_offby(d):
    px(d, 0, 0, PANEL, 16, 16)
    px(d, 1, 1, CYAN, 6, 6)
    px(d, 9, 9, FAULT, 6, 6)
    px(d, 7, 7, WARN, 2, 2)


def draw_qa(d):
    px(d, 0, 0, PANEL_HI, 16, 16)
    px(d, 2, 2, BLK, 12, 12)
    # "QA"
    for x, y in ((4, 4), (4, 5), (4, 6), (4, 7), (4, 8), (4, 9), (5, 4), (6, 4),
                 (5, 6), (6, 6), (6, 7), (6, 8), (6, 9),
                 (8, 4), (8, 5), (8, 6), (8, 7), (8, 8), (8, 9),
                 (9, 4), (10, 4), (9, 6), (10, 6), (10, 7), (10, 8), (10, 9)):
        px(d, x, y, WARN, 1, 1)


def draw_checker(d):
    for y in range(16):
        for x in range(16):
            c = PANEL if (x // 4 + y // 4) % 2 == 0 else VOID
            px(d, x, y, c, 1, 1)


def draw_gel_mark(d):
    px(d, 0, 0, VOID, 16, 16)
    px(d, 2, 10, PRP, 12, 4)
    px(d, 4, 8, PRP, 8, 2)


def draw_ice_tile(d):
    px(d, 0, 0, ICE, 16, 16)
    px(d, 1, 1, WHT, 4, 2)
    px(d, 10, 8, WHT, 3, 1)


def draw_bridge(d):
    px(d, 0, 6, RUST, 16, 4)
    for i in range(0, 16, 4):
        px(d, i, 5, WARN, 3, 1)
        px(d, i + 1, 10, BLK, 1, 4)


def draw_glitch(d):
    px(d, 0, 0, VOID, 16, 16)
    for i in range(8):
        px(d, i * 2, (i * 5) % 16, FAULT if i % 2 else CYAN, 2, 2)
        px(d, (15 - i * 2), (i * 3) % 16, WARN, 1, 3)


def draw_ticket(d):
    px(d, 1, 2, WHT, 14, 12)
    px(d, 2, 3, FAULT, 12, 1)
    px(d, 2, 5, GRY, 10, 1)
    px(d, 2, 7, GRY, 8, 1)
    px(d, 2, 9, GRY, 11, 1)
    px(d, 2, 11, OK, 4, 1)


TILE_DEFS: list[tuple] = [
    ("air", draw_air, {}),
    ("void", draw_void, {}),
    ("floor", draw_floor, {"collision": True}),
    ("wall", draw_wall, {"collision": True, "notportalable": True}),
    ("breakable", draw_breakable, {"collision": True, "breakable": True}),
    ("platform", draw_platform, {"collision": True, "platform": True}),
    ("spike", draw_spike, {"collision": True, "spikestop": True}),
    ("grate", draw_grate, {"collision": True, "grate": True}),
    ("pipe", draw_pipe, {"collision": True}),
    ("warn", draw_warn, {"collision": True}),
    ("bug", draw_bug, {}),
    ("null", draw_null_tile, {}),
    ("mem", draw_mem, {"collision": True}),
    ("offby", draw_offby, {"collision": True}),
    ("qa", draw_qa, {}),
    ("checker", draw_checker, {}),
    ("gel", draw_gel_mark, {}),
    ("ice", draw_ice_tile, {"collision": True}),
    ("bridge", draw_bridge, {"collision": True, "bridge": True, "platform": True}),
    ("glitch", draw_glitch, {}),
    ("ticket", draw_ticket, {}),
    # pads to ~40
    ("floor2", draw_floor, {"collision": True}),
    ("wall2", draw_wall, {"collision": True}),
    ("break2", draw_breakable, {"collision": True, "breakable": True}),
    ("plat2", draw_platform, {"collision": True, "platform": True}),
    ("void2", draw_void, {}),
    ("spike2", draw_spike, {"collision": True, "spikestop": True}),
    ("grate2", draw_grate, {"collision": True, "grate": True}),
    ("warn2", draw_warn, {"collision": True}),
    ("glitch2", draw_glitch, {}),
    ("bug2", draw_bug, {}),
    ("mem2", draw_mem, {"collision": True}),
    ("null2", draw_null_tile, {}),
    ("ice2", draw_ice_tile, {"collision": True}),
    ("bridge2", draw_bridge, {"collision": True, "bridge": True, "platform": True}),
    ("qa2", draw_qa, {}),
    ("ticket2", draw_ticket, {}),
    ("checker2", draw_checker, {}),
    ("gel2", draw_gel_mark, {}),
    ("pipe2", draw_pipe, {"collision": True}),
]


def gen_tiles() -> dict[str, int]:
    cols = 8
    rows = (len(TILE_DEFS) + cols - 1) // cols
    img = Image.new("RGBA", (cols * 17, rows * 17), (0, 0, 0, 0))
    ids: dict[str, int] = {}
    for i, (name, drawer, props) in enumerate(TILE_DEFS):
        tx, ty = i % cols, i // cols
        tile_cell(img, tx, ty, drawer, props)
        ids[name] = CUSTOM_TILE_BASE + i
    path = OUT / "tiles.png"
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)
    print(f"wrote {path.relative_to(ROOT)} {img.size} tiles={len(TILE_DEFS)}")
    # collision count
    n = 0
    data = img.load()
    for ty in range(rows):
        for tx in range(cols):
            if data[tx * 17 + 16, ty * 17][3] > 127:
                n += 1
    print(f"  collision flags: {n}")
    return ids


def gen_icon() -> None:
    im = Image.new("RGBA", (50, 50), VOID)
    d = ImageDraw.Draw(im)
    # broken window chrome
    px(d, 4, 8, PANEL, 42, 34)
    px(d, 4, 8, PANEL_HI, 42, 6)
    px(d, 6, 10, FAULT, 3, 3)
    px(d, 11, 10, WARN, 3, 3)
    px(d, 16, 10, OK, 3, 3)
    # BSOD-ish body
    px(d, 6, 16, (20, 40, 120, 255), 38, 24)
    # "EF" / crash
    for x, y in ((12, 22), (12, 23), (12, 24), (12, 25), (12, 26), (12, 27),
                 (13, 22), (14, 22), (13, 24), (14, 24), (13, 27), (14, 27),
                 (18, 22), (18, 23), (18, 24), (18, 25), (18, 26), (18, 27),
                 (19, 22), (20, 22), (19, 24), (20, 24), (20, 25), (20, 26), (20, 27)):
        px(d, x, y, WHT, 1, 1)
    # glitch bars
    px(d, 8, 36, FAULT, 12, 2)
    px(d, 22, 35, CYAN, 8, 3)
    px(d, 32, 36, WARN, 10, 2)
    # border
    d.rectangle([0, 0, 49, 49], outline=BLK)
    path = OUT / "icon.png"
    hard_alpha(im).save(path)
    print(f"wrote {path.relative_to(ROOT)}")


# --- enemies ---

def sheet(frames: int, size: int = 16) -> tuple[Image.Image, ImageDraw.ImageDraw]:
	# Mari0: frames LEFT→RIGHT (width=quadcount*size), height=frame size when nospritesets.
	im = Image.new("RGBA", (size * frames, size), (0, 0, 0, 0))
	return im, ImageDraw.Draw(im)


def draw_nullptr(d, x0, frame):
	# ghostly pointer diamond + "0"
	if frame == 0:
		px(d, x0 + 7, 2, CYAN, 2, 12)
		px(d, x0 + 4, 5, CYAN, 8, 2)
		px(d, x0 + 5, 7, WHT, 6, 4)
		px(d, x0 + 6, 8, BLK, 4, 2)
	else:
		px(d, x0 + 6, 3, CYAN, 4, 10)
		px(d, x0 + 3, 6, FAULT, 10, 2)
		px(d, x0 + 5, 8, WHT, 6, 3)


def draw_offbyone(d, x0, frame):
	# body shifted look: outline one side, fill other
	px(d, x0 + 2 + frame, 4, WARN, 10, 10)
	px(d, x0 + 3 + frame, 5, FAULT, 8, 8)
	px(d, x0 + 5 + frame, 7, BLK, 2, 2)
	px(d, x0 + 8 + frame, 7, BLK, 2, 2)
	px(d, x0 + 14, 2, CYAN, 1, 1)  # stray pixel = off-by-one joke


def draw_memleak(d, x0, frame):
	# growing blob of hex garbage
	s = 8 + frame * 2
	ox = (16 - s) // 2
	px(d, x0 + ox, ox, PRP, s, s)
	px(d, x0 + ox + 1, ox + 1, PNK, s - 2, s - 2)
	px(d, x0 + ox + 2, ox + 3, BLK, 2, 2)
	px(d, x0 + ox + s - 4, ox + 3, BLK, 2, 2)
	if frame:
		px(d, x0 + ox - 1, ox + 2, OK, 2, 2)
		px(d, x0 + ox + s - 1, ox + 6, FAULT, 2, 2)


def save_enemy_png(name: str, drawer, frames: int = 2) -> None:
    im, d = sheet(frames, 16)
    for i in range(frames):
        drawer(d, i * 16, i)
    im = hard_alpha(im)
    ENEMY_OUT.mkdir(parents=True, exist_ok=True)
    path = ENEMY_OUT / f"{name}.png"
    im.save(path)
    print(f"wrote {path.relative_to(ROOT)} {im.size}")


def write_enemy_json(name: str, data: dict) -> None:
    path = ENEMY_OUT / f"{name}.json"
    path.write_text(json.dumps(data, indent="\t") + "\n")
    print(f"wrote {path.relative_to(ROOT)}")


def base_enemy(**kw) -> dict:
    d = {
        "quadcount": 2,
        "quadno": 1,
        "animationtype": "mirror",
        "animationspeed": 0.2,
        "static": False,
        "active": True,
        "category": 4,
        "mask": MASK_NORMAL,
        "emancipatecheck": True,
        "autodelete": True,
        "nospritesets": True,
        "offsetX": 6,
        "offsetY": 3,
        "quadcenterX": 8,
        "quadcenterY": 8,
        "width": 0.75,
        "height": 0.75,
    }
    d.update(kw)
    return d


def gen_enemies() -> None:
    save_enemy_png("nullptr", draw_nullptr, 2)
    write_enemy_json("nullptr", base_enemy(
        movement="nullptr", npspeed=3.2, npcone=0.55,
        width=0.75, height=0.75, gravity=0, mask=MASK_FLY,
        kills=True, invulnerable=True, category=5,
        stompable=False, killsonsides=True,
    ))

    save_enemy_png("offbyone", draw_offbyone, 2)
    write_enemy_json("offbyone", base_enemy(
        movement="offbyone",
        truffleshufflespeed=2, truffleshuffleacceleration=8,
        width=0.75, height=0.75, gravity=80,
        stompable=True, killsonsides=True, category=4,
    ))

    save_enemy_png("memleak", draw_memleak, 2)
    write_enemy_json("memleak", base_enemy(
        movement="memleak", mlgrow=0.08, mlsplit=6.0, mlmax=3.0,
        truffleshufflespeed=1.5, truffleshuffleacceleration=6,
        width=0.75, height=0.75, gravity=70,
        stompable=True, killsonsides=True, category=4,
    ))


# --- levels ---

def rle_encode(tilemap: list[list[int]], ents: dict[tuple[int, int], str]) -> str:
    """Row-major RLE matching level_serialize_maptiles.

    ents values may contain extra layer tokens already joined with LD
    (e.g. 'animationtrigger×compiler' or 'textentity×DONT_JUMP').
    """
    h, w = len(tilemap), len(tilemap[0])
    tokens: list[str] = []
    for y in range(h):
        for x in range(w):
            tid = tilemap[y][x]
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


def write_level(name: str, tilemap: list[list[int]], ents: dict[tuple[int, int], str],
                bg=(24, 28, 48), timelimit=400) -> None:
    h = len(tilemap)
    body = rle_encode(tilemap, ents)
    opts = (
        f"backgroundr{EQ}{bg[0]}{CD}backgroundg{EQ}{bg[1]}{CD}backgroundb{EQ}{bg[2]}"
        f"{CD}spriteset{EQ}1{CD}timelimit{EQ}{timelimit}"
        f"{CD}scrollfactor{EQ}0{CD}fscrollfactor{EQ}0"
    )
    text = f"{h}{CD}{body}{CD}{opts}"
    path = OUT / f"{name}.txt"
    path.write_text(text)
    print(f"wrote {path.relative_to(ROOT)} {len(tilemap[0])}x{h}")


def blank(w: int, h: int, fill: int) -> list[list[int]]:
    return [[fill for _ in range(w)] for _ in range(h)]


def fill_rect(m, x0, y0, x1, y1, tid):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if 0 <= y < len(m) and 0 <= x < len(m[0]):
                m[y][x] = tid


def gen_levels(ids: dict[str, int]) -> None:
    air, floor, wall, brk = ids["air"], ids["floor"], ids["wall"], ids["breakable"]
    plat, spike, void, warn = ids["platform"], ids["spike"], ids["void"], ids["warn"]
    bug, ticket, qa, glitch = ids["bug"], ids["ticket"], ids["qa"], ids["glitch"]
    nullt, memt, offbyt = ids["null"], ids["mem"], ids["offby"]

    # --- 1-1 showcase: breakable tutorial jokes ---
    w, h = 40, 15
    m = blank(w, h, air)
    fill_rect(m, 0, 0, w - 1, 1, void)
    fill_rect(m, 0, h - 2, w - 1, h - 1, floor)
    fill_rect(m, 0, 2, 0, h - 3, wall)
    fill_rect(m, w - 1, 2, w - 1, h - 3, wall)
    # platforms + breakables with contradictory "signs" (deco tiles)
    fill_rect(m, 4, 10, 8, 10, plat)
    fill_rect(m, 10, 8, 14, 8, brk)
    fill_rect(m, 16, 10, 20, 10, plat)
    fill_rect(m, 22, 7, 26, 7, brk)
    fill_rect(m, 28, 10, 34, 10, plat)
    # spike pit joke
    fill_rect(m, 21, h - 2, 23, h - 2, spike)
    # deco
    m[5][6] = warn
    m[5][12] = ticket
    m[4][18] = bug
    m[5][24] = qa
    m[3][30] = glitch
    m[6][32] = nullt
    ents = {
        (3, h - 3): "spawn",
        (36, h - 3): "flag",
        (12, 7): "offbyone",
        (19, 9): "goomba",
        (30, 9): "nullptr",
    }
    write_level("1-1", m, ents)

    # --- 1-2: nullptr corridor + compiler NPC zone ---
    w, h = 48, 15
    m = blank(w, h, air)
    fill_rect(m, 0, 0, w - 1, 1, void)
    fill_rect(m, 0, h - 2, w - 1, h - 1, floor)
    fill_rect(m, 0, 2, 1, h - 3, wall)
    fill_rect(m, w - 2, 2, w - 1, h - 3, wall)
    fill_rect(m, 8, 10, 12, 10, plat)
    fill_rect(m, 16, 8, 22, 8, plat)
    fill_rect(m, 26, 10, 30, 10, plat)
    fill_rect(m, 34, 7, 40, 7, plat)
    m[5][10] = ticket
    m[6][20] = nullt
    m[5][28] = warn
    m[4][36] = qa
    m[h - 4][9] = ticket
    ents = {
        (3, h - 3): "spawn",
        (44, h - 3): "flag",
        (11, 9): "nullptr",
        (19, 7): "nullptr",
        (28, 9): "nullptr",
        (37, 6): "offbyone",
        # compiler NPC: proximity dialogue via animations (playerxgreater≈9.5)
        (9, h - 3): f"textentity{LD}COMPILER",
        (10, h - 3): f"textentity{LD}TICKET_4471",
    }
    write_level("1-2", m, ents)

    # --- 1-3: memleak arena ---
    w, h = 36, 15
    m = blank(w, h, air)
    fill_rect(m, 0, 0, w - 1, 1, void)
    fill_rect(m, 0, h - 2, w - 1, h - 1, floor)
    fill_rect(m, 0, 2, 0, h - 3, wall)
    fill_rect(m, w - 1, 2, w - 1, h - 3, wall)
    fill_rect(m, 6, 11, 10, 11, plat)
    fill_rect(m, 14, 9, 20, 9, plat)
    fill_rect(m, 24, 11, 28, 11, brk)
    fill_rect(m, 12, h - 2, 14, h - 2, spike)
    m[4][8] = memt
    m[5][16] = memt
    m[3][25] = warn
    m[6][22] = offbyt
    ents = {
        (2, h - 3): "spawn",
        (32, h - 3): "flag",
        (8, 10): "memleak",
        (17, 8): "memleak",
        (26, 10): "offbyone",
        (20, h - 3): "nullptr",
    }
    write_level("1-3", m, ents)


def write_settings() -> None:
    path = OUT / "settings.txt"
    path.write_text(
        "name=ENGINE FAULT\n"
        "author=qa4\n"
        "description=build still compiling. you are tester #4. "
        "ticket tracker narrates. glitches are features (WONTFIX).\n"
    )
    print(f"wrote {path.relative_to(ROOT)}")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    write_settings()
    ids = gen_tiles()
    gen_icon()
    gen_enemies()
    gen_levels(ids)
    # expose tile id map for quests/docs
    (OUT / "tileids.json").write_text(json.dumps(ids, indent=2) + "\n")
    print("ENGINE FAULT art pipeline done.")


if __name__ == "__main__":
    main()
