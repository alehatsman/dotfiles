# Claude Nvim Plugin - Provisioning Integration

## Overview

The Claude Nvim plugin has been integrated into your Ansible-based Neovim provisioning system.

## What Was Done

### 1. Plugin Files Added
```
templates/lua/claude_nvim/
├── init.lua              # Main plugin entry point
├── proc.lua              # Process management
├── ui.lua                # UI and chat buffers
├── context.lua           # Context injection
├── util.lua              # Utilities
├── README.md             # Full documentation
├── QUICKSTART.md         # Quick start guide
├── INTEGRATION.md        # Integration examples
└── ARCHITECTURE.md       # Technical architecture
```

### 2. Init.lua Modified

**Added to packer plugins section** (line ~191):
```lua
use {
  'ibhagwan/fzf-lua',
  requires = { 'nvim-tree/nvim-web-devicons' },
}
```

**Added after bootstrap check** (line ~211):
```lua
require("claude_nvim").setup({
  auto_start = true,
  default_model = "sonnet",
})
```

## Deployment Workflow

When you run your Ansible provisioning:

```bash
# Deploy nvim config (from dotfiles root)
ansible-playbook -i inventory playbook.yml --tags nvim
```

This will:
1. Create `~/.config/nvim/` directory structure
2. Copy `templates/init.lua` → `~/.config/nvim/init.lua`
3. Copy `templates/lua/` → `~/.config/nvim/lua/` (including claude_nvim)
4. Install packer if not present
5. Run `PackerSync` to install all plugins including fzf-lua
6. Initialize Claude Nvim on first Neovim launch

## File Paths After Provisioning

```
~/.config/nvim/
├── init.lua                          # Main config
├── lua/
│   └── claude_nvim/
│       ├── init.lua
│       ├── proc.lua
│       ├── ui.lua
│       ├── context.lua
│       ├── util.lua
│       └── docs...
├── autoload/                         # Packer autoload
├── undodir/                          # Undo history
├── after/                            # After configs
└── ftplugin/                         # Filetype configs
```

## Usage After Deployment

### First Launch
1. Open Neovim: `nvim`
2. Packer will install plugins (including fzf-lua)
3. Claude session auto-starts
4. You'll see: `Claude session started: abc12345`

### Open Chat
Press `<Space>cw` to see the session picker, then select your session.

### Send Messages
In the chat buffer, type after `>> ` and press `<CR>` to send.

### Context Commands
- `:ClaudeContextBuffer` - Send current file
- `:ClaudeContextSelection` - Send selection
- `:ClaudeContextAllBuffers` - Send all open files

### Keybindings (in chat buffer)
- `<CR>` - Send message
- `<Space>cc` - Context current buffer
- `<Space>cs` - Context selection (visual)
- `<Space>ca` - Context all buffers
- `q` - Close window

## Customization

To change default settings, edit `templates/init.lua`:

```lua
require("claude_nvim").setup({
  auto_start = true,          -- Set to false to disable auto-start
  default_model = "opus",     -- Change default model: sonnet, opus, haiku
})
```

## Verifying Installation

After provisioning, check:

```bash
# 1. Plugin files exist
ls ~/.config/nvim/lua/claude_nvim/

# 2. fzf-lua is installed
ls ~/.local/share/nvim/site/pack/packer/start/ | grep fzf-lua

# 3. Test in Neovim
nvim -c "lua print(vim.inspect(require('claude_nvim')))"
```

## Logs and Debugging

Session logs are stored:
- **With git**: `.git/.claude-nvim/logs/<session-id>.log`
- **Without git**: `.claude-nvim/logs/<session-id>.log`

Check logs:
```bash
tail -f .git/.claude-nvim/logs/*.log
```

## Prerequisites

Make sure `claude` CLI is installed:
```bash
# Check if claude is available
which claude

# Test claude
claude --help
```

If not installed, install Claude Code CLI from:
https://github.com/anthropics/claude-code

## Rollback

To remove the plugin:

1. Edit `templates/init.lua`:
   - Remove the fzf-lua `use` block
   - Remove the `require("claude_nvim").setup()` call

2. Re-run provisioning:
   ```bash
   ansible-playbook -i inventory playbook.yml --tags nvim
   ```

3. Clean up:
   ```bash
   rm -rf ~/.config/nvim/lua/claude_nvim
   rm -rf ~/.local/share/nvim/site/pack/packer/start/fzf-lua
   ```

## Next Steps

1. **Test the setup**:
   ```bash
   # Run provisioning
   cd ~/Projects/dotfiles
   ansible-playbook -i inventory playbook.yml --tags nvim

   # Open Neovim
   nvim

   # Press <Space>cw to open session picker
   ```

2. **Read the docs**:
   - `templates/lua/claude_nvim/README.md` - Full documentation
   - `templates/lua/claude_nvim/QUICKSTART.md` - Quick start
   - `templates/lua/claude_nvim/INTEGRATION.md` - Advanced integration

3. **Customize**:
   - Adjust keybindings in `templates/lua/claude_nvim/init.lua`
   - Change default model in `templates/init.lua`
   - Add custom context commands (see INTEGRATION.md)

## Troubleshooting

**"Session not alive"**:
- Check logs: `tail -f .git/.claude-nvim/logs/*.log`
- Verify `claude` is in PATH: `which claude`
- Try manual spawn: `:lua require("claude_nvim.proc").spawn_session({model="sonnet"})`

**"fzf-lua not found"**:
- Run `:PackerSync` in Neovim
- Check installation: `:PackerStatus`

**"No active Claude session"**:
- Create manually: `<Space>cw` → "New session…" → select model
- Or: `:lua require("claude_nvim.proc").spawn_session({})`

For more help, see the documentation in `templates/lua/claude_nvim/`.
