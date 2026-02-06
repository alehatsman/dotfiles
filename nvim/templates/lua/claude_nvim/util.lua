-- lua/claude_nvim/util.lua
-- Utility functions: UUID, JSON parsing, root detection, logging

local M = {}

-- Seed random number generator once
math.randomseed(os.time() + vim.loop.hrtime())

-- Generate a UUID v4
function M.uuid()
  local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
  return string.gsub(template, "[xy]", function(c)
    local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
    return string.format("%x", v)
  end)
end

-- Find git root or fallback to cwd
function M.find_root(path)
  path = path or vim.fn.getcwd()
  local git_root = vim.fn.systemlist("git -C " .. vim.fn.shellescape(path) .. " rev-parse --show-toplevel 2>/dev/null")[1]
  if git_root and git_root ~= "" then
    return git_root
  end
  return path
end

-- Get log directory for sessions
function M.get_log_dir(cwd)
  local root = M.find_root(cwd)
  local log_dir
  if vim.fn.isdirectory(root .. "/.git") == 1 then
    log_dir = root .. "/.git/.claude-nvim/logs"
  else
    log_dir = root .. "/.claude-nvim/logs"
  end
  vim.fn.mkdir(log_dir, "p")
  return log_dir
end

-- Get log file path for session
function M.get_log_path(session_id, cwd)
  local log_dir = M.get_log_dir(cwd)
  return log_dir .. "/" .. session_id .. ".log"
end

-- Log to file
function M.log_to_file(log_path, message)
  local timestamp = os.date("%Y-%m-%d %H:%M:%S")
  local log_line = string.format("[%s] %s\n", timestamp, message)
  local f = io.open(log_path, "a")
  if f then
    f:write(log_line)
    f:close()
  end
end

-- Parse NDJSON line by line from buffer
-- Returns: array of decoded objects, remaining unparsed string
function M.parse_ndjson(buffer)
  local lines = vim.split(buffer, "\n", { plain = true })
  local decoded = {}
  local remaining = ""

  -- If buffer ends with \n, all lines are complete
  -- If not, last line is incomplete
  local buffer_ends_with_newline = buffer:sub(-1) == "\n"

  for i, line in ipairs(lines) do
    local is_last = (i == #lines)
    local is_complete = not is_last or buffer_ends_with_newline

    if is_complete and line ~= "" then
      local ok, obj = pcall(vim.json.decode, line)
      if ok then
        table.insert(decoded, obj)
      end
    elseif is_last and not buffer_ends_with_newline then
      -- Keep incomplete last line
      remaining = line
    end
  end

  return decoded, remaining
end

-- Encode message to NDJSON line for stdin
function M.encode_message(msg_type, content)
  local obj = {
    type = msg_type,
    message = {
      role = msg_type,
      content = content,
    }
  }
  return vim.json.encode(obj) .. "\n"
end

return M
