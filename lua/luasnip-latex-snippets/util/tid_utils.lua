local M = {}

M.is_math = function(treesitter)
  local bufnr = 0
  local pos = vim.api.nvim_win_get_cursor(0)
  local row, col = pos[1], pos[2] -- row: 1-based, col: 0-based
  local line = (vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]) or ""

  -- inline: $$ ... $$
  do
    local col1 = col + 1 -- to 1-based
    local idxs = {}
    local init = 1
    while true do
      local s, e = line:find("%$%$", init, false)
      if not s then break end
      table.insert(idxs, s)
      init = e + 1
    end
    for i = 1, #idxs - 1, 2 do
      local open_s = idxs[i]
      local close_s = idxs[i + 1]
      local content_start = open_s + 2
      local content_end = close_s - 1
      if col1 >= content_start and col1 <= content_end then
        return true
      end
    end
  end

  -- block: lines containing only $$
  local function is_dollar_line(s)
    return s:match("^%s*%$%$%s*$") ~= nil
  end
  if is_dollar_line(line) then
    return false
  end

  local n = vim.api.nvim_buf_line_count(bufnr)

  local upper
  do
    local i = row - 2
    while i >= 0 do
      local l = vim.api.nvim_buf_get_lines(bufnr, i, i + 1, false)[1] or ""
      if is_dollar_line(l) then
        upper = i
        break
      end
      i = i - 1
    end
  end
  if not upper then return false end

  local lower
  do
    local i = row
    while i < n do
      local l = vim.api.nvim_buf_get_lines(bufnr, i, i + 1, false)[1] or ""
      if is_dollar_line(l) then
        lower = i
        break
      end
      i = i + 1
    end
  end
  if not lower then return false end

  return (upper < (row - 1)) and ((row - 1) < lower)
end

M.not_math = function(treesitter)
  return not M.is_math()
end

return M
