local Path = require("plenary.path")
local Job = require("plenary.job")
local Ueberzug = require("telescope._extensions.media.ueberzug")

local util = require("telescope.utils")
local bview = require("telescope.previewers.buffer_previewer")
local putil = require("telescope.previewers.utils")

local scope = require("telescope._extensions.media.scope")
local rifle = require("telescope._extensions.media.rifle")
local mutil = require("telescope._extensions.media.util")

local NULL = vim.NIL
local ERROR = vim.log.levels.ERROR

local if_nil = vim.F.if_nil
local U = vim.loop
local V = vim.fn
local A = vim.api
local B = rifle.bullets

local function _dial(buffer, window, message, fill) pcall(putil.set_preview_message, buffer, window, message, fill) end

local function _run(command, buffer, options, extension)
  local task = Job:new(command)
  local ok, result, code = pcall(Job.sync, task, options.preview.timeout, options.preview.wait, options.preview.redraw)
  if ok then
    if code == 0 then
      pcall(A.nvim_buf_set_lines, buffer, 0, -1, false, result)
      A.nvim_buf_set_option(buffer, "filetype", if_nil(extension, "text"))
    else
      _dial(buffer, options.preview.winid, "PREVIEWER ERROR", options.preview.fill.error)
    end
  else
    _dial(buffer, options.preview.winid, "PREVIEWER TIMED OUT", options.preview.fill.timeout)
  end
  return false
end

local function redirect(buffer, extension, absolute, options)
  local mime = util.get_os_command_output(B.file + { "--brief", "--mime-type", absolute })[1]
  local _mime = vim.split(mime, "/", { plain = true })
  local window = options.preview.winid
  local fill_binary = options.preview.fill.binary
  local fill_file = options.preview.fill.file

  -- TODO: This looks vile. Cleanup is required.
  if B.readelf and vim.tbl_contains({ "x-executable", "x-pie-executable", "x-sharedlib" }, _mime[2]) then
    return _run(B.readelf + absolute, buffer, options)
  elseif
    -- Huge list of archive filetypes/extensions. {{{
    vim.tbl_contains({
      "a",
      "ace",
      "alz",
      "arc",
      "arj",
      "bz",
      "bz2",
      "cab",
      "cpio",
      "deb",
      "gz",
      "jar",
      "lha",
      "lz",
      "lzh",
      "lzma",
      "lzo",
      "rpm",
      "rz",
      "t7z",
      "tar",
      "tbz",
      "tbz2",
      "tgz",
      "tlz",
      "txz",
      "tZ",
      "tzo",
      "war",
      "xpi",
      "xz",
      "Z",
      "zip",
    }, extension)
    -- }}}
  then
    local command = rifle.orders(absolute, "bsdtar", "atool")
    if command then _run(command, buffer, options) end
  elseif extension == "rar" and B.unrar then
    return _run(B.unrar + absolute, buffer, options)
  elseif extension == "7z" and B["7z"] then
    return _run(B["7z"] + absolute, buffer, options)
  elseif extension == "pdf" and B.exiftool then
    return _run(B.exiftool + absolute, buffer, options)
  elseif extension == "torrent" then
    local command = rifle.orders(absolute, "transmission-show", "aria2c")
    if command then return _run(command, buffer, options) end
  elseif vim.tbl_contains({ "odt", "sxw", "ods", "odp" }, extension) then
    local command = rifle.orders(absolute, "odt2txt", "pandoc")
    if command then return _run(command, buffer, options) end
  elseif extension == "xlsx" and B.xlsx2csv then
    return _run(B.xlsx2csv + absolute, buffer, options)
  elseif mutil.any(mime, "wordprocessingml%.document$", "/epub%+zip$", "/x%-fictionbook%+xml$") and B.pandoc then
    return _run(B.pandoc + absolute, buffer, options, "markdown")
  elseif mutil.any(mime, "text/rtf$", "msword$") and B.catdoc then
    return _run(B.catdoc + absolute, buffer, options)
  elseif mutil.any(_mime[2], "ms%-excel$") and B.xls2csv then
    return _run(B.xls2csv + absolute, buffer, options)
  elseif mutil.any(mime, "message/rfc822$") and B.mu then
    return _run(B.mu + absolute, buffer, options)
  elseif mutil.any(mime, "^image/vnd%.djvu") then
    local command = rifle.orders(absolute, "djvutxt", "exiftool")
    if command then return mutil.termopen(buffer, command) end
  elseif mutil.any(mime, "^image/") and B.exiftool then
    return _run(B.exiftool + absolute, buffer, options)
  elseif mutil.any(mime, "^audio/", "^video/") then
    local command = rifle.orders(absolute, "mediainfo", "exiftool")
    if command then return mutil.termopen(buffer, command) end
  elseif extension == "md" then
    if B.glow then return mutil.termopen(buffer, B.glow + absolute) end
    return true
  elseif vim.tbl_contains({ "htm", "html", "xhtml", "xhtm" }, extension) then
    local command = rifle.orders(absolute, "lynx", "w3m", "elinks", "pandoc")
    if command then return _run(command, buffer, options, "markdown") end
    return true
  elseif extension == "ipynb" and B.jupyter then
    return _run(B.jupyter + absolute, buffer, options, "markdown")
  elseif _mime[2] == "json" or extension == "json" then
    local command = rifle.orders(absolute, "jq", "python")
    if command then return _run(command, buffer, options, "json") end
    return true
  elseif vim.tbl_contains({ "dff", "dsf", "wv", "wvc" }, extension) then
    local command = rifle.orders(absolute, "mediainfo", "exiftool")
    if command then return _run(command, buffer, options) end
  elseif _mime[1] == "text" or vim.tbl_contains({ "lua" }, extension) then
    return true
  end

  -- last line of defence
  if B.file then
    local results = util.get_os_command_output(B.file + absolute)[1]
    _dial(buffer, window, vim.split(results, ": ", { plain = true })[2], fill_binary)
    return false
  end

  _dial(buffer, window, "CANNOT PREVIEW FILE", fill_file)
  return false
