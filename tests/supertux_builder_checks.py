#!/usr/bin/env python3
"""
Headless checks for scripts/mapsdk/build_supertux.py collision / composite logic.
Does not require a full world rebuild; uses toconvert/supertux/data when present.
"""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts" / "mapsdk"))

from build_supertux import (  # noqa: E402
    ST_OBJECTS,
    apply_special_tile_props,
    as_string,
    children,
    composite_tilemaps,
    field,
    force_unknown_solid_collision,
    parse_sexpr,
    parse_strf,
    snap_spawn_to_ground,
    tile_collides,
)

failed = 0


def check(name: str, cond: bool, detail: str = "") -> None:
    global failed
    if cond:
        print(f"OK  {name}")
    else:
        failed += 1
        print(f"FAIL {name}" + (f": {detail}" if detail else ""))


def main() -> int:
    data = ROOT / "toconvert" / "supertux" / "data"
    if not (data / "images" / "tiles.strf").exists():
        print("SKIP: toconvert/supertux/data missing (clone SuperTux data first)")
        return 0

    props, images = parse_strf((data / "images" / "tiles.strf").read_text(encoding="utf-8", errors="replace"))
    apply_special_tile_props(props, images)

    check("snow cap 8 non-solid", not tile_collides(8, props))
    check("snow cap 7 non-solid", not tile_collides(7, props))
    check("ice surface 14 solid", tile_collides(14, props))
    check("fill 11 solid", tile_collides(11, props))
    check("coin 44 is coin", bool(props.get(44, {}).get("coin")))
    check("coin 44 not collision", not props.get(44, {}).get("collision"))
    check("brick 78 breakable", bool(props.get(78, {}).get("breakable")))
    check("tree 7732 non-solid", not tile_collides(7732, props))
    check("weak_block→tile", ST_OBJECTS.get("weak_block", (None,))[0] == "tile")

    # force_unknown must not override explicit non-solids
    props2 = {8: {}, 14: {"collision": True}}
    n = force_unknown_solid_collision(props2, {8, 14, 99999})
    check("force skips known 8", not props2[8].get("collision"))
    check("force adds unknown", n == 1 and props2.get(99999, {}).get("collision") is True)

    stl = data / "levels" / "world1" / "welcome_antarctica.stl"
    if stl.exists():
        root = parse_sexpr(stl.read_text(encoding="utf-8", errors="replace"))
        sector = None
        for sec in children(root, "sector"):
            sn = as_string(field(sec, "name")[0])
            if sn == "main" or sector is None:
                sector = sec
                if sn == "main":
                    break
        assert sector is not None
        grid, mask, _used, _st = composite_tilemaps(sector, props)
        check("1-1 tile8 row air", grid[21][3] == 8 and mask[21][3] is False)
        check("1-1 tile14 row solid", grid[22][3] == 14 and mask[22][3] is True)
        # tree column near start
        tree_solid = any(
            mask[y][10] and grid[y][10] >= 7732 for y in range(len(grid))
        )
        check("1-1 trees not solid", not tree_solid)
        # No residual: mask True implies strf collision on that cell's tid
        residual = sum(
            1
            for y in range(len(grid))
            for x in range(len(grid[0]))
            if mask[y][x] and grid[y][x] and not tile_collides(grid[y][x], props)
        )
        check("1-1 mask matches strf", residual == 0, f"residual={residual}")
        phantom = sum(
            1
            for y in range(len(grid))
            for x in range(len(grid[0]))
            if grid[y][x] and tile_collides(grid[y][x], props) and not mask[y][x]
        )
        check("1-1 no deco phantoms", phantom == 0, f"phantom={phantom}")
        sx, sy = snap_spawn_to_ground(mask, 3, 20)
        check("1-1 spawn on ice", sy == 21 and mask[sy + 1][sx] is True, f"got {(sx, sy)}")

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
