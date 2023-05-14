local M = {}

local A = vim.api
local V = vim.fn

function M.parse_args(args, ...)
  local results = {}
  for key, value in pairs(args) do
    local value_type = type(value)
    local key_type = type(key)

    if key_type == "number" then
      if value_type == "string" then
        table.insert(results, value)
      elseif value_type == "number" then
        table.insert(results, tostring(value))
      elseif value_type == "function" then
        local function_value = value(...)
        local function_value_type = type(function_value)

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
      if key ~= "-" and key ~= "--" and not vim.startswith(key, "--") then
        if key:len() > 2 then
          key = "--" .. key
        elseif not vim.startswith(key, "-") then
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
