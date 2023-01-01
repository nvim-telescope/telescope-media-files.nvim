local M = {}

local NO_PREVIEW = vim.fn.fnamemodify(require("plenary.debug_utils").sourced_filepath(), ":h:h:h:h:h")
  .. "/.github/none.jpg"

local Job = require("plenary.job")
local Path = require("plenary.path")

local sha = require("telescope._extensions.media.sha")
local fn = vim.fn
local uv = vim.loop

M.caches = {}
M.handlers = {}

M.supports = setmetatable({}, {
  __call = function(self)
    return vim.tbl_map(string.lower, vim.tbl_keys(self))
  end,
})

function M.encode_name(filepath, inode)
  return sha.sha512(inode .. filepath):upper()
end

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

function M.handlers.image_handler(image_path, cache_path, options)
  local sha_path = M.encode_name(image_path, uv.fs_stat(image_path).ino) .. ".jpg"
  local cached_path = cache_path.filename .. "/" .. sha_path
  if M.caches[sha_path] then
    return cached_path
  end

  options = vim.tbl_extend("keep", options, {
    quality = "20%",
    blurred = "0.06",
    interlace = "Plane",
  })
  Job:new({
    command = "convert",
    args = {
      "-strip",
      "-interlace",
      options.interlace,
      "-gaussian-blur",
      options.blurred,
      "-quality",
      options.quality,
      image_path,
      cached_path,
    },
    interactive = false,
    enable_handlers = false,
    enable_recording = false,
    on_exit = function(_, code, _)
      if code == 0 then
        M.caches[sha_path] = true
      end
    end,
  }):start()
  return image_path
end

