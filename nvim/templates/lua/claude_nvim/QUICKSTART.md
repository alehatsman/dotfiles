# Quick Start Guide

## 1. Install

Add to your lazy.nvim plugin config:

```lua
-- In your plugins directory (e.g., lua/plugins/claude.lua)
return {
  "claude_nvim",
  dir = vim.fn.expand("~/.config/nvim/lua/claude_nvim"),
  dependencies = { "ibhagwan/fzf-lua" },
  config = function()
    require("claude_nvim").setup()
  end,
  lazy = false,
}
```

Restart Neovim or run `:Lazy sync`.

## 2. Verify Installation

1. Check Claude CLI is available:
   ```bash
   claude --help
   ```

2. Open Neovim - a session should auto-start:
   ```
   nvim
   ```

   You should see: `Claude session started: 3f8a9c2d`

## 3. Open Chat

Press `<Space>cw` to open the session picker, then select your session.

A chat buffer opens in a vertical split.

## 4. Send a Message

1. Type your message after the `>> ` prompt
2. Press `<CR>` in normal mode to send
3. Claude's response streams into the buffer

Example:
```
>> What is the capital of France?
```

Press `<CR>` and wait for response.

## 5. Send Context

Open a file you want Claude to see, then press `<Space>cc` in the chat buffer to send its context.

Or use commands:
```vim
:ClaudeContextBuffer       " Send current file
:ClaudeContextAllBuffers   " Send all open files
```

## 6. Multiple Sessions

Press `<Space>cw`, then select "New session…" to create another Claude session with a different model.

## 7. Troubleshooting

Check logs if something breaks:
```bash
ls -la .git/.claude-nvim/logs/
tail -f .git/.claude-nvim/logs/<session-id>.log
```

## Common Keybindings

**Global:**
- `<Space>cw` - Open session picker

**In chat buffer:**
- `<CR>` - Send message
- `<Space>cc` - Send current buffer context
- `<Space>cs` - Send selection (visual mode)
- `<Space>ca` - Send all buffers context
- `q` - Close window

## Tips

- Chat buffers persist hidden when closed (press `q`)
- Use `:ClaudeSessions` to switch between sessions
- Session IDs are UUIDs - first 8 chars shown in picker
- Each session is independent with its own model and context

That's it! You're ready to code with Claude in Neovim.
