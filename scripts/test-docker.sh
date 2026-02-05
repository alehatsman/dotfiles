#!/bin/bash

# Default to Ubuntu 22.04 if no OS specified
OS="${1:-ubuntu:22.04}"

echo "Testing dotfiles in Docker container: $OS"

docker run --rm -v $(pwd):/dotfiles -w /dotfiles $OS bash -c "
  # Update package manager
  if command -v apt-get &> /dev/null; then
    apt-get update && apt-get install -y curl git
  elif command -v apk &> /dev/null; then
    apk add --no-cache curl git bash
  fi

  # Install mooncake
  curl -sSL https://raw.githubusercontent.com/alehatsman/mooncake/main/install.sh | bash
  export PATH=\$PATH:/root/.local/bin

  # Run dry-run
  echo 'Running mooncake dry-run...'
  mooncake run -c main.yml -v personal_variables.yml --dry-run

  echo 'Docker test completed successfully!'
"
