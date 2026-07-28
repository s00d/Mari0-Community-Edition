#!/usr/bin/env python3
"""Generate METROID FAULT: 10+ roomcam levels + per-level rooms JSON + boss enemies.

Each level is a separate map file (1-1.txt … 1-10.txt) with its own rooms/<level>.json.
Ability globools persist across nextlevel(); each level also places local pickups so
mid-pack level select stays softlock-safe.
"""
from __future__ import annotations

import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "mappacks" / "metroidfault"
ROOMS_DIR = OUT / "rooms"
ENEMY_OUT = OUT / "enemies"
ENGINE = ROOT / "mappacks" / "enginefault"

BD, LD, CD, MD, EQ = "¤", "×", "¸", "·", "¨"
ENT_SPAWN = 8
ENT_GATEDOOR = 29
ENT_FLAG = 11
RW, RH = 25, 15


def load_ids() -> dict[str, int]:
    path = OUT / "tileids.json"
    if path.exists():
        return json.loads(path.read_text())
    raise SystemExit("missing tileids.json — run after stub art exists")


IDS = load_ids()

THEME = {
    "hub": dict(floor="floor", wall="wall", plat="platform", deco=("qa", "ticket", "warn"), void="void", spike="spike", brk="breakable"),
    "drain": dict(floor="floor2", wall="pipe", plat="plat2", deco=("bug", "null", "mem"), void="void2", spike="spike2", brk="break2"),
    "tech": dict(floor="mem", wall="wall2", plat="grate", deco=("glitch", "offby", "gel"), void="void", spike="warn", brk="breakable"),
    "ice": dict(floor="ice", wall="ice2", plat="bridge", deco=("null2", "qa2", "glitch2"), void="void2", spike="spike", brk="break2"),
    "rift": dict(floor="checker", wall="grate2", plat="bridge2", deco=("bug2", "glitch", "ticket2"), void="void", spike="spike2", brk="breakable"),
    "core": dict(floor="floor2", wall="wall2", plat="plat2", deco=("warn2", "mem2", "qa"), void="void2", spike="spike", brk="break2"),
}

