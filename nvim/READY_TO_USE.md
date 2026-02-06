# ✅ Claude Nvim Plugin - Ready to Use!

## Current Status

**Plugin**: ✅ Installed and working
**Dependencies**: ✅ fzf-lua installed
**Configuration**: ✅ Properly integrated
**Provisioning**: ✅ Fixed for future deployments
**Test Result**: ✅ Session auto-started (cb9c1a5b)

---

## Quick Start (Right Now!)

### 1. Open Neovim
```bash
nvim
```

You should see: `Claude session started: abc12345`

### 2. Open Session Picker
Press `<Space>cw` (space + c + w)

You'll see:
```
Claude Sessions>
  ✓ [sonnet] abc12345 - /Users/alehatsman/Projects/dotfiles
  New session…
```

### 3. Select Your Session
- Arrow keys to navigate
- Enter to select
- Chat buffer opens in right split

### 4. Send a Message
```
>> What files are in this project?
```

Press `<CR>` (Enter) and watch Claude respond!

---

## Keyboard Shortcuts

### Global (anywhere in nvim)
| Key | Action |
|-----|--------|
| `<Space>cw` | Open session picker |

### In Chat Buffer
| Key | Action |
|-----|--------|
| `<CR>` | Send message (on `>> ` line) |
| `<Space>cc` | Send current buffer context |
| `<Space>cs` | Send visual selection (visual mode) |
| `<Space>ca` | Send all open buffers |
| `q` | Close chat window |

---

## Commands

```vim
:ClaudeSessions              " Open session picker
:ClaudeContextBuffer         " Send current file
:ClaudeContextSelection      " Send visual selection
:ClaudeContextAllBuffers     " Send all open files
```

---

## Example Workflow

```bash
# 1. Start nvim in your project
cd ~/Projects/myproject
nvim

# 2. Open a file
:e src/main.go

# 3. Send file to Claude
<Space>cc

# 4. Ask a question in chat
>> Can you explain this code?
<CR>

# 5. Watch Claude analyze and respond!
```

---

## Checking Logs

If something goes wrong:

```bash
# Find your session ID
ls .git/.claude-nvim/logs/

# Tail logs
tail -f .git/.claude-nvim/logs/<session-id>.log
```

Logs show:
- All messages sent (TX)
- All responses received (RX)
- Parse errors
- Process status

---

## Creating Multiple Sessions

Want to compare different models?

1. Press `<Space>cw`
2. Select "New session…"
3. Choose model: sonnet / opus / haiku
4. New session starts!

Each session is independent with its own:
- Model
- Conversation history
- Log file
- Chat buffer

---

## Provisioning for Future

The provisioning is now fixed! To redeploy in the future:

```bash
# From dotfiles root
cd ~/Projects/dotfiles

# Deploy everything
make install

# Or just nvim
mooncake run -c nvim-only.yml -v personal_variables.yml
```

Directory structure is preserved automatically.

---

## Documentation

Comprehensive docs in your config:

```bash
# Full documentation
cat ~/.config/nvim/lua/claude_nvim/README.md

# Quick start guide
cat ~/.config/nvim/lua/claude_nvim/QUICKSTART.md

# Advanced integration
cat ~/.config/nvim/lua/claude_nvim/INTEGRATION.md

# Architecture details
cat ~/.config/nvim/lua/claude_nvim/ARCHITECTURE.md
```

Or in the source:
```bash
cd ~/Projects/dotfiles/nvim
ls templates/lua/claude_nvim/*.md
```

---

## Customization

Edit `~/Projects/dotfiles/nvim/templates/init.lua`:

```lua
require("claude_nvim").setup({
  auto_start = false,       -- Disable auto-start
  default_model = "opus",   -- Change default model
})
```

Then redeploy:
```bash
mooncake run -c nvim-only.yml -v personal_variables.yml
```

---

## What's Working

✅ Auto-spawn session on startup
✅ Session picker with fzf-lua
✅ Streaming chat in split
✅ Context injection (files, selections, all buffers)
✅ Multiple concurrent sessions
✅ Per-session debug logs
✅ Robust error handling
✅ Non-blocking UI

---

## Support

**Having issues?**

1. Run verification: `./verify-claude-setup.sh`
2. Check logs: `tail -f .git/.claude-nvim/logs/*.log`
3. Test manually: `:lua require("claude_nvim.proc").list_sessions()`
4. Read troubleshooting: `CLAUDE_SETUP.md`

**Working great?**

Enjoy coding with Claude in Neovim! 🚀

---

**Last Updated**: 2026-02-06
**Plugin Version**: 1.0
**Verified Working**: ✅ Yes

Happy coding! 👨‍💻
