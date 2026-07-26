# Shipped media lives under this folder.

| Path | Content |
|------|---------|
| `assets/graphics/` | Images, tilesets, UI chrome |
| `assets/sounds/` | SFX + music |
| `assets/shaders/` | Post-process `.frag` + `init.lua` (`require "assets.shaders"`) |
| `assets/characters/` | Playable character packs |
| `assets/enemies/` | Built-in enemy JSON/PNG (mappack enemies stay under `mappacks/*/enemies/`) |

`AssetStore` (`src/assets/store.tl`) exposes prefix constants: `GRAPHICS`, `SOUNDS`, `SHADERS`, `CHARACTERS`, `ENEMIES`.
