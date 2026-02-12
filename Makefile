.PHONY: help version patch minor major tag

# Default target
help:
	@echo "tmw - tmux worktree manager"
	@echo ""
	@echo "Version management targets:"
	@echo "  make version    - Show current version"
	@echo "  make patch      - Bump patch version (0.1.0 -> 0.1.1)"
	@echo "  make minor      - Bump minor version (0.1.0 -> 0.2.0)"
	@echo "  make major      - Bump major version (0.1.0 -> 1.0.0)"
	@echo "  make tag        - Tag current version (creates git tag v<X.X.X>)"
	@echo ""
	@echo "Install/uninstall:"
	@echo "  make install    - Install tmw to /usr/local/bin"
	@echo "  make uninstall  - Remove tmw from /usr/local/bin"

# Get current version from tmw script
CURRENT_VERSION := $(shell grep 'readonly VERSION=' tmw | sed 's/readonly VERSION="\(.*\)"/\1/')

version:
	@echo "tmw $(CURRENT_VERSION)"

# Parse version components
MAJOR := $(shell echo $(CURRENT_VERSION) | cut -d. -f1)
MINOR := $(shell echo $(CURRENT_VERSION) | cut -d. -f2)
PATCH := $(shell echo $(CURRENT_VERSION) | cut -d. -f3)

NEW_PATCH := $(shell echo $$(($(PATCH) + 1)))
NEW_MINOR := $(shell echo $$(($(MINOR) + 1)))
NEW_MAJOR := $(shell echo $$(($(MAJOR) + 1)))

patch:
	@NEW_VERSION="$(MAJOR).$(MINOR).$(NEW_PATCH)"; \
	sed -i '' 's/readonly VERSION="$(CURRENT_VERSION)"/readonly VERSION="'"$$NEW_VERSION"'"/' tmw; \
	git add tmw; \
	git commit -m "Bump version to $$NEW_VERSION"; \
	echo "Bumped version to $$NEW_VERSION"

minor:
	@NEW_VERSION="$(MAJOR).$(NEW_MINOR).0"; \
	sed -i '' 's/readonly VERSION="$(CURRENT_VERSION)"/readonly VERSION="'"$$NEW_VERSION"'"/' tmw; \
	git add tmw; \
	git commit -m "Bump version to $$NEW_VERSION"; \
	echo "Bumped version to $$NEW_VERSION"

major:
	@NEW_VERSION="$(NEW_MAJOR).0.0"; \
	sed -i '' 's/readonly VERSION="$(CURRENT_VERSION)"/readonly VERSION="'"$$NEW_VERSION"'"/' tmw; \
	git add tmw; \
	git commit -m "Bump version to $$NEW_VERSION"; \
	echo "Bumped version to $$NEW_VERSION"

tag:
	@git tag -a "v$(CURRENT_VERSION)" -m "Release v$(CURRENT_VERSION)"; \
	echo "Created tag v$(CURRENT_VERSION)"; \
	echo "Run 'git push origin v$(CURRENT_VERSION)' to push tag"

install:
	@cp tmw /usr/local/bin/tmw
	@chmod +x /usr/local/bin/tmw
	@echo "Installed tmw to /usr/local/bin/tmw"

uninstall:
	@rm -f /usr/local/bin/tmw
	@echo "Uninstalled tmw from /usr/local/bin/tmw"
