#!/usr/bin/env python3
"""
Export SMB3 overworld map metatiles (object set 0) from ROM via Foundry.

Writes dump/worlds/map_tiles/palette_N.png — 16×16 grid of 16×16 tiles (256 per palette).

Usage:
  python3 scripts/mapsdk/export_smb3_map_tiles.py \\
      --rom '/path/to/Super Mario Bros. 3 (USA) (Rev 1).nes' \\
      --foundry /path/to/smb3/vendor/SMB3-Foundry \\
      --out /path/to/smb3/dump/worlds/map_tiles
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")

from PySide6.QtGui import QImage, QPainter  # noqa: E402
from PySide6.QtWidgets import QApplication  # noqa: E402

MAP_PALETTE_COUNT = 8
TILE = 16
COLS = 16


def export_palette(foundry_root: Path, rom_path: Path, out_dir: Path) -> int:
    sys.path.insert(0, str(foundry_root))
    from foundry.game.File import ROM  # noqa: E402
    from foundry.game.gfx.block_cache import get_worldmap_tile  # noqa: E402
    from foundry.game.gfx.drawable.Block import Block  # noqa: E402

    ROM.load_from_file(rom_path)
    out_dir.mkdir(parents=True, exist_ok=True)
    index: list[dict] = []

    for pal in range(MAP_PALETTE_COUNT):
        sheet = QImage(COLS * TILE, COLS * TILE, QImage.Format.Format_RGBA8888)
        sheet.fill(0)
        painter = QPainter(sheet)
        for tid in range(256):
            block = get_worldmap_tile(tid, pal)
            x = (tid % COLS) * TILE
            y = (tid // COLS) * TILE
            block.draw(painter, x, y, Block.SIDE_LENGTH, transparent=True)
        painter.end()
        name = f"palette_{pal}.png"
        if not sheet.save(str(out_dir / name)):
            raise RuntimeError(f"failed to write {out_dir / name}")
        index.append({"palette": pal, "file": name})
        print(f"  wrote {name}")

    (out_dir / "index.json").write_text(json.dumps(index, indent=2) + "\n")
    return len(index)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--rom", type=Path, required=True)
    ap.add_argument("--foundry", type=Path, required=True, help="SMB3-Foundry vendor root")
    ap.add_argument("--out", type=Path, required=True)
    args = ap.parse_args()

    if not args.rom.is_file():
        print(f"ROM not found: {args.rom}", file=sys.stderr)
        return 1
    if not (args.foundry / "foundry").is_dir():
        print(f"Foundry root invalid: {args.foundry}", file=sys.stderr)
        return 1

    QApplication.instance() or QApplication([])
    n = export_palette(args.foundry, args.rom, args.out)
    print(f"Done: {n} palette sheets → {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
