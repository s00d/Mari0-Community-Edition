# Vendored LuaRocks (pure Lua, Love-safe)

Synced by `scripts/vendor-rocks` from rockspecs declared in
`mari0-ce-dependencies-1.rockspec`. Do not hand-edit; re-run the script.

| Module | Rock | Why |
|--------|------|-----|
| `dkjson` | dkjson 2.10-1 | Pure Lua JSON; Love `.love` friendly (no C `lua-cjson`) |
| `sha1` | sha1 0.5-1 | Pure Lua SHA-1 (kikito); callable module |
| `middleclass` | middleclass 3.0-1 | Same major as historical vendor; transitional until records |

## Teal / unused-local footguns

Do **not** silence unused warnings by rewriting `a, b = f()` into `local _, _ = f()` when `a`/`b` are **globals** (or otherwise needed). That drops the assignment and leaves nils → runtime compare/index crashes (seen with `mousex`/`mousey`). Prefer: keep the real names, initialize globals, or delete truly dead code.