# Each level: id, title, bg, start room, layout, gates, items, enemies, bosses, spawns, flags
# layout id -> (x, y, w, h, flags, theme)
LEVELS: list[dict] = [
    {
        "id": "1-1",
        "title": "Gate Protocol",
        "bg": (16, 18, 32),
        "start": "entry",
        "layout": {
            "entry": (0, 0, RW, RH, "scroll_h", "hub"),
            "atrium": (25, 0, RW, RH, "scroll_h", "hub"),
            "exit": (50, 0, RW, RH, "scroll_h|save", "hub"),
        },
        "gates": {("entry", "atrium"): ("open", "open"), ("atrium", "exit"): ("blue", "open")},
        "items": {
            "entry": [{"uid": "l1_portal", "ability": "portal", "dx": 6, "dy": 11}],
        },
        "enemies": {
            "entry": [("goomba", 10, 12), ("koopa", 16, 12)],
            "atrium": [("spikey", 8, 12), ("beetle", 14, 12), ("goomba", 18, 12)],
            "exit": [("goomba", 10, 12)],
        },
        "bosses": {},
        "spawns": {"entry": (4, 12)},
        "flags": {"exit": (20, 12)},
    },
    {
        "id": "1-2",
        "title": "Vent Crawl",
        "bg": (12, 28, 28),
        "start": "shaft",
        "layout": {
            "shaft": (0, 0, RW, RH, "scroll_h|scroll_v", "drain"),
            "vents": (25, 0, RW, RH, "scroll_h", "drain"),
            "drain": (50, 0, RW, RH, "scroll_h|save", "drain"),
        },
        "gates": {
            ("shaft", "vents"): ("morph", "open"),
            ("vents", "drain"): ("open", "open"),
        },
        "items": {
            # morph must be BEFORE the morph gate (softlock otherwise)
            "shaft": [
                {"uid": "l2_portal", "ability": "portal", "dx": 5, "dy": 11},
                {"uid": "l2_morph", "ability": "morphball", "dx": 12, "dy": 11},
            ],
            "vents": [{"uid": "l2_gel", "ability": "gelcannon", "dx": 12, "dy": 11}],
        },
        "enemies": {
            "shaft": [("plant", 10, 12), ("spikey", 16, 12)],
            "vents": [("cheepcheepred", 10, 10), ("squid", 16, 9)],
            "drain": [("plant", 8, 12), ("koopa", 14, 12)],
        },
        "bosses": {},
        "spawns": {"shaft": (4, 12)},
        "flags": {"drain": (20, 12)},
    },
    {
        "id": "1-3",
        "title": "Lab Access",
        "bg": (24, 16, 36),
        "start": "lobby",
        "layout": {
            "lobby": (0, 0, RW, RH, "scroll_h", "tech"),
            "lab": (25, 0, RW, RH, "scroll_h", "tech"),
            "pipes": (50, 0, RW, RH, "scroll_h|save", "tech"),
        },
        "gates": {
            ("lobby", "lab"): ("blue", "open"),
            ("lab", "pipes"): ("open", "open"),
        },
        "items": {
            "lobby": [
                {"uid": "l3_portal", "ability": "portal", "dx": 5, "dy": 11},
                {"uid": "l3_morph", "ability": "morphball", "dx": 8, "dy": 11},
            ],
            "lab": [{"uid": "l3_gel", "ability": "gelcannon", "dx": 12, "dy": 10}],
        },
        "enemies": {
            "lobby": [("turret", 10, 10), ("latcher", 16, 12)],
            "lab": [("turret", 8, 10), ("turret", 18, 10), ("latcher", 14, 12)],
            "pipes": [("plant", 7, 12), ("hammerbros", 16, 12)],
        },
        "bosses": {},
        "spawns": {"lobby": (4, 12)},
        "flags": {"pipes": (20, 12)},
    },
    {
        "id": "1-4",
        "title": "Cryo Wing",
        "bg": (20, 28, 48),
        "start": "chill",
        "layout": {
            "chill": (0, 0, RW, RH, "scroll_h", "ice"),
            "cryo": (25, 0, RW, RH, "scroll_h", "ice"),
            "iceboss": (50, 0, RW, RH, "scroll_h|boss|save", "ice"),
        },
        "gates": {
            ("chill", "cryo"): ("open", "open"),
            ("cryo", "iceboss"): ("open", "open"),
        },
        "items": {
            "chill": [
                {"uid": "l4_portal", "ability": "portal", "dx": 4, "dy": 11},
            ],
            "iceboss": [{"uid": "l4_highjump", "ability": "highjump", "dx": 20, "dy": 11}],
        },
        "enemies": {
            "chill": [("drybones", 8, 12), ("boo", 16, 10)],
            "cryo": [("drybones", 7, 12), ("drybones", 14, 12), ("floater", 18, 9)],
        },
        "bosses": {"iceboss": ("icewarden", 12, 10)},
        "spawns": {"chill": (4, 12)},
        "flags": {"iceboss": (22, 12)},
    },
    {
        "id": "1-5",
        "title": "Split Works",
        "bg": (28, 18, 40),
        "start": "gelworks",
        "layout": {
            "gelworks": (0, 0, RW, RH, "scroll_h", "tech"),
            "span": (25, 0, RW, RH, "scroll_h", "tech"),
            "splitboss": (50, 0, RW, RH, "scroll_h|boss|save", "tech"),
        },
        "gates": {
            ("gelworks", "span"): ("open", "open"),
            ("span", "splitboss"): ("open", "open"),
        },
        "items": {
            "gelworks": [
                {"uid": "l5_gel", "ability": "gelcannon", "dx": 6, "dy": 11},
                {"uid": "l5_portal", "ability": "portal", "dx": 9, "dy": 11},
            ],
        },
        "enemies": {
            "gelworks": [("splitter", 9, 12), ("splitter", 15, 12), ("latcher", 20, 12)],
            "span": [("koopaflying", 8, 8), ("floater", 14, 9), ("boo", 18, 7)],
        },
        "bosses": {"splitboss": ("splitking", 12, 11)},
        "spawns": {"gelworks": (4, 12)},
        "flags": {"splitboss": (20, 12)},
    },
    {
        "id": "1-6",
        "title": "Rift Bridge",
        "bg": (36, 14, 28),
        "start": "rift",
        "layout": {
            "rift": (0, 0, RW, RH, "scroll_h|scroll_v", "rift"),
            "hookhall": (25, 0, RW, RH, "scroll_h", "rift"),
            "bridge": (50, 0, RW, RH, "scroll_h|save", "rift"),
        },
        "gates": {
            ("rift", "hookhall"): ("open", "open"),
            ("hookhall", "bridge"): ("open", "open"),
        },
        "items": {
            "rift": [
                {"uid": "l6_hook", "ability": "hookshot", "dx": 8, "dy": 10},
                {"uid": "l6_highjump", "ability": "highjump", "dx": 12, "dy": 11},
            ],
        },
        "enemies": {
            "rift": [("floater", 10, 8), ("medusa", 16, 9), ("boo", 20, 7)],
            "hookhall": [("medusa", 8, 9), ("charger", 14, 12), ("arrowtrap", 20, 10)],
            "bridge": [("floater", 10, 9), ("boo", 16, 8)],
        },
        "bosses": {},
        "spawns": {"rift": (4, 12)},
        "flags": {"bridge": (20, 12)},
    },
    {
        "id": "1-7",
        "title": "Gorgon Nest",
        "bg": (40, 12, 32),
        "start": "roost",
        "layout": {
            "roost": (0, 0, RW, RH, "scroll_h|scroll_v", "rift"),
            "nest": (25, 0, RW, RH, "scroll_h", "rift"),
            "medusaboss": (50, 0, RW, RH, "scroll_h|boss|save", "rift"),
        },
        "gates": {
            ("roost", "nest"): ("open", "open"),
            ("nest", "medusaboss"): ("open", "open"),
        },
        "items": {
            "roost": [
                {"uid": "l7_hook", "ability": "hookshot", "dx": 10, "dy": 11},
            ],
        },
        "enemies": {
            "roost": [("boo", 8, 8), ("medusa", 14, 9), ("floater", 18, 7)],
            "nest": [("medusa", 8, 9), ("medusa", 16, 8), ("arrowtrap", 20, 10)],
        },
        "bosses": {"medusaboss": ("gorgoncore", 12, 9)},
        "spawns": {"roost": (4, 12)},
        "flags": {"medusaboss": (20, 12)},
    },
    {
        "id": "1-8",
        "title": "Grav Vault",
        "bg": (28, 12, 18),
        "start": "vault",
        "layout": {
            "vault": (0, 0, RW, RH, "scroll_h|save", "core"),
            "core": (25, 0, RW, RH, "scroll_h|scroll_v", "core"),
            "gravlab": (50, 0, RW, RH, "scroll_h|save", "core"),
        },
        "gates": {
            ("vault", "core"): ("open", "open"),
            ("core", "gravlab"): ("green", "open"),
        },
        "items": {
            "vault": [
                {"uid": "l8_portal", "ability": "portal", "dx": 5, "dy": 11},
            ],
            "core": [{"uid": "l8_grav", "ability": "gravitygun", "dx": 18, "dy": 10}],
        },
        "enemies": {
            "vault": [("thwomp", 10, 6), ("turret", 16, 10)],
            "core": [("charger", 8, 12), ("turret", 14, 10)],
            "gravlab": [("thwomp", 9, 6), ("hammerbros", 15, 12), ("charger", 20, 12)],
        },
        "bosses": {},
        "spawns": {"vault": (4, 12)},
        "flags": {"gravlab": (20, 12)},
    },
    {
        "id": "1-9",
        "title": "Slab Descent",
        "bg": (22, 10, 14),
        "start": "descent",
        "layout": {
            "descent": (0, 0, RW, RH, "scroll_h", "core"),
            "pit": (25, 0, RW, RH, "scroll_h|scroll_v", "core"),
            "thwompboss": (50, 0, RW, RH, "scroll_h|boss|save", "core"),
        },
        "gates": {
            ("descent", "pit"): ("green", "open"),
            ("pit", "thwompboss"): ("open", "open"),
        },
        "items": {
            "descent": [
                {"uid": "l9_grav", "ability": "gravitygun", "dx": 6, "dy": 11},
                {"uid": "l9_highjump", "ability": "highjump", "dx": 10, "dy": 11},
            ],
        },
        "enemies": {
            "descent": [("thwomp", 8, 6), ("charger", 14, 12)],
            "pit": [("thwomp", 10, 5), ("turret", 16, 10), ("hammerbros", 20, 12)],
        },
        "bosses": {"thwompboss": ("slaberror", 12, 6)},
        "spawns": {"descent": (4, 12)},
        "flags": {"thwompboss": (20, 12)},
    },
    {
        "id": "1-10",
        "title": "Fault Core",
        "bg": (18, 8, 12),
        "start": "approach",
        "layout": {
            "approach": (0, 0, RW, RH, "scroll_h", "core"),
            "final": (25, 0, RW * 2, RH, "scroll_h|boss|save", "core"),
        },
        "gates": {("approach", "final"): ("green", "open")},
        "items": {
            "approach": [
                {"uid": "l10_grav", "ability": "gravitygun", "dx": 6, "dy": 11},
                {"uid": "l10_portal", "ability": "portal", "dx": 10, "dy": 11},
                {"uid": "l10_morph", "ability": "morphball", "dx": 14, "dy": 11},
            ],
        },
        "enemies": {
            "approach": [("charger", 10, 12), ("turret", 16, 10)],
            "final": [("charger", 16, 12), ("turret", 24, 10), ("hammerbros", 32, 12)],
        },
        "bosses": {"final": ("faultcore", 40, 11)},
        "spawns": {"approach": (4, 12)},
        "flags": {"final": (46, 12)},
    },
]


