---@diagnostic disable: param-type-mismatch
---@tag media.util

---@config { ["name"] = "UTIL", ["field_heading"] = "Options", ["module"] = "telescope._extensions.util" }

---@brief [[
--- General utilites.
---@brief ]]

local M = {}

local A = vim.api
local N = vim.fn

--- If all patterns match then return true, false otherwise
---@param item string the string that needs to be matched
---@param ... table<string> patterns that needs to be matched with
---@return string|nil|boolean
function M.any(item, ...)
  local patterns = { ... }
  if #patterns == 1 then return item:match(patterns[1]) end
  for _, pattern in ipairs(patterns) do
    if item:match(pattern) then return true end
  end
  return false
end

--- Run arbitrary command in a terminal buffer
---@param buffer integer the previewer buffer number
---@param command table<string> command that should be executed in the terminal buffer
---@return false
function M.termopen(buffer, command)
  A.nvim_buf_call(buffer, function()
    if A.nvim_buf_is_valid(buffer) and A.nvim_buf_get_option(buffer, "modifiable") then N.termopen(command) end
  end)
  return false
end

return M

-- vim:filetype=lua
