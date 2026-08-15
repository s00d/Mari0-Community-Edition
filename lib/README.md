# Vendored pure-Lua libs (Love 12 / .love safe)

Synced by `scripts/vendor-libs` (+ `scripts/vendor-rocks` for dkjson/sha1).
Do not hand-edit library sources; re-run the scripts after bumping pins.

| Module | Source | Why |
|--------|--------|-----|
| `dkjson` / `sha1` | luarocks pins | JSON / hash |
| `anim8` | kikito/anim8 v2.3.1 | sprite frames |
| `bump` | kikito/bump.lua v3.1.7 | AABB collisions |
| `flux` | rxi/flux | tweens |
| `baton` | tesselode/baton v1.0.2 | input |
| `ripple` | tesselode/ripple | audio tags (music/sfx) |
| `inspect` | kikito/inspect.lua | debug dump |
| `hump.camera` / `hump.timer` | vrld/hump | world camera / timers |

Dropped: lume (API mismatch), hump.vector/gamestate/signal (unused), sti (0 callers; N-M levelio only), slab (debug overlay only; editor stays guielement).
