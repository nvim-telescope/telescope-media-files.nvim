local M = {}

local V = vim.fn

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

local meta = {}

function meta._add(this, item)
  if type(item) == "table" then return vim.tbl_flatten({ this, item }) end
  if type(item) == "string" then
    local copy = vim.deepcopy(this)
    table.insert(copy, item)
    return setmetatable(copy, { __add = meta._add, __sub = meta._sub })
  end
  error("Only string and list are allowed.", vim.log.levels.ERROR)
end

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
  if V.executable(args[1]) ~= 1 then M.bullets[command] = nil
  else M.bullets[command] = setmetatable(args, { __add = meta._add, __sub = meta._sub, __call = meta._call }) end
end

function M.orders(extras, ...)
  local binaries = { ... }
  for _, binary in ipairs(binaries) do
    local bullet = M.bullets[binary]
    if bullet then return bullet + extras end
  end
end

M.bullets = setmetatable(M.bullets, {
  __call = function(self, _) return vim.tbl_keys(self) end,
})

return M