def adjacency(layout: dict, a: str, b: str):
    ax, ay, aw, ah = layout[a][:4]
    bx, by, bw, bh = layout[b][:4]
    if ax + aw == bx and ay < by + bh and by < ay + ah:
        y0, y1 = max(ay, by), min(ay + ah, by + bh)
        mid = (y0 + y1) // 2
        return ("E", aw - 1, mid - ay, "W", 0, mid - by)
    if bx + bw == ax and ay < by + bh and by < ay + ah:
        y0, y1 = max(ay, by), min(ay + ah, by + bh)
        mid = (y0 + y1) // 2
        return ("W", 0, mid - ay, "E", bw - 1, mid - by)
    if ay + ah == by and ax < bx + bw and bx < ax + aw:
        x0, x1 = max(ax, bx), min(ax + aw, bx + bw)
        mid = (x0 + x1) // 2
        return ("S", mid - ax, ah - 1, "N", mid - bx, 0)
    if by + bh == ay and ax < bx + bw and bx < ax + aw:
        x0, x1 = max(ax, bx), min(ax + aw, bx + bw)
        mid = (x0 + x1) // 2
        return ("N", mid - ax, 0, "S", mid - bx, bh - 1)
    return None


def build_room_defs(level: dict) -> list[dict]:
    layout = level["layout"]
    gates = level.get("gates") or {}
    ids = list(layout)
    doors: dict[str, list] = {i: [] for i in ids}
    for i, a in enumerate(ids):
        for b in ids[i + 1 :]:
            adj = adjacency(layout, a, b)
            if not adj:
                continue
            _side_a, dxa, dya, _side_b, dxb, dyb = adj
            key = (a, b) if (a, b) in gates else ((b, a) if (b, a) in gates else None)
            if key == (a, b):
                ka, kb = gates[key]
            elif key == (b, a):
                kb, ka = gates[key]
            else:
                ka = kb = "open"
            doors[a].append({"kind": ka, "to": b, "dx": dxa, "dy": dya, "uid": f"{level['id']}:{a}>{b}"})
            doors[b].append({"kind": kb, "to": a, "dx": dxb, "dy": dyb, "uid": f"{level['id']}:{b}>{a}"})

    rooms = []
    for rid, (x, y, w, h, flags, theme) in layout.items():
        rooms.append({
            "id": rid,
            "x": x, "y": y, "w": w, "h": h,
            "flags": flags,
            "theme": theme,
            "doors": doors[rid],
            "items": (level.get("items") or {}).get(rid, []),
            "enemies": (level.get("enemies") or {}).get(rid, []),
            "boss": (level.get("bosses") or {}).get(rid),
            "spawn": (level.get("spawns") or {}).get(rid),
            "flag": (level.get("flags") or {}).get(rid),
        })
    return rooms


