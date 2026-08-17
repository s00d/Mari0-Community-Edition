# Vendored libs (живой контракт)

Правила и «что навсегда своё»: [`../refactor-plan.md`](../refactor-plan.md).

Источник: `scripts/vendor-libs` (+ `scripts/vendor-rocks` для dkjson/sha1). Типы: `types/*.d.tl`, `types/hump/*.d.tl`.

## Принципы

1. **Replace или DROP** — не прослойка поверх.
2. Формат данных не трогать — N-M / JSON / characterloader.
3. **Net LOC ↓**. Dual-mode / dual-API запрещены.
4. Мёртвый vendor без callers — удалить.
5. Порталы / portal stencil / resolve / Push — не трогать.

## В репо сейчас

| Либа | Роль |
|------|------|
| anim8 | sprite cycles (`anim8_*`) |
| bump | spatial index (resolve v1 свой) |
| hump.camera / hump.timer | attach-only world draw + timers |
| baton | input (`input_bindings`) |
| flux | UI / camera / portal open tweens |
| ripple | один `SoundEntry.sound`; tags music/sfx |
| dkjson / sock / bitser | JSON / net / binary |

Не вендорить снова: STI, Slab, lume, roomy, hump.gamestate/signal/vector, Push.

## Восстановление lib/types

```bash
./scripts/vendor-libs
```

`types/*.d.tl` — в git. Не `git clean` без exclude для `lib/` и `types/`.

```bash
make teal && make test && make run
```
