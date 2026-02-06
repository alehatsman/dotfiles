# Integration Examples

## Integrating into Your Neovim Config

### Option 1: Direct in init.lua

If your config structure is a single `init.lua`:

```lua
-- init.lua
require("claude_nvim").setup({
  auto_start = true,
  default_model = "sonnet",
})
```

### Option 2: Lazy.nvim plugin spec

Create `lua/plugins/claude.lua`:

```lua
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

### Option 3: Custom keymap prefix

Override the default `<Space>cw` keymap:

```lua
require("claude_nvim").setup({
  auto_start = true,
  default_model = "opus",
})

-- Override default keymap
vim.keymap.del("n", "<Space>cw")
vim.keymap.set("n", "<leader>cc", function()
  require("claude_nvim.ui").show_session_picker()
end, { desc = "Claude Chat" })
```

### Option 4: Disable auto-start

If you prefer to manually start sessions:

```lua
require("claude_nvim").setup({
  auto_start = false,
})

-- Start session manually with your own command
vim.api.nvim_create_user_command("ClaudeStart", function()
  local proc = require("claude_nvim.proc")
  local ui = require("claude_nvim.ui")
  local session = proc.spawn_session({
    model = "sonnet",
    cwd = vim.fn.getcwd(),
  })
  if session then
    ui.open_chat(session.session_id)
  end
end, {})
```

## Custom Context Commands

Add your own context injection patterns:

```lua
-- Send only changed files (git diff)
vim.api.nvim_create_user_command("ClaudeContextGitDiff", function()
  local changed_files = vim.fn.systemlist("git diff --name-only")
  local context = "Context: Changed files\n" .. table.concat(changed_files, "\n")

  local session_id = require("claude_nvim").get_current_session_id()
  if session_id then
    require("claude_nvim.proc").send_message(session_id, context)
  end
end, {})

-- Send only files in current directory
vim.api.nvim_create_user_command("ClaudeContextLocalFiles", function()
  local files = vim.fn.globpath(".", "*.{lua,py,js,ts}", false, true)
  local context = "Context: Local files\n" .. table.concat(files, "\n")

  local session_id = require("claude_nvim").get_current_session_id()
  if session_id then
    require("claude_nvim.proc").send_message(session_id, context)
  end
end, {})
```

## Custom Keybindings

### Which-key.nvim integration

```lua
local wk = require("which-key")

wk.register({
  ["<leader>c"] = {
    name = "Claude",
    w = { "<cmd>lua require('claude_nvim.ui').show_session_picker()<cr>", "Pick session" },
    c = { "<cmd>ClaudeContextBuffer<cr>", "Context: buffer" },
    s = { "<cmd>ClaudeContextSelection<cr>", "Context: selection" },
    a = { "<cmd>ClaudeContextAllBuffers<cr>", "Context: all" },
  },
})
```

### Custom chat buffer keymaps

Modify `ui.lua` or override after setup:

```lua
-- Add custom keymap to all claude buffers
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "claude://*",
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()

    -- Add custom keymap: <C-c> to copy last response
    vim.keymap.set("n", "<C-c>", function()
      -- Your custom logic
    end, { buffer = bufnr })
  end,
})
```

## Model Selection

### Per-project model configuration

Create `.nvim.lua` in project root:

```lua
-- .nvim.lua (load with exrc)
vim.g.claude_project_model = "opus"

-- Override auto-start to use project model
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local model = vim.g.claude_project_model or "sonnet"
    local proc = require("claude_nvim.proc")
    proc.spawn_session({ model = model })
  end,
  once = true,
})
```

## Advanced: Session Management

### Auto-restart dead sessions

```lua
-- Auto-restart if session dies
local function setup_auto_restart()
  local proc = require("claude_nvim.proc")

  vim.api.nvim_create_autocmd("User", {
    pattern = "ClaudeSessionExit",
    callback = function(ev)
      local session_id = ev.data.session_id
      local session = proc.sessions[session_id]

      vim.notify("Session died, restarting...", vim.log.levels.WARN)

      -- Respawn with same config
      proc.spawn_session({
        model = session.model,
        cwd = session.cwd,
      })
    end,
  })
end
```

### Session cleanup on exit

```lua
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    local proc = require("claude_nvim.proc")
    for sid, sess in pairs(proc.sessions) do
      if sess.alive then
        proc.stop_session(sid)
      end
    end
  end,
})
```

## Debugging

### Enable verbose logging

Modify `util.lua` to add more logging:

```lua
-- In proc.lua, add logging for all messages
function M.send_message(session_id, content)
  local session = M.sessions[session_id]
  if not session or not session.alive then
    util.log_to_file(session.log_path, "ERROR: Cannot send, session not alive")
    return
  end

  util.log_to_file(session.log_path, "SEND: " .. content)
  -- ... rest of function
end
```

### Inspect session state

```lua
:lua vim.print(require("claude_nvim.proc").sessions)
```

## Testing

### Manual test workflow

```lua
-- Test session spawn
:lua local proc = require("claude_nvim.proc")
:lua local s = proc.spawn_session({model="haiku"})
:lua print(s.session_id)

-- Test message send
:lua proc.send_message(s.session_id, "Hello")

-- Test UI
:lua require("claude_nvim.ui").open_chat(s.session_id)

-- Check logs
:!tail -f .git/.claude-nvim/logs/*.log
```

---

For more examples, see the README.md and source code.
