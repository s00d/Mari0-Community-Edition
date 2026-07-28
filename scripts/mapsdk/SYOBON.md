# Open Syobon Action → Mari0 CE (mapsdk)

Converter only. Pack name: **`opensyobon`** (Syobon Action / Cat Mario — **not** Cave Story).

## Legal

| What | Status |
|---|---|
| Chiku original art/levels | **No clear redistributable license** in OpenSyobonAction |
| OpenSyobonAction SDL port | Attribution required; license still murky for assets |
| Converter scripts in this repo | OK to share |
| Committing `mappacks/opensyobon/` art | **Avoid** — gitignored like cavestory |

**Do not** silently replace `mappacks/cavestory/` with Syobon content. Keep both packs separate.

## Source layout

```
OpenSyobonAction-master/
  main.cpp          # stagep() embeds all maps as byte stagedatex[][]
  res/brock.PNG     # blocks (30×30 @ 33 stride)
  res/teki.PNG      # enemies
  res/player.PNG
  …
```

There are **no external map files** — levels are hardcoded C arrays.

## Build

```bash
python3 scripts/mapsdk/build_opensyobon.py \
  --src /path/to/OpenSyobonAction-master \
  --out mappacks/opensyobon

# Optional: also emit pipe subrooms as N-M_S.txt
python3 scripts/mapsdk/build_opensyobon.py \
  --src /path/to/OpenSyobonAction-master \
  --out mappacks/opensyobon \
  --include-sub

python3 scripts/gen_mappack_icons.py
```

Play: Mari0 CE → **opensyobon (local)** → `1-1`, `1-2`, … `3-1`.

## Mapping notes

- Tile codes → collision / breakable / coinblock / spikes / pipes.
- Enemy codes 50–79 → goomba/koopa/plant/… (not original Syobon AI).
- Spawn: left-side floor with headroom + side clearance.
- Gaps vs original: troll scripts, fake blocks AI, many gimmicks, BGM/SE, Japanese text.

## Tests

```bash
lua tests/opensyobon_format_checks.lua
```
