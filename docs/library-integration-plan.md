# План поэтапной интеграции библиотек в v1

Полный маршрут (что брать из awesome-love2d, что никогда не менять, структура репо): [`../refactor-plan.md`](../refactor-plan.md). Этот файл — статус уже вендоренных шагов 1–7.

Цель: подключать vendored-библиотеки **только как замену** старого пути (старый код удаляется). Полный маршрут: [`../refactor-plan.md`](../refactor-plan.md).

Источник библиотек: `scripts/vendor-libs` (+ `scripts/vendor-rocks` для dkjson/sha1).  
Типы Teal: `types/*.d.tl`, `types/hump/*.d.tl`.

---

## Принципы

1. **Replace или DROP** — не «прослойка поверх». Куски на диске ≠ готово.
2. **Формат данных не трогаем** — N-M / JSON / characterloader.
3. **Net LOC ↓**. Dual-mode / dual-API = **не готово**, не «частично».
4. Мёртвый vendor без callers — удалить.
5. Порталы / portal stencil / resolve — не трогать ради либ (Push и т.п. — DROP).

---

## Статус

Куски на диске ≠ стадия закрыта. Нет «Xa частично / Xb потом».

| # | Библиотека | Интеграция | Статус |
|---|------------|------------|--------|
| 1 | anim8 | cycles | **чисто** |
| 2 | bump | spatial index | **чисто** |
| 3 | hump camera/timer | attach-only + Flux pan | **готово** |
| 4 | **sti** | удалён | **готово (DROP)** |
| 5 | baton | input | **чисто** |
| 6 | flux | tweens | **чисто** |
| — | ripple | один `SoundEntry.sound`; tags music/sfx | **готово** |
| 7 | slab | удалён | **готово (DROP)** |
| — | Push | canvas/stencil/порталы | **DROP** (не трогать) |

**States (стадия 3):** `gamestate_register` → domain; `states/*` удалены — **готово**.

**Маршрут и правила:** [`../refactor-plan.md`](../refactor-plan.md).
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

**STI:** DROP выполнен — см. этап 4.

---

## Этап 3 — hump camera/timer — готово

Откат wrappers + attach-only camera + Flux pan + HumpTimer. gamestate/signal/vector удалены на стадии 1 плана.

Проверка: `hump_no_wrapper_checks`, `hump_timer_checks`, `camera_follow_checks`, `helper_checks` (pan).
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

## Этап 4 — sti — DROP выполнен

Удалены `lib/sti`, `sti_runtime`, `types/sti.d.tl`, vendor clone. N-M `levelio` — единственный load path. TMX native — не этот план.
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

## Этап 7 — slab — DROP выполнен

Удалены `lib/slab`, `editor_slab.tl`, types, vendor clone. Editor остаётся на `guielement`. Full Slab rewrite — вне плана.

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
