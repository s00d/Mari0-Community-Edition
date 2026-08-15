# План поэтапной интеграции библиотек в v1

Полный маршрут (что брать из awesome-love2d, что никогда не менять, структура репо): [`../refactor-plan.md`](../refactor-plan.md). Этот файл — статус уже вендоренных шагов 1–7.

Цель: подключать vendored-библиотеки из `lib/` **по одной**, в старый (v1) код Mari0 CE, **без изменения форматов данных** (уровни, mappacks, characterloader, spawn-форматы и т.д.).

Источник библиотек: `scripts/vendor-libs` (+ `scripts/vendor-rocks` для dkjson/sha1).  
Типы Teal: `types/*.d.tl`, `types/hump/*.d.tl`.

---

## Принципы

1. **Одна библиотека за шаг** — закончить, проверить (`make teal`, `make test`, ручной smoke), только потом следующая.
2. **Формат данных не трогаем** — новые библиотеки меняют только runtime-логику/рендер/физику, не JSON/N-M/TMX/Lua-экспорты mappack'ов.
3. **Замена + удаление** — compat-слой допустим только как временный мост (< 1 PR). PR успешен, если net LOC в затронутом модуле **уменьшается** (цель ~−30% за фазу).
4. **Рендер v1 сохраняем**, пока явно не переносим состояние (как с `runframe` для anim8).

---

## Статус

| # | Библиотека | lib/ | types/ | Интеграция в v1 | Статус |
|---|------------|------|--------|-----------------|--------|
| 1 | **anim8** | `lib/anim8.lua` | `types/anim8.d.tl` | `anim8_core` + `anim8_player` / `anim8_enemy` / `anim8_effects` / `anim8_tile` | **готово** |
| 2 | **bump** | `lib/bump.lua` | `types/bump.d.tl` | `physics/world` + checkrect/handlegroup broadphase | **готово** |
| 3 | hump | `lib/hump/*` | `types/hump/*` | `hump_compat`, `scroll_update`, `world_camera`, timer UI | **в работе (replace+delete)** |
| 4 | sti | `lib/sti/*` | `types/sti.d.tl` | — | не начато |
| 5 | baton | `lib/baton.lua` | `types/baton.d.tl` | `src/app/input_bindings.tl` | готово |
| 6 | flux | `lib/flux.lua` | `types/flux.d.tl` | portal/menu/intro/shake/roomcam/notice | **готово** |
| 7 | slab | `lib/slab/*` | `types/slab.d.tl` | — | не начато |

Вспомогательные (без отдельного этапа интеграции): `lume`, `inspect` — подключать по мере необходимости внутри шагов выше.

---

## Этап 1 — anim8 (готово)

**Задача:** централизованный стек анимаций: anim8 для sprite cycles, `anim8_core` для hold/blink/lerp/flip/counter.

- [x] `src/assets/anim8_core.tl` — общие хелперы
- [x] `src/assets/anim8_player.tl` — Mario (run/jump/swim/climb/vine/flag/raccoon/grow timing)
- [x] `src/assets/anim8_enemy.tl` — enemy frames + squid quad map
- [x] `src/assets/anim8_effects.tl` — portal, fire, fireball, bowser walk
- [x] `src/assets/anim8_tile.tl` — animatedquad
- [x] `src/assets/ui_run_preview.tl` — lobby/online UI preview
- [x] Per-instance `clone()` для всех anim8-циклов
- [x] `make teal` проходит; рендер v1 (`setquad`, `drawplayer`) не менялся

**Следующий этап:** bump (этап 2) — готово, см. ниже.

---

## Этап 2 — bump (готово)

**Задача:** AABB spatial index через bump, сохранив resolve/порталы/маски v1.

- [x] `src/physics/world.tl` — `bump.newWorld(2)`, upsert (zero-size epsilon), query, prune, refresh (load/tests)
- [x] Lifecycle: reset + один refresh при loadlevel; каждый кадр — `prune` + upsert movers (до/после collision); spawn/despawn — upsert/remove
- [x] Tile mutations: `modifyportaltiles`, block break, animated tiles, portalwalls → upsert/remove
- [x] `checkrect` → `queryRect` + post-filter (без fallback scan)
- [x] `handlegroup` + tile broadphase в `physicsupdate` → bump query + group filter; `checkcollision` без изменений
- [x] **Не** используем `world:move` responses для gameplay resolve

### Этап 2b — runtime hooks (готово)

- [x] Симметричный `physics_world_set_tile` (objects + bump); `physics_world_remove_slot` / `physics_world_upsert_slot`
- [x] Runtime: editor paint/resize, `changemapwidth`/`height`, maze extension, gravity gun, bridge/axe, `portal:removeportal`
- [x] Bulk load (`levelio`, initial tile spawn) → один `physics_world_refresh` на load; без `sync_group`

### Этап 2c — polish (готово)

