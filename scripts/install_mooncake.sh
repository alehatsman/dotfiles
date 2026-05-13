#!/usr/bin/env bash
set -euo pipefail

# Target binary location
MOONCAKE_BIN="/usr/local/bin/mooncake"
MOONCAKE_URL="https://github.com/alehatsman/mooncake/releases/latest/download/mooncake_Linux_x86_64.tar.gz"

# Check if Mooncake is already installed
if command -v mooncake >/dev/null 2>&1; then
    echo "Mooncake is already installed at $(command -v mooncake)"
    exit 0
fi

echo "Downloading Mooncake..."
curl -L -o /tmp/mooncake.tar.gz "$MOONCAKE_URL"

echo "Extracting..."
tar -xzf /tmp/mooncake.tar.gz -C /tmp mooncake
rm /tmp/mooncake.tar.gz

echo "Moving binary to /usr/local/bin..."
echo "${SUDO_PASS:-}" | sudo -S mv /tmp/mooncake "$MOONCAKE_BIN" 2>/dev/null || \
  sudo mv /tmp/mooncake "$MOONCAKE_BIN"

echo "Setting executable permissions..."
echo "${SUDO_PASS:-}" | sudo -S chmod +x "$MOONCAKE_BIN" 2>/dev/null || \
  sudo chmod +x "$MOONCAKE_BIN"

# Verify installation
echo "Installed Mooncake version:"
"$MOONCAKE_BIN" --version || echo "Mooncake installed successfully, but --version returned nothing"

echo "Done!"
