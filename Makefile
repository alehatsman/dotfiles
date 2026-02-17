.PHONY: help plan install install-work backup test-ubuntu

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

plan: ## Preview changes (dry-run)
	mooncake run -c main.yml -v personal_variables.yml --dry-run

install: ## Install dotfiles
	@if [ -f .sudo ]; then \
		mooncake run -c main.yml -v personal_variables.yml -s $$(cat .sudo) --insecure-sudo-pass; \
	else \
		mooncake run -c main.yml -v personal_variables.yml; \
	fi

install-work: ## Install with work config
	@if [ -f .sudo ]; then \
		mooncake run -c main.yml -v work_variables.yml -s $$(cat .sudo) --insecure-sudo-pass; \
	else \
		mooncake run -c main.yml -v work_variables.yml; \
	fi

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
		mooncake run -c main.yml -v personal_variables.yml --dry-run"

install-tag: ## Install with specific tag
	@if [ -f .sudo ]; then \
		mooncake run -c main.yml -v personal_variables.yml -s $$(cat .sudo) --insecure-sudo-pass --tags $(TAG); \
	else \
		mooncake run -c main.yml -v personal_variables.yml --tags $(TAG); \
	fi
