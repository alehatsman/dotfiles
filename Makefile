.PHONY: help backup
.DEFAULT_GOAL := help

# Per-machine targets. Pick the entry that matches the box you're on.
.PHONY: x1 main_pc mini_pc mac
.PHONY: x1-plan main_pc-plan mini_pc-plan mac-plan

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-18s %s\n", $$1, $$2}'

x1:       ## Apply on x1 (Arch laptop, Hyprland)
	mooncake apply -c ./x1.yml -K
x1-plan:  ## Plan on x1 (no changes)
	mooncake plan -c ./x1.yml

main_pc:       ## Apply inside WSL on main_pc (run bootstrap.yml on the Windows host first)
	mooncake apply -c ./main_pc.yml
main_pc-plan:  ## Plan inside WSL on main_pc
	mooncake plan -c ./main_pc.yml

mini_pc:       ## Apply inside WSL on mini_pc
	mooncake apply -c ./mini_pc.yml
mini_pc-plan:  ## Plan inside WSL on mini_pc
	mooncake plan -c ./mini_pc.yml

mac:           ## Apply on macOS
	mooncake apply -c ./mac.yml -K
mac-plan:      ## Plan on macOS
	mooncake plan -c ./mac.yml

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
