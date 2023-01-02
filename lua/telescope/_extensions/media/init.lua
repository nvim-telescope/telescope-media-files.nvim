---@module "telescope._extensions.media.init"

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
local previewers = require("telescope.previewers")
local config = require("telescope.config")
local action_state = require("telescope.actions.state")

local Ueberzug = require("telescope._extensions.media.backends.ueberzug")
local Job = require("plenary.job")
local Path = require("plenary.path")

local scope = require("telescope._extensions.media.scope")
local canned = require("telescope._extensions.media.canned")

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
  ---Command that will populate the finder. Any listing command or,
  ---script is allowed. Like ripgrep, find, fd, ls, etc.
  ---@warn Use unsupported filetypes at your own discretion.
  find_command = {
    "rg",
    "--no-config",
    "--files",
    "--glob",
    [[*.{]] .. table.concat(scope.supports(), ",") .. [[}]],
    ".",
  },
  on_confirm = canned.open_path,
  on_confirm_muliple = canned.bulk_copy,
  cache_path = "/tmp/tele.media.cache",
}
-- }}}

-- Setup functions and previewer function. {{{
local function setup(options) DEFAULTS = vim.tbl_deep_extend("keep", vim.F.if_nil(options, {}), DEFAULTS) end

local media_preview = utils.make_default_callable(function(options)
  local cache_path = Path:new(options.cache_path)
  local UEBERZUG = Ueberzug:new(os.tmpname())
  UEBERZUG:listen()

  return previewers.new({
    setup = function() scope.cleanup(cache_path) end,
    preview_fn = function(_, entry, _)
      scope.load_caches(cache_path)
      local preview = options.get_preview_window()
      local handler = scope.supports[fn.fnamemodify(entry.value, ":e")]

      if handler then
        UEBERZUG:send({
          path = handler(fn.fnamemodify(entry.value, ":p"), cache_path, {
            quality = "30%",
            blurred = "0.02",
          }),
          x = preview.col + options.geometry.x,
          y = preview.line + options.geometry.y,
          width = preview.width + options.geometry.width,
          height = preview.height + options.geometry.height,
        })
      end
    end,
    teardown = function() UEBERZUG:kill() end,
  })
end, {})
-- }}}

-- Main driver function. {{{
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
  options.get_preview_window = function() return popup_options.preview end

  local picker = pickers.new(options, {
    prompt_title = "Media",
    finder = finders.new_oneshot_job(options.find_command, options),
    previewer = media_preview.new(options),
    sorter = config.values.file_sorter(options),
  })

  local line_count = vim.o.lines - vim.o.cmdheight
  if vim.o.laststatus ~= 0 then line_count = line_count - 1 end

  ---@diagnostic disable-next-line: undefined-field
  popup_options = picker:get_window_options(vim.o.columns, line_count)
  picker:find()
end
-- }}}

return telescope.register_extension({
  setup = setup,
  exports = {
    media = media,
  },
})

---vim:filetype=lua:fileencoding=utf-8