def blank(w: int, h: int, fill: int) -> list[list[int]]:
    return [[fill for _ in range(w)] for _ in range(h)]


def fill_rect(m, x0, y0, x1, y1, tid):
    h, w = len(m), len(m[0])
    for y in range(max(0, y0), min(h, y1 + 1)):
        for x in range(max(0, x0), min(w, x1 + 1)):
            m[y][x] = tid


def carve(m, x, y, w, h, tid):
    fill_rect(m, x, y, x + w - 1, y + h - 1, tid)


def rle_encode(tilemap: list[list[int]], ents: dict[tuple[int, int], str]) -> str:
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


def write_level_file(level_id: str, tilemap, ents, bg=(16, 18, 32)):
    h = len(tilemap)
    body = rle_encode(tilemap, ents)
    opts = (
        f"backgroundr{EQ}{bg[0]}{CD}backgroundg{EQ}{bg[1]}{CD}backgroundb{EQ}{bg[2]}"
        f"{CD}spriteset{EQ}1{CD}timelimit{EQ}0{CD}scrollfactor{EQ}0{CD}fscrollfactor{EQ}0"
    )
    (OUT / f"{level_id}.txt").write_text(f"{h}{CD}{body}{CD}{opts}", encoding="utf-8")
    print(f"wrote {level_id}.txt {len(tilemap[0])}x{h} ents={len(ents)}")


