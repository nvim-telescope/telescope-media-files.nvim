---@tag media.scope

---@config { ["name"] = "SCOPE", ["field_heading"] = "Options", ["module"] = "telescope._extensions.media.scope" }

---@brief [[
--- Functions and utils that will handle caching and supplying Ueberzug or, any other
--- backend with the cache path.
---@brief ]]

-- Imports and file-local definitions. {{{
local M = {}

local Path = require("plenary.path")
local sha = require("telescope._extensions.media.sha")
local utils = require("telescope._extensions.media.utils")
local scandir = require("plenary.scandir")

local fn = vim.fn
local uv = vim.loop
local F = vim.F
local NULL = vim.NIL

--- All filenames that are located at the `cache_path`.
---@type table<string>
M.caches = {}

---@alias NULL NULL

--- Handler or, cache maker functions for specific filetypes and filetype categories.
--- Like for example `image_handler` is a filetype category which consists of JPGs, PNGs, JIFFs, etc.
--- And `gif_handler` for example, can be called a specialized handler.
---@type table<string, fun(filepath: string, cache_path: Path, options: tablelib): NULL|string>
M.handlers = {}

--- Handler registry. Hardcoded handlers for individual filetypes.
--- Calling the table will return a table of currently supported filetypes.
---@type table<string, fun(filepath: string, cache_path: Path, options: table): NULL|string>|fun(): table<string>
M.supports = setmetatable({}, {
  __call = function(self) return vim.tbl_keys(self) end,
})
-- }}}

-- Helper functions. {{{
function M.load_caches(cache_path)
  if cache_path:is_dir() then
    local files = fn.readdir(cache_path.filename)
    for _, file in ipairs(files) do
      M.caches[file] = true
    end
  else
    cache_path:mkdir({ parents = true, exists_ok = true })
  end
end

function M.cleanup(cache_path)
  scandir.scan_dir(cache_path.filename, {
    add_dirs = true,
    hidden = true,
    on_insert = function(path)
      local stem = fn.fnamemodify(path, ":t:r")
      if #stem ~= 128 then
        path = Path:new(path)
        if path:exists() then path:rm() end
      end
    end,
  })
end

---@private
local function _encode_options(filepath, cache_path, options)
  if options.alias then filepath = options.alias end
  local encoded_path = sha.sha512(uv.fs_stat(filepath).ino .. filepath):upper() .. ".jpg"
  local cached_path = cache_path.filename .. "/" .. encoded_path
  return F.if_nil(M.caches[encoded_path] and cached_path, false), encoded_path, cached_path
end
-- }}}

