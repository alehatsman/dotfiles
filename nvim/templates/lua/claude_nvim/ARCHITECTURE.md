# Architecture Overview

## High-Level Design

```
┌─────────────────────────────────────────────────────────┐
│                    Neovim (UI Layer)                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Chat Buffer  │  │  fzf-lua     │  │  Commands    │  │
│  │ (markdown)   │  │  Pickers     │  │  & Keymaps   │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         │                 │                 │           │
│         └─────────────────┴─────────────────┘           │
│                           │                             │
└───────────────────────────┼─────────────────────────────┘
                            │
┌───────────────────────────┼─────────────────────────────┐
│                  Plugin Core (Lua)                      │
│  ┌────────────────────────▼───────────────────────┐    │
│  │           Session Registry (proc.lua)          │    │
│  │  { session_id -> { job_id, model, bufnr, ... }}│    │
│  └────────────┬───────────────────────┬───────────┘    │
│               │                       │                 │
│     ┌─────────▼─────────┐   ┌────────▼────────┐        │
│     │   I/O Handler     │   │  Context Builder│        │
│     │  (NDJSON parse)   │   │  (paths/temps)  │        │
│     └─────────┬─────────┘   └─────────────────┘        │
└───────────────┼─────────────────────────────────────────┘
                │
┌───────────────▼─────────────────────────────────────────┐
│              Claude CLI Process (Job)                   │
│  claude --session-id UUID --model MODEL                 │
│         --input-format=stream-json                      │
│         --output-format=stream-json                     │
│                                                          │
│  stdin  ◄── {"type":"user","content":"..."}             │
│  stdout ──► {"type":"assistant","content":"..."}        │
│  stderr ──► (logged to .claude-nvim/logs/)              │
└──────────────────────────────────────────────────────────┘
```

## Module Responsibilities

### init.lua (Entry Point)
- **Setup**: Initialize plugin with user config
- **Autocommands**: VimEnter auto-start
- **Commands**: Register `:ClaudeContext*` commands
- **Keymaps**: Global `<Space>cw` binding

**Key Functions**:
- `setup(opts)` - Initialize plugin
- `setup_commands()` - Register user commands
- `setup_keymaps()` - Register global keymaps
- `get_current_session_id()` - Heuristic to find active session

### proc.lua (Process Manager)
- **Session Registry**: Maintain `sessions` table
- **Job Management**: Spawn/stop Claude processes
- **I/O Handling**: Parse NDJSON stdout, send stdin
- **Lifecycle**: Handle process exit, mark sessions dead

**Key Functions**:
- `spawn_session(opts)` - Create new Claude process
- `send_message(session_id, content)` - Send user message to stdin
- `on_stdout(session_id, data)` - Parse and handle output
- `on_exit(session_id, exit_code)` - Mark session dead
- `list_sessions()` - Get all sessions for picker

**Session Object**:
```lua
{
  session_id = "uuid-v4",
  model = "sonnet"|"opus"|"haiku",
  cwd = "/path/to/project",
  job_id = 12345,
  bufnr = 42,
  alive = true,
  log_path = ".git/.claude-nvim/logs/uuid.log",
  stdout_buf = "", -- buffered partial NDJSON
  stdin = function(data) ... end,
}
```

### ui.lua (User Interface)
- **Chat Buffer**: Create/manage `claude://` buffers
- **Pickers**: fzf-lua session and model selection
- **Message Display**: Append streaming content
- **Keymaps**: Buffer-local bindings in chat

**Key Functions**:
- `open_chat(session_id)` - Open or show chat buffer
- `append_to_chat(bufnr, text)` - Non-blocking append
- `setup_chat_keymaps(bufnr, session_id)` - Set buffer keymaps
- `send_current_line(bufnr, session_id)` - Send `>> ` line
- `show_session_picker()` - fzf-lua session list
- `show_model_picker()` - fzf-lua model selection

**Chat Buffer**:
- Name: `claude://<session-id>`
- Type: `buftype=nofile`, `bufhidden=hide`
- Filetype: `markdown`
- Modifiable: `true` (user can type)

### context.lua (Context Injection)
- **Buffer Context**: Send file path references
- **Selection Context**: Inline code or temp file
- **All Buffers**: List of open file paths

**Key Functions**:
- `send_buffer_context(session_id, bufnr, line_range)`
- `send_selection_context(session_id)`
- `send_all_buffers_context(session_id, opts)`

**Context Format**:
```
Context: /path/to/file.lua (lines 10-20)

```
or
```
Context: All open buffers
- /path/to/file1.lua (50 lines)
- /path/to/file2.py (120 lines)
```

### util.lua (Utilities)
- **UUID**: Generate v4 UUIDs for session IDs
- **Root Detection**: Find git root or use cwd
- **Logging**: Append timestamped logs to files
- **JSON Parsing**: NDJSON frame extraction

