# План поэтапной интеграции библиотек в v1

Цель: подключать vendored-библиотеки из `lib/` **по одной**, в старый (v1) код Mari0 CE, **без изменения форматов данных** (уровни, mappacks, characterloader, spawn-форматы и т.д.).

Источник библиотек: `scripts/vendor-libs` (+ `scripts/vendor-rocks` для dkjson/sha1).  
Типы Teal: `types/*.d.tl`, `types/hump/*.d.tl`.

---

## Принципы

1. **Одна библиотека за шаг** — закончить, проверить (`make teal`, `make test`, ручной smoke), только потом следующая.
2. **Формат данных не трогаем** — новые библиотеки меняют только runtime-логику/рендер/физику, не JSON/N-M/TMX/Lua-экспорты mappack'ов.
3. **Минимальные прослойки** — compat-модуль в `src/assets/` или рядом с существующим кодом; не плодить `vnext/`, конвертеры «на лету» и дублирующие пайплайны.
4. **Рендер v1 сохраняем**, пока явно не переносим состояние (как с `runframe` для anim8).

---

## Статус

| # | Библиотека | lib/ | types/ | Интеграция в v1 | Статус |
|---|------------|------|--------|-----------------|--------|
| 1 | **anim8** | `lib/anim8.lua` | `types/anim8.d.tl` | `anim8_core` + `anim8_player` / `anim8_enemy` / `anim8_effects` / `anim8_tile` | **готово** |
| 2 | bump | `lib/bump.lua` | `types/bump.d.tl` | — | не начато |
| 3 | hump | `lib/hump/*` | `types/hump/*` | — | не начато |
| 4 | sti | `lib/sti/*` | `types/sti.d.tl` | — | не начато |
| 5 | baton | `lib/baton.lua` | `types/baton.d.tl` | — | не начато |
| 6 | flux | `lib/flux.lua` | `types/flux.d.tl` | — | не начато |
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

**Следующий этап:** bump (этап 2).

---

## Этап 2 — bump

**Задача:** AABB-коллизии через bump, сохранив внешний контракт там, где это возможно.

- Точка входа: `src/physics/` (world, collision, move)
- Сохранить: фильтры сторон/порталов, сигнатуры `world:move`-подобных вызовов для entity-кода
- Не менять: tile map format, `map[x][y]` структуру, spawn registry
- Проверка: `tests/collision_checks.lua`, `tests/physics_order_checks.lua`, порталы на платформах

---

## Этап 3 — hump

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

**Задача:** action maps поверх текущего input, **имена действий сохранить** (`left`, `right`, `jump`, `portal`, weapon fire и т.д.).

- Точка входа: `src/app/ui_input.tl` / key bindings
- Gameplay-код продолжает вызывать `leftkey(i)`, `jumpkey(i)` или thin wrappers
- Проверка: splitscreen, editor shortcuts не ломаются

---

## Этап 6 — flux

**Задача:** визуальные tweens (UI, camera shake, portal open) вместо ручных `timer`/`lerp` где уже есть аналог.

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
