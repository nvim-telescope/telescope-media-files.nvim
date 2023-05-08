local M = {}

local A = vim.api
local V = vim.fn

function M.any(item, ...)
  local patterns = { ... }
  if #patterns == 1 then return item:match(patterns[1]) end
  for _, pattern in ipairs(patterns) do
    if item:match(pattern) then return true end
  end
  return false
end

function M.termopen(buffer, command)
  A.nvim_buf_call(buffer, function()
    if A.nvim_buf_is_valid(buffer) and A.nvim_buf_get_option(buffer, "modifiable") then V.termopen(command) end
  end)
  return false
end

return M
