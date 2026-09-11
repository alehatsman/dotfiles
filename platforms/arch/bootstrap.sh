#!/usr/bin/env bash
# First-boot bootstrap — run once after a fresh Arch install
# Clones dotfiles and runs the full setup
set -euo pipefail

DOTFILES_REPO="https://github.com/alehatsman/dotfiles"
DOTFILES_DIR="$HOME/dotfiles"

info() { printf '\n\e[1;34m==> %s\e[0m\n' "$*"; }
die()  { printf '\e[1;31mERROR: \e[0m%s\n' "$*" >&2; exit 1; }

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

# `provision` (https://github.com/alehatsman/provision) must already be on
# PATH — this repo has no bootstrap installer for it (README's own
# from-nothing flow makes the same assumption).
command -v provision >/dev/null 2>&1 || \
  die "provision not found on PATH — install it first, see https://github.com/alehatsman/provision"

info "Running full setup..."
# x1 is the Arch machine. --ask-sudo-pass prompts once for sudo (pacman,
# systemd units, /etc writes). Preview first with: provision plan ./x1.yml
provision apply ./x1.yml --ask-sudo-pass

info "Done! Restart your shell or run: exec zsh"
