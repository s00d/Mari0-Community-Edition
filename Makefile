# Mari0: Community Edition — Love2D helpers
#
# Requires: Love 11.x (https://love2d.org), zip (for package)
# Override binary:  make run LOVE=/path/to/love
#                   LOVE=/path/to/love make run

NAME      ?= mari0-ce
DIST      ?= dist
LOVE_FILE ?= $(DIST)/$(NAME).love

# Resolve love binary: LOVE env/make var, then PATH (love|love2d), then common macOS paths
ifndef LOVE
  LOVE := $(shell \
    command -v love 2>/dev/null \
    || command -v love2d 2>/dev/null \
    || { test -x /Applications/love.app/Contents/MacOS/love && echo /Applications/love.app/Contents/MacOS/love; } \
    || { test -x /opt/homebrew/bin/love && echo /opt/homebrew/bin/love; } \
    || { test -x /usr/local/bin/love && echo /usr/local/bin/love; } \
    || echo love)
endif

.PHONY: help run play build package clean check snap

.DEFAULT_GOAL := help

help: ## Show this help
	@echo "Mari0 CE — targets:"
	@echo "  make run / play   Run the game with Love"
	@echo "  make build        Build $(LOVE_FILE)"
	@echo "  make package      Alias for build"
	@echo "  make check        Verify Love binary is available"
	@echo "  make snap         Build Linux snap (needs snapcraft)"
	@echo "  make clean        Remove $(DIST)/ and local snap artifacts"
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

run: check ## Launch the game from this directory
	@"$(LOVE)" .

play: run ## Alias for run

build: $(LOVE_FILE) ## Build .love archive

package: build ## Alias for build

$(LOVE_FILE):
	@mkdir -p "$(DIST)"
	@rm -f "$@"
	zip -9 -qr "$@" . \
		-x './.git/*' \
		-x './.gitignore' \
		-x './dist/*' \
		-x './Makefile' \
		-x './snap/*' \
		-x './snap/.snapcraft/*' \
		-x './parts/*' \
		-x './stage/*' \
		-x './prime/*' \
		-x '*.snap' \
		-x '*_source.tar.bz2' \
		-x '*.DS_Store'
	@echo "Built $@"

snap: ## Build snap package (Linux; requires snapcraft)
	snapcraft

clean: ## Remove build artifacts
	rm -rf "$(DIST)"
	rm -rf snap/.snapcraft parts stage prime
	rm -f *.snap *_source.tar.bz2
