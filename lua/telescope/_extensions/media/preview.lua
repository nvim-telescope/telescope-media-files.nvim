local Path = require("plenary.path")
local Job = require("plenary.job")

local util = require("telescope.utils")
local bview = require("telescope.previewers.buffer_previewer")
local putil = require("telescope.previewers.utils")

local Ueberzug = require("telescope._extensions.media.lib.ueberzug")
local Scope = require("telescope._extensions.media.core.scope")
local Rifle = require("telescope._extensions.media.core.rifle")
local Util = require("telescope._extensions.media.util")
local Log = require("telescope._extensions.media.core.log")

local fb = Rifle.file_backends
local ib = Rifle.image_backends

local NULL = vim.NIL
local ERROR = vim.log.levels.ERROR

local fnamemod = vim.fn.fnamemodify
local fs_access = vim.loop.fs_access
local if_nil = vim.F.if_nil
local set_lines = vim.api.nvim_buf_set_lines
local set_option = vim.api.nvim_buf_set_option

local function dialog(buffer, window, message, fill)
  pcall(putil.set_preview_message, buffer, window, message, fill)
end

local function try_run(command, buffer, options, extension)
  local task = Job:new(command)
  local ok, result, code = pcall(Job.sync, task, options.preview.timeout, options.preview.wait, options.preview.redraw)
  if ok then
    if code == 0 then
      pcall(set_lines, buffer, 0, -1, false, result)
      set_option(buffer, "filetype", if_nil(extension, "text"))
    else
      dialog(buffer, options.preview.winid, "PREVIEWER ERROR", options.preview.fill.error)
    end
  else
    dialog(buffer, options.preview.winid, "PREVIEWER TIMED OUT", options.preview.fill.timeout)
  end
  return false
end

local function redirect(buffer, extension, absolute, options)
  local mime = util.get_os_command_output(fb.file + { "--brief", "--mime-type", absolute })[1]
  local mimetype = vim.split(mime, "/", { plain = true })
  local window = options.preview.winid
  local fill_binary = options.preview.fill.binary
  local fill_file = options.preview.fill.file

  if fb.readelf and vim.tbl_contains({ "x-executable", "x-pie-executable", "x-sharedlib" }, mimetype[2]) then
    return try_run(fb.readelf + absolute, buffer, options)
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
    local command = Rifle.orders(absolute, "bsdtar", "atool")
    if command then return try_run(command, buffer, options) end
  elseif extension == "rar" and fb.unrar then
    return try_run(fb.unrar + absolute, buffer, options)
  elseif extension == "7z" and fb["7z"] then
    return try_run(fb["7z"] + absolute, buffer, options)
  elseif extension == "pdf" and fb.exiftool then
    return try_run(fb.exiftool + absolute, buffer, options)
  elseif extension == "torrent" then
    local command = Rifle.orders(absolute, "transmission-show", "aria2c")
    if command then return try_run(command, buffer, options) end
  elseif vim.tbl_contains({ "odt", "sxw", "ods", "odp" }, extension) then
    local command = Rifle.orders(absolute, "odt2txt", "pandoc")
    if command then return try_run(command, buffer, options) end
  elseif extension == "xlsx" and fb.xlsx2csv then
    return try_run(fb.xlsx2csv + absolute, buffer, options)
  elseif Util.any(mime, "wordprocessingml%.document$", "/epub%+zip$", "/x%-fictionbook%+xml$") and fb.pandoc then
    return try_run(fb.pandoc + absolute, buffer, options, "markdown")
  elseif Util.any(mime, "text/rtf$", "msword$") and fb.catdoc then
    return try_run(fb.catdoc + absolute, buffer, options)
  elseif Util.any(mimetype[2], "ms%-excel$") and fb.xls2csv then
    return try_run(fb.xls2csv + absolute, buffer, options)
  elseif Util.any(mime, "message/rfc822$") and fb.mu then
    return try_run(fb.mu + absolute, buffer, options)
  elseif Util.any(mime, "^image/vnd%.djvu") then
    local command = Rifle.orders(absolute, "djvutxt", "exiftool")
    if command then return Util.termopen(buffer, command) end
  elseif Util.any(mime, "^image/") and fb.exiftool then
    return try_run(fb.exiftool + absolute, buffer, options)
  elseif Util.any(mime, "^audio/", "^video/") then
    local command = Rifle.orders(absolute, "mediainfo", "exiftool")
    if command then return Util.termopen(buffer, command) end
  elseif extension == "md" then
    if fb.glow then return Util.termopen(buffer, fb.glow + absolute) end
    return true
  elseif vim.tbl_contains({ "htm", "html", "xhtml", "xhtm" }, extension) then
    local command = Rifle.orders(absolute, "lynx", "w3m", "elinks", "pandoc")
    if command then return try_run(command, buffer, options, "markdown") end
    return true
  elseif extension == "ipynb" and fb.jupyter then
    return try_run(fb.jupyter + absolute, buffer, options, "markdown")
  elseif mimetype[2] == "json" or extension == "json" then
    local command = Rifle.orders(absolute, "jq", "python")
    if command then return try_run(command, buffer, options, "json") end
    return true
  elseif vim.tbl_contains({ "dff", "dsf", "wv", "wvc" }, extension) then
    local command = Rifle.orders(absolute, "mediainfo", "exiftool")
    if command then return try_run(command, buffer, options) end
  elseif mimetype[1] == "text" or vim.tbl_contains({ "lua" }, extension) then
    return true
  end

  -- last line of defence
  if fb.file then
    local results = util.get_os_command_output(fb.file + absolute)[1]
    dialog(buffer, window, vim.split(results, ": ", { plain = true })[2], fill_binary)
    return false
  end

  dialog(buffer, window, "CANNOT PREVIEW FILE", fill_file)
  return false
