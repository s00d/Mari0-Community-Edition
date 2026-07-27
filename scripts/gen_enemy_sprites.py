#!/usr/bin/env python3
"""Generate NES/Portal-ish pixel enemy spritesheets for Mari0 CE."""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "enemies"

# Limited NES-like palette
BLK = (0, 0, 0, 255)
WHT = (252, 252, 252, 255)
RED = (200, 60, 60, 255)
ORG = (228, 140, 40, 255)
YEL = (248, 216, 80, 255)
GRN = (56, 168, 56, 255)
CYN = (80, 200, 220, 255)
BLU = (60, 100, 200, 255)
PRP = (160, 80, 200, 255)
PNK = (240, 160, 180, 255)
BRN = (140, 90, 40, 255)
GRY = (140, 140, 150, 255)
DGR = (70, 70, 80, 255)
WHT2 = (220, 220, 230, 255)


def sheet(frames: int, size: int = 16) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    im = Image.new("RGBA", (size, size * frames), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def px(d: ImageDraw.ImageDraw, x: int, y: int, c, w: int = 1, h: int = 1) -> None:
    d.rectangle([x, y, x + w - 1, y + h - 1], fill=c)


def save(im: Image.Image, name: str) -> None:
    path = OUT / f"{name}.png"
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path)
    print(f"wrote {path.relative_to(ROOT)} {im.size}")


def write_json(name: str, data: dict) -> None:
    path = OUT / f"{name}.json"
    path.write_text(json.dumps(data, indent="\t") + "\n")
    print(f"wrote {path.relative_to(ROOT)}")


MASK_NORMAL = [
    True,
    False, False, False, False, True,
    False, True, False, True, False,
    False, False, False, False, False,
    True, True, False, False, False,
    False, True, True, False, False,
    True, False, True, True, True,
]

MASK_FLY = [True] * 31  # ignore everything


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
        "offsetX": 6,
        "offsetY": 3,
        "quadcenterX": 8,
        "quadcenterY": 8,
        "width": 0.75,
        "height": 0.75,
    }
    d.update(kw)
    return d


# --- drawers (y0 = frame top) ---

def draw_turret(d, y0, frame):
    # Portal sentry: white body, red eye, legs
    px(d, 5, y0 + 4, WHT2, 6, 8)
    px(d, 4, y0 + 6, GRY, 1, 4)
    px(d, 11, y0 + 6, GRY, 1, 4)
    eye = RED if frame == 0 else ORG
    px(d, 7, y0 + 6, eye, 2, 2)
    px(d, 4, y0 + 12, DGR, 3, 2)
    px(d, 9, y0 + 12, DGR, 3, 2)
    if frame == 1:
        px(d, 12, y0 + 7, RED, 3, 1)  # muzzle flash


def draw_medusa(d, y0, frame):
    # Castlevania medusa head
    px(d, 4, y0 + 5, PRP, 8, 6)
    px(d, 5, y0 + 4, PRP, 6, 1)
    px(d, 6, y0 + 6, YEL, 2, 2)
    px(d, 9, y0 + 6, YEL, 2, 2)
    px(d, 7, y0 + 9, PNK, 2, 1)
    # snakes
    for i, ox in enumerate((2, 12, 3, 11)):
        yy = y0 + 3 + ((frame + i) % 2)
        px(d, ox, yy, GRN, 2, 2)


def draw_boo(d, y0, frame):
    px(d, 3, y0 + 4, WHT, 10, 8)
    px(d, 4, y0 + 3, WHT, 8, 1)
    px(d, 5, y0 + 12, WHT, 6, 1)
    if frame == 0:  # shy cover
        px(d, 5, y0 + 6, BLK, 2, 2)
        px(d, 9, y0 + 6, BLK, 2, 2)
        px(d, 6, y0 + 10, BLK, 4, 1)
    else:
        px(d, 5, y0 + 6, BLK, 2, 3)
        px(d, 9, y0 + 6, BLK, 2, 3)
        px(d, 6, y0 + 10, RED, 4, 2)


