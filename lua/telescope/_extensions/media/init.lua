-- Imports and file-local definitions. {{{
local present, telescope = pcall(require, "telescope")

if not present then
  vim.api.nvim_notify("This plugin requires telescope.nvim!", vim.log.levels.ERROR, {
    title = "telescope-media-files.nvim",
    prompt_title = "telescope-media-files.nvim",
    icon = " ",
  })
  return
end

local utils = require("telescope.utils")
local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local config = require("telescope.config")
local action_state = require("telescope.actions.state")
local make_entry = require("telescope.make_entry")

local Job = require("plenary.job")
local Path = require("plenary.path")

local scope = require("telescope._extensions.media.scope")
local canned = require("telescope._extensions.media.canned")
local media_previewer = require("telescope._extensions.media.preview")

local F = vim.F
local fn = vim.fn
-- }}}

-- The default configuration. {{{
---This is the default configuration.
local DEFAULTS = {
  ---Dimensions of the preview ueberzug window.
  geometry = {
    ---X-offset of the ueberzug window.
    x = -2,
    ---Y-offset of the ueberzug window.
    y = -2,
    ---Width of the ueberzug window.
    width = 1,
    ---Height of the ueberzug window.
    height = 1,
  },
  ---Command to populate the finder.
  find_command = { "rg", "--no-config", "--files", "--glob", "*.{*}", "." },
  backend = "viu",
  on_confirm = canned.open_path,
  on_confirm_muliple = canned.bulk_copy,
  cache_path = "/tmp/tele.media.cache",
}
-- }}}

-- Main driver function. {{{
local function setup(options) DEFAULTS = vim.tbl_deep_extend("keep", vim.F.if_nil(options, {}), DEFAULTS) end

local function media(options)
  options = vim.tbl_deep_extend("keep", F.if_nil(options, {}), DEFAULTS)
  options.attach_mappings = function(buffer)
    actions.select_default:replace(function(prompt_buffer)
      local current_picker = action_state.get_current_picker(prompt_buffer)
      local selections = current_picker:get_multi_selection()
      actions.close(buffer)
      if #selections < 2 then
        options.on_confirm(action_state.get_selected_entry()[1])
      else
        selections = vim.tbl_map(function(item) return item[1] end, selections)
        options.on_confirm_muliple(selections)
      end
    end)
    return true
  end

  local popup_options = {}
  function options.get_preview_window() return popup_options.preview end
  options.entry_maker = make_entry.gen_from_file(options)

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
return telescope.register_extension({
  setup = setup,
  exports = {
    media = media,
  },
})
-- }}}

-- vim:filetype=lua:fileencoding=utf-8
