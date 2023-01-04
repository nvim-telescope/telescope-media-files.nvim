-- Imports and file-local definitions. {{{
local M = {}

local scope = require("telescope._extensions.media.scope")
local Path = require("plenary.path")
local Job = require("plenary.job")

local fn = vim.fn
-- }}}

-- Canned functions for single selection. {{{
function M.copy_path(filepath, options)
  options = vim.tbl_extend("keep", vim.F.if_nil(options, {}), {
    name_mod = ":p",
  })
  fn.setreg(vim.v.register, fn.fnamemodify(filepath, options.name_mod))
end

function M.copy_image(filepath, options)
  options = vim.tbl_extend("keep", vim.F.if_nil(options, {}), {
    command = "/usr/bin/xclip",
    args = { "-selection", "clipboard", "-target", "image/png", filepath },
  })
  Job:new(options):start()
end

function M.set_wallpaper(filepath, options)
  vim.ui.select(
    {
      "SEAMLESS",
      "TILE",
      "SCALE",
      "FILL",
      "CENTER",
    },
    {
      prompt = "Select background behavior:",
      format_item = function(item) return "Set background behavior to " .. item end,
    },
    function(choice)
      Job:new(vim.tbl_extend("keep", vim.F.if_nil(options, {}), {
        command = "/usr/bin/feh",
        args = { "--bg-" .. choice:lower(), filepath },
      })):start()
    end
  )
end

function M.open_path(filepath, options)
  options = vim.tbl_extend("force", vim.F.if_nil(options, {}), {
    command = "/usr/bin/xdg-open",
    args = { filepath },
  })
  Job:new(options):start()
end
-- }}}

-- Canned functions for multiple selections. {{{
function M.bulk_copy(entries, options)
  options = vim.tbl_extend("keep", vim.F.if_nil(options, {}), {
    name_mod = ":p",
  })
  vim.fn.setreg(
    vim.v.register,
    table.concat(vim.tbl_map(function(item) return fn.fnamemodify(item, options.name_mod) end, entries), "\n")
  )
end

return M
-- }}}

-- vim:filetype=lua:fileencoding=utf-8
