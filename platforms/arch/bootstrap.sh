#!/usr/bin/env bash
# First-boot bootstrap — run once after a fresh Arch install
# Clones dotfiles, installs mooncake, and runs the full setup
set -euo pipefail

DOTFILES_REPO="https://github.com/alehatsman/dotfiles"
DOTFILES_DIR="$HOME/dotfiles"

info() { printf '\n\e[1;34m==> %s\e[0m\n' "$*"; }

info "Installing git and curl..."
echo "${SUDO_PASS:-}" | sudo -S pacman -S --noconfirm --needed git curl 2>/dev/null || \
  sudo pacman -S --noconfirm --needed git curl

info "Cloning dotfiles..."
if [[ -d "$DOTFILES_DIR" ]]; then
  echo "Already exists at $DOTFILES_DIR — pulling latest"
  git -C "$DOTFILES_DIR" pull
else
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi
cd "$DOTFILES_DIR"

info "Installing mooncake..."
sh scripts/install_mooncake.sh

# install_mooncake.sh installs to ~/.local/bin, which a fresh Arch login
# shell has no reason to have on PATH yet (components/zsh puts it there,
# but that only lands after the apply below).
export PATH="$HOME/.local/bin:$PATH"

info "Running full setup..."
# x1 is the Arch machine. -K prompts once for sudo (pacman, systemd
# units, /etc writes). Preview first with: mooncake plan -c ./x1.yml
mooncake apply -c ./x1.yml -K

info "Done! Restart your shell or run: exec zsh"
