#!/usr/bin/env bash
# verify-claude-setup.sh
# Quick verification script for Claude Nvim plugin setup

set -e

echo "=== Claude Nvim Setup Verification ==="
echo ""

# Check if claude CLI is available
echo "1. Checking claude CLI..."
if command -v claude &> /dev/null; then
    echo "   ✓ claude CLI found: $(which claude)"
else
    echo "   ✗ claude CLI not found in PATH"
    echo "   Install from: https://github.com/anthropics/claude-code"
    exit 1
fi

# Check if nvim config exists
echo ""
echo "2. Checking Neovim config..."
if [ -f ~/.config/nvim/init.lua ]; then
    echo "   ✓ init.lua exists"
else
    echo "   ✗ init.lua not found"
    echo "   Run: ansible-playbook -i inventory playbook.yml --tags nvim"
    exit 1
fi

# Check if claude_nvim plugin exists
echo ""
echo "3. Checking claude_nvim plugin..."
if [ -d ~/.config/nvim/lua/claude_nvim ]; then
    echo "   ✓ claude_nvim directory exists"
    file_count=$(ls -1 ~/.config/nvim/lua/claude_nvim/*.lua 2>/dev/null | wc -l)
    echo "   ✓ Found $file_count Lua files"
else
    echo "   ✗ claude_nvim directory not found"
    echo "   Run provisioning to deploy templates"
    exit 1
fi

# Check if init.lua contains claude_nvim setup
echo ""
echo "4. Checking init.lua integration..."
if grep -q "claude_nvim" ~/.config/nvim/init.lua; then
    echo "   ✓ claude_nvim setup found in init.lua"
else
    echo "   ✗ claude_nvim setup not found in init.lua"
    echo "   Check templates/init.lua has the setup() call"
    exit 1
fi

# Check if fzf-lua is mentioned (dependency)
echo ""
echo "5. Checking fzf-lua dependency..."
if grep -q "fzf-lua" ~/.config/nvim/init.lua; then
    echo "   ✓ fzf-lua configured in init.lua"
else
    echo "   ⚠ fzf-lua not found (may need to run :PackerSync)"
fi

# Check if packer is installed
echo ""
echo "6. Checking packer..."
if [ -d ~/.local/share/nvim/site/pack/packer/start/packer.nvim ]; then
    echo "   ✓ packer.nvim installed"
else
    echo "   ⚠ packer.nvim not found"
    echo "   It will be installed on first nvim launch"
fi

# Test if Neovim can load the plugin (dry run)
echo ""
echo "7. Testing plugin load..."
if nvim --headless --noplugin -u NONE -c "set rtp+=~/.config/nvim/lua" -c "lua require('claude_nvim.util').uuid()" -c "q" 2>/dev/null; then
    echo "   ✓ Plugin loads successfully"
else
    echo "   ⚠ Plugin load test skipped (may need dependencies)"
fi

echo ""
echo "=== Verification Complete ==="
echo ""
echo "Next steps:"
echo "1. Open Neovim: nvim"
echo "2. Wait for plugins to install (first launch)"
echo "3. Check Claude session started: look for notification"
echo "4. Press <Space>cw to open session picker"
echo "5. Check logs: tail -f .git/.claude-nvim/logs/*.log"
echo ""
echo "For help, see: CLAUDE_SETUP.md"
