# Architecture (Teal migration)

## Layout

- `src/` — Teal sources (`app/`, `assets/`, `core/`, `physics/`, `world/`, `util/`, `entities/`, `ui/`)
- `build/` — generated Lua from Teal (`make teal`); gitignored; **included in `.love` packages**
- **No root re-export shims** — use dotted requires (`core.tilekey`, `physics.collision`, `util.hatutil`, `entities.mario`, `ui.menu`, …)
- `types/love.d.tl` — LÖVE 11 globals for the Teal checker
- `types/game.d.tl` — major gameplay/session globals (`map`, `objects`, `xscroll`, …); required from `love.d.tl`
- `assets/` — graphics, sounds, shaders, characters, built-in enemies
- `legacy/netplayinc/` — unused netplay helpers (kept for reference; not required at runtime)
- `mappacks/` — unchanged format (`N-M.txt`, settings **disk colors 0–255** via `DISK_COLOR_MAX`)

## Runtime

- Target: **LÖVE 11.x only**
- Color: `LOVE_COLOR_MAX = 1` (Love 11 channels); mappack/disk bytes use `DISK_COLOR_MAX = 255`
- Audio sources: `MUSIC_SOURCE_TYPE` (`"stream"`)
- Keyboard: scancodes (layout-independent)
- Physics: custom AABB + portals (`src/physics/`), **not** `love.physics`
- Boot: `app.boot` (`Boot.run_early`, `Boot.require_game`, `Boot.load_media`, `Boot.run_load`)
- Thin entry: `main.lua` (<300 LOC) — thin `love.load`, mouse wrappers; `app.errhand`, `app.love_run`, `app.love_callbacks`, `app.main_util`
- Game loop phases: `app.game_update`; draw/load/portal/main_util split into facades + parts (see below)
- Logging: `app.logger`
- Assets: `assets.store` (`AssetStore`) with path prefixes under `assets/`; default imagelist/sounds registered in `Boot.load_media`; one-shot loads via `AssetStore.load_image` / `load_sound`
- Session bag: `world.session` (`World`) — `sync_session_from_globals` on load/spawn; `set_gamestate` / `set_scroll` are single writers to `_G` where wired
- Gamestate: `app.gamestate` — handlers registered in `Boot.register_gamestates` for menu/game/intro/levelscreen; `love_callbacks` prefer handlers when present

## Smoke checklist (`make run`)

1. Title / intro plays (or skip with debug), then main menu appears
2. Start game → levelscreen → world 1-1 loads and scrolls
3. Pause / return to menu still works; no missing-module errors in console

## Stability architecture (teal-migration)

| Layer | Module | Role |
|-------|--------|------|
| Global guard | `core.global_freeze` | Write-only `_G` metatable after `love.load` completes |
| RNG | `core.rng` | `Rng.install(seed?)` — `MARI0_SEED`, `--seed=N`, else `os.time()` |
| Physics order | `physics.order` | `PHYSICS_GROUP_ORDER` + sorted per-group keys in `physicsupdate` |
| Session | `world.session` | `sync_session_from_globals`; `set_gamestate` single-writer for state |

Headless checks: `tests/global_freeze_checks.lua`, `steptimer_checks.lua`, `rng_checks.lua`, `physics_order_checks.lua`, `session_checks.lua`.

## Structural migration status

**Structural Teal migration is complete.** Post-migration polish waves L–O:

| Wave | Status |
|------|--------|
| L — remove root `game.lua`, thin `main.lua`, smoke docs | done |
| M — `types/game.d.tl`, media lint → AssetStore, root lua allowlist | done |
| N — expand `world.session`, wire Gamestate handlers | done (Teal `global record` OO) |
| O — split draw/load/portal/main_util monoliths | done |

Facades (keep `_G` function names via require):

| Facade | Parts |
|--------|--------|
| `app.game_draw` | `game_draw_world`, `game_draw_hud`, `game_draw_effects` |
| `app.game_load` | `game_load_level`, `game_load_objects` |
| `app.game_portal` | `game_portal_input`, `game_portal_world` |
| `app.main_util` | `main_util_options`, `main_util_misc` |

## Ported modules (dotted require)

| Area | Module |
|------|--------|
| Mario / enemy / portal entity | `entities.mario`, `entities.enemy`, `entities.enemies`, `entities.portal`, scrolling score/text |
| Infra | `app.variables`, `assets.characterloader`, `assets.musicloader`, `ui.notice`, `world.quad`, `world.tile` |
| Screens / camera | `ui.intro`, `ui.levelscreen`, `app.camera` |
| Entity registry / animation | `world.entitylist`, `world.animation`, `world.animationsystem`, `ui.animationguiline` |
| Menu / editor / GUI | `ui.menu`, `ui.editor`, `ui.gui`, `ui.rightclickmenu` |
| Core / physics / levelio / util | `core.*`, `physics.*`, `world.*`, `util.*` |

## Build

Project Teal build is **[Cyan](https://github.com/teal-language/cyan)** (`cyan build`), driven by `tlconfig.lua` (`source_dir = "src"`, `build_dir = "build"`, `gen_target = "5.1"`, `feat_arity = "on"`, `global_env_def = "love"`, `include_dir = { "types" }`).

```bash
luarocks install --local cyan   # once (matches Homebrew luarocks Lua, often 5.5)
make vendor-rocks               # sync dkjson/sha1 into lib/
make teal                       # scripts/teal-build → cyan build only
make teal-watch                 # optional: rebuild on change
make test                       # teal + lua suites
make run                        # teal + love . (precompiled build/)
make package                    # .love includes build/ + lib/
```

**Lua constraint:** Cyan/`lfs` must run on the Lua version luarocks built them for. Do **not** force Cyan under LuaJIT when rocks were installed for Lua 5.x — `lfs.so` will fail to load. `scripts/cyan` picks the luarocks `cyan` binary (which embeds the correct interpreter).

**Deps (Love-safe):** pure-Lua rocks vendored into `lib/` (`dkjson`, `sha1`) via `scripts/vendor-rocks` / [`dependencies-1.rockspec`](../dependencies-1.rockspec). `conf.lua` prepends `lib/?.lua` to `package.path`. Prefer **dkjson** over `lua-cjson` (C modules do not ship inside `.love`).

**OO:** Entity/UI classes are Teal `global record`s in `types/records.d.tl` (impl in `src/`). Drive remaining type diagnostics down via ambient records/globals until `cyan build -u` is clean.

Runtime uses precompiled `build/` — `tl.loader` is **dev-only**, not the default for `make run`.

## Mappack contract

Do not change tile/entity encoding or on-disk color space (`DISK_COLOR_MAX` / 0–255) without a migrator.
