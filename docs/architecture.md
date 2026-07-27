# Architecture (Mari0 CE / Teal)

## Layout

- `src/` — Teal sources (`app/`, `assets/`, `core/`, `physics/`, `world/`, `util/`, `entities/`, `ui/`)
- `build/` — generated Lua from Teal (`make teal`); gitignored; **included in `.love` packages**
- **No root re-export shims** — use dotted requires (`core.tilekey`, `physics.collision`, `util.hatutil`, `entities.mario`, `ui.menu`, …)
- `types/love.d.tl` — LÖVE 11 globals for the Teal checker
- `types/game.d.tl` — ~1519 ambient gameplay globals (`map`, `objects`, `xscroll`, …); required from `love.d.tl`
- `assets/` — graphics, sounds, shaders, characters, built-in enemies
- `mappacks/` — unchanged format (`N-M.txt`, settings **disk colors 0–255** via `DISK_COLOR_MAX`)

## Runtime model

**`_G` is the source of truth.** Mari0 CE intentionally keeps the original Love2D global style: gameplay state lives in `_G`, typed for the checker via `types/game.d.tl`. There is no ongoing migration to a context object or Level OOP wrapper.

| Concern | Where it lives |
|---------|----------------|
| Map, objects, scroll, most gameplay | `_G` (declared in `types/game.d.tl`) |
| New globals after boot | Blocked by `core.global_freeze` (write-only `_G` metatable; late writes use `rawset`) |
| Per-frame step budget | `app.love_frame` — module-local `steptimer` |
| RNG | `core.rng` — `Rng.install(seed?)` |
| Physics iteration order | `physics.order` — `PHYSICS_GROUP_ORDER` + sorted keys |
| Level load reset | `reset_level_state()` / `fresh_objects()` in `world.level` — replaces manual zeroing; **not** Ctx, **not** Level OOP |
| Game-flow bag | `world.session` (`World`) — `mariotimer`, `gamestate`, `mappack`, `currentlevel`, `editormode`, `paused` only; reads `_G` via `sync_session_from_globals` on load/spawn; `set_gamestate` / `set_scroll` write back to `_G` where wired |

Entity/UI classes are Teal `global record`s in `types/records.d.tl` (impl in `src/`). That is normal OO for entities — not a deglobalization layer for map/objects.

### Boot & loop

- Target: **LÖVE 11.x only**
- Color: `LOVE_COLOR_MAX = 1` (Love 11 channels); mappack/disk bytes use `DISK_COLOR_MAX = 255`
- Audio sources: `MUSIC_SOURCE_TYPE` (`"stream"`)
- Keyboard: scancodes (layout-independent)
- Physics: custom AABB + portals (`src/physics/`), **not** `love.physics`
- Boot: `app.boot` (`Boot.run_early`, `Boot.require_game`, `Boot.load_media`, `Boot.run_load`)
- Thin entry: `main.lua` (<300 LOC) — thin `love.load`, mouse wrappers; `app.errhand`, `app.love_run`, `app.love_callbacks`, `app.main_util`
- Game loop: `app.game_update`; draw/load/portal/main_util split into facades + parts (below)
- Logging: `app.logger`
- Assets: `assets.store` (`AssetStore`); default imagelist/sounds in `Boot.load_media`
- Gamestate: `app.gamestate` — handlers in `Boot.register_gamestates`; `love_callbacks` prefer handlers when present

Headless checks: `tests/global_freeze_checks.lua`, `steptimer_checks.lua`, `rng_checks.lua`, `physics_order_checks.lua`, `session_checks.lua`, `level_leak_checks.lua`.

## Removed experiments (do not revive without cause)

Stage 2 briefly tried `core.ctx` (Ctx.level bag), Level OOP with push/pull mirrors, and `push_globals` on session. PR3 removed Ctx and the session mirror; Phase 3 dropped `push_globals` in favor of one-way `sync_session_from_globals`. PR4 removed a stub replay harness that did not exercise real physics. **Mass deglobalization is not planned** — fix globals only when a specific bug or test demands it.

## Structural Teal migration (complete)

Post-migration polish waves L–O:

| Wave | Status |
|------|--------|
| L — remove root `game.lua`, thin `main.lua`, smoke docs | done |
| M — `types/game.d.tl`, media lint → AssetStore, root lua allowlist | done |
| N — `world.session` for game-flow; Gamestate handlers | done |
| O — split draw/load/portal/main_util monoliths | done |

Facades (keep `_G` function names via require):

| Facade | Parts |
|--------|--------|
| `app.game_draw` | `game_draw_world`, `game_draw_hud`, `game_draw_effects` |
| `app.game_load` | `game_load_level`, `game_load_objects` |
| `app.game_portal` | `game_portal_input`, `game_portal_world` |
| `app.main_util` | `main_util_options`, `main_util_misc` |

## Online / multiplayer

Stable host-authoritative multiplayer over non-blocking UDP + JSON (no LUBE).

| Piece | Module |
|-------|--------|
| Transport | `src/net/transport.tl` — LuaSocket UDP, `settimeout(0)`, burst recv cap |
| Protocol | `src/net/protocol.tl` — JSON opcodes (`hello`, `start`, `input`, `snap`, chat, …) |
| Session | `src/net/session.tl` — host/join, lobby, timeouts, match lifecycle |
| Match | `src/net/match.tl` — slot assign, cosmetics, `game_load` |
| Sync | `src/net/sync.tl` — client input → host; host player snapshots → clients |

**Flow:** Online play → Create game (host) or Join via IP:port → Lobby (chat) → Host Start → shared level → play.

**Sync model:** Host runs physics for all players. Clients send held controls (~30 Hz). Host applies remote input and broadcasts player snapshots (~20 Hz). Clients soft-correct local player and hard-apply remotes. MagicDNS is optional and **off by default** (disabled when `socket.http`/`ssl` stub on Love 12).

**Not included:** full enemy/entity lockstep, mappack transfer, lag compensation beyond soft correct.

## Next work (real priorities)

- **Golden replay on real physics** — deterministic regression over actual `physicsupdate`, not a fake harness
- **Weapons stage** — typed/weapons subsystem cleanup where needed
- **Broadphase** — collision performance / correctness improvements in `src/physics/`

Not a priority: wrapping `_G` in Ctx, mirroring map/objects into session, or shrinking `game.d.tl` for aesthetics.

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

Runtime uses precompiled `build/` — `tl.loader` is **dev-only**, not the default for `make run`.

## Mappack contract

Do not change tile/entity encoding or on-disk color space (`DISK_COLOR_MAX` / 0–255) without a migrator.
