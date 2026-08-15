# План: меньше кастома — упрощение, не обёртки

Цель: **удалить** самописный generic-код и мёртвый vendor. Библиотека оправдана только если после PR:

1. старый путь **удалён** (не «и ещё через либу»);
2. net LOC в затронутых модулях **падает**;
3. один SoT на зону (не dual-mode / не `.source`+`.ripple` / не wrapper→global).

Иначе — **не вендорить**. Идея не «подключить awesome-love2d», а упростить логику и код.

Источники: `docs/architecture.md`, `docs/library-integration-plan.md`, [awesome-love2d](https://github.com/love2d-community/awesome-love2d).

---

## Правила (жёсткие)

1. **Replace или DROP.** Куски на диске ≠ стадия закрыта. Пока dual-path / лишний слой / «for future» — статус **не готово**, не «частично» и не «Xa ✓ / Xb потом».
2. **Net LOC ↓** в затронутых файлах. Если после интеграции LOC вырос — откат.
3. **Форматы на диске не трогать:** `N-M.txt`, JSON-анимации, characterloader, `DISK_COLOR_MAX`.
4. Не держать две либы на одну задачу. Мёртвый vendor в `lib/` — удалить, не «когда-нибудь вшьём».
5. Кастом остаётся только там, где либа не знает порталы / gel / 16px / `session.objects`.
6. **Порталы / portal resolve / stencil порталов — не трогать.** Ни Push, ни «упрощение» collision под либу.

---

## Что навсегда своё

| Кусок | Почему |
|-------|--------|
| `physics/collision` + portal resolve | AABB + порталы + gel + mask[]; bump только query |
| portal stencil / draw path | не ломать ради canvas-либы |
| `levelio` + mappack `N-M` | контракт сообщества |
| `animation.tl` | DSL триггеров mappack, не sprite-cycles |
| `entities/*` | ECS даст клей, не минус LOC |
| pixel `ui.menu` / `guielement` | Slab/ImGui не заменят |
| `tile_spritebatch` | full fill + cell update |
| `AssetStore` mappack override | cargo/lily не знают |

---

## Честный статус

### Готово (чисто)

| # | Зона | Почему ок |
|---|------|-----------|
| 1 | мёртвый vendor | lume / hump.vector\|gamestate\|signal удалены |
| 2 | hump.camera | attach-only + Flux pan; один world-px path; batches/parallax вне attach намеренно |
| 3 | states | `Gamestate.call` → [`gamestate_register.tl`](src/app/gamestate_register.tl) → domain; нет `states/*`; нет мёртвого `editor` state |
| 5 | ripple | один `SoundEntry.sound`; tags music/sfx; нет `tag_ui` / dual `.source` |
| 6 | STI | vendor + stubs удалены; N-M `levelio` only |
| 7 | Slab | vendor + debug overlay удалены; editor = guielement |
| 9 | монолиты | editor ownership modules + `menu_options_draw`; `editor.tl` ≈ orchestrator |
| — | anim8 / bump / baton / flux / hump.timer | replace без dual-path |
| — | dkjson / sock / bitser | рабочие контракты |

### DROP / не начинать

| Идея | Вердикт |
|------|---------|
| **Push / Shöve / fullscreen-lib** | **DROP.** Риск stencil/порталов; canvas blit в `love_run` оставить. |
| Slab full editor rewrite | **вне плана** — guielement остаётся |
| roomy / hump.gamestate | Не нужны. |
| lume | Не воскрешать. |
| Любая правка portal resolve / portal stencil «под либу» | **запрещено** этим планом. |

---

## Стадии

### 0 — инвентарь — готово

### 1 — мёртвый vendor — готово (чисто)

### 2 — hump.camera — готово

- `scenedraw` → `world_camera_attach` вокруг tiles/props/objects/fx/fg
- Flux `cameraxpan` / `cameraypan`
- Attach-only helpers в [`world_camera.tl`](src/util/world_camera.tl)
- Coinblock / scrolling score / vine — один path
- Параллакс/tile batches вне камеры (свой offset)
- Удалён `world_spritebatch_offset`

**Вне scope:** editor overlays с ручным scroll; `camera:lock`.

Проверка: `camera_follow_checks`, `helper_checks` (pan).

### 3 — states — готово

- Удалён `src/app/states/*` (третий слой)
- Один SoT: [`gamestate_register.tl`](src/app/gamestate_register.tl) → domain globals
- Асимметрии input (konami / lobby escape / menu joy) в register
- State `"editor"` не регистрируется (`editormode` внутри `"game"`)

Проверка: `gamestate_checks`.

### 4 — Push — **DROP** (не делать)

Не трогать canvas/`love_run` ради Push. Портальный stencil не переписывать.

### 5 — ripple — готово

- `soundlist[id].sound` — единственный play object (`RippleSound`)
- `playsound` / `stopsound` / `sound_duration` / pitch через ripple helpers
- Tags: music + sfx; удалён мёртвый `tag_ui`
- Duration кэш при bind; callers не трогают Love `Source`

Проверка: `audio_checks`.

### 6 — STI — готово (DROP выполнен)

- Удалены `lib/sti/`, `sti_runtime.tl`, `types/sti.d.tl`
- Убраны boot require и vendor clone
- N-M `levelio` — единственный load path

Проверка: `sti_gone_checks`.

### 7 — Slab — готово (DROP выполнен)

- Удалены `lib/slab/`, `editor_slab.tl`, `types/slab.d.tl`
- Убраны boot/editor/variables glue и vendor clone
- Editor остаётся на `guielement` (full Slab rewrite — вне плана)

Проверка: `slab_gone_checks`.

### 8 — debug (lurker/lovebird) — ок, только `--debug`

### 9 — нарезка монолитов — готово

Механические extract’ы без смены поведения:

**Menu**
- [`menu_options_draw.tl`](src/ui/menu_options_draw.tl) — `menu_draw_options`

**Editor ownership** (`editor.tl` ≈ оркестратор ~1.5k LOC):

| Модуль | Concern |
|--------|---------|
| [`editor_draw.tl`](src/ui/editor_draw.tl) | overlay / status / menu panels / chrome |
| [`editor_tabs.tl`](src/ui/editor_tabs.tl) | tab builders |
| [`editor_tilefilters.tl`](src/ui/editor_tilefilters.tl) | palette filters + `generateentitylist` |
| [`editor_animation.tl`](src/ui/editor_animation.tl) | animation-tab glue |
| [`editor_mapio.tl`](src/ui/editor_mapio.tl) | resize / maps / multitile files |
| [`editor_settings.tl`](src/ui/editor_settings.tl) | toggles / dropdowns / hotkeys |
| [`editor_input.tl`](src/ui/editor_input.tl) | mouse / key / text |

В оркестраторе: `editor_load` / `update*` / `draw` shim / `placetile` / open-close / playtest / linking / selection.

Проверка: `monolith_split_checks`, `editor_checks`, `menu_checks`.

### 10 — dist/CI — поздно

---

## Порядок работ

```
1 dead vendor     ✓
2 camera          ✓
3 states          ✓
5 ripple          ✓
6 DROP sti        ✓
7 DROP slab       ✓
9 split monoliths ✓  (editor ownership modules + menu_options_draw)
4 Push            DROP — не в очереди
8 debug           ок (только --debug)
10 dist
```

Push и порталы — вне очереди навсегда в этом плане.

---

## Метрика

Ожидаемо дальше:

- dist/CI по желанию
- дальнейшая нарезка editor input / menu — опционально

Не ожидаем минус в `physics/collision`, portal code, `entities/*`, `levelio` N-M.

```bash
make teal && make test && make run
```

---

## Ссылки

- [docs/architecture.md](docs/architecture.md)
- [docs/library-integration-plan.md](docs/library-integration-plan.md)
- [awesome-love2d](https://github.com/love2d-community/awesome-love2d)
