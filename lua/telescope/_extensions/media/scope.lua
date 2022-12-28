local M = {}

local Path = require("plenary.path")
local Job = require("plenary.job")

M.supports = {
  "png",
  "jpeg",
  "jpg",
  "gif",
  "webp",
  "pdf",
}

function M.is_supported(filepath)
  return vim.tbl_contains(M.supports, M.get_extension(filepath))
end

function M.get_extension(filepath)
  return vim.fn.fnamemodify(filepath, ":e")
end

function M.create_cache(path)
  ---@module "plenary.path"
  path = Path:new(path)
  if not path:is_dir() then
    path:mkdir({ exists_ok = true, parents = true })
  end
  vim.g.telescope_media_cache = path.filename
  return vim.g.telescope_media_cache
end

function M.get_filename(filepath)
  return vim.fn.fnamemodify(filepath, ":t:r")
end

function M.cache_images(image_path)
  local cached_path = Path:new(string.format("%s/%s.jpg", vim.g.telescope_media_cache, M.get_filename(image_path)))
  if not cached_path:is_file() then
    vim.fn.system({
      "/bin/convert",
      "-strip",
      "-interlace",
      "Plane",
      "-gaussian-blur",
      "0.05",
      "-quality",
      "30",
      image_path,
      cached_path.filename,
    })
  end
  return cached_path.filename
end

return M

---vim:filetype=lua:fileencoding=utf-8
