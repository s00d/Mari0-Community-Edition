# Правила: меньше кастома — упрощение, не обёртки

Библиотека оправдана только если после PR: старый путь удалён, net LOC падает, один SoT на зону. Иначе — не вендорить.

Источники: [`docs/architecture.md`](docs/architecture.md), [`docs/library-integration-plan.md`](docs/library-integration-plan.md), [awesome-love2d](https://github.com/love2d-community/awesome-love2d).

## Жёсткие правила

1. **Replace или DROP** — не dual-path / лишний слой / «for future».
2. **Net LOC ↓** в затронутых файлах; иначе откат.
3. **Форматы на диске не трогать:** `N-M.txt`, JSON-анимации, characterloader, `DISK_COLOR_MAX`.
4. Не две либы на одну задачу. Мёртвый vendor в `lib/` — удалить.
5. Кастом только там, где либа не знает порталы / gel / 16px / `session.objects`.
6. **Порталы / portal resolve / stencil / Push — не трогать.**

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

```bash
make teal && make test && make run
```
