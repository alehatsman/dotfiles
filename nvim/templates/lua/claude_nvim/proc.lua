-- lua/claude_nvim/proc.lua
-- Process management: spawning, session registry, I/O handling

local util = require("claude_nvim.util")

local M = {}

-- Session registry: session_id -> session object
M.sessions = {}

-- Session object structure:
-- {
--   session_id = string,
--   model = string,
--   cwd = string,
--   job_id = number,
--   bufnr = number or nil,
--   alive = boolean,
--   log_path = string,
--   stdout_buf = string (accumulated partial data),
--   stdin = function (wraps vim.fn.chansend),
--   history = array of {type = "user"|"assistant", content = string},
--   name = string or nil (user-assigned name)
-- }

-- Spawn a new Claude Code session
function M.spawn_session(opts)
  opts = opts or {}
  local session_id = opts.session_id or util.uuid()
  local model = opts.model or "sonnet"
  local cwd = opts.cwd or vim.fn.getcwd()
  local root = util.find_root(cwd)
  local log_path = util.get_log_path(session_id, cwd)

  -- Build command
  local cmd = {
    "claude",
    "--print",
    "--verbose",
    "--input-format=stream-json",
    "--output-format=stream-json",
    "--include-partial-messages",
    "--session-id",
    session_id,
    "--add-dir",
    root,
    "--model",
    model,
  }

  util.log_to_file(log_path, "Spawning session: " .. table.concat(cmd, " "))

  -- Preserve history and name if resurrecting existing session
  local existing = M.sessions[session_id]
  local history = (existing and existing.history) or {}
  local name = (existing and existing.name) or nil

  local session = {
    session_id = session_id,
    model = model,
    cwd = cwd,
    job_id = nil,
    bufnr = nil,
    alive = false,
    log_path = log_path,
    stdout_buf = "",
    history = history,
    name = name,
  }

  -- Start job
  local job_id = vim.fn.jobstart(cmd, {
    cwd = cwd,
    stdin = "pipe",
    stdout_buffered = false,
    stderr_buffered = false,
    on_stdout = function(_, data, _)
      M.on_stdout(session_id, data)
    end,
    on_stderr = function(_, data, _)
      M.on_stderr(session_id, data)
    end,
    on_exit = function(_, exit_code, _)
      M.on_exit(session_id, exit_code)
    end,
  })

  if job_id <= 0 then
    util.log_to_file(log_path, "ERROR: Failed to spawn job")
    vim.notify("Failed to spawn Claude session", vim.log.levels.ERROR)
    return nil
  end

  session.job_id = job_id
  session.alive = true
  session.stdin = function(data)
    vim.fn.chansend(job_id, data)
  end

  M.sessions[session_id] = session
  util.log_to_file(log_path, "Session started with job_id=" .. job_id)

  return session
end

-- Handle stdout data
function M.on_stdout(session_id, data)
  local session = M.sessions[session_id]
  if not session then
    return
  end

  -- Accumulate data - jobstart splits on \n, so re-add them
  for i, chunk in ipairs(data) do
    session.stdout_buf = session.stdout_buf .. chunk
    -- Add newline back (jobstart removes them when splitting)
    if i < #data or chunk ~= "" then
      session.stdout_buf = session.stdout_buf .. "\n"
    end
  end

  -- Parse complete lines
  local decoded, remaining = util.parse_ndjson(session.stdout_buf)
  session.stdout_buf = remaining

  -- Process each message
  for _, msg in ipairs(decoded) do
    M.handle_message(session_id, msg)
  end
end

-- Handle stderr data
function M.on_stderr(session_id, data)
  local session = M.sessions[session_id]
  if not session then
    return
  end

  for _, line in ipairs(data) do
    if line ~= "" then
      util.log_to_file(session.log_path, "STDERR: " .. line)
    end
  end
end

-- Handle process exit
function M.on_exit(session_id, exit_code)
  local session = M.sessions[session_id]
  if not session then
    return
  end

  session.alive = false
  util.log_to_file(session.log_path, "Session exited with code: " .. exit_code)

  if session.bufnr and vim.api.nvim_buf_is_valid(session.bufnr) then
    vim.schedule(function()
      local ui = require("claude_nvim.ui")
      ui.append_to_chat(session.bufnr, "\n[Session ended with code " .. exit_code .. "]\n")
    end)
  end
