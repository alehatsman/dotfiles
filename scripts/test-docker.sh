#!/bin/bash

# Default to Ubuntu 22.04 if no OS specified
OS="${1:-ubuntu:22.04}"

echo "Testing dotfiles in Docker container: $OS"

docker run --rm -v $(pwd):/dotfiles -w /dotfiles $OS bash -c "
  # Update package manager
  if command -v apt-get &> /dev/null; then
    apt-get update && apt-get install -y curl git tar
  elif command -v apk &> /dev/null; then
    apk add --no-cache curl git bash tar
  fi

  # Install mooncake via this repo's own installer — handles OS/arch
  # detection and falls back to building from source when the latest
  # release lags main (see scripts/install_mooncake.sh).
  sh scripts/install_mooncake.sh
  export PATH=\$PATH:/root/.local/bin

  # Smoke-test the WSL entry's plan (closest to a vanilla Ubuntu container).
  # main_pc.yml self-loads its own vars (shared/variables.yml +
  # machines/main_pc/vars.yml) via vars.load — no -v flags needed.
  echo 'Running mooncake plan for main_pc.yml...'
  mooncake plan -c main_pc.yml

  echo 'Docker test completed successfully!'
"