function M.handlers.font_handler(font_path, cache_path, options)
  local sha_path = M.encode_name(font_path, uv.fs_stat(font_path).ino) .. ".jpg"
  local cached_path = cache_path.filename .. "/" .. sha_path
  if M.caches[sha_path] then
    return cached_path
  end

  options = vim.tbl_extend("keep", options, {
    quality = "90%",
    blurred = "0.0",
    interlace = "Plane",
    width = "-1",
    height = "-1",
    text_lines = {
      [[  ABCDEFGHIJKLMNOPQRSTUVWXYZ  ]],
      [[  abcdefghijklmnopqrstuvwxyz  ]],
      [[  0123456789.:,;(*!?') ff fl fi ffi ffl  ]],
      [[  The quick brown fox jumps over the lazy dog.  ]],
    },
  })
  Job:new({
    command = "fontimage",
    args = {
      "--o",
      cached_path .. ".png",
      "--width",
      options.width,
      "--height",
      options.height,
      "--pixelsize",
      "120",
      "--fontname",
      "--pixelsize",
      "80",
      "--text",
      options.text_lines[1],
      "--text",
      options.text_lines[2],
      "--text",
      options.text_lines[3],
      "--text",
      options.text_lines[4],
      font_path,
    },
    interactive = false,
    enable_handlers = false,
    enable_recording = false,
    on_exit = function(result, _)
      if result.code == 0 then
        local image_path = Path:new(result.args[2])
        Job:new({
          command = "convert",
          args = {
            "-strip",
            "-interlace",
            options.interlace,
            "-gaussian-blur",
            options.blurred,
            "-quality",
            options.quality,
            image_path.filename,
            cached_path,
          },
          interactive = false,
          enable_handlers = false,
          enable_recording = false,
          on_exit = function(_, code, _)
            if code == 0 and image_path:is_file() then
              M.caches[sha_path] = true
              image_path:rm()
            end
          end,
        }):start()
      end
    end,
  }):start()
  return NO_PREVIEW
end

function M.handlers.video_handler(video_path, cache_path, options)
  local sha_path = M.encode_name(video_path, uv.fs_stat(video_path).ino) .. ".jpg"
  local cached_path = cache_path.filename .. "/" .. sha_path
  if M.caches[sha_path] then
    return cached_path
  end

  Job:new({
    command = "ffmpeg",
    args = {
      "-i",
      video_path,
      "-map",
      "0:v",
      "-map",
      "0:V",
      "-c",
      "copy",
      cached_path,
    },
    interactive = false,
    enable_handlers = false,
    enable_recording = false,
    on_exit = function(r, code, _)
      if code == 0 then
        M.caches[sha_path] = true
      else
        Job:new({
          command = "ffmpegthumbnailer",
          args = {
            "-i",
            video_path,
            "-o",
            cached_path,
            "-s",
            "0",
          },
          interactive = false,
          enable_handlers = false,
          enable_recording = false,
          on_exit = function(_, child_code, _)
            if child_code == 0 then
              M.caches[sha_path] = true
            end
          end,
        }):start()
      end
    end,
  }):start()
  return NO_PREVIEW
end

function M.handlers.gif_handler(gif_path, cache_path, options)
  local sha_path = M.encode_name(gif_path, uv.fs_stat(gif_path).ino) .. ".jpg"
  local cached_path = cache_path.filename .. "/" .. sha_path
  if M.caches[sha_path] then
    return cached_path
  end

  options = vim.tbl_extend("keep", options, {
    quality = "20%",
    blurred = "0.06",
    interlace = "Plane",
  })
  Job:new({
    command = "convert",
    args = {
      "-strip",
      "-interlace",
      options.interlace,
      "-gaussian-blur",
      options.blurred,
      "-quality",
      options.quality,
      gif_path .. "[0]",
      cached_path,
    },
    interactive = false,
    enable_handlers = false,
    enable_recording = false,
    on_exit = function(_, code, _)
      if code == 0 then
        M.caches[sha_path] = true
      end
    end,
  }):start()
  return NO_PREVIEW
end

function M.handlers.audio_handler(audio_path, cache_path, options)
  local sha_path = M.encode_name(audio_path, uv.fs_stat(audio_path).ino) .. ".jpg"
  local cached_path = cache_path.filename .. "/" .. sha_path
  if M.caches[sha_path] then
    return cached_path
  end

  Job:new({
    command = "ffmpeg",
    args = {
      "-i",
      audio_path,
      "-map",
      "0:v",
      "-map",
      "-0:V",
      "-c",
      "copy",
      cached_path,
    },
    interactive = false,
    enable_handlers = false,
    enable_recording = false,
    on_exit = function(_, code, _)
      if code == 0 then
        M.caches[sha_path] = true
      end
    end,
  }):start()
  return NO_PREVIEW
end

function M.handlers.pdf_handler(pdf_path, cache_path, options)
  local sha_path = M.encode_name(pdf_path, uv.fs_stat(pdf_path).ino) .. ".jpg"
  local cached_path = cache_path.filename .. "/" .. sha_path
  if M.caches[sha_path] then
    return cached_path
  end

  Job:new({
    command = "pdftoppm",
    args = {
      "-f",
      "1",
      "-l",
      "1",
      "-scale-to-x",
      "-1",
      "-scale-to-y",
      "-1",
      "-singlefile",
      "-jpeg",
      "-tiffcompression",
      "jpeg",
      pdf_path,
      fn.fnamemodify(cached_path, ":r"),
    },
    interactive = false,
    enable_handlers = false,
    enable_recording = false,
    on_exit = function(_, code, _)
      if code == 0 then
        M.caches[sha_path] = true
      end
    end,
  }):start()
  return NO_PREVIEW
end

M.supports["GIF"] = M.handlers.gif_handler
M.supports["EPS"] = M.handlers.gif_handler
M.supports["PDF"] = M.handlers.pdf_handler

M.supports["PNG"] = M.handlers.image_handler
M.supports["JPG"] = M.handlers.image_handler
M.supports["JPEG"] = M.handlers.image_handler
M.supports["SVG"] = M.handlers.image_handler
M.supports["WEBP"] = M.handlers.image_handler
M.supports["JPG"] = M.handlers.image_handler
M.supports["BMP"] = M.handlers.image_handler
M.supports["JIFF"] = M.handlers.image_handler
M.supports["AI"] = M.handlers.image_handler

M.supports["OTF"] = M.handlers.font_handler
M.supports["TTF"] = M.handlers.font_handler
M.supports["WOFF"] = M.handlers.font_handler
M.supports["WOFF2"] = M.handlers.font_handler

M.supports["MP4"] = M.handlers.video_handler
M.supports["MKV"] = M.handlers.video_handler
M.supports["FLV"] = M.handlers.video_handler
M.supports["3GP"] = M.handlers.video_handler
M.supports["WMV"] = M.handlers.video_handler
M.supports["MOV"] = M.handlers.video_handler
M.supports["WEBM"] = M.handlers.video_handler
M.supports["MPG"] = M.handlers.video_handler
M.supports["MPEG"] = M.handlers.video_handler
M.supports["AVI"] = M.handlers.video_handler
M.supports["OGG"] = M.handlers.video_handler

M.supports["AA"] = M.handlers.audio_handler
M.supports["AAC"] = M.handlers.audio_handler
M.supports["AIFF"] = M.handlers.audio_handler
M.supports["ALAC"] = M.handlers.audio_handler
M.supports["MP3"] = M.handlers.audio_handler
M.supports["OPUS"] = M.handlers.audio_handler
M.supports["OGA"] = M.handlers.audio_handler
M.supports["MOGG"] = M.handlers.audio_handler
M.supports["WAV"] = M.handlers.audio_handler
M.supports["CDA"] = M.handlers.audio_handler
M.supports["WMA"] = M.handlers.audio_handler

return M

---vim:filetype=lua:fileencoding=utf-8
