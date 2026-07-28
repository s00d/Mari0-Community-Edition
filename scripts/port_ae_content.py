#!/usr/bin/env python3
"""Port Alesan99's Entities (mari0_ae) custom enemies + showcase pack into Mari0 CE.

Source: ../mari0_ae (or MARI0_AE env). Fan content attribution: alesan99 / Mari0 AE.
"""
from __future__ import annotations

import json
import os
import shutil
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
AE = Path(os.environ.get("MARI0_AE", ROOT.parent / "mari0_ae"))
OUT = ROOT / "assets" / "enemies"
GFX = AE / "graphics" / "SMB"
TOOLTIPS_SRC = AE / "graphics" / "entitytooltips"
TOOLTIPS_DST = ROOT / "assets" / "graphics" / "entitytooltips"
DEFAULT_DST = ROOT / "assets" / "graphics" / "DEFAULT"
PACK = ROOT / "mappacks" / "alesans_entities"
LIC = ROOT / "licenses"

MASK_NORMAL = [
	True,
	False, False, False, False, True,
	False, True, False, True, False,
	False, False, False, False, False,
	True, True, False, False, False,
	False, True, True, False, False,
	True, False, True, True, True,
]

MASK_FLY = [True] * 31
MASK_STATIC = [True]


def write_json(name: str, data: dict) -> None:
	path = OUT / f"{name}.json"
	path.write_text(json.dumps(data, indent="\t") + "\n")
	print(f"json {path.relative_to(ROOT)}")


def copy_png(name: str, src_name: str | None = None) -> bool:
	src = GFX / f"{src_name or name}.png"
	if not src.exists():
		print(f"MISSING {src}")
		return False
	dst = OUT / f"{name}.png"
	shutil.copy2(src, dst)
	im = Image.open(dst)
	print(f"png  {dst.relative_to(ROOT)} {im.size}")
	return True


def walker(name: str, **kw) -> dict:
	d = {
		"description": kw.pop("description", f"AE {name} (alesan99)"),
		"quadcount": kw.pop("quadcount", 2),
		"quadno": 1,
		"animationtype": "mirror",
		"animationspeed": 0.2,
		"static": False,
		"active": True,
		"category": 4,
		"mask": list(MASK_NORMAL),
		"emancipatecheck": True,
		"autodelete": True,
		"offsetX": 6,
		"offsetY": 3,
		"quadcenterX": 8,
		"quadcenterY": 8,
		"width": 0.75,
		"height": 0.75,
		"movement": "truffleshuffle",
		"truffleshufflespeed": 2,
		"truffleshuffleacceleration": 8,
		"stompable": True,
		"killsonsides": True,
		"killsonbottom": True,
	}
	d.update(kw)
	return d


