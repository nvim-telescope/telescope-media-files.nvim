---@tag media.preview

---@config { ["name"] = "MEDIA PREVIEWER", ["field_heading"] = "Options", ["module"] = "telescope._extensions.media.preview" }

---@brief [[
--- Implementation of a custom previewer.
---@brief ]]

-- Imports and local declarations. {{{
local Path = require("plenary.path")
local Job = require("plenary.job")
local Ueberzug = require("telescope._extensions.media.ueberzug")

local utils = require("telescope.utils")
local previewers = require("telescope.previewers")
local scope = require("telescope._extensions.media.scope")
local filetype = require("plenary.filetype")

local preview_utils = require("telescope.previewers.utils")

local api = vim.api
local fn = vim.fn
local uv = vim.loop
local F = vim.F

local present, colorizer = pcall(require, "colorizer")
-- }}}

-- Helper functions. {{{
--- Hide the ueberzug window (stops viewing the image).
---@param options table needs to have the backend key.
---@param ueberzug Ueberzug the ueberzug object.
---@private
local function ueberzug_hide(options, ueberzug)
  if options.backend == "ueberzug" and ueberzug then
    ueberzug:send({
      path = vim.NIL, -- vim.NIL represents null
      x = 100,
      y = 100,
      width = 1,
      height = 1,
    })
  end
end
-- }}}