end

local function filetype_hook(filepath, buffer, options)
  local extension = fnamemod(filepath, ":e"):lower()
  local absolute = fnamemod(filepath, ":p")
  local handler = Scope.supports[extension]

  if handler then
    local file_cachepath
    local backend = options.backend
    local backend_options = if_nil(options.backend_options[backend], {})
    local extra_args = if_nil(backend_options.extra_args, {})
    if
      extension == "gif"
      and vim.tbl_contains(Rifle.allows_gifs, backend)
      and backend_options
      and backend_options.move
    then
      file_cachepath = absolute
    elseif options.backend == "file" then
      return redirect(buffer, extension, absolute, options)
    else
      file_cachepath = handler(absolute, options.cache_path, options)
    end
    if file_cachepath == NULL then return redirect(buffer, extension, absolute, options) end

    local window_options = options.get_preview_window()
    if options.backend == "ueberzug" then
      options._ueberzug:send({
        path = file_cachepath,
        x = window_options.col + backend_options.xmove,
        y = window_options.line + backend_options.ymove,
        width = window_options.width,
        height = window_options.height,
      })
      return false
    else
      if not ib[backend] then
        local message = {
          "# `" .. backend .. "` could not be found.\n",
          "Following are the possible reasons.",
          "- Binary is not in `$PATH`",
          "- Has not been registered into the `rifle.bullets` table.",
        }
        vim.notify(table.concat(message, "\n"), ERROR)
        return redirect(buffer, extension, absolute, options)
      end

      local parsed_extra_args = Util.parse_args(extra_args, window_options, options)
      local total_args = ib[backend] + vim.tbl_flatten({ parsed_extra_args, file_cachepath })
      Log.debug("filetype_hook(): arguments generated for " .. backend .. ": " .. table.concat(total_args, " "))
      Util.open_term(buffer, total_args)
      return false
    end
  end
  return redirect(buffer, extension, absolute, options)
end

local MediaPreview = util.make_default_callable(function(options)
  options.cache_path = Path:new(options.cache_path)
  Scope.load_caches(options.cache_path)
  local fill_perm = options.preview.fill.permission

  local ueberzug_options = if_nil(options.backend_options["ueberzug"], {})
  if options.backend == "ueberzug" then
    options._ueberzug = Ueberzug:new(os.tmpname(), not ueberzug_options.warnings)
    options._ueberzug:listen()
  end

  options.preview.filetype_hook = filetype_hook
  options.preview.msg_bg_fillchar = options.preview.fill.mime

  return bview.new_buffer_previewer({
    define_preview = function(self, entry, status)
      local entry_full = (string.format("%s/%s", entry.cwd, entry.value):gsub("//", "/"))
      local function read_access_callback(_, permission)
        if permission then
          -- TODO: Is there a nicer way of doing this?
          options.preview.winid = status.preview_win
          options.winid = status.preview_win -- why?
          bview.file_maker(entry_full, self.state.bufnr, options)
          return
        end
        dialog(self.state.bufnr, self.state.winid, "INSUFFICIENT PERMISSIONS", fill_perm)
      end
      fs_access(entry_full, "R", vim.schedule_wrap(read_access_callback))
      if options.backend == "ueberzug" then
        Log.debug("define_preview(): ueberzug window is now hidden.")
        options._ueberzug:hide()
      end
    end,
    setup = function(self)
      Scope.cleanup(options.cache_path)
      Log.debug("setup(): removed non-cache files")
      return if_nil(self.state, {})
    end,
    teardown = function()
      if options.backend == "ueberzug" and options._ueberzug then
        options._ueberzug:kill()
        options._ueberzug = nil
        Log.info("teardown(): killed ueberzug process.")
      end
    end,
  })
end)

return MediaPreview
