# SuperTux → Mari0 CE (mapsdk)

Converter only. **Do not copy SuperTux C++/engine (GPL-3) into `src/`.**

## Legal

| What | License | OK? |
|---|---|---|
| SuperTux engine code in Mari0 `src/` | GPL-3 (viral) | **no** |
| Levels/art declaring CC-BY-SA → `mappacks/supertux/` + `LICENSE` + `AUTHORS.txt` | share-alike on data | **yes** |
| Mari0 engine | stays WTFPL | unaffected |

- Raw SuperTux clone / data: gitignored under `/toconvert/` (use `toconvert/supertux/`).
- Converted pack: gitignored `/mappacks/supertux/` (like smb3/cavestory). Commit the **converter**, not large art, unless you intentionally vendor a small licensed pack.
- **Do not use OpenSyobonAction** (no clear license).

## F0 — data path

Shallow sparse clone (data only):

```bash
mkdir -p toconvert
git clone --depth 1 --filter=blob:none --sparse \
  https://github.com/SuperTux/supertux.git toconvert/supertux
cd toconvert/supertux
git sparse-checkout set data
```

Expected layout:

- `toconvert/supertux/data/levels/world1/*.stl`
- `toconvert/supertux/data/images/tiles.strf`
- `toconvert/supertux/data/images/tiles/**/*.png`

## Build

```bash
python3 scripts/mapsdk/build_supertux.py \
  --data toconvert/supertux/data \
  --out mappacks/supertux \
  --world world1

# Object histogram (fills ST_OBJECTS from frequency)
python3 scripts/mapsdk/build_supertux.py \
  --data toconvert/supertux/data --world world1 --histogram
```

Then launch Mari0 CE → mappack **supertux (local)** → levels `1-1` …

Graphics: tiles are **nearest-neighbor 32→16** into Mari0’s 17×17 prop sheet. Geometry: **1 ST tile = 1 Mari0 tile** (object coords `/32`). Height is **not cropped** (`mapheight > 15` is fine).

## Headless tests

```bash
lua tests/supertux_format_checks.lua
# or
lua tests/run.lua
```

Synthetic `.stl` snippets only — CI does not need a SuperTux checkout.

## Pipeline status

| Phase | Status |
|---|---|
| F0 data path + docs | done |
| F1 sexpr + RLE + tests | done |
| F2 tiles.strf → props → tiles.png | done |
| F3 `license_ok` + `AUTHORS.txt` | done (before mass convert) |
| F4 object histogram → `ST_OBJECTS` | done (world1-backed) |
| F5 world1 → playable IR → emit | converter ready; play locally after build |
| F6+ other worlds / art regen | not in this pass |

## Files

- `scripts/mapsdk/sources/sexpr.lua` — parse / field / decode_tiles
- `scripts/mapsdk/sources/supertux.lua` — license, strf, convert_stl, ST_OBJECTS
- `scripts/mapsdk/build_supertux.py` — CLI + tileset writer
- `tests/supertux_format_checks.lua`