-- Preview function. {{{
--- A subsidiary function of `preview_fn`. This will only be called if a text file is opened. Essentially,
--- this will load a text file and will apply syntax highlights to it if said text file turns out to be a
--- code file (like python, Java, etc.).
---@param extension string file extension
---@param buffer integer the preview buffer identity
---@param window integer the preview window identity
---@param options table plugin settings
---@param mimetype string detect mime-type by `file --mime-type --brief <path>`
---@param preview_filetype string detected filetype
---@param self table reference to the Previewer
---@param code integer exit code
---@param signal integer exit signal
---@private
local function text_highlighter(extension, buffer, window, options, mimetype, preview_filetype, result)
  if not options.preview.check_mime_type then
    preview_utils.set_preview_message(buffer, window, "MIMETYPE CHECK IS DISABLED", options.preview.fill.mime_disable)
  elseif
    not vim.tbl_contains(options.preview.mimeforce, extension) -- allow hardcoded filetypes
    and mimetype ~= "text"
    and mimetype ~= "inode"
  then
    preview_utils.set_preview_message(buffer, window, "PREVIEW UNAVAILABLE", options.preview.fill.not_text_mime)
  else
    if not api.nvim_buf_is_valid(buffer) then return end
    api.nvim_buf_set_lines(buffer, 0, -1, false, result)

    if extension ~= "text" and extension ~= "txt" then
      if options.preview.regex and #result <= options.preview.regex_lines then
        preview_utils.regex_highlighter(buffer, preview_filetype)
      elseif options.preview.treesitter and #result <= options.preview.treesitter_lines then
        -- WARN: Slows down telescope when a file has more than ~1500 lines. Please help.
        preview_utils.ts_highlighter(buffer, preview_filetype)
      end
    end

    -- set window options
    for option, value in pairs(options.preview.window_options) do
      api.nvim_win_set_option(window, option, value)
    end
    -- enable nvim-colorizer.lua for rendering colors (if installed)
    if options.preview.colorizer and present and #result <= options.preview.colorizer_lines then
      colorizer.attach_to_buffer(buffer)
    end
  end
end

--- Another subsidiary of the `preview_fn` function. This one however, handles media files like images, audios,
--- videos, etc. This will look for a handler in |media.scope| and if it finds one then it'll call that handler.
--- The handler may return a path to the cached image. Which will then be previewed.
---@param ueberzug Ueberzug the ueberzug daemon object
---@param window integer the preview window identity
---@param buffer integer the preview buffer identity
---@param filepath string the path to the image/audio/video/font/... file.
---@param cache_path Path path where the images are being cached
---@param handler function media file handler
---@param preview_window table geometry of the preview window
---@param options table plugin settings
---@private
local function handle_backends(ueberzug, window, buffer, filepath, cache_path, handler, preview_window, options)
  -- clear the preview buffer
  -- TODO: Is there a better way to do this?
  api.nvim_buf_set_lines(buffer, 0, -1, false, { "" })
  local path = handler(filepath, cache_path, {})

  if path == vim.NIL then
    ueberzug_hide(options, ueberzug)
    preview_utils.set_preview_message(buffer, window, "CACHING PREVIEW IMAGE", options.preview.fill.caching)
    return
  end

  if options.backend == "ueberzug" and ueberzug then
    ueberzug:send({
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
end

-- stylua: ignore start
--- As the name implies, this function is to be called from `Previewer.preview_fn`. It acts a proxy
--- to `preview_fn`. We did this mainly because the code looks cleaner this way.
---@param self table the Previewer
---@param entry table current selected item on the prompt list
---@param status table I don't know what this is called - Previewer metadata perhaps
---@param cache_path Path path where all the cached images are stored
---@param ueberzug Ueberzug the ueberzug daemon object
---@param options table plugin settings
---@private
local function preview_fn_proxy(self, entry, status, cache_path, ueberzug, options)
  local buffer = status.preview_bufnr
  local window = status.preview_win

  self.state.winid = window
  local filepath = fn.fnamemodify(entry.value, ":p")
  local extension = fn.fnamemodify(filepath, ":e"):lower()

  local preview_filetype = ""
  if options.preview.filetype_detect then preview_filetype = filetype.detect(extension, { fs_access = true }) end
  if preview_filetype == "" then preview_filetype = extension end

  local handler = scope.supports[extension]
  -- do not load a file i.e. greater than this size
  uv.fs_stat(entry.value, vim.schedule_wrap(function(_, stat)
    if not stat then
      preview_utils.set_preview_message(buffer, window, "UNABLE TO INVOKE FS_STAT", options.preview.fill.stat_nil)
      return
    end

    if options.preview.filesize then
      local megabyte_filesize = math.floor(stat.size / math.pow(1024, 2))
      if megabyte_filesize > options.preview.filesize then
        ueberzug_hide(options, ueberzug)
        preview_utils.set_preview_message(buffer, window, "FILE EXCEEDS PREVIEW SIZE LIMIT", options.preview.fill.file_limit)
        return
      end
    end

    -- if a handler exists for the current file (entry) then call that handler
    -- else check if it is a text/text-like file - if so then view its contents - else view a message dialog
    if handler then
      handle_backends(ueberzug, window, buffer, filepath, cache_path, handler, options.get_preview_window(), options)
    else
      ueberzug_hide(options, ueberzug)
      -- TODO: Use read_async instead.
      local task = Job:new({ "cat", filepath })
      -- TODO: Is there a better way?
      local mime = (utils.get_os_command_output({ "file", "--mime-type", "--brief", filepath }))[1]
      local mimetype = vim.split(mime, "/", { plain = true })[1]

      task:add_on_exit_callback(function(...)
        local args = { ... }
        vim.schedule(function()
          text_highlighter(extension, buffer, window, options, mimetype, preview_filetype, args[1]:result())
        end)
      end)
      task:start()
    end
  end))
end
-- stylua: ignore end
-- }}}

-- Setup, teardown and scroll functions. {{{
--- Delete all residue cache files from archives and setup the previewer.
---@param self table the Previewer
---@param cache_path Path path to the cache images
---@param ueberzug Ueberzug the ueberzug daemon object
---@param options table plugin settings
---@return table
---@private
local function setup_proxy(self, cache_path, ueberzug, options)
  local state = {}
  scope.cleanup(cache_path)
  return state
end

--- The scrolling function for the previewer.
---@param self table the Previewer itself
---@param direction integer up/down scroll units
---@param cache_path Path path to the cache images
---@param ueberzug Ueberzug the ueberzug daemon
---@param options table plugin settings
---@private
local function scroll_fn_proxy(self, direction, cache_path, ueberzug, options)
  if not self.state then return end
  local input = direction > 0 and [[]] or [[]]
  local count = math.abs(direction)
  api.nvim_win_call(self.state.winid, function() api.nvim_command([[normal! ]] .. count .. input) end)
end

--- The cleanup function.
---@param self table the Previewer itself
---@param cache_path Path path to the cache images
---@param buffer integer the preview buffer identity
---@param ueberzug Ueberzug the ueberzug daemon
---@param options table plugin settings
---@private
local function teardown_proxy(self, cache_path, buffer, ueberzug, options)
  if ueberzug then ueberzug:kill() end
  if options.preview.enable_colorizer and present and colorizer.is_buffer_attached(buffer) then
    colorizer.detach_from_buffer(buffer)
  end
end
-- }}}

-- MediaPreview previewer {{{
--- A new previewer definition which handles viewing of both media files and text/text-like files.
---@param options table plugin settings
---@return table
---@private
local function media_previewer(options)
  local cache_path = Path:new(options.cache_path)
  scope.load_caches(cache_path)
  local UEBERZUG

  -- WARN: This is the most problematic part. If your previewer is open and an error occurs,
  --       we will not be able to terminate the ueberzug job.
  -- NOTE: We could solve this by going back to non-daemon process and running the script everytime
  --       preview_fn is called... but the preview won't be fast.
  if options.backend == "ueberzug" then
    UEBERZUG = Ueberzug:new(os.tmpname())
    UEBERZUG:listen()
  end

  --@see https://is.gd/HbG2AD this is so much better now.
  return previewers.new({
    setup = function(self) return setup_proxy(self, cache_path, UEBERZUG, options) end,
    preview_fn = function(self, entry, status) preview_fn_proxy(self, entry, status, cache_path, UEBERZUG, options) end,
    teardown = function(self) teardown_proxy(self, cache_path, buffer, UEBERZUG, options) end,
    scroll_fn = function(self, direction) scroll_fn_proxy(self, direction, cache_path, UEBERZUG, options) end,
    title = options.preview.title,
    -- TODO: Why does this not work? LMAO?
    dynamic_title = function(self, entry) return fn.fnamemodify(entry.value, ":t") end,
  })
end

return utils.make_default_callable(media_previewer, {})
-- }}}

-- vim:filetype=lua:fileencoding=utf-8
