-- lua/claude_nvim/context.lua
-- Context injection: buffer, selection, all buffers

local proc = require("claude_nvim.proc")
local util = require("claude_nvim.util")

local M = {}

-- Send current buffer context
function M.send_buffer_context(session_id, bufnr, line_range)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(bufnr)

  if filepath == "" or vim.startswith(filepath, "claude://") then
    vim.notify("Cannot send context from this buffer", vim.log.levels.WARN)
    return
  end

  local context_msg
  if line_range then
    context_msg = string.format("Context: %s (lines %d-%d)", filepath, line_range[1], line_range[2])
  else
    context_msg = string.format("Context: %s", filepath)
  end

  proc.send_message(session_id, context_msg)
  vim.notify("Sent buffer context to Claude", vim.log.levels.INFO)
end

-- Send visual selection context
function M.send_selection_context(session_id)
  -- Get visual selection
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_line = start_pos[2]
  local end_line = end_pos[2]

  local bufnr = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)

  if #lines == 0 then
    vim.notify("No selection", vim.log.levels.WARN)
    return
  end

  -- If buffer has a filepath, reference it
  if filepath ~= "" and not vim.startswith(filepath, "claude://") then
    local context_msg = string.format(
      "Context: %s (lines %d-%d)\n\n```\n%s\n```",
      filepath,
      start_line,
      end_line,
      table.concat(lines, "\n")
    )
    proc.send_message(session_id, context_msg)
  else
    -- Write to temp file
    local tmpfile = vim.fn.tempname() .. ".txt"
    local f = io.open(tmpfile, "w")
    if f then
      f:write(table.concat(lines, "\n"))
      f:close()
      local context_msg = string.format("Context from selection (saved to %s):\n\n```\n%s\n```", tmpfile, table.concat(lines, "\n"))
      proc.send_message(session_id, context_msg)
    end
  end

  vim.notify("Sent selection context to Claude", vim.log.levels.INFO)
end

-- Send all listed buffers context
function M.send_all_buffers_context(session_id, opts)
  opts = opts or {}
  local max_files = opts.max_files or 20
  local max_lines = opts.max_lines or 5000

  local buffers = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_buf_get_option(bufnr, "buflisted") then
      local filepath = vim.api.nvim_buf_get_name(bufnr)
      if filepath ~= "" and not vim.startswith(filepath, "claude://") then
        local line_count = vim.api.nvim_buf_line_count(bufnr)
        table.insert(buffers, {
          path = filepath,
          bufnr = bufnr,
          line_count = line_count,
        })
      end
    end
  end

  -- Sort by line count (smaller first to fit more)
  table.sort(buffers, function(a, b)
    return a.line_count < b.line_count
  end)

  -- Collect context
  local context_parts = { "Context: All open buffers\n" }
  local total_lines = 0
  local count = 0

  for _, buf in ipairs(buffers) do
    if count >= max_files or total_lines + buf.line_count > max_lines then
      break
    end

    table.insert(context_parts, string.format("- %s (%d lines)", buf.path, buf.line_count))
    total_lines = total_lines + buf.line_count
    count = count + 1
  end

  local context_msg = table.concat(context_parts, "\n")
  proc.send_message(session_id, context_msg)
  vim.notify(string.format("Sent %d buffer references to Claude", count), vim.log.levels.INFO)
end

return M
