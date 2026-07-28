# SuperTux → Mari0 CE (mapsdk)

Converter only. **Do not copy SuperTux C++/engine (GPL-3) into `src/`.**

## Legal

| What | License | OK? |
|---|---|---|
| SuperTux engine code in Mari0 `src/` | GPL-3 (viral) | **no** |
| Levels/art declaring CC-BY-SA → `mappacks/supertux/` + `LICENSE` + `AUTHORS.txt` | share-alike on data | **yes** |
| Mari0 engine | stays WTFPL | unaffected |

- Raw SuperTux clone / data: gitignored under `/toconvert/` (use `toconvert/supertux/`).
- Converted pack may be kept under `mappacks/supertux/` for playtesting.
- **Do not use OpenSyobonAction** (no clear license).

## Data path

```bash
mkdir -p toconvert
git clone --depth 1 --filter=blob:none --sparse \
  https://github.com/SuperTux/supertux.git toconvert/supertux
cd toconvert/supertux
git sparse-checkout set data
```

## Rebuild (one command)

```bash
python3 scripts/mapsdk/build_supertux.py \
  --data toconvert/supertux/data \
  --out mappacks/supertux \
  --all-worlds
```

Single world: omit `--all-worlds` and pass `--world world1`.

Then Mari0 CE → mappack **supertux (local)** → `1-1` (Welcome to Antarctica).

### What the builder fixes

- Composites **all** tilemaps (multiple solids + decorative fill)
- **Collision from `tiles.strf` only** — decorative snow caps (7/8/9), trees, coin
  tiles on solid layers stay non-solid (fixes sky/ground gap + walk-through trees)
- Coin tiles → Mari0 `coin` prop; bricks via `object-data` → `breakable`
- `weak_block` → ice brick tile (78)
- Spawn snapped to air-above-solid; flag from sequencetrigger **X** snapped to ground (ignores y=0)
- Markers use CE numeric ids: spawn=`8`, flag=`11`, spring=`94`, platform=`18`, manycoins=`5`
- Bosses: `yeti`/`ghosttree` → `boomboom` (not invalid `base=bowser`)
- Badguys map to existing CE `assets/enemies/*.json` names
- `timelimit=400`; world order from `worldmap.stwm` when present

## Headless tests

```bash
lua tests/supertux_format_checks.lua
python3 tests/supertux_builder_checks.py
```
