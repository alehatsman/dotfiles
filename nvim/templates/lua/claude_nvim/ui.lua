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
    -- Check if buffer with this name already exists
    local existing_bufnr = vim.fn.bufnr("claude://" .. session_id)
    local is_new_buffer = (existing_bufnr == -1)

    if is_new_buffer then
      bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(bufnr, "claude://" .. session_id)
    else
      bufnr = existing_bufnr
    end

    vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
    vim.api.nvim_buf_set_option(bufnr, "bufhidden", "hide")
    vim.api.nvim_buf_set_option(bufnr, "swapfile", false)
    vim.api.nvim_buf_set_option(bufnr, "filetype", "markdown")

    session.bufnr = bufnr

    -- Set initial content only for new buffers
    if is_new_buffer then
      vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
      vim.api.nvim_buf_set_lines(bufnr, 0, 1, false, {">> "})
      vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
    end

    -- Set buffer-local keymaps
    M.setup_chat_keymaps(bufnr, session_id)
  end

  -- Open in right vertical split
  vim.cmd("vsplit")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, bufnr)

  -- Position cursor at end of >> prompt (after the space)
  vim.api.nvim_win_set_cursor(win, {1, 3})

  -- Set statusline to show session info
  local status = session.alive and "ready" or "DEAD - send message to revive"
  vim.wo.statusline = string.format("  Claude [%s] %s ", session.model, status)
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

  local session = proc.sessions[session_id]
  if not session then
    vim.notify("Session not found", vim.log.levels.ERROR)
    return
  end

  -- If session is dead, create NEW session with buffer context
  if not session.alive then
    vim.notify("Session is dead. Creating new session with buffer context...", vim.log.levels.INFO)

    -- Get all buffer content as context
    local all_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local buffer_content = table.concat(all_lines, "\n")

    -- Spawn completely NEW session (new UUID required by Claude CLI)
    local new_session = proc.spawn_session({
      model = session.model,
      cwd = session.cwd,
    })

    if not new_session or not new_session.alive then
      vim.notify("Failed to spawn new session", vim.log.levels.ERROR)
      return
    end

    -- Transfer buffer to new session
    new_session.bufnr = bufnr
    proc.sessions[new_session.session_id] = new_session
    proc.sessions[session_id] = nil  -- Remove old dead session

    -- Update buffer name to new session ID
    vim.api.nvim_buf_set_name(bufnr, "claude://" .. new_session.session_id)

    -- Update local references
    session = new_session
    session_id = new_session.session_id

    -- Update statusline
    vim.wo.statusline = string.format("  Claude [%s] ready ", session.model)

    -- Send buffer content as context, then the new message
    local context_message = "Here's our conversation history:\n\n" .. buffer_content .. "\n\nNow: " .. message
    proc.send_message(session_id, context_message)
  else
    -- Normal send
    proc.send_message(session_id, message)
  end

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
    local name_part = sess.name and (" '" .. sess.name .. "'") or ""
    local entry = string.format("%s [%s]%s %s - %s", status, sess.model, name_part, sess.session_id:sub(1, 8), sess.cwd)
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
