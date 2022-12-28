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

local Job = require("plenary.job")
local action_state = require("telescope.actions.state")

local DEFAULTS = {
  geometry = {
    x = -2,
    y = -2,
    width = 1,
    height = 1,
  },
  find_command = {
    "rg",
    "--no-config",
    "--files",
    "--glob",
    [[*.{]] .. "png,jpg,gif,webp,jpeg" .. [[}]],
    ".",
  },
  on_confirm = function(filepath)
    vim.fn.setreg(vim.v.register, filepath)
    vim.notify("The image path has been copied!")
  end,
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

local media_preview = utils.make_default_callable(function(options)
  return previewers.new({
    preview_fn = function(_, entry, _)
      kill_process_all()
      local preview = options.get_preview_window()
      local ueberzug = Job:new({
        BASE_DIR .. "/scripts/view.py",
        vim.trim(entry.value),
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

local function media_files(options)
  options = vim.tbl_deep_extend("keep", vim.F.if_nil(options, {}), DEFAULTS)
  local sourced_file = require("plenary.debug_utils").sourced_filepath()
  BASE_DIR = vim.fn.fnamemodify(sourced_file, ":h:h:h:h")

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
  popup_options = picker:get_window_options(vim.o.columns, line_count)
  picker:find()
end

return telescope.register_extension({
  setup = setup,
  exports = {
    media_files = media_files,
  },
})

---vim:filetype=lua:fileencoding=utf-8
