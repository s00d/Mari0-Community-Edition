# Vendored pure-Lua libs (Love 12 / .love safe)

Synced by `scripts/vendor-libs` (+ `scripts/vendor-rocks` for dkjson/sha1).
Do not hand-edit library sources; re-run the scripts after bumping pins.

| Module | Source | Why |
|--------|--------|-----|
| `dkjson` / `sha1` | luarocks pins | JSON / hash |
| `anim8` | kikito/anim8 v2.3.1 | sprite frames |
| `bump` | kikito/bump.lua v3.1.7 | AABB collisions |
| `flux` | rxi/flux | tweens |
| `lume` | rxi/lume | utils |
| `baton` | tesselode/baton v1.0.2 | input |
| `inspect` | kikito/inspect.lua | debug dump |
| `hump.*` | vrld/hump | camera / gamestate / signal / timer / vector |
| `sti` | karai17/STI | Tiled maps |
| `slab` | flamendless/Slab | editor UI |

Vector math: `hump.vector` (rxi/vector.lua repo is gone).
