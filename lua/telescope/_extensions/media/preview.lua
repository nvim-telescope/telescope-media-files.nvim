-- Imports {{{
local Path = require("plenary.path")
local Job = require("plenary.job")
local Ueberzug = require("telescope._extensions.media.ueberzug")

local util = require("telescope.utils")
local state = require("telescope.state")
local action = require("telescope.actions")

local bview = require("telescope.previewers.buffer_previewer")
local putil = require("telescope.previewers.utils")

local scope = require("telescope._extensions.media.scope")
local rifle = require("telescope._extensions.media.rifle")
local mutil = require("telescope._extensions.media.util")

local NULL = vim.NIL
local ERROR = vim.log.levels.ERROR

local F = vim.F
local U = vim.loop
local N = vim.fn
local A = vim.api
local B = rifle.bullets
-- }}}

-- Helpers {{{
local function _dial(buffer, winid, message, fill) pcall(putil.set_preview_message, buffer, winid, message, fill) end

-- stylua: ignore start
local function _run(cmd, buffer, options, ex)
  local task = Job:new(cmd)
  local ok, result, code = pcall(Job.sync, task, options.preview.timeout, options.preview.wait, options.preview.redraw)
  if ok then
    if code == 0 then
      pcall(A.nvim_buf_set_lines, buffer, 0, -1, false, result)
      A.nvim_buf_set_option(buffer, "filetype", F.if_nil(ex, "text"))
    else _dial(buffer, options.preview.winid, "PREVIEWER ERROR", options.preview.fill.error) end
  else _dial(buffer, options.preview.winid, "PREVIEWER TIMED OUT", options.preview.fill.timeout) end
  return false
end

local function redirect(buffer, ex, absolute, options)
  local mime = util.get_os_command_output(B.file + { "--brief", "--mime-type", absolute })[1]
  local _mime = vim.split(mime, "/", { plain = true })
  timeout = F.if_nil(timeout, 50)

  if rifle.has("readelf") and vim.tbl_contains({ "x-executable", "x-pie-executable", "x-sharedlib" }, _mime[2]) then
    return _run(B.readelf + absolute, buffer, options)
  elseif vim.tbl_contains({ "a", "ace", "alz", "arc", "arj", "bz", "bz2", "cab", "cpio", "deb", "gz", "jar", "lha", "lz", "lzh", "lzma", "lzo", "rpm", "rz", "t7z", "tar", "tbz", "tbz2", "tgz", "tlz", "txz", "tZ", "tzo", "war", "xpi", "xz", "Z", "zip" }, ex) then
    local cmd = rifle.orders(absolute, "bsdtar", "atool")
    if cmd then _run(cmd, buffer, options) end
  elseif ex == "rar" and rifle.has("unrar") then
    return _run(B.unrar + absolute, buffer, options)
  elseif ex == "7z" and rifle.has("7z") then
    return _run(B["7z"] + absolute, buffer, options)
  elseif ex == "pdf" and rifle.has("exiftool") then
    return _run(B.exiftool + absolute, buffer, options)
  elseif ex == "torrent" then
    local cmd = rifle.orders(absolute, "transmission-show", "aria2c")
    if cmd then return _run(cmd, buffer, options) end
  elseif vim.tbl_contains({ "odt", "sxw", "ods", "odp" }, ex) then
    local cmd = rifle.orders(absolute, "odt2txt", "pandoc")
    if cmd then return _run(cmd, buffer, options) end
  elseif ex == "xlsx" and rifle.has("xlsx2csv") then
    return _run(B.xlsx2csv + absolute, buffer, options)
  elseif mutil.any(mime, "wordprocessingml%.document$", "/epub%+zip$", "/x%-fictionbook%+xml$") and rifle.has("pandoc") then
    return _run(B.pandoc + absolute, buffer, options, "markdown")
  elseif mutil.any(mime, "text/rtf$", "msword$") and rifle.has("catdoc") then
    return _run(B.catdoc + absolute, buffer, options)
  elseif mutil.any(_mime[2], "ms%-excel$") and rifle.has("xls2csv") then
    return _run(B.xls2csv + absolute, buffer, options)
  elseif mutil.any(mime, "message/rfc822$") and rifle.has("mu") then
    return _run(B.mu + absolute, buffer, options)
  elseif mutil.any(mime, "^image/vnd%.djvu") then
    local cmd = rifle.orders(absolute, "djvutxt", "exiftool")
    if cmd then return mutil.termopen(buffer, cmd) end
  elseif mutil.any(mime, "^image/") and rifle.has("exiftool") then
    return _run(B.exiftool + absolute, buffer, options)
  elseif mutil.any(mime, "^audio/", "^video/") then
    local cmd = rifle.orders(absolute, "mediainfo", "exiftool")
    if cmd then return mutil.termopen(buffer, cmd) end
  elseif ex == "md" then
    if rifle.has("glow") then return mutil.termopen(buffer, B.glow + absolute) end
    return true
  elseif vim.tbl_contains({ "htm", "html", "xhtml", "xhtm" }, ex) then
    local cmd = rifle.orders(absolute, "lynx", "w3m", "elinks", "pandoc")
    if cmd then return _run(cmd, buffer, options, "markdown") end
    return true
  elseif ex == "ipynb" and rifle.has("jupyter") then
    return _run(B.jupyter + absolute, buffer, options, "markdown")
  elseif _mime[2] == "json" or ex == "json" then
    local cmd = rifle.orders(absolute, "jq", "python")
    if cmd then return _run(cmd, buffer, options, "json") end
    return true
  elseif vim.tbl_contains({ "dff", "dsf", "wv", "wvc" }, ex) then
    local cmd = rifle.orders(absolute, "mediainfo", "exiftool")
    if cmd then return _run(cmd, buffer, options) end
  elseif _mime[1] == "text" or vim.tbl_contains({ "lua" }, ex) then
    return true
  end

  if rifle.has("file") then
    local results = util.get_os_command_output(B.file + absolute)[1]
    _dial(buffer, winid, vim.split(results, ": ", { plain = true })[2], fill_binary)
    return false
  end
  _dial(buffer, winid, "CANNOT PREVIEW FILE", fill_file)
  return false
end
-- stylua: ignore end
-- }}}

