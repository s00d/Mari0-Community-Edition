# План: меньше кастома, больше готовых библиотек

Цель: выкинуть самописный generic-код (камера, tween, input, UI редактора, утилиты, fullscreen) в vendored LÖVE-библиотеки. **Не** переписывать игру на ECS / Box2D / новый формат уровней.

Источники: [awesome-love2d](https://github.com/love2d-community/awesome-love2d), текущие `lib/`, `docs/library-integration-plan.md`, `docs/architecture.md`. Паттерны структуры: [tesselode/roomy](https://github.com/tesselode/roomy), [BobG1983/love2d-template](https://github.com/BobG1983/love2d-template), треды [структура LÖVE](https://love2d.org/forums/viewtopic.php?t=10581).

Смежный документ: `docs/library-integration-plan.md` — уже сделанные anim8 / bump / baton / flux и незакрытый hump. Этот файл — полный маршрут, включая структуру репо.

---

## Правила каждой стадии

1. **Одна библиотека (или один шов) за PR.** `make teal` + `make test` + smoke intro→menu→уровень→editor.
2. **PR успешен, только если net LOC падает** в затронутых модулях (цель ~−30%). Compat-слой — максимум один PR, потом удалить.
3. **Форматы на диске не трогать:** `N-M.txt`, JSON-анимации mappack, characterloader, цвета 0–255 (`DISK_COLOR_MAX`).
4. Сначала **дожать уже лежащее в `lib/`**, потом вендорить новое. Не держать две либы на одну задачу (lume+batteries, flux+tween.lua, baton+tactile, sti+cartographer, hump.timer+tick).
5. Кастом остаётся там, где библиотека не знает про порталы, gel, tile-grid 16px и `session.objects`.

---

## Что навсегда своё (не заменять)

| Кусок | Почему |
|-------|--------|
| `src/physics/collision.tl` + `portal.tl` + `update.tl` resolve (~2k LOC) | AABB + порталы + gel skip + emancipation + 31-bit `mask[]` + наклоны (`aabt`). bump только query; `world:move` / windfield / HC / slick — ломают порталы |
| `src/world/levelio.tl`, mappack `N-M` | контракт сообщества |
| `src/world/animation.tl` (~564 LOC) | DSL триггеров mappack (`mapload`, `pancameratox`, …), не sprite-cycles |
| `src/entities/*` (95 файлов) | уникальный update/draw; ECS (Concord/tiny-ecs) даст адаптеры, не минус LOC |
| Игровой HUD / `ui.menu` + `ui.editor` + `guielement` (~12k LOC) | Slab сейчас 22 LOC debug. SUIT/ImGui не заменят pixel-font editor/N-M/rightclick |
| `world.tile_spritebatch` | полный fill карты + точечный апдейт ячейки; autobatch этого не умеет |
| `AssetStore` override путей mappack | cargo/clove/lily не знают character/tileset override |
| `love.physics` | в `conf.lua` выключен сознательно |

Не воскрешать: `core.ctx`, Level OOP, `push_globals`, middleclass/classic как база сущностей (`docs/architecture.md`).

---

## Аудит awesome-love2d → Mari0 CE

### Уже в `lib/` и реально используется

| Либа | Статус | Дальше |
|------|--------|--------|
| [anim8](https://github.com/kikito/anim8) | sprite cycles игрока/врагов/тайлов | не трогать |
| [bump](https://github.com/kikito/bump.lua) | spatial index | не переключать resolve на `world:move` |
| [baton](https://github.com/tesselode/baton) | `input_bindings.tl` | не трогать |
| [flux](https://github.com/rxi/flux) | portal/menu/intro/shake/roomcam/notice | остался линейный `xpantimer`/`ypantimer` в `scroll_update.tl` |
| [hump.timer](https://hump.readthedocs.io/en/latest/timer.html) | delayer/intro/levelscreen | `walltimer` — игровой clock (кадры 1–10), не tween |
| [hump.camera](https://hump.readthedocs.io/en/latest/camera.html) | `world_camera.tl` attach/lookAt/zoom; follow **не** `camera:lock` | dual-mode `tile_draw_*` не дожат: objects/props/foreground |
| [sock.lua](https://github.com/camchenry/sock.lua) + [bitser](https://github.com/gvx/bitser) | host-authoritative net | не менять на Grease/LoverNet |
| [dkjson](https://github.com/LuaDist/dkjson) | JSON | не менять на lua-cjson (C-модуль не едет в `.love`) |

### Уже в `lib/`, почти не используется — приоритет

| Либа | Сейчас | Зачем подключать |
|------|--------|------------------|
| [lume](https://github.com/rxi/lume) | **ни одного `require` в src/** | перекрытие ~100 LOC: `round`/`split`/`tablecontains`. Не трогать `tilekey`, `remove_indices_desc`, `gcpace`, `global_freeze` |
| [inspect](https://github.com/kikito/inspect.lua) | не в runtime | dump в `--debug` / lovebird |
| [hump.signal](https://hump.readthedocs.io/en/latest/signal.html) | только `tests/` | не шина на всё; подключать точечно или выкинуть из vendor |
| [hump.vector](https://hump.readthedocs.io/en/latest/vector.html) | **мёртвый vendor** | скорость = `speedx`/`speedy` + `convert`; **не** внедрять, лучше убрать из `vendor-libs` |
| [hump.gamestate](https://hump.readthedocs.io/en/latest/gamestate.html) | **не required** | свой dispatcher 57 строк; стек сломает `menu`/`mappackmenu`/`options` |
| [STI](https://github.com/karai17/Simple-Tiled-Implementation) | `sti_try_load_map` **никто не зовёт** | либо вшить в load path для `.tmx`, либо не держать мёртвый vendor |
| [Slab](https://github.com/flamendless/Slab) | 22 LOC debug, `editor_slab_debug=false` | палитра/инспектор; игровой GUI = `guielement` (~12k LOC menu+editor) |

### Имеет смысл вендорить (новое)

| Либа | Вместо чего | Оценка |
|------|-------------|--------|
| [Push](https://github.com/Ulydev/push) или [Shöve](https://github.com/Oval-Tutu/shove) | fullscreen canvas в `love_run.tl` (~40 LOC хака + размазанный `scale`) | высокая, если stencil порталов живёт |
| [ripple](https://github.com/tesselode/ripple) | ручные volume music/sfx, play/stop в `musicloader` | средняя; **оставить** поиск файла в mappack |
| [lurker](https://github.com/rxi/lurker) + [Lovebird](https://github.com/rxi/lovebird) | самописный debug | только под `MARI0_DEBUG` |
| [jprof](https://github.com/pfirsich/jprof) / [AppleCake](https://github.com/EngineerSmith/AppleCake) | `tests/profiler.lua` | по желанию, не CI |
| [nativefs](https://github.com/EngineerSmith/nativefs) | если editor/export упрётся в sandbox Love | только editor |
| [GamepadGuesser](https://github.com/idbrii/love-gamepadguesser) | иконки кнопок в options | косметика, поздно |
| [love-release](https://github.com/MisterDA/love-release) / [boon](https://github.com/camchenry/boon) / [makelove](https://github.com/pfirsich/makelove) | рядом с `make package` | дистрибуция, не геймплей |

### Смотрели и отвергли

| Либа | Почему нет |
|------|------------|
| Concord / tiny-ecs / nata | 95 сущностей + порталы = больше клея, не меньше кода |
| windfield / breezefield / love.physics | порталы и tile AABB не Box2D |
| HC / slick | нужны, если появятся вращаемые полигоны; сейчас сетка 16px |
| classic / middleclass / hump.class | явный запрет в architecture |
| roomy / Scenery | свой `Gamestate` уже тонкий; стек сцен имеет смысл только если пауза станет отдельной сценой **и** это удалит ветки в `love_callbacks` |
| SUIT / LoveFrames / ImGui / Helium | игровой UI пиксельный; Slab — только editor overlay |
| cartographer | дубль STI |
| batteries | дубль lume (lume уже вендорен) |
| tween.lua / tick (rxi) | дубль flux / hump.timer |
| tactile | дубль baton |
| moonshine | у нас уже пачка своих `.frag` (CRT, hq2x, bloom); moonshine добавит второй пайплайн |
| autobatch | конфликт со своими spritebatch + stencil порталов |
| cargo / clove / lily | AssetStore знает override mappack; async-load не окупает intro |
| shack | shake уже на flux |
| splashy | intro свой, ассеты/тайминг Mari0 |
| log.lua | `app.logger` 69 LOC — vendor не окупается |

---

## Целевая структура (как у нормальных LÖVE-проектов, без шаблонного ECS)

Типичный современный LÖVE-репо: тонкий `main.lua` / `conf.lua`, `src/` логика, `lib/` вендор, `assets/` (или `res/`) медиа, сцены как таблицы `enter/update/draw`.

Шаблон [love2d-template](https://github.com/BobG1983/love2d-template) кладёт в `lib/` roomy+ripple+push+anim8+lume — **этот набор утилит нам подходит**. Он же тащит Concord+windfield+classic — **этому набору следовать нельзя**.

Mari0 CE уже ближе к «большой игре по доменам», чем к template из сцен. Целевой каркас:

```
main.lua conf.lua          # тонкий вход (уже так)
src/app/                   # boot, loop, callbacks, input
src/app/states/            # intro, menu, game, editor, lobby — таблицы update/draw
src/world/                 # session = SoT уровня
src/physics/               # bump query + свой resolve
src/entities/              # records, группы session.objects
src/weapons/
src/net/
src/ui/                    # pixel menus + editor (Slab overlay)
src/assets/                # AssetStore, anim8_*, music
lib/                       # только то, что required
assets/ mappacks/ tests/
```

Не делать: `src/scenes/` вместо доменов, плоский `lua/libs`, git-submodule «движка».

`session` остаётся источником правды уровня. `_G` — gamestate/options/media, не карта.

---

## Стадии

Каждая стадия — отдельный PR. Не начинать N+1, пока N не зелёная.

### Стадия 0 — инвентарь и запреты (этот документ)

- [x] Сверка awesome-love2d ↔ `lib/` ↔ `src/`
- [x] Список «не трогать»
- [x] Ссылка из `docs/library-integration-plan.md`

**Готово когда:** команда согласна с reject-списком.

### Стадия 1 — дожать уже вендоренное: lume

**Зачем:** `lib/lume.lua` мёртв. Перекрытие с `core/*util` маленькое (~100 LOC), не весь каталог.

| Своё | lume |
|------|------|
| `round` | `lume.round` |
| `strsplit` / `string.split` | `lume.split` |
| `tablecontains` | `lume.find` |

Не трогать: `remove_indices_desc` (горячий путь), `addzeros`, `getrainbowcolor`, `tilekey` (int pack 65536), `gcpace`/`keepalive`, `global_freeze`, `Rng`.

Если после замены `round`/`split`/`find` lume больше нигде не нужен — **не** тащить его в hot path ради трёх функций: тогда проще оставить алиасы и удалить lume из vendor. Критерий тот же: net LOC.

Параллельно вычистить мёртвый vendor: `hump.vector`, `hump.gamestate` (не required). `hump.signal` — либо один реальный вызов, либо тоже вон.

Проверка: `make test` (helper_checks, teal_checks).

### Стадия 2 — hump.camera до конца

Продолжение `docs/library-integration-plan.md` этап 3.

- `game_draw_objects` / `game_draw_props` / `drawforeground` → `world_camera_attach` + `wpx`/`wpy` (сейчас dual-mode: attached world-px vs screen scroll)
- Follow оставить своим (fastest local player, splitscreen, `camerastop`, metroid rooms) — не `camera:lock`
- `xpantimer`/`ypantimer` в `scroll_update.tl` → `Flux.to` (это не camera lib, но тот же PR: один шов «камера движется»)
- Не переносить физику на пиксели камеры: физика остаётся в тайлах

Ожидаемый выигрыш: −400…800 LOC размазанного `*16*scale - xscroll`.

Проверка: `tests/camera_follow_checks.lua`, `hump_no_wrapper_checks.lua`, splitscreen, editor pan, portal stencil.

### Стадия 3 — состояние как модули (без новой либы)

Паттерн forum/roomy: сцена = таблица колбэков. У нас это уже `Gamestate.handlers`, но колбэки размазаны по `love_callbacks.tl`.

- Вынести intro / menu / mappackmenu / options / onlinemenu / lobby / game / editor в `src/app/states/*.tl`
- `love.update`/`draw` только `Gamestate.update`/`draw` + общий input
- **Не** подключать roomy и **не** hump.gamestate, пока это не удалит больше, чем 57 строк dispatcher

Пауза: если после выноса pause всё ещё пачка `if pausemenuopen` — тогда (и только тогда) roomy stack. Иначе оставить флаг.

Проверка: переключение intro→menu→game→pause→editor, online lobby.

### Стадия 4 — Push (виртуальный кадр)

Сейчас: `completecanvas` + ручной blit в `love_run.tl`, `scale` размазан по draw.

- Вендор [push](https://github.com/Ulydev/push) (или Shöve, если нужен letterbox из коробки)
- Один `push:setupScreen(width*16, height*16, …)` в boot; `push:start`/`finish` вместо canvas-хака
- Сохранить: stencil порталов, `fullscreenmode` full vs letterbox, HighDPI

Если Push ломает stencil — **откат стадии**, кастом canvas дешевле.

Проверка: windowed, fullscreen, resize, splitscreen, portal through screen edge, intro без canvas (сейчас intro исключён из хака).

### Стадия 5 — ripple (аудио-теги)

- Теги `music` / `sfx` / `ui` вместо трёх ручных volume-путей
- `musicloader`: оставить `getfilepath` (mappack override), play/loop/pitch через ripple
- Не трогать сетевой tick и physics

Проверка: смена трека, star music, mappack custom music, mute options.

### Стадия 6 — STI только для `.tmx`

- `sti_try_load_map` → реальный слой тайлов + objects, маппинг в `session.map` / spawn
- N-M путь `levelio` без изменений
- Не делать runtime N-M→TMX и не заводить `*_vnext` mappack'и

Проверка: существующие mappack, плюс один `.tmx` smoke (если в репо нет — тестовый фикстурный файл в `tests/`).

### Стадия 7 — Slab: editor overlay

`ui.editor.tl` ~5000 LOC — не переписывать целиком.

Порядок выкусывания (каждый пункт — можно отдельный PR):

1. Debug overlay (уже есть `editor_slab_draw`) — включить по флагу
2. Инспектор выбранного entity (поля, которые сейчас в rightclick)
3. Палитра тайлов / поиск
4. Окно undo/dirty/map size

Оставить `guielement` для in-game checkbox/button/dropdown. Игровое `ui.menu.tl` (~2100 LOC) **не** переносить на Slab.

Проверка: editor open, paint, save, load, rightclick entity, undo.

### Стадия 8 — debug-тулчейн (только `--debug`)

- [lurker](https://github.com/rxi/lurker) — hot reload Lua/`build/` (осторожно с Teal: lurker видит `build/*.lua`)
- [lovebird](https://github.com/rxi/lovebird) — браузерная консоль; `inspect` для dump
- Опционально [jprof](https://github.com/pfirsich/jprof) вместо самописного `tests/profiler.lua`

Не включать в release `.love`.

### Стадия 9 — нарезка монолитов (структура, 0 новых либ)

Когда библиотеки на месте:

1. Дорезать `ui.editor.tl` по уже существующим `editor_*.tl`
2. Нарезать `ui.menu.tl` (layout уже в `menu_layout` / `menu_mappack`)
3. `ui.gui.tl` (859 LOC): оставить виджеты, которые ещё живы после Slab
4. Weapons — дочистить типы (как в architecture «Next work»), без новой либы

Критерий: файл > ~800 LOC и две ответственности → резать. Не резать `entities.mario` «для красоты».

### Стадия 10 — дистрибуция и CI (поздно)

- Оставить `make package` как есть, пока хватает
- При кросс-платформе: [love-release](https://github.com/MisterDA/love-release) или [boon](https://github.com/camchenry/boon) / GitHub [love-actions](https://github.com/love-actions)
- Тесты: текущий `tests/run.lua` не менять на busted (лишний раннер). Lust/luassert — только если появятся нечитаемые `assert`

Параллельно (не блокер библиотек): golden replay по реальному `physicsupdate` — это регрессия геймплея, не замена кастома.

---

## Порядок и зависимости

```
0 inventory
    → 1 lume            (нет зависимостей)
    → 2 hump.camera     (уже начато)
    → 3 states modules  (легче после камеры)
    → 4 push            (после камеры: один attach)
    → 5 ripple          (независимо от 2–4)
    → 6 sti             (независимо; не блокирует editor)
    → 7 slab            (editor; после 3 удобнее)
    → 8 debug           (любое время после 1)
    → 9 split monoliths (после 7, иначе резать дважды)
    → 10 dist           (когда API стабилен)
```

Не параллелить 2 и 4 (оба трогают draw). 1 / 5 / 6 / 8 можно параллельно.

---

## Метрика «кастом уменьшился»

После стадий 1–7 ожидаемо исчезнет или сожмётся:

- мёртвый зазор lume/inspect
- сотни строк `*16*scale - xscroll` в draw
- canvas-хак fullscreen
- ручные volume/play в аудио
- куски editor debug/inspector

Не ожидаем минус в `physics/collision`, `entities/*`, `levelio`, `animation.tl`. Если стадия туда лезет — это уже не «замена на либу», а смена игры.

Проверка после каждого PR:

```bash
make teal
make test
make run   # intro → menu → 1-1 → editor
```

Вендор новых либ только через `scripts/vendor-libs` + строка в `lib/README.md` + `types/*.d.tl`. Не копипастить руками.

---

## Ссылки

- [awesome-love2d](https://github.com/love2d-community/awesome-love2d)
- [docs/architecture.md](docs/architecture.md)
- [docs/library-integration-plan.md](docs/library-integration-plan.md)
- [hump](https://github.com/HDictus/hump) / [roomy](https://github.com/tesselode/roomy) / [ripple](https://github.com/tesselode/ripple) / [push](https://github.com/Ulydev/push) / [Slab](https://github.com/flamendless/Slab) / [STI](https://github.com/karai17/Simple-Tiled-Implementation)
