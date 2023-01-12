local M = {}

local A = vim.api
local N = vim.fn

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

local function _call(self, ...)
  local cmd = self
  for _, arg in ipairs({ ... }) do
    cmd = cmd + arg
  end
  return cmd
end

local function _add(self, item)
  if type(item) == "table" then return vim.tbl_flatten({ self, item }) end
  if type(item) == "string" then
    local copy = vim.list_slice(self)
    table.insert(copy, item)
    return copy
  end
  error("Only string and list are allowed.", vim.log.levels.ERROR)
end

local function _sub(self, item)
  local copy = vim.list_slice(self)
  if type(item) == "string" then item = { item } end
  if type(item) == "table" then
    for _, value in ipairs(item) do
      for index, arg in ipairs(copy) do
        if arg == value then table.remove(copy, index) end
      end
    end
    return copy
  end
  error("Only string and list are allowed.", vim.log.levels.ERROR)
end

for command, args in pairs(M.bullets) do
  M.bullets[command] = setmetatable(args, { __add = _add, __sub = _sub, __call = _call })
  M.bullets[command].has = N.executable(args[1]) == 1
end

function M.orders(extras, ...)
  local binaries = { ... }
  for _, binary in ipairs(binaries) do
    local bullet = M.bullets[binary]
    if bullet.has then return bullet + extras end
  end
end

function M.has(binary)
  binary = M.bullets[binary]
  if binary then return binary.has end
  return false
end

M.bullets = setmetatable(M.bullets, {
  __call = function(self, _) return vim.tbl_keys(self) end,
})

return M

-- vim:filetype=lua:fileencoding=utf-8
