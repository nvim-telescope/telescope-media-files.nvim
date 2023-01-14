---@tag media.rifle

---@config { ["name"] = "RIFLE", ["field_heading"] = "Options", ["module"] = "telescope._extensions.rifle" }

---@brief [[
--- This module is the same as `scope.lua` except this one is for files that do not need caching. These are
--- mostly text based previews. Like viewing an image in terminal using ASCII or by using some escape codes.
--- Which is again all text based.
---@brief ]]

local M = {}

local N = vim.fn

--- List of supported handlers with presetted arguments.
M.bullets = {
  ["viu"] = { "viu" },
  ["chafa"] = { "chafa" },
  ["w3m"] = { "w3m", "-no-mouse", "-dump" },
  ["jp2a"] = { "jp2a", "--colors" },
  ["catimg"] = { "catimg" },
  ["lynx"] = { "lynx", "-dump" },
  ["glow"] = { "glow", "--style=auto" },
  ["readelf"] = { "readelf", "--wide", "--demangle=auto", "--all" },
  ["file"] = { "file", "--no-pad", "--dereference" },
  ["transmission-show"] = { "transmission-show", "--unsorted" },
  ["aria2c"] = { "aria2c", "--show-file" },
  ["elinks"] = { "elinks", "-dump" },
  ["pandoc"] = { "pandoc", "--standalone", "--to=markdown" },
  ["odt2txt"] = { "odt2txt" },
  ["jq"] = { "jq", "--color-output", "--raw-output", "--monochrome-output", "." },
  ["python"] = { "python", "-m", "json.tool" },
  ["xlsx2csv"] = { "xlsx2csv" },
  ["jupyter"] = { "jupyter", "nbconvert", "--to", "markdown", "--stdout" },
  ["mediainfo"] = { "mediainfo" },
  ["exiftool"] = { "exiftool" },
  ["catdoc"] = { "catdoc" },
  ["mu"] = { "mu", "view" },
  ["xls2csv"] = { "xls2csv" },
  ["djvutxt"] = { "djvutxt" },
  ["bsdtar"] = { "bsdtar", "--list", "--file" },
  ["atool"] = { "atool", "--list" },
  ["unrar"] = { "unrar", "lt", "-p-" },
  ["7z"] = { "7z", "l", "-p" },
}

--- A table that will contain metatable functions. This is done so that we can recursively form a chain of
--- metatable operations like: `bu.mu + "45" + "-lmao=5" + "--long" + "-L" - "--long" -> "mu view 45 -lmao=5 -L"`
---@type table<function>
---@private
local meta = {}

--- A metatable function that allows appending arguments to a command/bullet.
---@param this table self
---@param item string|table the argument(s) that should be appended
---@return table
---@private
function meta._add(this, item)
  if type(item) == "table" then return vim.tbl_flatten({ this, item }) end
  if type(item) == "string" then
    local copy = vim.deepcopy(this)
    table.insert(copy, item)
    return setmetatable(copy, { __add = meta._add, __sub = meta._sub })
  end
  error("Only string and list are allowed.", vim.log.levels.ERROR)
end

--- A metatable function that allows removing matched arguments from a command/bullet
---@param this table self
---@param item string|table the argument(s) that should be removed
---@return table
---@private
function meta._sub(this, item)
  local copy = vim.deepcopy(this)
  if type(item) == "string" then item = { item } end
  if type(item) == "table" then
    for _, value in ipairs(item) do
      for index, arg in ipairs(copy) do
        if arg == value then table.remove(copy, index) end
      end
    end
    return setmetatable(copy, { __add = meta._add, __sub = meta._sub })
  end
  error("Only string and list are allowed.", vim.log.levels.ERROR)
end

for command, args in pairs(M.bullets) do
  if N.executable(args[1]) ~= 1 then M.bullets[command] = nil
  else M.bullets[command] = setmetatable(args, { __add = meta._add, __sub = meta._sub, __call = meta._call }) end
end

--- A convenience function that makes defining priorities and checking for executables easier.
---@param extras string|table<string> extra argument(s) that should be appended
---@param ... string handler commands based on priority i.e. if cava command is not installed then a fallback command (if specifed) will be used.
---@return number|nil
function M.orders(extras, ...)
  local binaries = { ... }
  for _, binary in ipairs(binaries) do
    local bullet = M.bullets[binary]
    if bullet then return bullet + extras end
  end
end

---@type table<string, table>
M.bullets = setmetatable(M.bullets, {
  --- List all supported commands.
  ---@param self table self
  ---@param _ any ignored
  ---@return table<string>
  __call = function(self, _) return vim.tbl_keys(self) end,
})

return M

-- vim:filetype=lua:fileencoding=utf-8
