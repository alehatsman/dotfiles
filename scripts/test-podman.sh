#!/bin/bash

# Default to Ubuntu 22.04 if no OS specified
OS="${1:-ubuntu:22.04}"

echo "Testing dotfiles in Podman container: $OS"

podman run --rm -v $(pwd):/dotfiles -w /dotfiles $OS bash -c "
  # Update package manager
  if command -v apt-get &> /dev/null; then
    apt-get update && apt-get install -y curl git tar
  elif command -v apk &> /dev/null; then
    apk add --no-cache curl git bash tar
  fi

  # provision must already be on PATH inside the image — this repo has no
  # bootstrap installer for it.
  command -v provision >/dev/null 2>&1 || { echo 'provision not found on PATH — build/install it into the test image first' >&2; exit 1; }

  # Smoke-test the WSL entry's plan (closest to a vanilla Ubuntu container).
  # main_pc.yml self-loads its own vars (shared/variables.yml +
  # machines/main_pc/vars.yml) via vars.load — no -v flags needed.
  echo 'Running provision plan for main_pc.yml...'
  provision plan --plan-no-probe main_pc.yml

  echo 'Podman test completed successfully!'
"
