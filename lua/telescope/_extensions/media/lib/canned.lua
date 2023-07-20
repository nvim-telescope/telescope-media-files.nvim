local M = {}

local Task = require("plenary.job")
local V = vim.fn
local if_nil = vim.F.if_nil
local Log = require("telescope._extensions.media.core.log")

---Canned functions for single selections only.
M.single = {}
---Canned functions for multiple selections.
M.multiple = {}

---Join entry.cwd with entry.value path and strip any trailing /.
---@param entry table telescope entry.
---@return string
local function _enpath(entry) return (string.format("%s/%s", entry.cwd, entry.value):gsub("//", "/")) end

---Copy the selected path into the current active register.
---@param entry table telecope entry.
---@param options MediaConfig the telescope-media.nvim config.
function M.single.copy_path(entry, options)
  local joined_path = _enpath(entry)
  options = vim.tbl_extend("keep", if_nil(options, {}), {
    name_mod = ":p",
  })
  V.setreg(vim.v.register, V.fnamemodify(joined_path, options.name_mod))
end

---Copy the selected path data into the clipboard. This depends on xclip.
---@param entry table telecope entry.
---@param options MediaConfig the telescope-media.nvim config.
function M.single.copy_image(entry, options)
  Log.errors(V.executable("xclip") == 1, "xclip is not installed.", "xclip")
  local joined_path = _enpath(entry)
  if not vim.tbl_contains({ "png", "jpg", "jpeg", "jiff", "webp" }, V.fnamemodify(entry, ":e")) then return end
  options = vim.tbl_extend("keep", if_nil(options, {}), {
    command = "xclip",
    args = { "-selection", "clipboard", "-target", "image/png", joined_path },
  })
  Task:new(options):start()
end

---Set the selected entry as the current wallpaper. This depends on feh.
---@param entry table telecope entry.
---@param options MediaConfig the telescope-media.nvim config.
function M.single.set_wallpaper(entry, options)
  local joined_path = _enpath(entry)
  -- feh only supports these image filetypes
  if not vim.tbl_contains({
    "png",
    "jpg",
    "jpeg",
    "jiff",
    "webp"
  }, V.fnamemodify(joined_path , ":e")) then return end
  vim.ui.select({ "TILE", "SCALE", "FILL", "CENTER" }, {
    prompt = "Background type:",
    format_item = function(item) return "Set background behavior to " .. item end,
  }, function(choice)
    Task:new(vim.tbl_extend("keep", if_nil(options, {}), {
      command = "feh",
      args = { "--bg-" .. choice:lower(), joined_path },
    })):start()
  end)
end

---Open selected entry path. This depends on xdg-open.
---@param entry table telecope entry.
---@param options MediaConfig the telescope-media.nvim config.
function M.single.open_path(entry, options)
  options = vim.tbl_extend("force", if_nil(options, {}), {
    command = "xdg-open",
    args = { _enpath(entry) },
  })
  Task:new(options):start()
end

---Copy multiple selected paths into the current active register.
---@param entries table[] multiple telescope entries.
---@param options MediaConfig the telescope-media.nvim config.
function M.multiple.bulk_copy(entries, options)
  entries = vim.tbl_map(function(entry) return _enpath(entry) end, entries)
  options = vim.tbl_extend("keep", if_nil(options, {}), { name_mod = ":p" })
  -- go through all entries
  -- modify paths W.R.T options.name_mod
  -- join paths by \n
  -- finally copy it into the register
  V.setreg(vim.v.register, table.concat(vim.tbl_map(function(item)
    return V.fnamemodify(item, options.name_mod)
  end, entries), "\n"))
end

return M
