local M = {}

local A = vim.api
local termopen = vim.fn.termopen
local Task = require("plenary.job")

---Encode a lua table into a string array of command line arguments.
---Consider the following table:
---```lua
---{
---  size = "fit", -- after conversion: --size fit
---  ["--frames"] = 5, -- after conversion: --frames 5
---  -- make sure the returning value is either boolean/string/number
---  columns = function(window, options)
---    return window.width
---  end,
---  "-r", function(window, options) return window.height end,
---  "-i",
---}
---```
---This will be turned into a table of strings:
---```lua
---{
---  "--size", "fit",
---  "--frames", "5",
---  "--columns", "150",
---  "-r", 100,
---  "-i",
---}
--```
---@param args table
---@param ... any these will be passed into the functional arguments
---@return table
function M.parse_args(args, ...)
  local results = {}
  for key, value in pairs(args) do
    local value_type = type(value)
    local key_type = type(key)

    -- if current key type is a number then it is an array entry
    -- which means we can ignore the key and use the value instead
    if key_type == "number" then
      if value_type == "string" then
        table.insert(results, value)
      elseif value_type == "number" then
        table.insert(results, tostring(value))
      elseif value_type == "function" then
        local function_value = value(...)
        local function_value_type = type(function_value)

        --- function return value should only be string, boolean and number
        if function_value_type == "string" then
          table.insert(results, function_value)
        elseif function_value_type == "boolean" then
          table.insert(results, tostring(function_value))
        elseif function_value_type == "number" then
          table.insert(results, tostring(function_value))
        else
          error("function_value can only be a string, number, boolean. function_value_type: " .. function_value_type)
        end
      elseif value_type == "boolean" then
        table.insert(results, tostring(value))
      else
        error("key can only be a string, number, boolean or, a function. key_type: " .. key_type)
      end
    elseif key_type == "string" then
      -- if the current key is not same as '-', '--' or if it does not start with '--' then skip
      if key ~= "-" and key ~= "--" and not vim.startswith(key, "--") then
        if key:len() > 2 then -- file -> --file
          key = "--" .. key
        elseif not vim.startswith(key, "-") then -- f -> -f
          key = "-" .. key
        end
      end

      if value_type == "string" then
        table.insert(results, key)
        table.insert(results, value)
      elseif value_type == "number" then
        table.insert(results, key)
        table.insert(results, tostring(value))
      elseif value_type == "function" then
        local function_value = value(...)
        local function_value_type = type(function_value)

        if function_value_type == "string" then
          table.insert(results, key)
          table.insert(results, function_value)
        elseif function_value_type == "boolean" then
          table.insert(results, key)
          table.insert(results, tostring(function_value))
        elseif function_value_type == "number" then
          table.insert(results, key)
          table.insert(results, tostring(function_value))
        else
          error("function_value can only be a string, number, boolean. function_value_type: " .. function_value_type)
        end
      elseif value_type == "boolean" then
        table.insert(results, key)
        table.insert(results, tostring(value))
      else
        error("key can only be a string, number, boolean or, a function. key_type: " .. key_type)
      end
    else
      error("key can only be a string or a number. key_type: " .. key_type)
    end
  end

  return results
end

---Match the first argument with all the others. If any of them ends up being a match
---then return true false otherwise.
---@param item string the argument that will be matched with the rest of the arguments
---@param ... string other arguments which will be matched with `item`
---@return boolean
function M.any(item, ...)
  local patterns = { ... }
  if #patterns == 1 then return item:match(patterns[1]) end
  for _, pattern in ipairs(patterns) do
    if item:match(pattern) then return true end
  end
  return false
end

function M.open_term(buffer, command)
  if A.nvim_buf_is_valid(buffer) and A.nvim_buf_get_option(buffer, "modifiable") then
    local channel = A.nvim_open_term(buffer, {})
    if channel == 0 then
      vim.notify("Error opening the terminal: " .. channel)
      return false
    end

    Task:new({
      command = table.remove(command, 1),
      args = command,
      on_stdout = vim.schedule_wrap(function(errors, data, _)
        if errors then return end
        local replaced = data:gsub("\n", "\r\n")
        pcall(A.nvim_chan_send, channel, replaced .. "\r\n")
      end),
    }):start()
  end
  return false
end

---Open a terminal in a buffer
---@see help |termopen()|
---@param buffer number buffer id
---@param command string[] table of command and its arguments { "file", "--dereference", "--brief", "rifle.lua" }
---@return boolean
-- TODO: This needs to be fixed.
function M.termopen(buffer, command)
  A.nvim_buf_call(buffer, function()
    if A.nvim_buf_is_valid(buffer) and A.nvim_buf_get_option(buffer, "modifiable") then
      local channel = termopen(command)
      if channel == 0 then
        vim.notify("Invalid number of arguments or, job table is full.")
      elseif channel == -1 then
        vim.notify(command[1] .. " is not executable.")
      end
    end
  end)
  return false
end

return M