def draw_drybones(d, y0, frame):
    if frame >= 4:  # collapsed pile
        px(d, 3, y0 + 10, WHT2, 10, 3)
        px(d, 4, y0 + 9, WHT2, 3, 1)
        px(d, 9, y0 + 9, WHT2, 3, 1)
        return
    # walking skeleton
    px(d, 5, y0 + 2, WHT2, 6, 5)  # skull
    px(d, 6, y0 + 3, BLK, 1, 1)
    px(d, 9, y0 + 3, BLK, 1, 1)
    px(d, 6, y0 + 7, WHT2, 4, 4)  # body
    leg = 1 if frame % 2 else 0
    px(d, 5, y0 + 11, WHT2, 2, 3)
    px(d, 9 + leg, y0 + 11, WHT2, 2, 3)


def draw_thwomp(d, y0, frame, size=32):
    # angry stone face
    px(d, 2, y0 + 2, GRY, size - 4, size - 4)
    px(d, 3, y0 + 3, DGR, size - 6, size - 6)
    px(d, 4, y0 + 4, GRY, size - 8, size - 8)
    brow = RED if frame == 1 else DGR
    px(d, 8, y0 + 8, brow, 6, 2)
    px(d, 18, y0 + 8, brow, 6, 2)
    px(d, 9, y0 + 12, BLK, 4, 4)
    px(d, 19, y0 + 12, BLK, 4, 4)
    px(d, 10, y0 + 20, BLK, 12, 3)


def draw_charger(d, y0, frame):
    # pinky bull
    px(d, 2, y0 + 4, PNK, 12, 8)
    px(d, 3, y0 + 3, PNK, 10, 1)
    px(d, 0, y0 + 5, WHT2, 3, 2)  # horn
    px(d, 13, y0 + 5, WHT2, 3, 2)
    px(d, 5, y0 + 6, BLK, 2, 2)
    px(d, 9, y0 + 6, BLK, 2, 2)
    if frame == 1:
        px(d, 6, y0 + 9, RED, 4, 2)


def draw_splitter(d, y0, frame):
    # slime
    px(d, 3, y0 + 5, GRN, 10, 8)
    px(d, 4, y0 + 4, GRN, 8, 1)
    px(d, 5, y0 + 7, BLK, 2, 2)
    px(d, 9, y0 + 7, BLK, 2, 2)
    if frame == 1:
        px(d, 6, y0 + 3, GRN, 4, 2)  # hop squash


def draw_arrowtrap(d, y0, frame):
    px(d, 2, y0 + 2, BRN, 12, 12)
    px(d, 3, y0 + 3, ORG, 10, 10)
    px(d, 6, y0 + 6, DGR, 4, 4)
    if frame == 1:
        px(d, 10, y0 + 7, YEL, 5, 2)  # arrow


def draw_floater(d, y0, frame):
    # cacodemon-ish
    px(d, 2, y0 + 3, RED, 12, 10)
    px(d, 4, y0 + 2, RED, 8, 1)
    px(d, 5, y0 + 5, YEL, 3, 3)
    px(d, 9, y0 + 5, YEL, 3, 3)
    px(d, 6, y0 + 6, BLK, 1, 1)
    px(d, 10, y0 + 6, BLK, 1, 1)
    mouth = 2 + frame
    px(d, 5, y0 + 10, BLK, 6, mouth)


def draw_latcher(d, y0, frame):
    # metroid-ish
    px(d, 4, y0 + 4, CYN, 8, 6)
    px(d, 5, y0 + 3, CYN, 6, 1)
    px(d, 6, y0 + 6, RED, 4, 2)
    for i, ox in enumerate((3, 7, 11)):
        yy = y0 + 10 + ((frame + i) % 2)
        px(d, ox, yy, CYN, 2, 3)


def gen_16(name, drawer, frames=2):
    im, d = sheet(frames, 16)
    for i in range(frames):
        drawer(d, i * 16, i)
    save(im, name)