def ensure_art():
    OUT.mkdir(parents=True, exist_ok=True)
    ROOMS_DIR.mkdir(parents=True, exist_ok=True)
    if not (OUT / "tiles.png").exists() and (ENGINE / "tiles.png").exists():
        shutil.copy2(ENGINE / "tiles.png", OUT / "tiles.png")
        print("copied tiles.png from enginefault")
    if not (OUT / "icon.png").exists() and (ENGINE / "icon.png").exists():
        shutil.copy2(ENGINE / "icon.png", OUT / "icon.png")


def write_boss_enemies():
    ENEMY_OUT.mkdir(parents=True, exist_ok=True)
    bosses = {
        "icewarden": ("thwomp", {"boss": True, "persistkill": True, "health": 6, "slamtrigger": 2.8}),
        "splitking": ("splitter", {"boss": True, "persistkill": True, "health": 5, "splitlevel": 3}),
        "gorgoncore": ("medusa", {"boss": True, "persistkill": True, "health": 7, "sineamp": 2.2}),
        "slaberror": ("thwomp", {"boss": True, "persistkill": True, "health": 8, "slamaccel": 110}),
        "faultcore": ("charger", {"boss": True, "persistkill": True, "health": 10}),
    }
    for name, (base, overlay) in bosses.items():
        (ENEMY_OUT / f"{name}.json").write_text("base=" + base + "\n" + json.dumps(overlay, indent="\t") + "\n")
        print(f"wrote enemies/{name}.json")


def door_dir(dx: int, dy: int, w: int, h: int) -> str:
    if dx <= 1 or dx >= w - 2:
        return "ver"
    return "hor"