def port_enemies() -> list[str]:
	OUT.mkdir(parents=True, exist_ok=True)
	ported: list[str] = []

	defs: list[tuple[str, dict, str | None]] = [
		("muncher", {
			"description": "static muncher — hurts on touch (AE)",
			"quadcount": 4,
			"animationtype": "frames",
			"animationframes": 2,
			"animationstart": 1,
			"animationspeed": 0.15,
			"static": True,
			"active": True,
			"category": 4,
			"mask": list(MASK_NORMAL),
			"emancipatecheck": True,
			"autodelete": True,
			"offsetX": 7,
			"offsetY": 2,
			"quadcenterX": 8,
			"quadcenterY": 8,
			"width": 0.875,
			"height": 0.875,
			"kills": True,
			"stompable": False,
			"resistsfire": True,
			"resistsstar": True,
			"notkilledfromblocksbelow": True,
		}, None),
		("ninji", walker("ninji", description="hopping ninji (AE)",
			movement="hop", hopdelay=0.9, hopforce=10, hopdrift=2.2,
			quadcount=2), None),
		("sidestepper", walker("sidestepper", description="angry sidestepper (AE)",
			quadcount=4, turnaroundoncliff=True, truffleshufflespeed=2.5), None),
		("splunkin", walker("splunkin", description="pumpkin goomba (AE)",
			quadcount=6, stompanimation=True, stompanimationtime=0.5, stompedframe=3), None),
		("shyguy", walker("shyguy", description="shy guy — freezes when watched (AE)",
			movement="shy", shycone=0.55, quads=2, quadcount=2), None),
		("goombrat", walker("goombrat", description="goombrat turns at cliffs (AE)",
			quadcount=2, turnaroundoncliff=True), None),
		("spike", walker("spike", description="spike throws spikeballs (simplified walker) (AE)",
			quadcount=6, stompable=False, kills=True), None),
		("spiketop", walker("spiketop", description="spiketop crawler (AE)",
			quadcount=2, stompable=False, kills=True, truffleshufflespeed=1.5), None),
		("fishbone", {
			"description": "fishbone — swimming skeleton (AE)",
			"quadcount": 2,
			"nospritesets": True,
			"animationtype": "mirror",
			"animationspeed": 0.2,
			"static": False,
			"active": True,
			"category": 4,
			"mask": list(MASK_FLY),
			"gravity": 0,
			"emancipatecheck": True,
			"autodelete": True,
			"offsetX": 11,
			"offsetY": 0,
			"quadcenterX": 11,
			"quadcenterY": 7,
			"width": 1.2,
			"height": 0.8,
			"movement": "sine",
			"sinespeed": 3.0,
			"sineamp": 1.2,
			"sinefreq": 2.0,
			"stompable": True,
			"killsonsides": True,
			"killsonbottom": True,
		}, None),
		("parabeetle", {
			"description": "parabeetle — flying beetle platform-ish (AE)",
			"quadcount": 4,
			"nospritesets": True,
			"animationtype": "frames",
			"animationframes": 2,
			"animationstart": 1,
			"animationspeed": 0.12,
			"static": False,
			"active": True,
			"category": 4,
			"mask": list(MASK_FLY),
			"gravity": 0,
			"emancipatecheck": True,
			"autodelete": True,
			"offsetX": 8,
			"offsetY": 0,
			"quadcenterX": 8,
			"quadcenterY": 8,
			"width": 1,
			"height": 0.75,
			"movement": "flyhorizontal",
			"stompable": True,
			"killsonsides": True,
		}, None),
		("amp", {
			"description": "amp — electric flyer (AE)",
			"quadcount": 4,
			"animationtype": "frames",
			"animationframes": 4,
			"animationstart": 1,
			"animationspeed": 0.08,
			"static": False,
			"active": True,
			"category": 11,
			"mask": list(MASK_FLY),
			"gravity": 0,
			"emancipatecheck": True,
			"autodelete": True,
			"offsetX": 16,
			"offsetY": 0,
			"quadcenterX": 16,
			"quadcenterY": 16,
			"width": 1.5,
			"height": 1.5,
			"movement": "sine",
			"sinespeed": 2.5,
			"sineamp": 2.0,
			"sinefreq": 1.5,
			"kills": True,
			"stompable": False,
			"resistsfire": True,
			"resistsstar": True,
		}, None),
		("fuzzy", walker("fuzzy", description="fuzzy (AE)",
			quadcount=2, movement="sine", gravity=0, mask=list(MASK_FLY),
			sinespeed=2.0, sineamp=1.0, sinefreq=2.5,
			stompable=True, kills=False, killsonsides=True, killsonbottom=True), None),
		("icicle", {
			"description": "icicle — drops when player is below (AE/slam)",
			"quadcount": 2,
			"animationtype": "none",
			"quadno": 1,
			"static": False,
			"active": True,
			"category": 4,
			"mask": list(MASK_NORMAL),
			"gravity": 0,
			"emancipatecheck": True,
			"autodelete": True,
			"offsetX": 8,
			"offsetY": 0,
			"quadcenterX": 8,
			"quadcenterY": 8,
			"width": 0.75,
			"height": 1.0,
			"movement": "slam",
			"slamtrigger": 4.0,
			"slamaccel": 60,
			"slammax": 20,
			"slamrest": 99,
			"slamrise": 0.01,
			"kills": True,
			"stompable": False,
			"resistsfire": True,
		}, None),
		("barrel", walker("barrel", description="rolling barrel (AE)",
			quadcount=2, truffleshufflespeed=4, stompable=False, kills=True), None),
		("mole", walker("mole", description="monty mole (AE)",
			quadcount=4), None),
		("bigmole", {
			"description": "mega mole — rideable-ish walker (AE)",
			"quadcount": 2,
			"animationtype": "mirror",
			"animationspeed": 0.25,
			"static": False,
			"active": True,
			"category": 4,
			"mask": list(MASK_NORMAL),
			"emancipatecheck": True,
			"autodelete": True,
			"offsetX": 16,
			"offsetY": 0,
			"quadcenterX": 16,
			"quadcenterY": 16,
			"width": 1.5,
			"height": 1.5,
			"movement": "truffleshuffle",
			"truffleshufflespeed": 1.5,
			"truffleshuffleacceleration": 6,
			"stompable": True,
			"killsonsides": True,
		}, None),
		("thwimp", {
			"description": "thwimp — tiny hopping thwomp (AE)",
			"quadcount": 1,
			"animationtype": "none",
			"quadno": 1,
			"static": False,
			"active": True,
			"category": 4,
			"mask": list(MASK_NORMAL),
			"emancipatecheck": True,
			"autodelete": True,
			"offsetX": 8,
			"offsetY": 0,
			"quadcenterX": 8,
			"quadcenterY": 8,
			"width": 1,
			"height": 1,
			"movement": "hop",
			"hopdelay": 1.4,
			"hopforce": 12,
			"hopdrift": 3.5,
			"kills": True,
			"stompable": False,
			"resistsfire": True,
			"resistsstar": True,
		}, None),
		("bobomb", walker("bobomb", description="bob-omb walker (AE simplified)",
			quadcount=3, truffleshufflespeed=1.5), "bomb"),
		("pokey", {
			"description": "pokey segment (AE simplified single)",
			"quadcount": 2,
			"nospritesets": True,
			"animationtype": "mirror",
			"animationspeed": 0.3,
			"static": False,
			"active": True,
			"category": 4,
			"mask": list(MASK_NORMAL),
			"emancipatecheck": True,
			"autodelete": True,
			"offsetX": 8,
			"offsetY": 0,
			"quadcenterX": 8,
			"quadcenterY": 8,
			"width": 1,
			"height": 1,
			"movement": "truffleshuffle",
			"truffleshufflespeed": 1.2,
			"truffleshuffleacceleration": 5,
			"stompable": True,
			"killsonsides": True,
			"killsonbottom": True,
		}, None),
		("chainchomp", {
			"description": "chain chomp (AE simplified follow)",
			"quadcount": 2,
			"animationtype": "mirror",
			"animationspeed": 0.15,
			"static": False,
			"active": True,
			"category": 4,
			"mask": list(MASK_NORMAL),
			"emancipatecheck": True,
			"autodelete": True,
			"offsetX": 10,
			"offsetY": 0,
			"quadcenterX": 10,
			"quadcenterY": 10,
			"width": 1.1,
			"height": 1.1,
			"movement": "follow",
			"kills": True,
			"stompable": False,
			"resistsfire": True,
		}, None),
		("bigbill", {
			"description": "banzai bill (AE)",
			"quadcount": 1,
			"animationtype": "none",
			"quadno": 1,
			"static": False,
			"active": True,
			"category": 5,
			"mask": list(MASK_FLY),
			"gravity": 0,
			"emancipatecheck": True,
			"autodelete": True,
			"offsetX": 16,
			"offsetY": 0,
			"quadcenterX": 16,
			"quadcenterY": 16,
			"width": 2,
			"height": 2,
			"movement": "rocket",
			"kills": True,
			"stompable": False,
			"resistsfire": True,
			"resistsstar": True,
		}, None),
		("cannonball", {
			"description": "cannonball (AE)",
			"quadcount": 1,
			"nospritesets": True,
			"animationtype": "none",
			"quadno": 1,
			"static": False,
			"active": True,
			"category": 5,
			"mask": list(MASK_FLY),
			"gravity": 0,
			"emancipatecheck": True,
			"autodelete": True,
			"offsetX": 12,
			"offsetY": 0,
			"quadcenterX": 12,
			"quadcenterY": 12,
			"width": 1.2,
			"height": 1.2,
			"movement": "rocket",
			"kills": True,
			"stompable": False,
			"resistsfire": True,
		}, None),
		("meteor", {
			"description": "meteor (AE)",
			"quadcount": 1,
			"nospritesets": True,
			"animationtype": "none",
			"quadno": 1,
			"static": False,
			"active": True,
			"category": 5,
			"mask": list(MASK_FLY),
			"gravity": 0,
			"emancipatecheck": True,
			"autodelete": True,
			"offsetX": 16,
			"offsetY": 0,
			"quadcenterX": 16,
			"quadcenterY": 12,
			"width": 1.5,
			"height": 1.2,
			"movement": "rocket",
			"kills": True,
			"stompable": False,
			"resistsfire": True,
			"resistsstar": True,
		}, None),
		("torpedoted", {
			"description": "torpedo ted (AE)",
			"quadcount": 4,
			"animationtype": "frames",
			"animationframes": 2,
			"animationstart": 1,
			"animationspeed": 0.1,
			"static": False,
			"active": True,
			"category": 5,
			"mask": list(MASK_FLY),
			"gravity": 0,
			"emancipatecheck": True,
			"autodelete": True,
			"offsetX": 8,
			"offsetY": 0,
			"quadcenterX": 8,
			"quadcenterY": 8,
			"width": 1,
			"height": 0.75,
			"movement": "rocket",
			"kills": True,
			"stompable": False,
		}, None),
		("rockywrench", walker("rockywrench", description="rocky wrench (AE trap)",
			quadcount=3, movement="trap", trapreach=10, trapcooldown=2.0, trapspeed=14,
			stompable=True, static=True, gravity=0), None),
		("angrysun", {
			"description": "angry sun (AE)",
			"quadcount": 2,
			"nospritesets": True,
			"animationtype": "mirror",
			"animationspeed": 0.2,
			"static": False,
			"active": True,
			"category": 11,
			"mask": list(MASK_FLY),
			"gravity": 0,
			"emancipatecheck": True,
			"autodelete": True,
			"offsetX": 14,
			"offsetY": 0,
			"quadcenterX": 14,
			"quadcenterY": 14,
			"width": 1.5,
			"height": 1.5,
			"movement": "follow",
			"kills": True,
			"stompable": False,
			"resistsfire": True,
			"resistsstar": True,
		}, None),
		("fighterfly", walker("fighterfly", description="fighter fly (AE)",
			quadcount=3, movement="hop", hopdelay=0.7, hopforce=8, hopdrift=3), None),
		("boomboom", {
			"description": "boomboom (AE simplified charger)",
			"quadcount": 5,
			"nospritesets": True,
			"animationtype": "frames",
			"animationframes": 2,
			"animationstart": 1,
			"animationspeed": 0.12,
			"static": False,
			"active": True,
			"category": 4,
			"mask": list(MASK_NORMAL),
			"emancipatecheck": True,
			"autodelete": True,
			"offsetX": 16,
			"offsetY": 0,
			"quadcenterX": 16,
			"quadcenterY": 16,
			"width": 1.8,
			"height": 1.8,
			"movement": "charge",
			"stompable": True,
			"killsonsides": True,
			"killsonbottom": True,
		}, None),
		("wiggler", {
			"description": "wiggler (AE simplified)",
			"quadcount": 5,
			"nospritesets": True,
			"animationtype": "frames",
			"animationframes": 2,
			"animationstart": 1,
			"animationspeed": 0.2,
			"static": False,
			"active": True,
			"category": 4,
			"mask": list(MASK_NORMAL),
			"emancipatecheck": True,
			"autodelete": True,
			"offsetX": 8,
			"offsetY": 0,
			"quadcenterX": 8,
			"quadcenterY": 8,
			"width": 1,
			"height": 1,
			"movement": "truffleshuffle",
			"truffleshufflespeed": 1.8,
			"truffleshuffleacceleration": 6,
			"stompable": True,
			"killsonsides": True,
		}, None),
		("grinder", {
			"description": "grinder saw (AE sine)",
			"quadcount": 3,
			"animationtype": "frames",
			"animationframes": 3,
			"animationstart": 1,
			"animationspeed": 0.05,
			"static": False,
			"active": True,
			"category": 11,
			"mask": list(MASK_FLY),
			"gravity": 0,
			"emancipatecheck": True,
			"autodelete": True,
			"offsetX": 24,
			"offsetY": 0,
			"quadcenterX": 24,
			"quadcenterY": 24,
			"width": 2.5,
			"height": 2.5,
			"movement": "sine",
			"sinespeed": 3.5,
			"sineamp": 0.5,
			"sinefreq": 4.0,
			"kills": True,
			"stompable": False,
			"resistsfire": True,
			"resistsstar": True,
		}, None),
		("skewer", {
			"description": "skewer spike (AE slam)",
			"quadcount": 1,
			"animationtype": "none",
			"quadno": 1,
			"static": False,
			"active": True,
			"category": 4,
			"mask": list(MASK_NORMAL),
			"gravity": 0,
			"emancipatecheck": True,
			"autodelete": True,
			"offsetX": 16,
			"offsetY": 0,
			"quadcenterX": 16,
			"quadcenterY": 16,
			"width": 1,
			"height": 3,
			"movement": "slam",
			"slamtrigger": 5,
			"slamaccel": 80,
			"slammax": 25,
			"slamrest": 1.2,
			"slamrise": 3.0,
			"kills": True,
			"stompable": False,
			"resistsfire": True,
			"resistsstar": True,
		}, None),
		("plantcreeper", {
			"description": "muncher creeper plant (AE simplified piston)",
			"quadcount": 4,
			"nospritesets": True,
			"animationtype": "frames",
			"animationframes": 2,
			"animationstart": 1,
			"animationspeed": 0.15,
			"static": True,
			"active": True,
			"category": 29,
			"mask": list(MASK_STATIC),
			"emancipatecheck": True,
			"offsetX": 16,
			"offsetY": 0,
			"quadcenterX": 16,
			"quadcenterY": 16,
			"width": 1,
			"height": 1.5,
			"movement": "piston",
			"pistondistx": 0,
			"pistondisty": -1.5,
			"pistonspeedx": 0,
			"pistonspeedy": 2.0,
			"pistonextendtime": 1.5,
			"pistonretracttime": 1.5,
			"kills": True,
			"stompable": False,
		}, None),
		("magikoopa", walker("magikoopa", description="magikoopa (AE simplified hop-mage)",
			quadcount=3, movement="hop", hopdelay=1.6, hopforce=7, hopdrift=1.5,
			offsetX=12, offsetY=0, quadcenterX=12, quadcenterY=16,
			width=1.2, height=1.5), None),
	]

	# Fix fishbone / angrysun / cannonball / meteor / boomboom / wiggler / plantcreeper / pokey / parabeetle
	# to nospritesets when source sheet is not 4-spriteset tall.
	force_nospriteset = {
		"fishbone", "parabeetle", "angrysun", "cannonball", "meteor",
		"pokey", "boomboom", "wiggler", "plantcreeper", "thwimp",
	}

	for name, data, src in defs:
		if name in force_nospriteset:
			data["nospritesets"] = True
		if not copy_png(name, src):
			continue
		# Auto-fix quadcount if sheet is classic spriteset (h divisible by 4)
		im = Image.open(OUT / f"{name}.png")
		w, h = im.size
		if not data.get("nospritesets") and h % 4 == 0:
			fh = h // 4
			if fh > 0 and w % fh == 0:
				data["quadcount"] = w // fh
		elif data.get("nospritesets"):
			# Prefer 16px frames when possible
			fw = 16 if w % 16 == 0 else (w if data.get("quadcount", 1) == 1 else w // int(data.get("quadcount", 1)))
			if fw > 0 and w % fw == 0:
				data["quadcount"] = w // fw
		write_json(name, data)
		ported.append(name)

	return ported


def copy_entity_graphics() -> None:
	DEFAULT_DST.mkdir(parents=True, exist_ok=True)
	TOOLTIPS_DST.mkdir(parents=True, exist_ok=True)
	for name in (
		"donut", "powblock", "flipblock", "belt", "belton", "beltoff",
		"longfire", "smallspring", "collectable", "collectableui",
	):
		src = GFX / f"{name}.png"
		if src.exists():
			shutil.copy2(src, DEFAULT_DST / f"{name}.png")
			print(f"gfx  DEFAULT/{name}.png")
	for tip in (
		"donut", "powblock", "flipblock", "belt", "longfire", "smallspring",
		"collectable", "camerastop", "muncher", "ninji", "amp", "angrysun",
		"chainchomp", "icicle", "mole", "bigmole", "sidestepper", "splunkin",
		"shyguy", "spike", "barrel", "boomboom", "grinder", "skewer",
	):
		src = TOOLTIPS_SRC / f"{tip}.png"
		if src.exists():
			shutil.copy2(src, TOOLTIPS_DST / f"{tip}.png")


def write_showcase_pack(enemies: list[str]) -> None:
	PACK.mkdir(parents=True, exist_ok=True)
	(PACK / "settings.txt").write_text(
		"name=alesan's entities\n"
		"author=alesan99 (port)\n"
		"description=CE port of Mari0 AE custom enemies/entities. Place AE enemies from the editor enemy list.\n"
	)
	icon_src = AE / "mappacks" / "alesans_entities_mappack" / "icon.png"
	if icon_src.exists():
		shutil.copy2(icon_src, PACK / "icon.png")

	# Minimal CE-format flat level: ground + spawn + sample enemies
	BD, LD, MD, CD, EQ = "¤", "×", "·", "¸", "¨"
	w, h = 60, 15
	# tile 1 = empty air-ish; 2 = solid ground (smb ground often ~2 or higher)
	# Use tile 2 for floor like many CE packs
	floor_tid = 2
	air = 1
	grid = [[air for _ in range(w)] for _ in range(h)]
	for x in range(w):
		grid[h - 1][x] = floor_tid
		grid[h - 2][x] = floor_tid
	# platforms
	for x in range(8, 20):
		grid[10][x] = floor_tid
	for x in range(25, 40):
		grid[8][x] = floor_tid

	ents: dict[tuple[int, int], str] = {}
	ents[(3, h - 3)] = "spawn"
	# Place a selection of AE enemies by name
	sample = [e for e in (
		"muncher", "ninji", "sidestepper", "splunkin", "shyguy", "goombrat",
		"mole", "amp", "parabeetle", "icicle", "thwimp", "fuzzy", "barrel",
		"spike", "chainchomp", "fishbone", "fighterfly", "bomb",
	) if e in enemies]
	x = 6
	for i, e in enumerate(sample):
		y = h - 3 if i % 3 != 2 else 9
		ents[(x, y)] = e
		x += 3
		if x > w - 4:
			x = 6

	tokens: list[str] = []
	for y in range(h):
		for x in range(w):
			tid = grid[y][x]
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
	meta = (
		f"{CD}backgroundr{EQ}92{CD}backgroundg{EQ}148{CD}backgroundb{EQ}252"
		f"{CD}spriteset{EQ}1{CD}music{EQ}overworld.ogg{CD}timelimit{EQ}400"
		f"{CD}scrollfactor{EQ}0{CD}fscrollfactor{EQ}0"
	)
	body = BD.join(parts)
	(PACK / "1-1.txt").write_text(f"{h}{CD}{body}{meta}\n")
	print(f"pack {PACK.relative_to(ROOT)}")


def write_attribution() -> None:
	LIC.mkdir(parents=True, exist_ok=True)
	(LIC / "alesan99-mari0-ae.txt").write_text(
		"Mari0: Alesan99's Entities (mari0_ae)\n"
		"=====================================\n\n"
		"Custom enemies, entities, graphics, hats, and the alesans_entities\n"
		"showcase content in this CE port originate from:\n\n"
		"  https://github.com/alesan99/mari0_ae\n"
		"  Author: alesan99\n"
		"  Forum: http://forum.stabyourself.net/viewtopic.php?f=13&t=3636\n\n"
		"Upstream license: see mari0_ae/LICENSE.txt (WTFPL-style Mari0 lineage).\n"
		"CE integrates selected custom content into the Teal rewrite; not a full\n"
		"engine fork. Nintendo IP remains fan-content under the same rules as CE.\n"
	)
	print("wrote licenses/alesan99-mari0-ae.txt")


def main() -> None:
	if not AE.is_dir():
		raise SystemExit(f"mari0_ae not found at {AE}")
	ported = port_enemies()
	copy_entity_graphics()
	write_showcase_pack(ported)
	write_attribution()
	print(f"ported {len(ported)} enemies: {', '.join(ported)}")


if __name__ == "__main__":
	main()
