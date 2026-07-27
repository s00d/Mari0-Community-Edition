# Mari0: Community Edition — Love2D + Teal helpers
#
# Requires: Love 11.x (https://love2d.org), zip (for package)
# Optional: luarocks --local cyan  (Teal build; scripts/cyan uses luarocks Lua, not LuaJIT)
# Override binary:  make run LOVE=/path/to/love

NAME      ?= mari0-ce
DIST      ?= dist
LOVE_FILE ?= $(DIST)/$(NAME).love

ifndef LOVE
  LOVE := $(shell \
    command -v love 2>/dev/null \
    || command -v love2d 2>/dev/null \
    || { test -x /Applications/love.app/Contents/MacOS/love && echo /Applications/love.app/Contents/MacOS/love; } \
    || { test -x /opt/homebrew/bin/love && echo /opt/homebrew/bin/love; } \
    || { test -x /usr/local/bin/love && echo /usr/local/bin/love; } \
    || echo love)
endif

.PHONY: help run play build package clean check snap test test-shaders teal teal-check teal-watch vendor-rocks

.DEFAULT_GOAL := help

help: ## Show this help
	@echo "Mari0 CE — targets:"
	@echo "  make teal         Compile src/**/*.tl -> build/ (cyan build)"
	@echo "  make teal-check   Typecheck Teal sources (cyan check)"
	@echo "  make teal-watch   Rebuild on change (watchexec/entr/fswatch/poll)"
	@echo "  make vendor-rocks Sync pure-Lua rocks into lib/ (dkjson/sha1)"
	@echo "  make run / play   Build Teal then run with Love"
	@echo "  make build        Build $(LOVE_FILE)"
	@echo "  make package      Alias for build"
	@echo "  make check        Verify Love binary is available"
	@echo "  make test         Teal build + Lua regression suite"
	@echo "  make test-shaders Compile all assets/shaders/*.frag via Love"
	@echo "  make snap         Build Linux snap (needs snapcraft)"
	@echo "  make clean        Remove dist/ and build artifacts"
	@echo ""
	@echo "Love binary: $(LOVE)"
	@echo "Override:    make run LOVE=/path/to/love"

check: ## Verify love can be executed
	@command -v "$(LOVE)" >/dev/null 2>&1 \
		|| test -x "$(LOVE)" \
		|| { echo "error: Love not found (tried: $(LOVE))"; \
		     echo "Install from https://love2d.org or set LOVE=/path/to/love"; \
		     exit 1; }
	@"$(LOVE)" --version

teal: ## Compile Teal sources into build/ via Cyan
	@chmod +x scripts/cyan scripts/teal-build
	@./scripts/teal-build

teal-check: ## Typecheck Teal (cyan check)
	@chmod +x scripts/cyan
	@./scripts/cyan check $$(find src -name '*.tl' | sort)

teal-watch: ## Rebuild Teal on src/types changes
	@chmod +x scripts/cyan scripts/teal-build scripts/teal-watch
	@./scripts/teal-watch

vendor-rocks: ## Refresh lib/ from LuaRocks pins (dependencies-1.rockspec)
	@chmod +x scripts/vendor-rocks
	@./scripts/vendor-rocks

test: teal ## Run pure-Lua test suite (no Love window)
	@lua tests/run.lua

test-update-baseline: teal ## Regenerate tests/baseline.json from current perf
	@UPDATE_BASELINE=1 lua tests/run.lua

test-shaders: check ## Compile all .frag shaders under Love
	@rm -rf "$(DIST)/shader_smoke"
	@mkdir -p "$(DIST)/shader_smoke/shaders"
	@cp tests/shader_smoke/main.lua tests/shader_smoke/conf.lua "$(DIST)/shader_smoke/"
	@cp assets/shaders/*.frag "$(DIST)/shader_smoke/shaders/"
	@"$(LOVE)" "$(DIST)/shader_smoke"

run: check ## Launch the game from this directory (fresh Teal build)
	@chmod +x scripts/cyan scripts/teal-build
	@./scripts/teal-build -u
	@"$(LOVE)" .

play: run ## Alias for run

build: teal $(LOVE_FILE) ## Build .love archive

package: build ## Alias for build

$(LOVE_FILE):
	@mkdir -p "$(DIST)"
	@rm -f "$@"
	zip -9 -qr "$@" . \
		-x './.git/*' \
		-x './.gitignore' \
		-x './dist/*' \
		-x './src/*' \
		-x './types/*' \
		-x './scripts/*' \
		-x './docs/*' \
		-x './legacy/*' \
		-x './Makefile' \
		-x './tlconfig.lua' \
		-x './tests/*' \
		-x './snap/*' \
		-x './snap/.snapcraft/*' \
		-x './parts/*' \
		-x './stage/*' \
		-x './prime/*' \
		-x '*.snap' \
		-x '*_source.tar.bz2' \
		-x '*.DS_Store'
	@echo "Built $@ (includes precompiled build/ for Teal shims)"

snap: ## Build snap package (Linux; requires snapcraft)
	snapcraft

clean: ## Remove build artifacts
	rm -rf "$(DIST)" build
	rm -rf snap/.snapcraft parts stage prime
	rm -f *.snap *_source.tar.bz2