def build_level_map(level: dict, rooms: list[dict]):
    W = max(r["x"] + r["w"] for r in rooms)
    H = max(r["y"] + r["h"] for r in rooms)
    air = IDS["air"]
    m = blank(W, H, IDS["void"])
    ents: dict[tuple[int, int], str] = {}

    for r in rooms:
        fill_rect(m, r["x"], r["y"], r["x"] + r["w"] - 1, r["y"] + r["h"] - 1, air)
        th = THEME[r["theme"]]
        floor, wall, plat = IDS[th["floor"]], IDS[th["wall"]], IDS[th["plat"]]
        void, spike, brk = IDS[th["void"]], IDS[th["spike"]], IDS[th["brk"]]
        deco = [IDS[n] for n in th["deco"]]
        x0, y0, w, h = r["x"], r["y"], r["w"], r["h"]

        fill_rect(m, x0, y0, x0 + w - 1, y0 + 1, void)
        fill_rect(m, x0, y0 + h - 2, x0 + w - 1, y0 + h - 1, floor)
        fill_rect(m, x0, y0 + 2, x0, y0 + h - 3, wall)
        fill_rect(m, x0 + w - 1, y0 + 2, x0 + w - 1, y0 + h - 3, wall)

        theme = r["theme"]
        if theme == "hub":
            fill_rect(m, x0 + 5, y0 + 9, x0 + 9, y0 + 9, plat)
            fill_rect(m, x0 + 14, y0 + 8, x0 + 18, y0 + 8, brk)
            m[y0 + 5][x0 + 7] = deco[0]
            m[y0 + 6][x0 + 15] = deco[1]
        elif theme == "drain":
            fill_rect(m, x0 + 4, y0 + 10, x0 + 8, y0 + 10, plat)
            fill_rect(m, x0 + 12, y0 + 8, x0 + 16, y0 + 8, IDS.get("pipe", wall))
            fill_rect(m, x0 + 10, y0 + h - 2, x0 + 12, y0 + h - 2, spike)
            m[y0 + 4][x0 + 6] = deco[0]
        elif theme == "tech":
            fill_rect(m, x0 + 3, y0 + 9, x0 + 6, y0 + 9, plat)
            fill_rect(m, x0 + 10, y0 + 7, x0 + 14, y0 + 7, brk)
            fill_rect(m, x0 + 17, y0 + 9, x0 + 21, y0 + 9, plat)
            m[y0 + 4][x0 + 11] = deco[0]
        elif theme == "ice":
            fill_rect(m, x0 + 5, y0 + 10, x0 + 10, y0 + 10, plat)
            fill_rect(m, x0 + 14, y0 + 8, x0 + 19, y0 + 8, IDS["bridge"])
            fill_rect(m, x0 + 11, y0 + h - 2, x0 + 13, y0 + h - 2, spike)
            m[y0 + 4][x0 + 8] = deco[0]
        elif theme == "rift":
            fill_rect(m, x0 + 4, y0 + 11, x0 + 6, y0 + 11, plat)
            fill_rect(m, x0 + 10, y0 + 9, x0 + 12, y0 + 9, plat)
            fill_rect(m, x0 + 16, y0 + 7, x0 + 18, y0 + 7, plat)
            fill_rect(m, x0 + 8, y0 + h - 2, x0 + 10, y0 + h - 2, spike)
            m[y0 + 3][x0 + 14] = deco[0]
        else:
            fill_rect(m, x0 + 4, y0 + 9, x0 + 8, y0 + 9, plat)
            fill_rect(m, x0 + 12, y0 + 7, x0 + 16, y0 + 7, brk)
            fill_rect(m, x0 + 18, y0 + 9, x0 + min(22, w - 3), y0 + 9, plat)
            m[y0 + 4][x0 + 10] = deco[0]

        if r["id"] == "final" and w >= 40:
            fill_rect(m, x0 + 28, y0 + 9, x0 + 34, y0 + 9, plat)
            fill_rect(m, x0 + 36, y0 + 7, x0 + 42, y0 + 7, brk)

        for d in r["doors"]:
            dx, dy = int(d["dx"]), int(d["dy"])
            ox, oy = x0 + dx, y0 + dy
            if dx <= 1:
                carve(m, x0, max(y0 + 2, oy - 1), 2, 3, air)
            elif dx >= w - 2:
                carve(m, x0 + w - 2, max(y0 + 2, oy - 1), 2, 3, air)
            elif dy <= 1:
                carve(m, max(x0 + 1, ox - 1), y0, 3, 2, air)
            else:
                carve(m, max(x0 + 1, ox - 1), y0 + h - 2, 3, 2, air)

            kind = d["kind"]
            if kind != "open":
                direction = door_dir(dx, dy, w, h)
                ents[(ox, oy)] = f"{ENT_GATEDOOR}{LD}{direction}{LD}{kind}"

        for name, ex, ey in r.get("enemies") or []:
            ents[(x0 + ex, y0 + ey)] = name
        if r.get("boss"):
            bname, bx, by = r["boss"]
            ents[(x0 + bx, y0 + by)] = bname
        if r.get("spawn"):
            sx, sy = r["spawn"]
            ents[(x0 + sx, y0 + sy)] = str(ENT_SPAWN)
        if r.get("flag"):
            fx, fy = r["flag"]
            ents[(x0 + fx, y0 + fy)] = str(ENT_FLAG)

        for it in r.get("items") or []:
            ix, iy = x0 + int(it["dx"]), y0 + int(it["dy"])
            if 0 <= iy < H and 0 <= ix < W:
                m[iy][ix] = air
                if iy + 1 < H:
                    m[iy + 1][ix] = floor

    write_level_file(level["id"], m, ents, bg=tuple(level.get("bg") or (16, 18, 32)))
    return W, H, len(ents)


