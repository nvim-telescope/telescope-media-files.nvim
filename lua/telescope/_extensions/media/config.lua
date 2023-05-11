local M = {}

local executable = vim.fn.executable

M._defaults = {
  backend = "file",
  backend_options = {
    ueberzug = { xmove = -1, ymove = -2 },
    catimg = { move = false },
    chafa = { move = false },
    viu = { move = false },
  },
  on_confirm_single = function(...)
    require("telescope._extensions.media.canned").single.copy_path(...)
  end,
  on_confirm_muliple = function(...)
    require("telescope._extensions.media.canned").multiple.bulk_copy(...)
  end,
  cache_path = "/tmp/media",
  preview_title = "Preview",
  results_title = "Files",
  prompt_title = "Media",
  cwd = vim.fn.getcwd(),
  preview = {
    timeout = 200,
    redraw = false,
    wait = 10,
    fill = {
      mime = "",
      permission = "╱",
      binary = "X",
      file = "~",
      error = ":",
      timeout = "+",
    },
  },
  log = {
    plugin = "telescope-media",
    level = "warn",
  },
}

M._current = vim.deepcopy(M._defaults)

local function validate_find_command(options)
  if options.find_command then
    if type(options.find_command) == "function" then return options.find_command(options) end
    return options.find_command
  elseif 1 == executable("rg") then
    return { "rg", "--files", "--color", "never" }
  elseif 1 == executable("fd") then
    return { "fd", "--type", "f", "--color", "never" }
  elseif 1 == executable("fdfind") then
    return { "fdfind", "--type", "f", "--color", "never" }
  elseif 1 == executable("find") then
    return { "find", ".", "-type", "f" }
  elseif 1 == executable("where") then
    return { "where", "/r", ".", "*" }
  end
  error("Invalid command!", vim.log.levels.ERROR)
end

function M.merge(options)
  options = vim.F.if_nil(options, {})
  options.find_command = validate_find_command(options)
  M._current = vim.tbl_deep_extend("keep", options, M._current)
end

function M.extend(options)
  options.find_command = validate_find_command(options)
  return vim.tbl_deep_extend("keep", options, M._current)
end

function M.get() return M._current end

return M
