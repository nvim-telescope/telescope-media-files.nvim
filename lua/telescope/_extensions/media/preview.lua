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
local rifle = require("telescope._extensions.media.rifle")

local NULL = vim.NIL
local F = vim.F
local U = vim.loop
local N = vim.fn
local A = vim.api

local _task = util.get_os_command_output
local _dialog = view_util.set_preview_message
-- }}}

local function _timeout_hook(filepath, buffer, options) _dialog(buffer, options.preview.winid, "HELLO", "=") end

local function _filetype_hook(filepath, buffer, options)
  local winid = options.preview.winid
  local extension = N.fnamemodify(filepath, ":e"):lower()
  local absolute = N.fnamemodify(filepath, ":p")
  local handler = scope.supports[extension]

  local fill_cache = options.preview.fill.caching
  local fill_binary = options.preview.fill.binary
  local fill_file = options.preview.fill.file

  -- TODO: Cleanup. This looks vile. {{{
  if not winid and not buffer and not A.nvim_buf_is_valid(buffer) and not A.nvim_win_is_valid(winid) then return end

  if handler then
    local cached_file = handler(absolute, options.cache_path, options)
    if cached_file == NULL then
      if A.nvim_win_is_valid(winid) then _dialog(buffer, winid, "CACHING ITEM", fill_cache) end
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
      if not rifle.bullets.viu.has then error("viu isn't in PATH.", vim.log.levels.ERROR) end
      rifle.termopen(buffer, rifle.bullets.viu + cached_file)
    elseif options.backend == "chafa" then
      if not rifle.bullets.chafa.has then error("chafa isn't in PATH.", vim.log.levels.ERROR) end
      rifle.termopen(buffer, rifle.bullets.chafa + cached_file)
    elseif options.backend == "jp2a" then
      if not rifle.bullets.jp2a.has then error("jp2a isn't in PATH.", vim.log.levels.ERROR) end
      rifle.termopen(buffer, rifle.bullets.jp2a + cached_file)
    elseif options.backend == "catimg" then
      if not rifle.bullets.catimg.has then error("catimg isn't in PATH.", vim.log.levels.ERROR) end
      rifle.termopen(buffer, rifle.bullets.catimg + cached_file)
    end
    return
  end

  local mime = _task(rifle.bullets.file + { "--brief", "--mime-type", absolute })[1]
  if mime then
    local _mime = vim.split(mime, "/", { plain = true })
    if
      rifle.bullets.readelf.has
      and vim.tbl_contains({ "x-executable", "x-pie-executable", "x-sharedlib" }, _mime[2])
    then
      local stdout = _task(rifle.bullets.readelf + absolute)
      A.nvim_buf_set_lines(buffer, 0, -1, false, stdout)
      return false
    elseif extension == "torrent" then
      local command
      if rifle.bullets.transmission_show.has then
        command = rifle.bullets.transmission_show + absolute
      elseif rifle.bullets.aria2c.has then
        command = rifle.bullets.aria2c + absolute
      end

      if command then
        local stdout = _task(command)
        A.nvim_buf_set_lines(buffer, 0, -1, false, stdout)
        return false
      end
    elseif vim.tbl_contains({ "odt", "sxw", "ods", "odp" }, extension) then
      local command
      if rifle.bullets.odt2txt.has then
        command = rifle.bullets.odt2txt + absolute
      elseif rifle.bullets.pandoc.has then
        command = rifle.bullets.pandoc + absolute
        A.nvim_buf_set_option(buffer, "filetype", "markdown")
      end

      if command then
        local stdout = _task(command)
        A.nvim_buf_set_lines(buffer, 0, -1, false, stdout)
        return false
      end
    elseif extension == "xlsx" then
      local command
      if rifle.bullets.xlsx2csv.has then
        command = rifle.bullets.xlsx2csv + absolute
        local stdout = _task(command)
        A.nvim_buf_set_lines(buffer, 0, -1, false, stdout)
        return false
      end
    elseif
      string.match(mime, "wordprocessingml%.document$")
      or string.match(mime, "/epub%+zip$")
      or string.match(mime, "/x%-fictionbook%+xml$")
    then
      local command
      if rifle.bullets.pandoc.has then
        command = rifle.bullets.pandoc + absolute
        local stdout = _task(command)
        A.nvim_buf_set_option(buffer, "filetype", "markdown")
        A.nvim_buf_set_lines(buffer, 0, -1, false, stdout)
        return false
      end
    elseif string.match(mime, "text/rtf$") or string.match(mime, "msword$") then
      local command
      if rifle.bullets.catdoc.has then
        command = rifle.bullets.catdoc + absolute
        local stdout = _task(command)
        A.nvim_buf_set_option(buffer, "filetype", "markdown")
        A.nvim_buf_set_lines(buffer, 0, -1, false, stdout)
        return false
      end
    elseif string.match(_mime[2], "ms%-excel$") then
      local command
      if rifle.bullets.xls2csv.has then
        command = rifle.bullets.xls2csv + absolute
        local stdout = _task(command)
        A.nvim_buf_set_lines(buffer, 0, -1, false, stdout)
        return false
      end
    elseif string.match(mime, "message/rfc822$") then
      local command
      if rifle.bullets.mu.has then
        command = rifle.bullets.mu + absolute
        local stdout = _task(command)
        A.nvim_buf_set_lines(buffer, 0, -1, false, stdout)
        return false
      end
    elseif string.match(mime, "^image/vnd%.djvu") then
      local command
      if rifle.bullets.djvutxt.has then
        command = rifle.bullets.djvutxt + absolute
      elseif rifle.bullets.exiftool.has then
        command = rifle.bullets.exiftool + absolute
      end

      if command then
        rifle.termopen(buffer, command)
        return false
      end
    elseif string.match(mime, "^image/") then
      local command
      if rifle.bullets.exiftool.has then
        command = rifle.bullets.exiftool + absolute
        local stdout = _task(command)
        A.nvim_buf_set_lines(buffer, 0, -1, false, stdout)
        return false
      end
    elseif extension == "md" then
      local command
      if rifle.bullets.glow.has then command = rifle.bullets.glow + absolute end

      if command then
        rifle.termopen(buffer, command)
        return false
      end
      return true
    elseif vim.tbl_contains({ "htm", "html", "xhtml", "xhtm" }, extension) then
      local command
      if rifle.bullets.lynx.has then
        command = rifle.bullets.lynx + absolute
      elseif rifle.bullets.w3m.has then
        command = rifle.bullets.w3m + absolute
      elseif rifle.bullets.elinks.has then
        command = rifle.bullets.elinks + absolute
      elseif rifle.bullets.pandoc.has then
        command = rifle.bullets.pandoc + absolute
      end

      if command then
        rifle.termopen(buffer, command)
        A.nvim_buf_set_option(buffer, "filetype", "markdown")
        return false
      end
      return true
    elseif _mime[2] == "json" or extension == "json" then
      local command
      if rifle.bullets.jq.has then
        command = rifle.bullets.jq + absolute
      elseif rifle.bullets.python.has then
        command = rifle.bullets.python + absolute
      end

      if command then
        local stdout = _task(command)
        A.nvim_buf_set_lines(buffer, 0, -1, false, stdout)
        A.nvim_buf_set_option(buffer, "filetype", "json")
        return false
      end
      return true
    elseif extension == "ipynb" then
      local command
      if rifle.bullets.jupyter.has then
        command = rifle.bullets.jupyter + absolute
        local stdout = _task(command)
        A.nvim_buf_set_lines(buffer, 0, -1, false, stdout)
        A.nvim_buf_set_option(buffer, "filetype", "markdown")
        return false
      end
    elseif vim.tbl_contains({ "dff", "dsf", "wv", "wvc" }, extension) then
      local command
      if rifle.bullets.mediainfo.has then
        command = rifle.bullets.mediainfo + absolute
      elseif rifle.bullets.exiftool.has then
        command = rifle.bullets.exiftool + absolute
      end

      if command then
        local stdout = _task(command)
        A.nvim_buf_set_lines(buffer, 0, -1, false, stdout)
        return false
      end
    elseif _mime[1] == "text" or vim.tbl_contains({ "lua" }, extension) then
      return true
    end
  end

  if rifle.bullets.file.has then
    local stdout = _task(rifle.bullets.file + absolute)[1]
    _dialog(buffer, winid, vim.split(stdout, ": ", { plain = true })[2], fill_binary)
    return false
  end
  --- }}}

  _dialog(buffer, winid, "CANNOT PREVIEW FILE", fill_file)
  return false
end

local _MediaPreview = util.make_default_callable(function(options)
  options.cache_path = Path:new(options.cache_path)
  scope.load_caches(options.cache_path)
  local fill_perm = options.preview.fill.permission

  if options.backend == "ueberzug" then
    options._ueberzug = Ueberzug:new(os.tmpname())
    options._ueberzug:listen()
  end

  options.preview.filetype_hook = _filetype_hook
  options.preview.timeout_hook = _timeout_hook
  options.preview.msg_bg_fillchar = options.preview.fill.mime

  return view.new_buffer_previewer({
    define_preview = function(self, entry, status)
      U.fs_access(
        entry.value,
        "R",
        vim.schedule_wrap(function(_, permission)
          if permission then
            options.preview.winid = status.preview_win
            view.file_maker(entry.value, self.state.bufnr, options)
            return
          end
          _dialog(self.state.bufnr, self.state.winid, "COULD NOT ACCESS FILE", fill_perm)
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
