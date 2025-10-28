# Project metadata -----------------------------------------------------------
PROJECT    ?= suda.nvim
NVIM       ?= nvim
LUA_DIRS   ?= lua plugin tests
DOC_DIR    ?= doc
MINIMAL    ?= tests/minimal_init.lua
TEST_CMD   ?= PlenaryBustedDirectory tests/ {minimal_init = '$(MINIMAL)'}

# Dependencies ---------------------------------------------------------------
PLENARY_DIR ?= $(HOME)/.local/share/nvim/site/pack/vendor/start/plenary.nvim

# Tools ----------------------------------------------------------------------
STYLUA     ?= stylua
LUACHECK   ?= luacheck

.PHONY: help test lint format check docs clean

help: ## Show available targets
	@echo "$(PROJECT) – available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-12s %s\n", $$1, $$2}'

test: ## Run the automated test suite
	@[ -d "$(PLENARY_DIR)" ] || { echo "plenary.nvim not found at $(PLENARY_DIR). Set PLENARY_DIR or clone the repository there."; exit 1; }
	@echo "Running tests..."
	@PLENARY_DIR="$(PLENARY_DIR)" $(NVIM) --headless -u $(MINIMAL) +"$(TEST_CMD)" +qa

lint: ## Lint Lua sources with luacheck
	@command -v $(LUACHECK) >/dev/null 2>&1 || { echo "luacheck not found. Install via 'luarocks install luacheck'."; exit 1; }
	@echo "Linting Lua sources..."
	@$(LUACHECK) $(LUA_DIRS)

format: ## Format Lua sources with stylua
	@command -v $(STYLUA) >/dev/null 2>&1 || { echo "stylua not found. Install via 'cargo install stylua'."; exit 1; }
	@echo "Formatting Lua sources..."
	@$(STYLUA) $(LUA_DIRS)

check: lint test ## Run linting and tests

docs: ## Regenerate helptags for documentation
	@echo "Generating helptags..."
	@$(NVIM) --headless +'helptags $(DOC_DIR)' +qa

clean: ## Remove generated artefacts
	@echo "Cleaning repository..."
	@rm -rf $(DOC_DIR)/tags
	@find . -type f \( -name '*.swp' -o -name '*.swo' -o -name '*.swx' \) -delete

.DEFAULT_GOAL := help