**Key Functions**:
- `uuid()` - Generate random UUID v4
- `find_root(path)` - Find git root
- `get_log_path(session_id, cwd)` - Log file location
- `log_to_file(path, msg)` - Append with timestamp
- `parse_ndjson(buffer)` - Extract complete JSON lines
- `encode_message(type, content)` - Build NDJSON stdin

## Data Flow

### Session Startup
```
User opens Neovim
    ↓
VimEnter autocmd fires
    ↓
proc.spawn_session()
    ↓
vim.fn.jobstart(["claude", ...])
    ↓
Session registered in proc.sessions
    ↓
Notification: "Claude session started: abc123"
```

### Sending a Message
```
User types ">> hello" and presses <CR>
    ↓
ui.send_current_line() extracts "hello"
    ↓
proc.send_message(session_id, "hello")
    ↓
util.encode_message("user", "hello")
    ↓
{"type":"user","content":"hello"}\n → stdin
    ↓
Log: TX: {"type":"user","content":"hello"}
```

### Receiving a Response
```
Claude process writes to stdout
    ↓
on_stdout callback receives data chunks
    ↓
Accumulate in session.stdout_buf
    ↓
util.parse_ndjson(stdout_buf)
    ↓
Decoded: [{type:"assistant", content:"Hi!"}]
    ↓
proc.handle_message()
    ↓
ui.append_to_chat(bufnr, "Hi!")
    ↓
User sees: "Hi!" in chat buffer
    ↓
Log: RX: {type="assistant", content="Hi!"}
```

### Context Injection
```
User presses <Space>cc in chat
    ↓
context.send_buffer_context(session_id)
    ↓
Get current buffer filepath
    ↓
Build message: "Context: /path/to/file.lua"
    ↓
proc.send_message(session_id, message)
    ↓
{"type":"user","content":"Context: ..."}\n → stdin
    ↓
Claude can now read the file via --add-dir
```

## Error Handling

### Process Exit
- `on_exit()` marks session as `alive=false`
- Appends "[Session ended]" to chat buffer
- User can create new session via `<Space>cw`

### Parse Errors
- Failed `vim.json.decode` is caught with `pcall`
- Logged to session log file
- Doesn't crash UI

### Invalid Commands
- Commands check `get_current_session_id()` first
- Notify user if no active session
- Graceful degradation

### Job Start Failure
- `jobstart()` returns <= 0 on failure
- Log error and notify user
- Don't register session

## Concurrency Model

- **Non-blocking I/O**: `stdout_buffered=false`
- **vim.schedule()**: All buffer modifications in callbacks
- **No busy-wait**: Event-driven via callbacks
- **Multiple sessions**: Independent processes, no shared state

## Security Considerations

- **No eval**: Never execute user input as code
- **Temp files**: Use `vim.fn.tempname()` for safe paths
- **File checks**: Validate `claude://` prefix to avoid conflicts
- **Log isolation**: Logs in `.git/` or `.claude-nvim/` (not sensitive)

## Performance

- **Lazy buffer loading**: Buffers created on demand
- **Efficient NDJSON parsing**: Only complete lines processed
- **No polling**: Callbacks trigger on data arrival
- **Log rotation**: Not implemented (consider for long sessions)

## Extension Points

### Custom Commands
- Add new `:ClaudeContext*` commands in user config
- Call `proc.send_message()` with custom format

### Custom Pickers
- Replace `fzf-lua` with Telescope or native `vim.ui.select`
- Implement own picker calling `proc.list_sessions()`

### Alternative Models
- Modify `ui.show_model_picker()` to add custom models
- Or override in user config

### Session Persistence
- Not implemented (sessions die with process)
- Could add: save chat history to `.claude-nvim/history/`
- Could add: restore session on Neovim restart

## Testing Strategy

### Manual Testing
```lua
-- Spawn session
local proc = require("claude_nvim.proc")
local s = proc.spawn_session({model="haiku"})

-- Check session
vim.print(s)

-- Send message
proc.send_message(s.session_id, "test")

-- Check logs
:!tail .git/.claude-nvim/logs/*.log

-- Open UI
require("claude_nvim.ui").open_chat(s.session_id)

-- Test context
:ClaudeContextBuffer
```

### Unit Testing (Future)
- Mock `vim.fn.jobstart` to test process logic
- Mock `vim.api` for buffer operations
- Test NDJSON parsing with edge cases

## Future Enhancements

- [ ] Persistent chat history
- [ ] Session resume after Neovim restart
- [ ] Inline code edits (apply diffs)
- [ ] Telescope.nvim picker alternative
- [ ] Statusline integration (show active session)
- [ ] Multi-model comparison (side-by-side)
- [ ] Token usage tracking
- [ ] Export chat to markdown
- [ ] Session sharing (export/import)
- [ ] Vim9script port (for wider compatibility)

---

**Plugin Size**: ~500 LOC
**Dependencies**: fzf-lua only
**Neovim Version**: 0.9+
**License**: MIT
