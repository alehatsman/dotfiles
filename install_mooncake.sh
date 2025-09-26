#!/usr/bin/env bash
set -euo pipefail

# Target binary location
MOONCAKE_BIN="/usr/local/bin/mooncake"
MOONCAKE_URL="https://github.com/alehatsman/mooncake/releases/download/latest/mooncake-linux-amd64"

# Check if Mooncake is already installed
if command -v mooncake >/dev/null 2>&1; then
    echo "Mooncake is already installed at $(command -v mooncake)"
    exit 0
fi

echo "Downloading Mooncake..."
curl -L -o /tmp/mooncake "$MOONCAKE_URL"

echo "Moving binary to /usr/local/bin..."
sudo mv /tmp/mooncake "$MOONCAKE_BIN"

echo "Setting executable permissions..."
sudo chmod +x "$MOONCAKE_BIN"

# Verify installation
echo "Installed Mooncake version:"
"$MOONCAKE_BIN" --version || echo "Mooncake installed successfully, but --version returned nothing"

echo "Done!"
