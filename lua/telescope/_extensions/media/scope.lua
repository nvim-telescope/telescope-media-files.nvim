local M = {}

local fn = vim.fn
local Path = require("plenary.path")
local Job = require("plenary.job")

M.SUP_FTYPE = {
  IMAGE = { "png", "jpeg", "jpg", "gif", "webp" },
}

M.SUP_FTYPE_FLAT = vim.tbl_flatten(vim.tbl_values(M.SUP_FTYPE))

function M.supports(filepath, category)
  if category then
    return vim.tbl_contains(M.SUP_FTYPE[category:upper()], M.get_extension(filepath))
  end
  return vim.tbl_contains(M.SUP_FTYPE_FLAT, M.get_extension(filepath))
end

function M.get_extension(filepath)
  return fn.fnamemodify(filepath, ":e")
end

function M.get_filename(filepath)
  return fn.fnamemodify(filepath, ":t:r")
end

function M.create_cache(cache_path)
  cache_path = Path:new(cache_path)
  if not cache_path:is_dir() then
    cache_path:mkdir({ exists_ok = true, parents = true })
  end

  for subcache, _ in pairs(M.SUP_FTYPE) do
    local path = Path:new(cache_path .. "/" .. subcache)
    if not path:is_dir() then
      path:mkdir({ exists_ok = true, parents = true })
    end
  end
  return cache_path
end

function M.delete_cache(cache_path)
  local cached_path = Path:new(cache_path)
  if cached_path:is_dir() then
    cached_path:rm({ recursive = true })
  end
end

function M.redirector(filepath, cache_path, options)
  if M.supports(filepath, "IMAGE") then
    return M.handle_image(filepath, cache_path, options)
  end
end

function M.handle_image(image_path, cache_path, options)
  local defaults = vim.tbl_extend("keep", vim.F.if_nil(options, {}), {
    quality = "25%",
    blurred = "0.06",
  })

  local cached_path = string.format("%s/IMAGE/%s.jpg", cache_path, M.get_filename(image_path))
  if not Path:new(cached_path):is_file() then
    Job:new({
      command = "/usr/bin/convert",
      args = {
        "-strip",
        "-interlace",
        "Plane",
        "-gaussian-blur",
        defaults.blurred,
        "-quality",
        defaults.quality,
        image_path,
        cached_path,
      },
    }):start()
    return image_path
  end
  return cached_path
end

return M

---vim:filetype=lua:fileencoding=utf-8