def write_level_rooms(level: dict, rooms: list[dict]):
    data = {
        "start": level["start"],
        "level": level["id"],
        "title": level.get("title", level["id"]),
        "rooms": [
            {
                "id": r["id"], "x": r["x"], "y": r["y"], "w": r["w"], "h": r["h"],
                "flags": r["flags"], "doors": r["doors"], "items": r["items"],
            }
            for r in rooms
        ],
    }
    path = ROOMS_DIR / f"{level['id']}.json"
    path.write_text(json.dumps(data, indent=2) + "\n")
    return data


def write_pack_meta(all_level_data: list[dict]):
    # Legacy pack-root rooms.json = first level (tools / old loaders)
    first = all_level_data[0]
    (OUT / "rooms.json").write_text(json.dumps(first, indent=2) + "\n")

    # Index for multi-level loaders / reachability
    index = {
        "levels": [lv["level"] for lv in all_level_data],
        "titles": {lv["level"]: lv.get("title", lv["level"]) for lv in all_level_data},
    }
    (OUT / "levels.json").write_text(json.dumps(index, indent=2) + "\n")

    lines = []
    for lv in all_level_data:
        for r in lv["rooms"]:
            lines.append(f"{lv['level']}:{r['x']},{r['y']},{r['w']},{r['h']},{r['id']},{r['flags']}")
    (OUT / "rooms.txt").write_text("\n".join(lines) + "\n")

    titles = ", ".join(f"{lv['level']} {lv.get('title', '')}" for lv in all_level_data)
    (OUT / "settings.txt").write_text(
        "name=METROID FAULT\n"
        "author=qa4\n"
        f"description=10-sector metroidvania fault-zone. Levels: {titles}.\n"
        "metroid=true\n"
        "lives=0\n"
        "maxhp=5\n"
    )
    print(f"wrote pack meta ({len(all_level_data)} levels)")


def main():
    ensure_art()
    write_boss_enemies()
    all_data = []
    total_rooms = 0
    for level in LEVELS:
        rooms = build_room_defs(level)
        data = write_level_rooms(level, rooms)
        all_data.append(data)
        w, h, n = build_level_map(level, rooms)
        total_rooms += len(rooms)
        print(f"  {level['id']} {level.get('title')}: {len(rooms)} rooms, {w}x{h}, {n} ents")
    write_pack_meta(all_data)
    # remove stale single megamap if we ever left extras — only keep generated ids
    print(f"METROID FAULT: {len(LEVELS)} levels, {total_rooms} rooms total")


if __name__ == "__main__":
    main()
