local Path = require("plenary.path")
local Job = require("plenary.job")
local Ueberzug = require("telescope._extensions.media.ueberzug")

local utils = require("telescope.utils")
local previewers = require("telescope.previewers")
local scope = require("telescope._extensions.media.scope")
local filetype = require("plenary.filetype")

local preview_utils = require("telescope.previewers.utils")
local debug_utils = require("plenary.debug_utils")

local api = vim.api
local fn = vim.fn
local F = vim.F

local MediaPreview = utils.make_default_callable(function(options)
  options = F.if_nil(options, {})
  options.preview = F.if_nil(options.preview, {})
  options.preview.time = F.if_nil(options.preview.time, 250)
  options.preview.filesize = F.if_nil(options.preview.filesize, 25)
  options.preview.fill = F.if_nil(options.preview.fill, "X")
  options.preview.treesitter = F.if_nil(options.preview.treesitter, true)

  local cache_path = Path:new(options.cache_path)
  scope.load_caches(cache_path)
  local UEBERZUG

  if options.backend == "ueberzug" then
    UEBERZUG = Ueberzug:new(os.tmpname())
    UEBERZUG:listen()
  end

  local function setup() scope.cleanup(cache_path) end

  local function preview_fn(_, entry, status)
    local buffer = status.preview_bufnr
    local window = status.preview_win
    local filepath = fn.fnamemodify(entry.value, ":p")
    local extension = fn.fnamemodify(filepath, ":e")

    local preview_filetype = filetype.detect(extension, { fs_access = true })
    if preview_filetype == "" then preview_filetype = extension end

    local preview_window = options.get_preview_window()
    local handler = scope.supports[extension]

    if handler then
      api.nvim_buf_set_lines(buffer, 0, -1, false, { "" })
      local path = handler(filepath, cache_path, {})
      if options.backend == "ueberzug" and UEBERZUG then
        UEBERZUG:send({
          path = path,
          x = preview_window.col + options.geometry.x,
          y = preview_window.line + options.geometry.y,
          width = preview_window.width + options.geometry.width,
          height = preview_window.height + options.geometry.height,
        })
      elseif options.backend == "viu" then
        ---@todo
      elseif options.backend == "chafa" then
        ---@todo
      elseif options.backend == "jp2a" then
        ---@todo
      end
    else
      if options.backend == "ueberzug" and UEBERZUG then
        UEBERZUG:send({
          path = vim.NIL,
          x = 100,
          y = 100,
          width = 1,
          height = 1,
        })
      end

      local task = Job:new({ "cat", filepath })
      local mime = (utils.get_os_command_output({ "file", "--mime-type", "--brief", filepath }))[1]
      local mimetype = vim.split(mime, "/", { plain = true })[1]

      -- stylua: ignore start
      task:add_on_exit_callback(function(...)
        local args = { ... }
        local result = args[1]:result()
        if args[2] == 0 then
          if mimetype ~= "text" and mimetype ~= "inode" then
            vim.schedule(function()
              preview_utils.set_preview_message(buffer, window, "PREVIEW UNAVAILABLE", options.preview.fill)
            end)
          else
            vim.schedule(function()
              api.nvim_buf_set_lines(buffer, 0, -1, false, result)
              if options.preview.treesitter then
                preview_utils.highlighter(buffer, preview_filetype)
              else
                preview_utils.regex_highlighter(buffer, preview_filetype)
              end
            end)
          end
        else
          vim.schedule(function()
            preview_utils.set_preview_message(buffer, window, "PERMISSION DENIED", options.preview.fill)
          end)
        end
      end)
      task:start()
      -- stylua: ignore end
    end
  end

  local function scroll_fn(self, direction)
    if not self.state then return end
    local input = direction > 0 and [[]] or [[]]
    local count = math.abs(direction)
    api.nvim_win_call(self.state.winid, function() api.nvim_command([[normal! ]] .. count .. input) end)
  end

  local function teardown()
    if UEBERZUG then UEBERZUG:kill() end
  end

  return previewers.new({
    setup = setup,
    preview_fn = preview_fn,
    teardown = teardown,
    scroll_fn = scroll_fn,
  })
end, {})

return MediaPreview

---vim:filetype=lua
