-- lua/claude_nvim/ui.lua
-- UI: chat buffer creation, message display, keymaps, fzf-lua pickers

local proc = require("claude_nvim.proc")
local util = require("claude_nvim.util")

local M = {}

-- Create or show chat buffer for session
function M.open_chat(session_id)
  local session = proc.sessions[session_id]
  if not session then
    vim.notify("Session not found: " .. session_id, vim.log.levels.ERROR)
    return
  end

  local bufnr = session.bufnr

  -- Create buffer if doesn't exist
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, "claude://" .. session_id)
    vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
    vim.api.nvim_buf_set_option(bufnr, "bufhidden", "hide")
    vim.api.nvim_buf_set_option(bufnr, "swapfile", false)
    vim.api.nvim_buf_set_option(bufnr, "filetype", "markdown")

    session.bufnr = bufnr

    -- Set initial content - clean and minimal
    M.append_to_chat(bufnr, ">> ")

    -- Set buffer-local keymaps
    M.setup_chat_keymaps(bufnr, session_id)
  end

  -- Open in right vertical split
  vim.cmd("vsplit")
  vim.api.nvim_win_set_buf(0, bufnr)

  -- Set statusline to show session info
  vim.wo.statusline = string.format("  Claude [%s] ready ", session.model)
end

-- Append text to chat buffer (non-blocking)
function M.append_to_chat(bufnr, text)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)

  local lines = vim.split(text, "\n", { plain = true })
  local last_line = vim.api.nvim_buf_line_count(bufnr)

  -- Append lines
  vim.api.nvim_buf_set_lines(bufnr, last_line, last_line, false, lines)

  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
end

-- Setup buffer-local keymaps for chat
function M.setup_chat_keymaps(bufnr, session_id)
  local opts = { buffer = bufnr, noremap = true, silent = true }

  -- <CR> in normal mode: send message if on >> line
  vim.keymap.set("n", "<CR>", function()
    M.send_current_line(bufnr, session_id)
  end, opts)

  -- <Space>cc: context current buffer
  vim.keymap.set("n", "<Space>cc", function()
    require("claude_nvim.context").send_buffer_context(session_id)
  end, opts)

  -- <Space>cs: context selection
  vim.keymap.set("v", "<Space>cs", function()
    require("claude_nvim.context").send_selection_context(session_id)
  end, opts)

  -- <Space>ca: context all buffers
  vim.keymap.set("n", "<Space>ca", function()
    require("claude_nvim.context").send_all_buffers_context(session_id)
  end, opts)

  -- i: insert mode - position cursor after >> if on prompt line
  vim.keymap.set("n", "i", function()
    local line_num = vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_buf_get_lines(bufnr, line_num - 1, line_num, false)[1]
    if line and vim.startswith(line, ">> ") then
      -- Position cursor after ">> "
      vim.api.nvim_win_set_cursor(0, {line_num, 3})
      vim.cmd("startinsert")
    else
      vim.cmd("normal! i")
    end
  end, opts)

  -- A: append - go to end of line and insert
  vim.keymap.set("n", "A", function()
    vim.cmd("normal! $a")
  end, opts)

  -- q: close window
  vim.keymap.set("n", "q", "<cmd>close<cr>", opts)

  -- Intercept :w to send message
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = bufnr,
    callback = function()
      M.send_current_line(bufnr, session_id)
      -- Mark buffer as not modified
      vim.api.nvim_buf_set_option(bufnr, "modified", false)
    end,
  })
end

-- Send message from current line (if starts with >>)
function M.send_current_line(bufnr, session_id)
  local line_num = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(bufnr, line_num - 1, line_num, false)[1]

  if not line or not vim.startswith(line, ">> ") then
    return
  end

  local message = line:sub(4) -- Remove ">> "
  if message == "" then
    return
  end

  -- Send message
  proc.send_message(session_id, message)

  -- Show thinking indicator
  M.append_to_chat(bufnr, "\n\n_Claude is thinking..._\n")
end

-- fzf-lua picker for sessions
function M.show_session_picker()
  local fzf = require("fzf-lua")
  local sessions = proc.list_sessions()

  local entries = { "New session…" }
  for _, sess in ipairs(sessions) do
    local status = sess.alive and "✓" or "✗"
    local entry = string.format("%s [%s] %s - %s", status, sess.model, sess.session_id:sub(1, 8), sess.cwd)
    table.insert(entries, entry)
  end

  fzf.fzf_exec(entries, {
    prompt = "Claude Sessions> ",
    actions = {
      ["default"] = function(selected)
        if not selected or #selected == 0 then
          return
        end

        local choice = selected[1]

        if choice == "New session…" then
          M.show_model_picker()
        else
          -- Extract session_id from the line
          local session_id = nil
          for _, sess in ipairs(sessions) do
            if choice:match(sess.session_id:sub(1, 8)) then
              session_id = sess.session_id
              break
            end
          end

          if session_id then
            M.open_chat(session_id)
          end
        end
      end,
    },
  })
end

-- fzf-lua picker for model selection
function M.show_model_picker()
  local fzf = require("fzf-lua")
  local models = { "sonnet", "opus", "haiku" }

  fzf.fzf_exec(models, {
    prompt = "Select Model> ",
    actions = {
      ["default"] = function(selected)
        if not selected or #selected == 0 then
          return
        end

        local model = selected[1]
        local session = proc.spawn_session({
          model = model,
          cwd = vim.fn.getcwd(),
        })

        if session then
          vim.notify("Started Claude session: " .. session.session_id, vim.log.levels.INFO)
          M.open_chat(session.session_id)
        end
      end,
    },
  })
end

return M
