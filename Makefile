.PHONY: help plan install backup test-ubuntu install-wsl install-tag

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

plan: ## Preview changes (mooncake plan)
	mooncake plan -c main.yml -v variables.yml

install: ## Install dotfiles
	mooncake apply -c main.yml -v variables.yml -K

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

test-ubuntu: ## Test in Ubuntu Docker
	docker run --rm -v $$(pwd):/dotfiles -w /dotfiles ubuntu:22.04 bash -c "\
		apt-get update && apt-get install -y curl git && \
		curl -sSL https://raw.githubusercontent.com/alehatsman/mooncake/main/install.sh | bash && \
		export PATH=\$$PATH:/root/.local/bin && \
		mooncake plan -c main.yml -v variables.yml"

install-wsl: ## Install on a WSL2 machine (set is_wsl=true in variables.yml)
	mooncake apply -c main.yml -v variables.yml -K --tags wsl

install-tag: ## Install with specific tag (TAG=...)
	mooncake apply -c main.yml -v variables.yml -K --tags $(TAG) --raw
