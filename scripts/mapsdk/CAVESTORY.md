# Cave Story → Mari0 CE (Level-1)

Converter only. **Pixel assets are never committed.**

## Legal

- Do **not** copy code from CSMP (CC BY-NC-SA).
- Format/physics reference: [doukutsu-rs](https://github.com/doukutsu-rs/doukutsu-rs) (MIT) — see `licenses/doukutsu-rs.MIT`.
- Cave Story maps/sprites/music stay on your machine under gitignored paths:
  - `/mappacks/cavestory/`
  - `/toconvert/cavestory/`

## F0 findings

| Check | Result |
|---|---|
| Quote character | `assets/characters/quote/` — physics fields in `config.txt` (÷0x2000 / tick convert from doukutsu-rs). `mario.tl` reads optional per-char speeds/gravity/jump when set. |
| `mapheight > 15` | Supported. Level files start with height (`levelio.tl`). Endless stitch builds arenas taller than 15 (room grid × 15). **Do not crop** CS maps. First Cave is 60×45. |
| License file | `licenses/doukutsu-rs.MIT` |

## Build a pack from a local install

Point `--data` at a folder that contains `Stage/*.pxm` (freeware data, CSE2 `game_english/data`, or doukutsu-rs data root):

```bash
python3 scripts/mapsdk/build_cavestory.py \
  --data /path/to/CaveStory/data \
  --out mappacks/cavestory \
  --stage Cave

# Optional: PXE type histogram
python3 scripts/mapsdk/build_cavestory.py --data /path/to/data --histogram

# Optional: all maps (still gitignored)
python3 scripts/mapsdk/build_cavestory.py --data /path/to/data --out mappacks/cavestory --all
```

Then launch Mari0 CE, select the **cave story (local)** mappack, play **1-1** (First Cave). Choose character **quote** for CS-tuned physics.

## Headless tests

```bash
lua tests/cavestory_format_checks.lua
# or full suite
lua tests/run.lua
```

## What’s playable (Level-1)

- Geometry from PXM + PXA collision/water/spikes/4-step slopes.
- Enemies remapped (Critter→goomba, Bat→koopaflying, …) — not CS AI.
- Doors → inert pipes (no TSC travel yet).
- No weapons, no full TSC, no zone AI ports.
