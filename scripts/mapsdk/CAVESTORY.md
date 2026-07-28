# Cave Story → Mari0 CE (mapsdk)

Converter only. **Pixel assets are never committed.**

## Legal

- Do **not** copy code from CSMP (CC BY-NC-SA).
- Format/physics reference: [doukutsu-rs](https://github.com/doukutsu-rs/doukutsu-rs) (MIT) — see `licenses/doukutsu-rs.MIT`.
- Cave Story maps/sprites/music stay on your machine under gitignored paths:
  - `/mappacks/cavestory/`
  - `/toconvert/cavestory/`
- This pack is **Cave Story (doukutsu)**, not Syobon / Cat Mario. Syobon lives in `mappacks/opensyobon/` (separate).

## What was wrong (fixed)

| Issue | Cause | Fix |
|---|---|---|
| Almost no levels | Default build only wrote First Cave as `1-1` | `--all` converts every resolvable `Stage/*.pxm` → `1-N.txt` |
| Spawn inside stone | Heuristic put spawn in a 1-tile pocket next to a solid wall; air tile 0 was opaque black | Collision-aware spawn + headroom/side clearance; force tile 0 transparent |
| Multi-stage tiles | Each stage overwrote `tiles.png` | Unified sheet packs every used `Prt*` tileset |

## Build

Point `--data` at a folder that contains `Stage/*.pxm` (freeware data, CSE2 `game_english/data`, or doukutsu-rs data root):

```bash
# First Cave only
python3 scripts/mapsdk/build_cavestory.py \
  --data /path/to/CaveStory/data \
  --out mappacks/cavestory \
  --stage Cave

# Full pack (all resolvable stages)
python3 scripts/mapsdk/build_cavestory.py \
  --data /path/to/CaveStory/data \
  --out mappacks/cavestory \
  --all

python3 scripts/gen_mappack_icons.py   # icon if missing
```

Then launch Mari0 CE → **cave story (local)** → start at **1-1** (First Cave). Prefer character **quote** for CS-tuned physics.

`STAGES.txt` in the pack lists `1-N` ↔ original map names.

## Headless tests

```bash
lua tests/cavestory_format_checks.lua
```

## What’s playable (Level-1)

- Geometry from PXM + PXA collision/water/spikes/4-step slopes.
- Enemies remapped (Critter→goomba, Bat→koopaflying, …) — not CS AI.
- Doors → inert pipes (no TSC travel yet).
- No weapons, no full TSC, no zone AI ports.