-- Hook {{{
local function _filetype_hook(filepath, buffer, options)
  local winid = options.preview.winid
  local ex = N.fnamemodify(filepath, ":e"):lower()
  local abs = N.fnamemodify(filepath, ":p")
  local handler = scope.supports[ex]

  local fill_binary = options.preview.fill.binary
  local fill_file = options.preview.fill.file

  if not winid and not buffer and not A.nvim_buf_is_valid(buffer) and not A.nvim_win_is_valid(winid) then return end
  if handler then
    local _cache
    -- stylua: ignore start
    if ex == "gif" and options.move then _cache = abs
    else _cache = handler(abs, options.cache_path, options) end
    if _cache == NULL then return redirect(buffer, ex, abs, options) end
    -- stylua: ignore end

    local win = options.get_preview_window()
    if options.backend == "ueberzug" then
      options._ueberzug:send({ path = _cache, x = win.col, y = win.line, width = win.width, height = win.height })
    elseif options.backend == "viu" then
      if not rifle.has("viu") then error("viu isn't in PATH.", ERROR) end
      mutil.termopen(buffer, B.viu + _cache)
    elseif options.backend == "chafa" then
      if not rifle.has("chafa") then error("chafa isn't in PATH.", ERROR) end
      mutil.termopen(buffer, B.chafa + _cache)
    elseif options.backend == "jp2a" then
      if not rifle.has("jp2a") then error("jp2a isn't in PATH.", ERROR) end
      mutil.termopen(buffer, B.jp2a + _cache)
    elseif options.backend == "catimg" then
      if not rifle.has("catimg") then error("catimg isn't in PATH.", ERROR) end
      mutil.termopen(buffer, B.catimg + _cache)
    else
      return redirect(buffer, ex, abs, options)
    end
    return false
  end
  return redirect(buffer, ex, abs, options)
end
-- }}}

-- Previewer {{{
local _MediaPreview = util.make_default_callable(function(options)
  options.cache_path = Path:new(options.cache_path)
  scope.load_caches(options.cache_path)
  local fill_perm = options.preview.fill.permission

  if options.backend == "ueberzug" then
    options._ueberzug = Ueberzug:new(os.tmpname())
    options._ueberzug:listen()
  end

  options.preview.filetype_hook = _filetype_hook
  options.preview.msg_bg_fillchar = options.preview.fill.mime

  return bview.new_buffer_previewer({
    define_preview = function(self, entry, status)
      entry_full = (string.format("%s/%s", entry.cwd, entry.value):gsub("//", "/"))
      -- stylua: ignore start
      U.fs_access(entry_full, "R", vim.schedule_wrap(function(_, permission)
        if permission then
          -- TODO: Is there any other way of doing this?
          options.preview.winid = status.preview_win
          bview.file_maker(entry_full, self.state.bufnr, options)
          return
        end
        _dial(self.state.bufnr, self.state.winid, "COULD NOT ACCESS FILE", fill_perm)
      end))
      -- stylua: ignore end
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
-- }}}

-- vim:filetype=lua:fileencoding=utf-8