def gen_thwomp():
    im, d = sheet(2, 32)
    for i in range(2):
        draw_thwomp(d, i * 32, i, 32)
    save(im, "thwomp")


def main():
    gen_16("turret", draw_turret, 2)
    write_json("turret", base_enemy(
        movement="turret", quadcount=2, width=0.75, height=1.0, gravity=40,
        stompable=False, killsonsides=True, killsontop=True, health=3, grabbable=True,
        turretrange=9, turretcone=0.82, turretwindup=0.6, turretburst=5,
        turretburstdelay=0.12, turretcooldown=1.4, offsetY=0, category=4,
    ))

    gen_16("medusa", draw_medusa, 2)
    write_json("medusa", base_enemy(
        movement="sine", sineamp=1.5, sinefreq=2.2, sinespeed=3.5,
        gravity=0, mask=MASK_FLY, stompable=True, killsonsides=True,
        portalable=True, category=5,
    ))

    gen_16("boo", draw_boo, 2)
    write_json("boo", base_enemy(
        movement="shy", shyspeed=3.0, shyaccel=6.0, shycone=0.6,
        width=0.9, height=0.9, gravity=0, mask=MASK_FLY,
        stompable=False, killsonsides=True, resistsfire=True,
        invulnerable=True, category=5,
    ))

    gen_16("drybones", draw_drybones, 6)
    write_json("drybones", base_enemy(
        movement="bones", bonesrevive=4.0, quadcount=6,
        truffleshufflespeed=2, truffleshuffleacceleration=8,
        width=0.75, height=0.9, stompable=True, killsonsides=True,
        resistsfire=True, category=4,
    ))

    gen_thwomp()
    write_json("thwomp", base_enemy(
        movement="slam", slamtrigger=3.5, slamaccel=90, slammax=22,
        slamrest=0.7, slamrise=2.0, width=2, height=2, gravity=0,
        stompable=False, kills=True, resistsfire=True, resistsstar=True,
        notkilledfromblocksbelow=True, category=6, hookanchor=True,
        quadcount=2, offsetX=16, offsetY=0, quadcenterX=16, quadcenterY=16,
    ))

    gen_16("charger", draw_charger, 2)
    write_json("charger", base_enemy(
        movement="charge", chargeaggro=8, chargewindup=0.55, chargespeed=13,
        chargestun=1.6, chargewalk=1.5, width=1.2, height=1.0, gravity=80,
        stompable=False, killsonsides=True, health=2, hookanchor=True,
        truffleshufflespeed=1.5, truffleshuffleacceleration=8, category=4,
    ))

    gen_16("splitter", draw_splitter, 2)
    write_json("splitter", base_enemy(
        movement="hop", hopforce=9, hopdelay=1.1, hopdrift=2.5,
        splitlevel=2, splitinto="splitter", splitcount=2, splitscale=0.6,
        width=1.0, height=1.0, gravity=70, stompable=True, killsonsides=True,
        category=4,
    ))

    gen_16("arrowtrap", draw_arrowtrap, 2)
    write_json("arrowtrap", base_enemy(
        movement="trap", trapreach=12, trapcooldown=1.8, trapspeed=18,
        width=1, height=1, static=True, gravity=0, stompable=False,
        kills=False, invulnerable=True, category=6, autodelete=False,
    ))

    gen_16("floater", draw_floater, 2)
    write_json("floater", base_enemy(
        movement="hover", hoverspeed=2.2, hoveraccel=3.5, hoverkeep=3.0,
        hoverfire=2.4, hoverlead=0.35, shotspeed=9,
        width=1.2, height=1.2, gravity=0, stompable=False, killsonsides=True,
        health=3, hookanchor=True, category=5,
    ))

    gen_16("latcher", draw_latcher, 2)
    write_json("latcher", base_enemy(
        movement="latch", latchspeed=4.5, latchdrain=0.9, latchshake=6,
        latchwindow=1.0, width=0.75, height=0.75, gravity=0,
        stompable=False, kills=False, category=5,
    ))


if __name__ == "__main__":
    main()
