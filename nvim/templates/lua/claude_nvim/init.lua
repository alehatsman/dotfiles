-- lua/claude_nvim/init.lua
-- Main entry point: setup, autocommands, commands, keymaps

local proc = require("claude_nvim.proc")
local ui = require("claude_nvim.ui")
local context = require("claude_nvim.context")

local M = {}

-- Plugin configuration
M.config = {
  auto_start = true, -- Auto-spawn session on VimEnter
  default_model = "sonnet",
}

-- Setup function
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend("force", M.config, opts)

  -- Auto-spawn session on VimEnter
  if M.config.auto_start then
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        -- Spawn one session for current directory
        local session = proc.spawn_session({
          model = M.config.default_model,
          cwd = vim.fn.getcwd(),
        })
        if session then
          vim.notify("Claude session started: " .. session.session_id:sub(1, 8), vim.log.levels.INFO)
        end
      end,
    })
  end

  -- Setup commands
  M.setup_commands()

  -- Setup global keymaps
  M.setup_keymaps()
end

-- Setup user commands
function M.setup_commands()
  -- :ClaudeContextBuffer
  vim.api.nvim_create_user_command("ClaudeContextBuffer", function(opts)
    -- Get current session (use first alive session or last created)
    local session_id = M.get_current_session_id()
    if not session_id then
      vim.notify("No active Claude session", vim.log.levels.WARN)
      return
    end
    context.send_buffer_context(session_id)
  end, { desc = "Send current buffer context to Claude" })

  -- :ClaudeContextSelection
  vim.api.nvim_create_user_command("ClaudeContextSelection", function(opts)
    local session_id = M.get_current_session_id()
    if not session_id then
      vim.notify("No active Claude session", vim.log.levels.WARN)
      return
    end
    context.send_selection_context(session_id)
  end, { range = true, desc = "Send visual selection context to Claude" })

  -- :ClaudeContextAllBuffers
  vim.api.nvim_create_user_command("ClaudeContextAllBuffers", function(opts)
    local session_id = M.get_current_session_id()
    if not session_id then
      vim.notify("No active Claude session", vim.log.levels.WARN)
      return
    end
    context.send_all_buffers_context(session_id)
  end, { desc = "Send all buffer contexts to Claude" })

  -- :ClaudeSessions
  vim.api.nvim_create_user_command("ClaudeSessions", function()
    ui.show_session_picker()
  end, { desc = "Show Claude session picker" })
end

-- Setup global keymaps
function M.setup_keymaps()
  -- <Space>cw: Open session picker
  vim.keymap.set("n", "<Space>cw", function()
    ui.show_session_picker()
  end, { noremap = true, silent = true, desc = "Claude: Pick session" })
end

-- Get current session ID (heuristic: first alive or any)
function M.get_current_session_id()
  -- Try to find alive session
  for sid, sess in pairs(proc.sessions) do
    if sess.alive then
      return sid
    end
  end

  -- Fallback to any session
  for sid, _ in pairs(proc.sessions) do
    return sid
  end

  return nil
end

return M
