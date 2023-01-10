-- Imports {{{
local Path = require("plenary.path")
local Job = require("plenary.job")
local Ueberzug = require("telescope._extensions.media.ueberzug")

local util = require("telescope.utils")
local state = require("telescope.state")
local actions = require("telescope.actions")
local view = require("telescope.previewers.buffer_previewer")
local view_util = require("telescope.previewers.utils")
local scope = require("telescope._extensions.media.scope")

local NULL = vim.NIL
local F = vim.F
local fn = vim.fn
local api = vim.api
local uv = vim.loop

local _task = util.get_os_command_output
local _dialog = view_util.set_preview_message
-- }}}

local function _termopen(buffer, command)
  vim.schedule(function()
    api.nvim_buf_call(buffer, function() fn.termopen(command) end)
  end)
end

local function _filetype_hook(filepath, buffer, options)
  local extension = fn.fnamemodify(filepath, ":e"):lower()
  local absolute = fn.fnamemodify(filepath, ":p")
  local handler = scope.supports[extension]

  if handler then
    local cached_file = handler(absolute, options.cache_path, options)
    if cached_file == NULL then
      if api.nvim_win_is_valid(options.preview.winid) then
        _dialog(buffer, options.preview.winid, "CACHING ITEM", options.preview.fill.caching)
      end
      return
    end

    local window = options.get_preview_window()
    if options.backend == "ueberzug" then
      options._ueberzug:send({
        path = cached_file,
        x = window.col,
        y = window.line,
        width = window.width,
        height = window.height,
      })
    elseif options.backend == "viu" then
      _termopen(buffer, { "viu", "-s", cached_file })
    elseif options.backend == "chafa" then
      _termopen(buffer, { "chafa", cached_file })
    elseif options.backend == "jp2a" then
      _termopen(buffer, { "jp2a", "--colors", cached_file })
    elseif options.backend == "catimg" then
      _termopen(buffer, { "catimg", cached_file })
    end
    return
  end

  local mime = _task({ "file", "--no-pad", "--dereference", "--brief", "--mime-type", absolute })[1]
  if mime then
    mime = vim.split(mime, "/", { plain = true })
    if vim.tbl_contains({ "x-executable", "x-pie-executable", "x-sharedlib" }, mime[2]) then
      local stdout = _task({ "readelf", "--wide", "--demangle=auto", "--all", absolute })
      api.nvim_buf_set_lines(buffer, 0, -1, false, stdout)
      return false
    elseif extension == "torrent" then
      local stdout = _task({ "transmission-show", "--unsorted", absolute })
      api.nvim_buf_set_lines(buffer, 0, -1, false, stdout)
      return false
    elseif extension == "md" then
      _termopen(buffer, { "glow", "--style=auto", absolute })
      return false
    elseif mime[2] == "html" then
      _termopen(buffer, { "lynx", "-dump", absolute })
      return false
    elseif mime[1] == "text" or vim.tbl_contains({ "lua", "json" }, extension) then
      return true
    end
  end

  local stdout = _task({ "file", "--no-pad", "--dereference", absolute })[1]
  _dialog(buffer, options.preview.winid, vim.split(stdout, ": ", { plain = true })[2], options.preview.fill.binary)
  return false
end

local _MediaPreview = util.make_default_callable(function(options)
  options.cache_path = Path:new(options.cache_path)
  scope.load_caches(options.cache_path)

  if options.backend == "ueberzug" then
    options._ueberzug = Ueberzug:new(os.tmpname())
    options._ueberzug:listen()
  end

  options.preview.filetype_hook = _filetype_hook
  options.preview.msg_bg_fillchar = options.preview.fill.mime

  return view.new_buffer_previewer({
    define_preview = function(self, entry, status)
      uv.fs_access(
        entry.value,
        "R",
        vim.schedule_wrap(function(_, permission)
          if permission then
            options.preview.winid = status.preview_win
            view.file_maker(entry.value, self.state.bufnr, options)
            return
          end
          _dialog(self.state.bufnr, self.state.winid, "COULD NOT ACCESS FILE", options.preview.fill.permission)
        end)
      )
      if options.backend == "ueberzug" then options._ueberzug:hide() end
    end,
    setup = function(self)
      scope.cleanup(options.cache_path)
      return F.if_nil(self.state, {})
    end,
    teardown = function(self)
      if options.backend == "ueberzug" and options._ueberzug then
        options._ueberzug:kill()
        options._ueberzug = nil
      end
    end,
  })
end, options)

return _MediaPreview

-- vim:filetype=lua:fileencoding=utf-8
