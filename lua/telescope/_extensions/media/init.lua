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

local Job = require("plenary.job")
local debug_utils = require("plenary.debug_utils")

local scope = require("telescope._extensions.media.scope")
local canned = require("telescope._extensions.media.canned")

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
    [[*.{]] .. table.concat(scope.SUP_FTYPE_FLAT, ",") .. [[}]],
    ".",
  },
  on_confirm = canned.copy_path,
  cache_path = "/tmp/tele.media.cache",
}

local SIGKILL = 9
local BASE_DIR = ""
local PIDS = {}

local function kill_process_all()
  for _, PID in pairs(PIDS) do
    vim.loop.kill(PID, SIGKILL)
  end
end

local function setup(options)
  DEFAULTS = vim.tbl_deep_extend("keep", vim.F.if_nil(options, {}), DEFAULTS)
end

--[[I am thinking of something.
  * How about we run a Ueberzug daemon process in the Previewer.setup
    method and that said daemon will listen to a FIFO as a plenary.Job.
  * And, Previewer.preview_fn method will send (write) the image metadata
    to that file. The daemon will adjuest to the new changes and display
    the new image.
  * Lastly, The Previewer.teardown method will kill the daemon process.
    We do not have to run the kill_process_all function if we did that!]]

local media_preview = utils.make_default_callable(function(options)
  return previewers.new({
    preview_fn = function(_, entry, _)
      kill_process_all()
      scope.create_cache(options.cache_path)
      local cached_file = vim.trim(entry.value)
      if scope.supports(entry.value) then
        cached_file = scope.cache_images(entry.value, options.cache_path)
      end

      local preview = options.get_preview_window()
      local ueberzug = Job:new({
        BASE_DIR .. "/scripts/view",
        cached_file,
        preview.col + options.geometry.x,
        preview.line + options.geometry.y,
        preview.width + options.geometry.width,
        preview.height + options.geometry.height,
      })
      ueberzug:start()
      table.insert(PIDS, ueberzug.pid)
    end,
    teardown = kill_process_all,
  })
end, {})

local function media(options)
  options = vim.tbl_deep_extend("keep", vim.F.if_nil(options, {}), DEFAULTS)
  BASE_DIR = vim.fn.fnamemodify(debug_utils.sourced_filepath(), ":h:h:h:h:h")

  options.attach_mappings = function(buffer)
    actions.select_default:replace(function()
      actions.close(buffer)
      options.on_confirm(action_state.get_selected_entry()[1])
    end)
    return true
  end

  local popup_options = {}
  options.get_preview_window = function()
    return popup_options.preview
  end

  local picker = pickers.new(options, {
    prompt_title = "Media Files",
    finder = finders.new_oneshot_job(options.find_command, options),
    previewer = media_preview.new(options),
    sorter = config.values.file_sorter(options),
  })

  local line_count = vim.o.lines - vim.o.cmdheight
  if vim.o.laststatus ~= 0 then
    line_count = line_count - 1
  end

  ---@diagnostic disable-next-line: undefined-field
  popup_options = picker:get_window_options(vim.o.columns, line_count)
  picker:find()
end

return telescope.register_extension({
  setup = setup,
  exports = {
    media = media,
  },
})

---vim:filetype=lua:fileencoding=utf-8