end

local function _filetype_hook(filepath, buffer, options)
  local extension = V.fnamemodify(filepath, ":e"):lower()
  local absolute = V.fnamemodify(filepath, ":p")
  local handler = scope.supports[extension]

  if handler then
    local _cache
    if
      extension == "gif"
      and vim.tbl_contains({ "chafa", "viu", "catimg" }, options.backend)
      and options.backend_options[options.backend]
      and options.backend_options[options.backend].move
    then
      _cache = absolute
    else
      _cache = handler(absolute, options.cache_path, options)
    end
    if _cache == NULL then return redirect(buffer, extension, absolute, options) end

    local win = options.get_preview_window()
    if options.backend == "ueberzug" then
      options._ueberzug:send({
        path = _cache,
        x = win.col + options.backend_options.ueberzug.xmove,
        y = win.line + options.backend_options.ueberzug.ymove,
        width = win.width,
        height = win.height,
      })
    elseif options.backend == "viu" then
      if not B.viu then error("viu isn't in PATH.", ERROR) end
      mutil.termopen(buffer, B.viu + _cache)
    elseif options.backend == "chafa" then
      if not B.chafa then error("chafa isn't in PATH.", ERROR) end
      mutil.termopen(buffer, B.chafa + _cache)
    elseif options.backend == "jp2a" then
      if not B.jp2a then error("jp2a isn't in PATH.", ERROR) end
      mutil.termopen(buffer, B.jp2a + _cache)
    elseif options.backend == "catimg" then
      if not B.catimg then error("catimg isn't in PATH.", ERROR) end
      mutil.termopen(buffer, B.catimg + _cache)
    else
      return redirect(buffer, extension, absolute, options)
    end
    return false
  end
  return redirect(buffer, extension, absolute, options)
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
  options.preview.msg_bg_fillchar = options.preview.fill.mime

  return bview.new_buffer_previewer({
    define_preview = function(self, entry, status)
      local entry_full = (string.format("%s/%s", entry.cwd, entry.value):gsub("//", "/"))
      -- stylua: ignore start
      U.fs_access(entry_full, "R", vim.schedule_wrap(function(_, permission)
        if permission then
          -- TODO: Is there any other way of doing this?
          options.preview.winid = status.preview_win
          bview.file_maker(entry_full, self.state.bufnr, options)
          return
        end
        _dial(self.state.bufnr, self.state.winid, "INSUFFICIENT PERMISSIONS", fill_perm)
      end))
      -- stylua: ignore end
      if options.backend == "ueberzug" then options._ueberzug:hide() end
    end,
    setup = function(self)
      scope.cleanup(options.cache_path)
      return if_nil(self.state, {})
    end,
    teardown = function()
      if options.backend == "ueberzug" and options._ueberzug then
        options._ueberzug:kill()
        options._ueberzug = nil
      end
    end,
  })
end)

return _MediaPreview
