# claude_nvim

Minimal, robust Neovim integration for Claude Code using `fzf-lua`.

## Features

- **Automatic session spawning** on Neovim startup
- **Multiple concurrent sessions** with unique session IDs
- **Streaming chat interface** in vertical split
- **Context injection** for buffers, selections, and all open files
- **fzf-lua pickers** for session and model selection
- **Per-session debug logs** for troubleshooting
- **Non-blocking UI** with robust process management

## Requirements

- Neovim 0.9+
- `claude` CLI installed and in PATH
- [fzf-lua](https://github.com/ibhagwan/fzf-lua) plugin

## Installation

### lazy.nvim

```lua
{
  "claude_nvim",
  dir = "~/Projects/dotfiles/nvim/lua/claude_nvim",
  dependencies = { "ibhagwan/fzf-lua" },
  config = function()
    require("claude_nvim").setup({
      auto_start = true,      -- Auto-spawn session on VimEnter
      default_model = "sonnet", -- Default model: "sonnet", "opus", "haiku"
    })
  end,
}
```

### Manual

Add to your `init.lua`:

```lua
-- Add to runtimepath
vim.opt.runtimepath:append("~/Projects/dotfiles/nvim/lua")

require("claude_nvim").setup({
  auto_start = true,
  default_model = "sonnet",
})
```

## Usage

### Session Management

**Open session picker**: `<Space>cw`
- Lists all running sessions
- Select "New session…" to create a new one
- Choose existing session to open its chat buffer

**Commands**:
- `:ClaudeSessions` - Open session picker

### Chat Interface

When you open a session, a chat buffer opens in a vertical split:

**Send messages**:
1. Type after the `>> ` prompt
2. Press `<CR>` in normal mode to send

**Buffer keymaps** (in chat buffer):
- `<CR>` - Send current line (if starts with `>> `)
- `<Space>cc` - Send current buffer context
- `<Space>cs` - Send visual selection context (in visual mode)
- `<Space>ca` - Send all open buffers context
- `q` - Close chat window (buffer persists hidden)

### Context Injection

**Commands**:
- `:ClaudeContextBuffer` - Reference current file
- `:ClaudeContextSelection` - Reference visual selection
- `:ClaudeContextAllBuffers` - Reference all listed buffers (max 20 files, 5000 lines)

**Context format**:
- Sends file paths by default (Claude can read them with `--add-dir`)
- For unnamed/unsaved buffers, creates temp files
- Selection context includes inline code snippet

## How Session IDs Work

Each Claude session is identified by a UUID v4 (e.g., `3f8a9c2d-...`).

- Sessions are spawned with `claude --session-id <uuid>`
- Multiple sessions can run concurrently
- Session state persists as long as the Claude process is alive
- Chat buffers are named `claude://<session-id>`

## Troubleshooting

### Check logs

Session logs are stored at:
- **With git repo**: `.git/.claude-nvim/logs/<session-id>.log`
- **Without git**: `<cwd>/.claude-nvim/logs/<session-id>.log`

Logs contain:
- Process spawn command
- All stdin/stdout/stderr
- Parse errors
- Exit codes

### Common issues

**"Session not alive"**:
- The Claude process has exited
- Check the log file for error messages
- Try creating a new session

**"Failed to spawn Claude session"**:
- Ensure `claude` is installed: `which claude`
- Check Claude CLI is working: `claude --help`
- Verify PATH in Neovim: `:echo $PATH`

**Messages not appearing**:
- Check if process is alive: `:ClaudeSessions` (look for ✓)
- Review session log for parsing errors
- Try sending a simple message like "hello"

**fzf-lua not found**:
- Install fzf-lua: `Lazy install fzf-lua`
- Or with your plugin manager

### Debug mode

To see all JSON frames:

```bash
tail -f .git/.claude-nvim/logs/<session-id>.log
```

## Architecture

### Modules

- **init.lua** - Setup, commands, keymaps, autocommands
- **proc.lua** - Process spawning, session registry, I/O handling
- **ui.lua** - Chat buffer, fzf-lua pickers, keymaps
- **context.lua** - Context injection commands
- **util.lua** - UUID, JSON parsing, logging, root detection

### Claude CLI invocation

```bash
claude \
  --print \
  --input-format=stream-json \
  --output-format=stream-json \
  --include-partial-messages \
  --session-id <uuid> \
  --add-dir <project-root> \
  --model <sonnet|opus|haiku>
```

**Input format** (stdin, NDJSON):
```json
{"type": "user", "content": "Your message here"}
```

**Output format** (stdout, NDJSON):
```json
{"type": "assistant", "content": "Response text"}
{"type": "assistant", "content": " more text"}
```

### Session lifecycle

1. **Spawn**: `proc.spawn_session()` creates job with `vim.fn.jobstart()`
2. **I/O**: Stdout/stderr callbacks parse NDJSON frames
3. **Chat**: User types in buffer → `send_message()` → stdin
4. **Response**: Claude stdout → parse → append to buffer
5. **Exit**: Process dies → mark session dead → notify user

## License

MIT

## Contributing

This plugin is part of a personal dotfiles repo. Feel free to fork and adapt for your needs.
