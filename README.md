# Mari0-CE
***The open-source, community-driven effort to improve upon the latest version of Mari0 SE.***

Mari0 is a cross over between the classic Super Mario Brothers and the cult hit Portal. Originally developed by Maurice Guégan, from [Stabyourself.net](http://stabyourself.net/).

## Requirements

- **LÖVE 11.x** ([love2d.org](https://love2d.org)) — older 0.9/0.10 are not supported
- Optional for developers: [Cyan](https://github.com/teal-language/cyan) + [Teal](https://github.com/teal-language/tl) via luarocks (`luarocks install --local cyan`). Project build is `cyan build` (`make teal` → `scripts/teal-build`). Use the same Lua as luarocks (Homebrew often Lua 5.5) — **not** LuaJIT, or `lfs` will fail to load. Runtime deps: `dependencies-1.rockspec` → `make vendor-rocks` → `lib/` (dkjson, sha1).

```bash
make teal         # cyan build: src/**/*.tl -> build/
make teal-watch   # rebuild on change (watchexec / entr / fswatch / poll)
make test         # Teal build + Lua regression suite
make run          # Teal then love . (uses precompiled build/, not tl.loader)
make package      # .love archive (includes build/)
```

See [docs/architecture.md](docs/architecture.md) for the Teal layout (dotted requires, no root shims). Media lives under `assets/` (`graphics/`, `sounds/`, `shaders/`, …).

You can run the .love files found in the [RELEASES](https://github.com/Mari0-CE/Mari0-Community-Edition/releases) section using **Löve**, which can be found here for [Windows](https://bitbucket.org/rude/love/downloads/love-11.1-win64.exe), [Mac](https://bitbucket.org/rude/love/downloads/love-11.1-macos.zip), [or other platforms](https://bitbucket.org/rude/love/downloads/ "Use 0.11.1").

If you're looking for help or mappacks, or you made a mappack of your own, [the game's forum is here](http://forum.stabyourself.net/viewforum.php?f=8). You can also find a dedicated thread to sharing user-made mappacks [HERE](http://forum.stabyourself.net/viewtopic.php?f=12&t=3591).

You can find the official releases of Mari0 SE [HERE](http://forum.stabyourself.net/viewtopic.php?f=8&t=4634) (note that they are unmaintained and might contain bugs/be incompatible with current mappacks).  
If you think you'd prefer Alesan's Entities (a mod for Mari0 1.6 that shares many features with Mari0 SE and Mari0 CE), you can find it [HERE](http://forum.stabyourself.net/viewtopic.php?f=13&t=3636).
