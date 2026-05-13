.PHONY: help backup
.DEFAULT_GOAL := help

# Per-machine targets. Pick the entry that matches the box you're on.
.PHONY: x1 main_pc mini_pc mac
.PHONY: x1-plan main_pc-plan mini_pc-plan mac-plan

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-18s %s\n", $$1, $$2}'

x1:       ## Apply on x1 (Arch laptop, Hyprland)
	./scripts/run.sh --machine x1
x1-plan:  ## Plan on x1 (no changes)
	./scripts/run.sh --machine x1 --plan

main_pc:       ## Apply inside WSL on main_pc (run bootstrap.yml on the Windows host first)
	./scripts/run.sh --machine main_pc
main_pc-plan:  ## Plan inside WSL on main_pc
	./scripts/run.sh --machine main_pc --plan

mini_pc:       ## Apply inside WSL on mini_pc
	./scripts/run.sh --machine mini_pc
mini_pc-plan:  ## Plan inside WSL on mini_pc
	./scripts/run.sh --machine mini_pc --plan

mac:           ## Apply on macOS
	./scripts/run.sh --machine mac
mac-plan:      ## Plan on macOS
	./scripts/run.sh --machine mac --plan

backup: ## Backup current configs
	@echo "Creating backup..."
	@mkdir -p ~/.dotfiles-backup/$$(date +%Y%m%d_%H%M%S)
	@for f in .zshrc .tmux.conf .gitconfig; do \
		if [ -f ~/$$f ]; then \
			cp ~/$$f ~/.dotfiles-backup/$$(date +%Y%m%d_%H%M%S)/$$f; \
			echo "Backed up ~/$$f"; \
		fi; \
	done
	@echo "Backup complete in ~/.dotfiles-backup/$$(date +%Y%m%d_%H%M%S)/"