- [x] `changemapheight` → upsert всех `screenboundary` после смены `height`
- [x] Flag pole finish → `physics_world_upsert` после `active = false`
- [x] Runtime platform spawn → `physics_world_insert_platform`
- [x] Убраны мёртвые fallback-ветки `else objects[...]`; прямые вызовы хелперов в hot path

**Следующий этап:** sti (этап 4).

---

## Этап 3 — hump (replace+delete, в работе)

Откат псевдо-прослоек (фаза 0): удалены `game_flow.tl`, `game_spawn_timers.tl`, `app/camera.tl`, `GameFlow` signal emit→impl.

| Фаза | Сделано |
|------|---------|
| 0 | −~300 LOC wrappers; `tests/hump_no_wrapper_checks.lua` |
| 1a | `util/world_camera.tl` + `drawlevel_tiles` на `wpx`/`wpy` (без `xscrollfrac`) |
| 2a | `delayer` / `walltimer` → `HumpTimer` (удалены ручные timer loops) |
| 3 | `Gamestate.is` / `in_menu_family`; один dispatcher без hump.gamestate stack |
| retro | `physics/world.tl`: общий `physics_world_set_group_slot` |

Остаётся: `game_draw_objects` / `game_draw_props` / `drawforeground` на world camera (−400…800 LOC).

Проверка: `tests/hump_no_wrapper_checks.lua`, `tests/hump_timer_checks.lua`, `tests/camera_follow_checks.lua`, `make teal`, `make test`.

---

## Этап 3 — hump (архив: compat-подход, отменён)

**Задача:** camera / gamestate / signal / timer / vector — без массовой переписки gameplay.

| Модуль hump | Куда в v1 | Заметки |
|-------------|-----------|---------|
| `camera` | scroll / `roomcam` / follow player | заменить ручной xscroll/yscroll там, где уже централизовано |
| `gamestate` | `app` states (menu, game, pause) | опционально; не ломать текущий gamestate string |
| `signal` | события между UI ↔ world | вместо новых глобальных колбэков |
| `timer` | одноразовые/повторяющиеся таймеры | только где сейчас дублируется timer-логика |
| `vector` | новый код / рефактор точечно | не переписывать весь mario.tl сразу |

---

## Этап 4 — sti

**Задача:** загрузка/рендер Tiled-карт через STI, **runtime-формат v1 не менять**.

- v1 уже может использовать Tiled Lua export — STI подключается к существующему пути загрузки уровня
- Не делать: runtime-конвертацию N-M → TMX, новые `*_vnext` mappack'и
- Проверка: загрузка существующих mappack levels, tile layers + object layers

---

## Этап 5 — baton

**Сделано:** один модуль `src/app/input_bindings.tl` — baton `down`/`pressed`/`released`/`get`. Gameplay: `leftkey(i)` / `ui_action_get(i,"jump")` / `input_player(i):get("jump")`. Editor/menu modifiers: `sys_down("shift"|"alt"|"ctrl"|arrows|"f1")`. Прямых `love.keyboard.isDown` в `src/` нет (кроме scancode-обёртки в `love_load`, которую читает сам baton). `controls[slot]` — только таблица биндингов для options.txt, не baton-инстанс.

- Gameplay: `leftkey(i)` / `runkey(i)` → `baton:down()`; discrete actions в `ui_input_update` через `pressed`/`released`
- Проверка: splitscreen, editor shortcuts, rebind в options

---

## Этап 6 — flux (готово)

**Задача:** визуальные tweens (UI, camera shake, portal open) вместо ручных `timer`/`lerp` где уже есть аналог.

- [x] `portal:createportal` → `Flux.to(openscale)` (без `+dt*15` в update)
- [x] menu cursor / hover / mappack scrolls → `Flux.to`; удалён `menu_ease`
- [x] intro logo/load alpha → Flux timeline
- [x] `screenshake` / `screenshake_amp` → Flux decay; удалён manual `earthquake` decay
- [x] roomcam blend → Flux `cam_blend.k`
- [x] notice slide in/out → Flux `y_factor`
- Не трогать: физику Mario, сетевой tick
- Проверка: portal open animation, menu transitions

---

## Этап 7 — slab

**Задача:** только editor/menu HUD слой, не весь legacy GUI сразу.

- Начать с: editor palette / debug panels
- Не заменять: весь `guielement` в одном PR
- Проверка: editor open, tile pick, save level

---

## Проверка после каждого этапа

```bash
make teal
make test
make run   # intro → menu → game
```

При падении `cyan` с `invalid order function for sorting` — см. `scripts/teal-build` (артефакты в `build/`).

---

## Восстановление lib/types

Если `lib/` или `types/` потеряны после отката:

```bash
./scripts/vendor-libs          # lib/*
# types/*.d.tl — в git или восстановить из docs/library-integration-plan.md + transcript
```

Не запускать `git clean` без явного exclude для `lib/` и `types/`.
