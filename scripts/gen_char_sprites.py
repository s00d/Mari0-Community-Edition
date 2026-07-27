#!/usr/bin/env python3
"""Generate CE-format character animation sheets (mario layout 240×80 small)."""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
CHAR = ROOT / "assets" / "characters"

# Mario small sheet: 12 cols × 4 rows of 20×20
SW, SH = 20, 20
COLS, ROWS = 12, 4
SMALL_W, SMALL_H = COLS * SW, ROWS * SH  # 240×80
# Big: 20×36, 12×4 = 240×144
BW, BH = 20, 36
BIG_W, BIG_H = COLS * BW, ROWS * BH


def px(d, x, y, c, w=1, h=1):
    d.rectangle([x, y, x + w - 1, y + h - 1], fill=c)


def mario_like_config(**extra) -> dict:
    cfg = {
        "defaulthat": 0,
        "smalloffsetX": 6,
        "smalloffsetY": 3,
        "smallquadcenterX": 11,
        "smallquadcenterY": 10,
        "shrinkquadcenterX": 9,
        "shrinkquadcenterY": 32,
        "shrinkoffsetY": -3,
        "shrinkquadcenterY2": 16,
        "growquadcenterY": 4,
        "growquadcenterY2": -2,
        "duckquadcenterY": 22,
        "duckoffsetY": 7,
        "runframes": 3,
        "jumpframes": 1,
        "customframes": 3,
        "smallquadwidth": 20,
        "smallquadheight": 20,
        "smallimgwidth": SMALL_W,
        "smallimgheight": SMALL_H,
        "bigquadcenterY": 20,
        "bigquadcenterX": 9,
        "bigoffsetY": -3,
        "bigoffsetX": 6,
        "bigquadwidth": 20,
        "bigquadheight": 36,
        "bigimgwidth": BIG_W,
        "bigimgheight": BIG_H,
        "hatoffsets": {
            "idle": [0, 0],
            "running": [[0, 0], [0, 0], [-1, -1]],
            "sliding": [0, 0],
            "jumping": [[0, -1]],
            "falling": [0, 0],
            "climbing": [[2, 0], [2, -1]],
            "swimming": [[1, -1], [1, -1]],
            "grow": [-6, 0],
        },
        "bighatoffsets": {
            "idle": [-4, -2],
            "fire": [-5, -4],
            "running": [[-5, -4], [-4, -3], [-3, -2]],
            "sliding": [-5, -2],
            "jumping": [[-4, -4]],
            "falling": [-4, -2],
            "climbing": [[-4, -4], [-4, -4]],
            "swimming": [[-5, -4], [-5, -4]],
            "ducking": [-5, -12],
            "grow": [-6, 0],
        },
    }
    cfg.update(extra)
    return cfg


def draw_figure(d, ox, oy, colors, big=False):
    """Simple readable silhouette at cell origin."""
    skin, suit, accent = colors
    h = BH if big else SH
    # legs
    px(d, ox + 6, oy + h - 6, suit, 3, 5)
    px(d, ox + 11, oy + h - 6, suit, 3, 5)
    # body
    body_top = oy + (10 if big else 6)
    body_h = 14 if big else 6
    px(d, ox + 5, body_top, suit, 10, body_h)
    # head
    hx = ox + 6
    hy = oy + (2 if big else 1)
    px(d, hx, hy, skin, 8, 7)
    px(d, hx + 2, hy + 2, (0, 0, 0, 255), 2, 2)  # eye
    px(d, hx + 1, hy, accent, 6, 2)  # hair/helmet


def fill_sheet(colors, big=False):
    w, h = (BIG_W, BIG_H) if big else (SMALL_W, SMALL_H)
    cw, ch = (BW, BH) if big else (SW, SH)
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for row in range(ROWS):
        for col in range(COLS):
            draw_figure(d, col * cw, row * ch, colors, big=big)
            # slight pose variation
            if col % 3 == 1:
                px(d, col * cw + 4, row * ch + ch - 4, colors[1], 2, 2)
            if col % 3 == 2:
                px(d, col * cw + 14, row * ch + ch - 4, colors[1], 2, 2)
    return im


def write_char(name: str, colors, flags: dict):
    folder = CHAR / name
    folder.mkdir(parents=True, exist_ok=True)
    fill_sheet(colors, False).save(folder / "animations.png")
    fill_sheet(colors, True).save(folder / "biganimations.png")
    cfg = mario_like_config(**flags)
    cfg["name"] = name
    (folder / "config.txt").write_text(json.dumps(cfg, indent="\t") + "\n")
    print(f"wrote assets/characters/{name}/")


def main():
    # Samus — orange power suit
    write_char(
        "samus",
        ((252, 188, 176, 255), (228, 140, 40, 255), (60, 100, 200, 255)),
        {"morphball": True},
    )
    # Ninja — dark blue/black
    write_char(
        "ninja",
        ((252, 188, 176, 255), (40, 40, 70, 255), (200, 40, 40, 255)),
        {"wallcling": True},
    )
    # Bomberman — white suit + pink
    write_char(
        "bomberman",
        ((252, 188, 176, 255), (240, 240, 245, 255), (240, 100, 160, 255)),
        {"bomb": True},
    )
    # Quote — patch recoil into existing config
    qcfg_path = CHAR / "quote" / "config.txt"
    if qcfg_path.exists():
        cfg = json.loads(qcfg_path.read_text())
        cfg["recoil"] = True
        qcfg_path.write_text(json.dumps(cfg, indent="\t") + "\n")
        print("patched quote recoil=true")


if __name__ == "__main__":
    main()