end

-- Handle parsed message from Claude
function M.handle_message(session_id, msg)
  local session = M.sessions[session_id]
  if not session then
    return
  end

  util.log_to_file(session.log_path, "RX: " .. vim.inspect(msg))

  -- Extract content from Claude's response
  local content = nil
  if msg.type == "assistant" and msg.message and msg.message.content then
    -- Claude response format: msg.message.content = [{type:"text", text:"..."}]
    for _, item in ipairs(msg.message.content) do
      if item.type == "text" and item.text then
        content = (content or "") .. item.text
      end
    end
  end

  -- Record assistant response in history
  if content then
    table.insert(session.history, { type = "assistant", content = content })
  end

  -- If we have a chat buffer and content, append it
  if content and session.bufnr and vim.api.nvim_buf_is_valid(session.bufnr) then
    vim.schedule(function()
      local ui = require("claude_nvim.ui")
      ui.append_to_chat(session.bufnr, content)

      -- Add new prompt and move cursor to it
      ui.append_to_chat(session.bufnr, "\n\n>> ")

      -- Find window displaying this buffer and set cursor position
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == session.bufnr then
          local line_count = vim.api.nvim_buf_line_count(session.bufnr)
          -- Position cursor at end of last line (after >> )
          vim.api.nvim_win_set_cursor(win, {line_count, 3})
          break
        end
      end
    end)
  end
end

-- Send a user message to session
function M.send_message(session_id, content)
  local session = M.sessions[session_id]
  if not session or not session.alive then
    vim.notify("Session not alive: " .. session_id, vim.log.levels.ERROR)
    return
  end

  -- Record in history
  table.insert(session.history, { type = "user", content = content })

  local line = util.encode_message("user", content)
  util.log_to_file(session.log_path, "TX: " .. vim.trim(line))
  session.stdin(line)
end

-- Resurrect a dead session by replaying history
function M.resurrect_session(session_id)
  local old_session = M.sessions[session_id]
  if not old_session then
    vim.notify("Session not found: " .. session_id, vim.log.levels.ERROR)
    return nil
  end

  if old_session.alive then
    vim.notify("Session is already alive", vim.log.levels.WARN)
    return old_session
  end

  -- Save history before respawning
  local saved_history = vim.deepcopy(old_session.history)

  -- Respawn with same session_id (will start with empty history that we'll replay)
  local new_session = M.spawn_session({
    session_id = session_id,
    model = old_session.model,
    cwd = old_session.cwd,
  })

  if not new_session then
    return nil
  end

  -- Clear history so we can replay without duplicates
  new_session.history = {}

  -- Wait for initialization
  vim.wait(3000)

  -- Verify session is alive before replaying
  if not new_session.alive or not new_session.stdin then
    vim.notify("Failed to resurrect session - not alive", vim.log.levels.ERROR)
    return nil
  end

  -- Replay history (only user messages - responses will come from Claude)
  if #saved_history > 0 then
    vim.notify("Resurrecting session with " .. #saved_history .. " messages...", vim.log.levels.INFO)

    for _, msg in ipairs(saved_history) do
      if msg.type == "user" then
        -- Use send_message to properly record in history
        M.send_message(session_id, msg.content)
        -- Wait for response
        vim.wait(2000)
      end
    end
  end

  return new_session
end

-- Rename/name a session
function M.rename_session(session_id, name)
  local session = M.sessions[session_id]
  if not session then
    vim.notify("Session not found: " .. session_id, vim.log.levels.ERROR)
    return false
  end

  session.name = name
  vim.notify("Session renamed to: " .. name, vim.log.levels.INFO)
  return true
end

-- Get list of active sessions
function M.list_sessions()
  local list = {}
  for sid, sess in pairs(M.sessions) do
    table.insert(list, {
      session_id = sid,
      model = sess.model,
      cwd = sess.cwd,
      alive = sess.alive,
      name = sess.name,
    })
  end
  return list
end

-- Stop a session
function M.stop_session(session_id)
  local session = M.sessions[session_id]
  if session and session.alive and session.job_id then
    vim.fn.jobstop(session.job_id)
    session.alive = false
  end
end

return M
