---@tag media

---@config { ["name"] = "INTRODUCTION", ["field_heading"] = "Options", ["module"] = "telescope._extensions.media" }

---@brief [[
--- telescope-media.nvim is a telescope extension that allows you to view both media files
--- and text files. It basically, combines the features of `find_files` and what this plugin
--- used to be i.e. a image viewer.
---
--- The main idea at the moment is to extract covers, thumbnails embedded covers, etc from
--- audio, video, etc. And, lower the quality and save them at a directory.
--- We can then access those files and view them instead, all the while keeping the paths
--- (entries) the same.
--- Image files will only be degraded and we won't need to extract or, unzip anything (duh).
---@brief ]]

-- Imports and file-local definitions. {{{
local present, telescope = pcall(require, "telescope")

if not present then
  vim.api.nvim_notify("This plugin requires telescope.nvim!", vim.log.levels.ERROR, {
    title = "telescope-media.nvim",
    prompt_title = "telescope-media.nvim",
    icon = " ",
  })
  return
end

local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local config = require("telescope.config")

local action_state = require("telescope.actions.state")
local make_entry = require("telescope.make_entry")

local scope = require("telescope._extensions.media.scope")
local canned = require("telescope._extensions.media.canned")
local media_previewer = require("telescope._extensions.media.preview")

local F = vim.F
local fn = vim.fn
-- }}}

-- The default configuration. {{{
---This is the default configuration.
local _TelescopeMediaConfig = {
  backend = "ueberzug",
  on_confirm = canned.single.copy_path,
  on_confirm_muliple = canned.multiple.bulk_copy,
  cache_path = "/tmp/tele.media.cache",
  preview_title = "",
  results_title = "",
  prompt_title = "Media",
  preview = {
    fill = {
      mime = "",
      permission = "╱",
      caching = "⎪",
      binary = "X",
      file = "~",
    },
  },
}
-- }}}

-- Helpers {{{
--- Find command helper.
---@param options table plugin settings
---@return table<string>|fun(options: table): table<string>
---@see telescope.previewers.buffer_previewer
local function _find_command(options)
  if options.find_command then
    if type(options.find_command) == "function" then return options.find_command(options) end
    return options.find_command
  elseif 1 == fn.executable("rg") then
    return { "rg", "--files", "--color", "never" }
  elseif 1 == fn.executable("fd") then
    return { "fd", "--type", "f", "--color", "never" }
  elseif 1 == fn.executable("fdfind") then
    return { "fdfind", "--type", "f", "--color", "never" }
  elseif 1 == fn.executable("find") then
    return { "find", ".", "-type", "f" }
  elseif 1 == fn.executable("where") then
    return { "where", "/r", ".", "*" }
  end
  error("Invalid command!", vim.log.levels.ERROR)
end
-- }}}

-- Main driver function. {{{
--- This function will be called by telescope when `load_extension` will be called.
--- Essentially, this will fetch options from the `telescope.config.extensions.media`
--- section. So, make sure to have that configured.
---@param options table plugin settings
---@private
local function _setup(options)
  options = F.if_nil(options, {})
  options.find_command = _find_command(options)
  _TelescopeMediaConfig = vim.tbl_deep_extend("keep", options, _TelescopeMediaConfig)
end

--- The main function that defines the picker.
---@param options table plugin settings
---@private
local function _media(options)
  options = F.if_nil(options, {})
  options.attach_mappings = function(buffer, map)
    actions.select_default:replace(function(prompt_buffer)
      local current_picker = action_state.get_current_picker(prompt_buffer)
      local selections = current_picker:get_multi_selection()

      actions.close(prompt_buffer)
      if #selections < 2 then
        options.on_confirm(action_state.get_selected_entry()[1])
      else
        selections = vim.tbl_map(function(item) return item[1] end, selections)
        options.on_confirm_muliple(selections)
      end
    end)
    return true
  end

  -- we need to do this everytime because a new table might be passed
  -- for example: one might want to run this through the cmdline or whatever
  options = vim.tbl_deep_extend("keep", options, _TelescopeMediaConfig)

  -- Validate find_command {{{
  ---@see telescope.previewers.buffer_previewer
  local command = options.find_command[1]
  if options.search_dirs then
    for key, value in pairs(options.search_dirs) do
      options.search_dirs[key] = fn.expand(value)
    end
  end

  if command == "fd" or command == "fdfind" or command == "rg" then
    if options.hidden then options.find_command[#options.find_command + 1] = "--hidden" end
    if options.no_ignore then options.find_command[#options.find_command + 1] = "--no-ignore" end
    if options.no_ignore_parent then options.find_command[#options.find_command + 1] = "--no-ignore-parent" end
    if options.follow then options.find_command[#options.find_command + 1] = "-L" end
    if options.search_file then
      if command == "rg" then
        options.find_command[#options.find_command + 1] = "-g"
        options.find_command[#options.find_command + 1] = "*" .. options.search_file .. "*"
      else
        options.find_command[#options.find_command + 1] = options.search_file
      end
    end
    if options.search_dirs then
      if command ~= "rg" and not options.search_file then options.find_command[#options.find_command + 1] = "." end
      vim.list_extend(options.find_command, options.search_dirs)
    end
  elseif command == "find" then
    if not options.hidden then
      table.insert(options.find_command, { "-not", "-path", "*/.*" })
      options.find_command = vim.tbl_flatten(options.find_command)
    end
    if options.no_ignore ~= nil then
      vim.notify("The 'no_ignore' key is not available for the 'find' command in 'find_files'.")
    end
    if options.no_ignore_parent ~= nil then
      vim.notify("The 'no_ignore_parent' key is not available for the 'find' command in 'find_files'.")
    end
    if options.follow then table.insert(options.find_command, 2, "-L") end
    if options.search_file then
      table.insert(options.find_command, "-name")
      table.insert(options.find_command, "*" .. options.search_file .. "*")
    end
    if options.search_dirs then
      table.remove(options.find_command, 2)
      for _, value in pairs(options.search_dirs) do
        table.insert(options.find_command, 2, value)
      end
    end
  end
  -- }}}

  local popup_options = {}
  ---get preview window geometry.
  ---@return table
  ---@private
  function options.get_preview_window() return popup_options.preview end
  options.entry_maker = make_entry.gen_from_file(options) -- support devicons

  local picker = pickers.new(options, {
    prompt_title = "Media",
    finder = finders.new_oneshot_job(options.find_command, options),
    previewer = media_previewer.new(options),
    sorter = config.values.file_sorter(options),
  })

  local line_count = vim.o.lines - vim.o.cmdheight
  if vim.o.laststatus ~= 0 then line_count = line_count - 1 end

  popup_options = picker:get_window_options(vim.o.columns, line_count)
  picker:find()
end
-- }}}

-- Plugin registration. {{{
-- TODO: Add presets like image_media, font_media, audio_media, etc.
return telescope.register_extension({
  setup = _setup,
  exports = {
    media = _media,
  },
})
-- }}}

-- vim:filetype=lua:fileencoding=utf-8
