#!/usr/bin/env python3
"""Generate 50x50 CE-style pixel icons for mappacks."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SIZE = 50


def new(bg: tuple[int, ...]) -> Image.Image:
    return Image.new("RGBA", (SIZE, SIZE), bg)


def px(draw: ImageDraw.ImageDraw, x: int, y: int, c: tuple[int, ...], w: int = 1, h: int = 1) -> None:
    draw.rectangle([x, y, x + w - 1, y + h - 1], fill=c)


def border(draw: ImageDraw.ImageDraw, c: tuple[int, ...]) -> None:
    draw.rectangle([0, 0, SIZE - 1, SIZE - 1], outline=c)


def oval_ring(draw: ImageDraw.ImageDraw, cx: int, cy: int, rx: int, ry: int, outer: tuple, mid: tuple, inner: tuple) -> None:
    # draw filled ellipses as ring approximation
    for r_off, col in ((0, outer), (2, mid), (4, inner)):
        bbox = [cx - rx + r_off, cy - ry + r_off, cx + rx - r_off, cy + ry - r_off]
        draw.ellipse(bbox, outline=col)
        draw.ellipse([bbox[0] + 1, bbox[1] + 1, bbox[2] - 1, bbox[3] - 1], outline=col)


def save(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    # Drop unused alpha channel noise for RGB-looking icons when fully opaque
    out = img.convert("RGBA")
    out.save(path, "PNG")
    print(f"wrote {path.relative_to(ROOT)} ({out.size[0]}x{out.size[1]})")


# --- icons ---

def icon_endless() -> Image.Image:
    # Spelunky-ish: dark shaft, ascending platforms, infinity loop
    bg = (18, 22, 40, 255)
    im = new(bg)
    d = ImageDraw.Draw(im)
    stone = (72, 78, 98, 255)
    stone_hi = (110, 118, 140, 255)
    lava = (220, 70, 30, 255)
    lava_hi = (255, 180, 60, 255)
    gold = (255, 210, 70, 255)
    # shaft walls
    for y in range(SIZE):
        px(d, 0, y, stone, 4, 1)
        px(d, 46, y, stone, 4, 1)
        if y % 5 == 0:
            px(d, 1, y, stone_hi, 2, 1)
            px(d, 47, y, stone_hi, 2, 1)
    # platforms climbing up
    plats = [(8, 40, 18), (24, 30, 16), (10, 20, 14), (26, 12, 14)]
    for x, y, w in plats:
        px(d, x, y, stone, w, 3)
        px(d, x, y, stone_hi, w, 1)
    # lava bottom
    px(d, 4, 46, lava, 42, 4)
    px(d, 6, 46, lava_hi, 8, 2)
    px(d, 28, 47, lava_hi, 10, 1)
    # infinity symbol (two loops)
    cyan = (80, 220, 255, 255)
    for dx in (-6, 6):
        oval_ring(d, 25 + dx, 22, 7, 5, cyan, (40, 160, 220, 255), cyan)
    # connector
    px(d, 22, 21, cyan, 6, 2)
    border(d, (8, 10, 20, 255))
    return im


def icon_portal() -> Image.Image:
    im = new((0, 0, 0, 255))
    d = ImageDraw.Draw(im)
    # tilted blue portal
    cx, cy = 25, 25
    for i, col in enumerate([(20, 60, 140, 255), (40, 140, 230, 255), (120, 220, 255, 255), (40, 140, 230, 255)]):
        rx, ry = 14 - i * 2, 20 - i * 2
        # slight tilt via offset ellipses
        d.ellipse([cx - rx + i, cy - ry, cx + rx + i, cy + ry], outline=col)
        d.ellipse([cx - rx + i + 1, cy - ry + 1, cx + rx + i - 1, cy + ry - 1], outline=col)
    return im


def icon_smb() -> Image.Image:
    # sky, green hill, bricks, mini mario silhouette
    sky = (92, 148, 252, 255)
    im = new(sky)
    d = ImageDraw.Draw(im)
    green = (0, 168, 0, 255)
    green_d = (0, 104, 0, 255)
    # hill
    d.ellipse([2, 22, 48, 62], fill=green)
    px(d, 14, 34, (0, 0, 0, 255), 4, 3)
    px(d, 28, 30, (0, 0, 0, 255), 5, 4)
    # bricks
    brick = (180, 100, 40, 255)
    brick_d = (120, 60, 20, 255)
    for i in range(4):
        x = 8 + i * 9
        px(d, x, 40, brick, 8, 8)
        px(d, x, 40, brick_d, 8, 1)
        px(d, x, 40, brick_d, 1, 8)
    # mario: red hat, face, overalls
    red = (200, 40, 40, 255)
    skin = (252, 188, 120, 255)
    brown = (120, 60, 20, 255)
    blue = (40, 60, 180, 255)
    # body
    px(d, 22, 28, blue, 6, 6)  # overalls
    px(d, 20, 26, red, 10, 4)  # shirt/hat area
    px(d, 22, 22, skin, 6, 5)  # head
    px(d, 20, 20, red, 10, 3)  # hat
    px(d, 28, 24, brown, 3, 2)  # hair
    px(d, 24, 34, brown, 3, 3)  # shoe
    px(d, 27, 34, brown, 3, 3)
    border(d, (40, 80, 160, 255))
    return im


def icon_smb2() -> Image.Image:
    # Lost Levels: night sky, poison mushroom vibe, harder hills
    sky = (20, 24, 72, 255)
    im = new(sky)
    d = ImageDraw.Draw(im)
    # stars
    star = (255, 255, 200, 255)
    for x, y in ((6, 6), (14, 10), (40, 8), (32, 14), (10, 16), (44, 18)):
        px(d, x, y, star, 1, 1)
    # red grass (lost levels overworld often red)
    redg = (180, 40, 40, 255)
    d.ellipse([0, 28, 50, 70], fill=redg)
    px(d, 12, 36, (0, 0, 0, 255), 4, 3)
    # poison mushroom
    stem = (240, 220, 180, 255)
    cap = (160, 40, 200, 255)
    spot = (255, 255, 255, 255)
    px(d, 22, 30, stem, 6, 8)
    d.ellipse([14, 18, 36, 34], fill=cap)
    px(d, 18, 22, spot, 3, 3)
    px(d, 28, 24, spot, 3, 2)
    # "LL" mark
    gold = (255, 210, 60, 255)
    px(d, 6, 40, gold, 2, 8)
    px(d, 6, 46, gold, 5, 2)
    px(d, 14, 40, gold, 2, 8)
    px(d, 14, 46, gold, 5, 2)
    border(d, (10, 10, 40, 255))
    return im


def icon_smb3() -> Image.Image:
    # SMB3 overworld: blue sky, tanooki leaf / map card
    sky = (100, 180, 255, 255)
    im = new(sky)
    d = ImageDraw.Draw(im)
    # card border
    card = (255, 248, 220, 255)
    edge = (40, 40, 40, 255)
    px(d, 8, 6, card, 34, 38)
    d.rectangle([8, 6, 41, 43], outline=edge)
    # green leaf (raccoon power)
    leaf = (40, 160, 60, 255)
    leaf_d = (20, 100, 40, 255)
    d.ellipse([14, 12, 36, 34], fill=leaf)
    px(d, 24, 14, leaf_d, 2, 18)
    # stem
    px(d, 23, 32, (80, 50, 20, 255), 4, 6)
    # world number style dots
    for i, col in enumerate([(220, 40, 40, 255), (40, 120, 220, 255), (240, 180, 40, 255)]):
        px(d, 12 + i * 10, 38, col, 4, 3)
    border(d, (30, 80, 140, 255))
    return im


def icon_smbl() -> Image.Image:
    # Game Boy greens: mushroom + superball
    gb_d = (15, 56, 15, 255)
    gb_m = (48, 98, 48, 255)
    gb_l = (202, 220, 80, 255)
    im = new(gb_l)
    d = ImageDraw.Draw(im)
    border(d, gb_d)
    d.rectangle([1, 1, 48, 48], outline=gb_m)
    px(d, 20, 28, gb_m, 10, 10)  # stem
    d.ellipse([10, 10, 40, 34], fill=gb_d)
    px(d, 16, 16, gb_l, 4, 4)
    px(d, 28, 18, gb_l, 5, 4)
    px(d, 22, 14, gb_l, 3, 3)
    d.ellipse([34, 30, 46, 42], fill=gb_d)
    px(d, 37, 33, gb_l, 3, 2)
    px(d, 4, 42, gb_m, 42, 6)
    for x0 in (8, 16, 24, 32):
        px(d, x0, 43, gb_l, 5, 4)
    return im


def icon_portal_tribute() -> Image.Image:
    im = new((240, 240, 240, 255))
    d = ImageDraw.Draw(im)
    blue = (40, 140, 230, 255)
    orange = (230, 120, 40, 255)
    ink = (40, 40, 40, 255)
    # floor portal (blue)
    d.ellipse([8, 36, 28, 46], outline=blue, width=2)
    # wall portal (orange)
    d.ellipse([34, 10, 44, 28], outline=orange, width=2)
    # stick figure falling / launching
    px(d, 16, 20, ink, 2, 8)
    px(d, 14, 18, ink, 6, 2)  # head-ish
    # arrows
    px(d, 18, 30, ink, 2, 6)
    px(d, 16, 34, ink, 6, 2)
    px(d, 28, 16, ink, 6, 2)
    px(d, 32, 14, ink, 2, 6)
    border(d, (80, 80, 80, 255))
    return im


def icon_acid_trip() -> Image.Image:
    im = new((20, 0, 40, 255))
    d = ImageDraw.Draw(im)
    palette = [
        (0, 255, 200, 255),
        (255, 0, 200, 255),
        (180, 255, 0, 255),
        (80, 40, 255, 255),
        (255, 220, 0, 255),
    ]
    # kaleidoscope rings
    for i, col in enumerate(palette):
        r = 22 - i * 3
        d.ellipse([25 - r, 25 - r, 25 + r, 25 + r], outline=col)
        d.ellipse([25 - r + 1, 25 - r + 1, 25 + r - 1, 25 + r - 1], outline=col)
    # diamond center
    pts = [(25, 12), (38, 25), (25, 38), (12, 25)]
    d.polygon(pts, outline=(255, 255, 255, 255))
    # radial bars
    for a in range(0, 50, 5):
        col = palette[a % len(palette)]
        px(d, a, 0, col, 2, 3)
        px(d, a, 47, col, 2, 3)
        px(d, 0, a, col, 3, 2)
        px(d, 47, a, col, 3, 2)
    return im


def icon_escape_lab() -> Image.Image:
    im = new((30, 30, 36, 255))
    d = ImageDraw.Draw(im)
    wall = (90, 100, 110, 255)
    door = (60, 180, 220, 255)
    warn = (255, 200, 40, 255)
    # corridor
    px(d, 0, 0, wall, 50, 12)
    px(d, 0, 38, wall, 50, 12)
    # door / portal exit
    d.rectangle([32, 14, 46, 36], outline=door)
    px(d, 34, 16, door, 10, 18)
    # running stick
    ink = (240, 240, 240, 255)
    px(d, 12, 18, ink, 4, 4)
    px(d, 13, 22, ink, 2, 8)
    px(d, 10, 30, ink, 4, 2)
    px(d, 15, 30, ink, 4, 2)
    # hazard stripes
    for i in range(5):
        px(d, 2 + i * 6, 40, warn, 4, 3)
    border(d, (20, 20, 24, 255))
    return im


def icon_science() -> Image.Image:
    im = new((40, 48, 64, 255))
    d = ImageDraw.Draw(im)
    glass = (140, 220, 255, 255)
    liquid = (80, 200, 120, 255)
    stand = (180, 180, 190, 255)
    # flask
    px(d, 20, 8, glass, 10, 4)
    px(d, 18, 12, glass, 14, 4)
    d.polygon([(14, 18), (36, 18), (42, 40), (8, 40)], outline=glass)
    d.polygon([(16, 20), (34, 20), (38, 38), (12, 38)], fill=liquid)
    # bubbles
    px(d, 22, 26, (220, 255, 230, 255), 2, 2)
    px(d, 28, 30, (220, 255, 230, 255), 3, 3)
    # stand
    px(d, 10, 40, stand, 30, 4)
    # portal swirl accent
    d.ellipse([34, 6, 46, 18], outline=(40, 140, 230, 255))
    border(d, (20, 24, 32, 255))
    return im


def icon_untitled() -> Image.Image:
    im = new((28, 28, 36, 255))
    d = ImageDraw.Draw(im)
    # question / branching paths
    path = (200, 200, 210, 255)
    trap = (220, 50, 50, 255)
    safe = (50, 200, 80, 255)
    # Y fork
    px(d, 24, 8, path, 2, 16)
    px(d, 10, 24, path, 16, 2)
    px(d, 24, 24, path, 16, 2)
    px(d, 10, 24, path, 2, 16)
    px(d, 38, 24, path, 2, 16)
    # nodes
    d.ellipse([20, 4, 30, 14], fill=safe)
    d.ellipse([6, 36, 16, 46], fill=trap)
    d.ellipse([34, 36, 44, 46], fill=safe)
    # "?"
    q = (255, 220, 60, 255)
    px(d, 22, 16, q, 6, 2)
    px(d, 26, 18, q, 2, 4)
    px(d, 24, 24, q, 2, 2)
    border(d, (10, 10, 14, 255))
    return im


def icon_lost_levels_dlc() -> Image.Image:
    # Similar to smb2 but distinct: wind + flag
    sky = (40, 120, 200, 255)
    im = new(sky)
    d = ImageDraw.Draw(im)
    cloud = (255, 255, 255, 255)
    d.ellipse([4, 8, 22, 20], fill=cloud)
    d.ellipse([14, 6, 32, 18], fill=cloud)
    # ground
    px(d, 0, 40, (0, 160, 0, 255), 50, 10)
    # flagpole
    pole = (220, 220, 220, 255)
    px(d, 36, 12, pole, 2, 28)
    px(d, 36, 12, (220, 40, 40, 255), 10, 6)
    # wind lines
    w = (200, 230, 255, 255)
    for y in (22, 26, 30):
        px(d, 8, y, w, 12, 1)
    border(d, (20, 60, 120, 255))
    return im


def icon_cavestory() -> Image.Image:
    # Misty cave + Quote silhouette + polar star gun
    bg = (24, 36, 48, 255)
    im = new(bg)
    d = ImageDraw.Draw(im)
    rock = (70, 90, 100, 255)
    rock_hi = (110, 140, 150, 255)
    mist = (160, 200, 190, 80)
    # cave walls
    px(d, 0, 0, rock, 8, 50)
    px(d, 42, 0, rock, 8, 50)
    for y in (4, 14, 28, 40):
        px(d, 1, y, rock_hi, 4, 2)
        px(d, 44, y + 2, rock_hi, 4, 2)
    # mist blobs
    d.ellipse([10, 30, 28, 44], fill=mist)
    d.ellipse([22, 34, 40, 48], fill=mist)
    # Quote: white body, black hair tuft
    body = (240, 240, 245, 255)
    ink = (20, 20, 28, 255)
    gun = (200, 180, 60, 255)
    px(d, 20, 18, body, 8, 10)  # torso
    px(d, 21, 12, body, 6, 7)  # head
    px(d, 22, 10, ink, 5, 3)  # hair
    px(d, 23, 14, ink, 2, 2)  # eye
    # gun pointing right
    px(d, 28, 22, gun, 10, 3)
    px(d, 36, 21, gun, 4, 5)
    # floor
    px(d, 8, 44, rock, 34, 6)
    border(d, (10, 16, 22, 255))
    return im


def icon_opensyobon() -> Image.Image:
    # Cat Mario / Syobon: sky + green ground + white cat silhouette (NOT Cave Story)
    sky = (120, 180, 255, 255)
    im = new(sky)
    d = ImageDraw.Draw(im)
    grass = (40, 160, 50, 255)
    dirt = (120, 80, 40, 255)
    brick = (180, 60, 40, 255)
    cat = (250, 250, 255, 255)
    ink = (30, 30, 40, 255)
    # ground
    px(d, 0, 38, dirt, 50, 12)
    px(d, 0, 36, grass, 50, 3)
    # brick
    px(d, 8, 22, brick, 10, 10)
    px(d, 9, 23, (220, 100, 70, 255), 3, 3)
    # cat body
    px(d, 24, 20, cat, 10, 12)
    px(d, 26, 14, cat, 8, 8)  # head
    px(d, 26, 12, cat, 3, 4)  # ear L
    px(d, 31, 12, cat, 3, 4)  # ear R
    px(d, 28, 16, ink, 2, 2)  # eye
    px(d, 22, 28, cat, 4, 2)  # tail stub
    border(d, (20, 40, 80, 255))
    return im


def icon_supertux() -> Image.Image:
    # Snowy hill + orange penguin
    sky = (140, 190, 255, 255)
    im = new(sky)
    d = ImageDraw.Draw(im)
    snow = (250, 250, 255, 255)
    snow_d = (200, 210, 230, 255)
    orange = (240, 120, 30, 255)
    orange_d = (180, 70, 10, 255)
    white = (255, 255, 255, 255)
    ink = (20, 20, 30, 255)
    # hills
    d.ellipse([-10, 28, 40, 70], fill=snow)
    d.ellipse([20, 32, 60, 72], fill=snow_d)
    # penguin body
    d.ellipse([16, 14, 34, 40], fill=orange)
    d.ellipse([19, 20, 31, 38], fill=white)
    # head
    d.ellipse([18, 8, 32, 22], fill=orange)
    px(d, 22, 12, ink, 2, 2)
    px(d, 27, 12, ink, 2, 2)
    # beak
    px(d, 23, 15, (255, 200, 40, 255), 5, 2)
    # feet
    px(d, 18, 38, orange_d, 5, 3)
    px(d, 27, 38, orange_d, 5, 3)
    # snowflakes
    flake = (255, 255, 255, 255)
    for x, y in ((6, 6), (40, 8), (44, 18), (8, 16)):
        px(d, x, y, flake, 2, 2)
    border(d, (60, 100, 160, 255))
    return im


def icon_metroidfault() -> Image.Image:
    # Gate zone: green acid + morph orb + ability door
    bg = (12, 20, 28, 255)
    im = new(bg)
    d = ImageDraw.Draw(im)
    metal = (80, 100, 110, 255)
    metal_hi = (140, 160, 170, 255)
    acid = (40, 200, 80, 255)
    acid_d = (20, 120, 50, 255)
    orb = (220, 180, 40, 255)
    orb_hi = (255, 240, 120, 255)
    door = (60, 160, 220, 255)
    # corridor walls
    px(d, 0, 0, metal, 50, 10)
    px(d, 0, 40, metal, 50, 10)
    px(d, 0, 10, metal_hi, 50, 1)
    px(d, 0, 40, metal_hi, 50, 1)
    # ability door (right)
    px(d, 36, 12, door, 10, 26)
    px(d, 38, 16, (20, 40, 60, 255), 6, 18)
    px(d, 39, 22, acid, 4, 4)
    # acid pool left
    px(d, 4, 32, acid_d, 18, 8)
    px(d, 6, 32, acid, 14, 3)
    # morph ball
    d.ellipse([14, 16, 30, 32], fill=orb)
    d.ellipse([17, 18, 24, 25], fill=orb_hi)
    px(d, 20, 26, (40, 40, 40, 255), 4, 2)
    border(d, (6, 10, 14, 255))
    return im


def icon_enginefault() -> Image.Image:
    # Broken window / EF crash chrome (same idea as gen_enginefault_art)
    void = (40, 40, 56, 255)
    im = new(void)
    d = ImageDraw.Draw(im)
    panel = (72, 80, 104, 255)
    panel_hi = (120, 130, 160, 255)
    fault = (200, 60, 80, 255)
    warn = (248, 200, 40, 255)
    ok = (80, 200, 120, 255)
    cyan = (60, 160, 220, 255)
    white = (252, 252, 252, 255)
    px(d, 4, 8, panel, 42, 34)
    px(d, 4, 8, panel_hi, 42, 6)
    px(d, 6, 10, fault, 3, 3)
    px(d, 11, 10, warn, 3, 3)
    px(d, 16, 10, ok, 3, 3)
    px(d, 6, 16, (20, 40, 120, 255), 38, 24)
    for x, y in (
        (12, 22), (12, 23), (12, 24), (12, 25), (12, 26), (12, 27),
        (13, 22), (14, 22), (13, 24), (14, 24), (13, 27), (14, 27),
        (18, 22), (18, 23), (18, 24), (18, 25), (18, 26), (18, 27),
        (19, 22), (20, 22), (19, 24), (20, 24), (20, 25), (20, 26), (20, 27),
    ):
        px(d, x, y, white, 1, 1)
    px(d, 8, 36, fault, 12, 2)
    px(d, 22, 35, cyan, 8, 3)
    px(d, 32, 36, warn, 10, 2)
    border(d, (0, 0, 0, 255))
    return im


SETTINGS: dict[str, dict[str, str]] = {
    "mappacks/endless": {
        "name": "endless climb",
        "author": "community",
        "description": "procedural spelunky-style rooms. climb forever - seed shows in HUD/console.",
        "extra": "endless=true\nlives=3\n",
    },
    "mappacks/portal": {
        "name": "portal",
        "author": "stabyourself",
        "description": "cake and mushrooms will be served at the conclusion of the test.",
        "extra": "",
    },
    "mappacks/smb": {
        "name": "super mario bros.",
        "author": "nintendo",
        "description": "the classic NES campaign - pipes, goombas, and flagpoles.",
        "extra": "",
    },
    "mappacks/smb2": {
        "name": "super mario bros. 2 (japan) / lost levels",
        "author": "nintendo / vglc import",
        "description": "SMB2J Lost Levels from TheVGLC. Brutal jumps, poison mushrooms. DEFAULT tileset; pipes are solid decor.",
        "extra": "",
    },
    "mappacks/smb3": {
        "name": "super mario bros. 3",
        "author": "local dump - do not redistribute",
        "description": "SMB3 worlds regenerated locally from a Foundry dump. Tanooki dreams; keep offline.",
        "extra": "",
    },
    "mappacks/smbl": {
        "name": "super mario land",
        "author": "nintendo / vglc import",
        "description": "Game Boy Mario Land via TheVGLC. Superballs & alien worlds. Incomplete: no 2-3/4-3 shooters.",
        "extra": "",
    },
    "toconvert/dlc_a_portal_tribute": {
        "name": "a portal tribute",
        "author": "alphaorionis",
        "description": "speedy thing goes in... speedy thing comes out. classic portal momentum puzzles.",
        "extra": "lives=0\n",
    },
    "toconvert/dlc_acid_trip": {
        "name": "acid trip",
        "author": "raicuparta",
        "description": "we gon sev da prinsass - psychedelic portals, wild tiles, zero chill.",
        "extra": "lives=3\n",
    },
    "toconvert/dlc_escape_the_lab": {
        "name": "escape the lab",
        "author": "xser0",
        "description": "run away from the lab. short portal escape sequence - don't look back.",
        "extra": "lives=0\n",
    },
    "toconvert/dlc_scienceandstuff": {
        "name": "science and stuff",
        "author": "matt y",
        "description": "a brisk refresher of testing. chamber puzzles with portals and wit.",
        "extra": "",
    },
    "toconvert/dlc_smb2J": {
        "name": "the lost levels",
        "author": "nintendo",
        "description": "the japanese version of SMB2. made by renhoex. wind, spikes, no mercy.",
        "extra": "",
    },
    "toconvert/dlc_the_untitled_game": {
        "name": "the untitled game",
        "author": "fartzilla",
        "description": "choose-your-own-adventure mappack. branch wisely - watch for traps!",
        "extra": "lives=0\n",
    },
    "mappacks/cavestory": {
        "name": "cave story (local)",
        "author": "Pixel — do not redistribute assets",
        "description": "Regenerated locally via mapsdk/build_cavestory.py from your CS install",
        "extra": "",
    },
    "mappacks/supertux": {
        "name": "supertux (local)",
        "author": "see AUTHORS.txt — CC-BY-SA levels from SuperTux",
        "description": "CC-BY-SA SuperTux levels (data only; engine GPL not included)",
        "extra": "",
    },
    "mappacks/opensyobon": {
        "name": "opensyobon (local)",
        "author": "Chiku / OpenSyobonAction — local rebuild only",
        "description": "Syobon Action (Cat Mario) via mapsdk/build_opensyobon.py — NOT Cave Story",
        "extra": "",
    },
    "mappacks/enginefault": {
        "name": "ENGINE FAULT",
        "author": "qa4",
        "description": "build still compiling. you are tester #4. ticket tracker narrates. glitches are features (WONTFIX).",
        "extra": "",
    },
    "mappacks/metroidfault": {
        "name": "METROID FAULT",
        "author": "qa4",
        "description": "gate-zone stub for metroid core (rooms+ability doors).",
        "extra": "metroid=true\nlives=0\n",
    },
}

ICONS = {
    "mappacks/endless": icon_endless,
    "mappacks/portal": icon_portal,
    "mappacks/smb": icon_smb,
    "mappacks/smb2": icon_smb2,
    "mappacks/smb3": icon_smb3,
    "mappacks/smbl": icon_smbl,
    "mappacks/cavestory": icon_cavestory,
    "mappacks/supertux": icon_supertux,
    "mappacks/opensyobon": icon_opensyobon,
    "mappacks/enginefault": icon_enginefault,
    "mappacks/metroidfault": icon_metroidfault,
    "toconvert/dlc_a_portal_tribute": icon_portal_tribute,
    "toconvert/dlc_acid_trip": icon_acid_trip,
    "toconvert/dlc_escape_the_lab": icon_escape_lab,
    "toconvert/dlc_scienceandstuff": icon_science,
    "toconvert/dlc_smb2J": icon_lost_levels_dlc,
    "toconvert/dlc_the_untitled_game": icon_untitled,
}


def write_settings(rel: str, meta: dict[str, str], *, overwrite: bool) -> None:
    path = ROOT / rel / "settings.txt"
    if not path.parent.exists():
        print(f"skip settings (missing dir): {rel}")
        return
    if path.exists() and not overwrite:
        print(f"keep settings: {path.relative_to(ROOT)}")
        return
    text = (
        f"name={meta['name']}\n"
        f"author={meta['author']}\n"
        f"description={meta['description']}\n"
        f"{meta.get('extra', '')}"
    )
    path.write_text(text, encoding="utf-8")
    print(f"wrote {path.relative_to(ROOT)}")


def sync_converted_dlc(*, overwrite_icons: bool) -> None:
    """Copy toconvert DLC settings/icon into mappacks/dlc_* if present (gitignored)."""
    import shutil

    for src in sorted((ROOT / "toconvert").glob("dlc_*")):
        dst = ROOT / "mappacks" / src.name
        if not dst.is_dir():
            continue
        for name in ("settings.txt", "icon.png"):
            s, d = src / name, dst / name
            if not s.exists():
                continue
            if name == "icon.png" and d.exists() and not overwrite_icons:
                print(f"keep synced icon: {d.relative_to(ROOT)}")
                continue
            if name == "settings.txt" and d.exists() and not overwrite_icons:
                print(f"keep synced settings: {d.relative_to(ROOT)}")
                continue
            shutil.copy2(s, d)
            print(f"synced {d.relative_to(ROOT)}")


def icon_is_placeholder(path: Path) -> bool:
    """True if icon is missing, empty, wrong size, or a known stub duplicate."""
    if not path.exists() or path.stat().st_size < 64:
        return True
    try:
        with Image.open(path) as im:
            if im.size != (SIZE, SIZE):
                return True
    except OSError:
        return True
    return False


def duplicate_icon_paths() -> set[Path]:
    """Find packs that share identical icon bytes (usually a copied stub)."""
    import hashlib

    by_hash: dict[str, list[Path]] = {}
    for pack in sorted((ROOT / "mappacks").iterdir()):
        icon = pack / "icon.png"
        if not icon.is_file():
            continue
        h = hashlib.sha256(icon.read_bytes()).hexdigest()
        by_hash.setdefault(h, []).append(icon)
    dupes: set[Path] = set()
    for paths in by_hash.values():
        if len(paths) > 1:
            # Keep the first pack's icon; treat the rest as placeholders to replace
            for p in paths[1:]:
                dupes.add(p.resolve())
    return dupes


def main() -> None:
    import argparse

    ap = argparse.ArgumentParser(description="Generate 50x50 mappack icons / settings")
    ap.add_argument(
        "--force",
        action="store_true",
        help="Overwrite existing icons and settings (default: only missing/broken)",
    )
    ap.add_argument(
        "--force-settings",
        action="store_true",
        help="Overwrite settings.txt even when --force is not set",
    )
    args = ap.parse_args()
    overwrite = args.force
    overwrite_settings = args.force or args.force_settings
    dupes = duplicate_icon_paths() if not overwrite else set()

    for rel, fn in ICONS.items():
        dest = ROOT / rel
        if not dest.exists():
            print(f"skip icon (missing dir): {rel}")
            continue
        out = dest / "icon.png"
        needs = overwrite or icon_is_placeholder(out) or out.resolve() in dupes
        if not needs:
            print(f"keep icon: {out.relative_to(ROOT)}")
            continue
        save(fn(), out)

    for rel, meta in SETTINGS.items():
        write_settings(rel, meta, overwrite=overwrite_settings)
    sync_converted_dlc(overwrite_icons=overwrite)


if __name__ == "__main__":
    main()