-- Handler functions. {{{
---@param image_path string
---@param cache_path Path
---@param options tablelib
---@return unknown
function M.handlers.image_handler(image_path, cache_path, options)
  local in_cache, sha_path, cached_path = _encode_options(image_path, cache_path, options)
  if in_cache then return in_cache end
  utils.magick(image_path, cached_path, options, function() M.caches[sha_path] = true end)
  return image_path
end

---@param font_path string
---@param cache_path Path
---@param options tablelib
---@return unknown
function M.handlers.font_handler(font_path, cache_path, options)
  local in_cache, sha_path, cached_path = _encode_options(font_path, cache_path, options)
  if in_cache then return in_cache end
  utils.fontmagick(font_path, cached_path, options, function(self, _)
    if self.code == 0 then M.caches[sha_path] = true end
  end)
  return NULL
end

---@param video_path string
---@param cache_path Path
---@param options tablelib
---@return unknown
function M.handlers.video_handler(video_path, cache_path, options)
  local in_cache, sha_path, cached_path = _encode_options(video_path, cache_path, options)
  if in_cache then return in_cache end
  utils.ffmpeg(video_path, cached_path, options, function(_, code, _)
    if code == 0 then
      M.caches[sha_path] = true
    else
      utils.ffmpegthumbnailer(video_path, cached_path, options, function(_, _code, _)
        if _code == 0 then M.caches[sha_path] = true end
      end)
    end
  end)
  return NULL
end

---@param gif_path string
---@param cache_path Path
---@param options tablelib
---@return unknown
function M.handlers.gif_handler(gif_path, cache_path, options)
  local in_cache, sha_path, cached_path = _encode_options(gif_path, cache_path, options)
  if in_cache then return in_cache end
  options.index = "[0]"
  utils.magick(gif_path, cached_path, options, function(_, code, _)
    if code == 0 then M.caches[sha_path] = true end
  end)
  return NULL
end

---@param audio_path string
---@param cache_path Path
---@param options tablelib
---@return unknown
function M.handlers.audio_handler(audio_path, cache_path, options)
  local in_cache, sha_path, cached_path = _encode_options(audio_path, cache_path, options)
  if in_cache then return in_cache end
  utils.ffmpeg(audio_path, cached_path, options, function(_, code, _)
    if code == 0 then M.caches[sha_path] = true end
  end)
  return NULL
end

---@param pdf_path string
---@param cache_path Path
---@param options tablelib
---@return unknown
function M.handlers.pdf_handler(pdf_path, cache_path, options)
  local in_cache, sha_path, cached_path = _encode_options(pdf_path, cache_path, options)
  if in_cache then return in_cache end
  utils.pdftoppm(pdf_path, cached_path, options, function(_, code, _)
    if code == 0 then M.caches[sha_path] = true end
  end)
  return NULL
end

---@param epub_path string
---@param cache_path Path
---@param options tablelib
---@return unknown
function M.handlers.epub_handler(epub_path, cache_path, options)
  local in_cache, sha_path, cached_path = _encode_options(epub_path, cache_path, options)
  if in_cache then return in_cache end
  utils.epubthumbnailer(epub_path, cached_path, options, function(_, code, _)
    if code == 0 then
      M.caches[sha_path] = true
    else
      utils.ebookmeta(epub_path, cached_path, options, function(_, child_code, _)
        if child_code == 0 then M.caches[sha_path] = true end
      end)
    end
  end)
  return NULL
end
-- }}}

-- Adding handlers to supported filetypes. {{{
M.supports["pdf"] = M.handlers.pdf_handler

M.supports["gif"] = M.handlers.gif_handler
M.supports["eps"] = M.handlers.gif_handler

M.supports["epub"] = M.handlers.epub_handler
M.supports["mobi"] = M.handlers.epub_handler
M.supports["fb2"] = M.handlers.epub_handler

M.supports["png"] = M.handlers.image_handler
M.supports["jpg"] = M.handlers.image_handler
M.supports["jpeg"] = M.handlers.image_handler
M.supports["svg"] = M.handlers.image_handler
M.supports["webp"] = M.handlers.image_handler
M.supports["jpg"] = M.handlers.image_handler
M.supports["bmp"] = M.handlers.image_handler
M.supports["jiff"] = M.handlers.image_handler
M.supports["ai"] = M.handlers.image_handler

M.supports["otf"] = M.handlers.font_handler
M.supports["ttf"] = M.handlers.font_handler
M.supports["woff"] = M.handlers.font_handler
M.supports["woff2"] = M.handlers.font_handler

M.supports["mp4"] = M.handlers.video_handler
M.supports["mkv"] = M.handlers.video_handler
M.supports["flv"] = M.handlers.video_handler
M.supports["3gp"] = M.handlers.video_handler
M.supports["wmv"] = M.handlers.video_handler
M.supports["mov"] = M.handlers.video_handler
M.supports["webm"] = M.handlers.video_handler
M.supports["mpg"] = M.handlers.video_handler
M.supports["mpeg"] = M.handlers.video_handler
M.supports["avi"] = M.handlers.video_handler
M.supports["ogg"] = M.handlers.video_handler

M.supports["aa"] = M.handlers.audio_handler
M.supports["aac"] = M.handlers.audio_handler
M.supports["aiff"] = M.handlers.audio_handler
M.supports["alac"] = M.handlers.audio_handler
M.supports["mp3"] = M.handlers.audio_handler
M.supports["opus"] = M.handlers.audio_handler
M.supports["oga"] = M.handlers.audio_handler
M.supports["mogg"] = M.handlers.audio_handler
M.supports["wav"] = M.handlers.audio_handler
M.supports["cda"] = M.handlers.audio_handler
M.supports["wma"] = M.handlers.audio_handler

return M
-- }}}

-- vim:filetype=lua:fileencoding=utf-8
