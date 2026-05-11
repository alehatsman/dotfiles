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
bash install_mooncake.sh

info "Running full setup..."
mooncake run -c main.yml -v personal_variables.yml

info "Done! Restart your shell or run: exec zsh"
