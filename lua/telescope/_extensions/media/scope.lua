local M = {}

local Job = require("plenary.job")
local Path = require("plenary.path")
local sha = require("telescope._extensions.media.sha")
local fn = vim.fn

M.caches = {}

M.handlers = {}

local function encode_name(filepath, inode)
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

function M.handlers.PNG(image_path, cache_path, options)
  local sha_path = encode_name(image_path, vim.loop.fs_stat(image_path).ino) .. ".jpg"
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

M.handlers.JPG = M.handlers.PNG
M.handlers.JPEG = M.handlers.PNG
M.handlers.SVG = M.handlers.PNG
M.handlers.WEBP = M.handlers.PNG
M.handlers.JPG = M.handlers.PNG
M.handlers.BMP = M.handlers.PNG
M.handlers.JIFF = M.handlers.PNG

function M.handlers.OTF(font_path, cache_path, options)
  local sha_path = encode_name(font_path, vim.loop.fs_stat(font_path).ino) .. ".jpg"
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
end

M.handlers.TTF = M.handlers.OTF
M.handlers.WOFF = M.handlers.OTF
M.handlers.WOFF2 = M.handlers.OTF

return M

---vim:filetype=lua:fileencoding=utf-8
