local M = {}

M.commands = {
  ["viu"] = { "viu", "-s" },
  ["chafa"] = { "chafa" },
  ["w3m"] = { "w3m", "-no-mouse", "-dump" },
  ["jp2a"] = { "jp2a", "--colors" },
  ["catimg"] = { "catimg" },
  ["lynx"] = { "lynx", "-dump" },
  ["glow"] = { "glow", "--style=auto" },
  ["readelf"] = { "readelf", "--wide", "--demangle=auto", "--all" },
  ["file"] = { "file", "--no-pad", "--dereference" },
  ["transmission-show"] = { "--unsorted" },
  ["elinks"] = { "elinks", "-dump" },
  ["pandoc"] = { "pandoc", "--standalone", "--to=markdown" },
  ["odt2txt"] = { "odt2txt" },
  ["xlsx2csv"] = { "xlsx2csv" },
  ["jupyter"] = { "jupyter", "nbconvert", "--to", "markdown" },
  ["jq"] = { "jq", "--color-output", "." },
  ["python"] = { "python", "-m", "json.tool" },
  ["mediainfo"] = { "mediainfo" },
  ["exiftool"] = { "exiftool" },
  ["catdoc"] = { "catdoc" },
  ["mu"] = { "mu", "view" },
  ["xls2csv"] = { "xls2csv" },
  ["djvutxt"] = { "djvutxt" },
}

local function _call(self, ...)
  local cmd = self
  for _, arg in ipairs({ ... }) do
    cmd = cmd + arg
  end
  return cmd
end

local function _add(self, item)
  if type(item) == "table" then
    return setmetatable(vim.tbl_flatten({ self, item }), { __add = _add, __call = _call })
  end
  if type(item) == "string" then
    local copy = vim.list_slice(self)
    table.insert(copy, item)
    return setmetatable(copy, { __add = _add, __call = _call })
  end
  error("Only string and list are allowed.", vim.log.levels.ERROR)
end

for command, args in pairs(M.commands) do
  M.commands[command] = setmetatable(args, { __add = _add, __call = _call })
end

M.commands = setmetatable(M.commands, {
  __call = function(self, _) return vim.tbl_keys(self) end,
})

function M.has(binary)
  local exists
  if type(binary) == "table" then exists = vim.fn.executable(binary[1]) end
  if type(binary) == "string" then exists = vim.fn.executable(binary) end

  if exists == 1 then
    return binary
  elseif exists == 0 then
    return false
  end
end

function M.termopen(buffer, command)
  vim.schedule(function()
    vim.api.nvim_buf_call(buffer, function() vim.fn.termopen(command) end)
  end)
end

return M

-- vim:filetype=lua:fileencoding=utf-8
