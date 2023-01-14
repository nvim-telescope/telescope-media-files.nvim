---@tag media.canned

---@config { ["name"] = "PRESET FUNCTIONS", ["field_heading"] = "Options", ["module"] = "telescope._extensions.media.canned" }

---@brief [[
--- This module defines some premade callback functions that goes into the `on_confirm`
--- and `on_confirm_muliple` configuration values. For example, the function
--- `set_wallpaper` opens up a |vim.ui.select()| and allows to choose from some
--- image orientation choices. And, when a choice is made, the function sets the passed image
--- as the wallpaper.
---
--- Note that it is advised to read function documentations since functions for `on_confirm`
--- is not compatible for `on_confirm_muliple`. This is because one takes in only a single
--- entry and another takes in an array of entries.
---
--- Following are the functions that this module provides.
--- - On confirm.
---   - copy_path
---   - copy_image
---   - set_wallpaper
---   - open_path
--- - On confirm multiple.
---   - bulk_copy
---@brief ]]

-- Imports and file-local definitions. {{{
local M = {}

local Job = require("plenary.job")

local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")

local N = vim.fn
-- }}}

M.single = {}
M.multiple = {}
M.actions = {}

local function _enpath(entry)
  return (string.format("%s/%s", entry.cwd, entry.value):gsub("//", "/"))
end

-- Canned functions for single selection. {{{
--- A canned function that takes in a filepath and just copies it into
--- the |vim.v.register|.
---@param entry string the path to be copied.
---@param options table? additonal configurations.
---@field name_mod string string that would be passed onto |fnamemodify()|.
function M.single.copy_path(entry, options)
  entry = _enpath(entry)
  options = vim.tbl_extend("keep", vim.F.if_nil(options, {}), {
    name_mod = ":p",
  })
  N.setreg(vim.v.register, N.fnamemodify(entry, options.name_mod))
end

--- Copy the data within the image itself to the clipboard.
---@param filepath string the path to be copied.
---@param options table? additonal configurations.
---@field command string the clipboard util name. For example xclip.
---@field args table arguments that would be passed to the job command.
---@see Job for more options.
function M.single.copy_image(entry, options)
  entry = _enpath(entry)
  if not vim.tbl_contains({ "png", "jpg", "jpeg", "jiff", "webp" }, N.fnamemodify(entry, ":e")) then return end
  options = vim.tbl_extend("keep", vim.F.if_nil(options, {}), {
    command = "xclip",
    args = { "-selection", "clipboard", "-target", "image/png", entry },
  })
  Job:new(options):start()
end

--- Set the given path as the wallpaper. This currently depends on `feh`.
---@param filepath string set the current path as the wallpaper if it is an image.
---@param options table? arguments that would be passed into the job command.
---@field command string the wallpaper setter util name. For example hydrogen.
---@field args table arguments that would be passed to the job command.
---@see Job for more options.
function M.single.set_wallpaper(entry, options)
  entry = _enpath(entry)
  if not vim.tbl_contains({ "png", "jpg", "jpeg", "jiff", "webp" }, N.fnamemodify(entry, ":e")) then return end
  vim.ui.select(
    {
      "TILE",
      "SCALE",
      "FILL",
      "CENTER",
    },
    {
      prompt = "Background type:",
      format_item = function(item) return "Set background behavior to " .. item end,
    },
    function(choice)
      Job:new(vim.tbl_extend("keep", vim.F.if_nil(options, {}), {
        command = "feh",
        args = { "--bg-" .. choice:lower(), entry },
      })):start()
    end
  )
end

--- Open a path. This will be done by `xdg-open` command by default.
---@param filepath string path that needs to be opened.
---@param options table? additonal configurations.
---@field command string the command that will be used to open the filepath.
---@field args table arguments that would be passed to the job command.
---@see Job for more options.
function M.single.open_path(entry, options)
  entry = _enpath(entry)
  options = vim.tbl_extend("force", vim.F.if_nil(options, {}), {
    command = "xdg-open",
    args = { entry },
  })
  Job:new(options):start()
end
-- }}}

-- Canned functions for multiple selections. {{{
--- Copy multiple paths into the clipboard.
---@param entries table<string> a list of paths to be copied.
---@param options table? additonal configuration.
---@field name_mod string format string that will be passed onto |fnamemodify()|.
function M.multiple.bulk_copy(entries, options)
  entries = vim.tbl_map(function(entry) return _enpath(entry) end, entries)
  options = vim.tbl_extend("keep", vim.F.if_nil(options, {}), { name_mod = ":p" })
  N.setreg(vim.v.register, table.concat(vim.tbl_map(function(item) return N.fnamemodify(item, options.name_mod) end, entries), "\n"))
end

local function _split(prompt_buffer, command)
  local picker = actions_state.get_current_picker(prompt_buffer)
  local selections = picker:get_multi_selection()
  local entry = _enpath(actions_state.get_selected_entry())

  actions.close(prompt_buffer)
  if #selections < 2 then
    vim.cmd[command](entry.value)
  else
    for _, selection in ipairs(selections) do
      vim.cmd[command](selection.value)
    end
  end
end

function M.actions.multiple_split(prompt_buffer) _split(prompt_buffer, "split") end

function M.actions.multiple_vsplit(prompt_buffer) _split(prompt_buffer, "vsplit") end

return M
-- }}}

-- vim:filetype=lua:fileencoding=utf-8
