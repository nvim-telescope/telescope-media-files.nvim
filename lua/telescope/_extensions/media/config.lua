local M = {}

local executable = vim.fn.executable

---@class LogOptions
---@field plugin string name of the log file
---@field level string log level
---@field highlights boolean log file highlights
---@field use_file boolean write log entries into a file
---@field use_quickfix boolean write entries into the quickfix list

---@class FillOptions
---@field mime string character to be displayed when no mime matches are found for current entry
---@field permission string character to be displayed when current entry requires privilege elevation
---@field binary string character to be displayed when current entry is a binary
---@field file string string character to be displayed when current entry handler is the output of the file command
---@field error string character to be displayed when the handler task fails
---@field timeout string character to be displayed when the handler task exceeds the timeout

---@class PreviewOptions
---@field redraw boolean it |:redraw|s pending screen updates now
---@field timeout number number of milliseconds to wait
---@field wait number (approximate) number of milliseconds to wait between polls
---@field fill FillOptions display padded text on various conditions these will allow changing the padding character

---@class UeberzugOptions
---@field xmove number xoffset
---@field ymove number yoffset
---@field warnings boolean display warning messages
---@field supress_backend_warning boolean supress warning: https://github.com/dharmx/telescope-media.nvim/issues/9

---@class SharedBackendOptions
---@field move boolean allow rendering gifs
---@field extra_args string[] additional arguments that will be forwarded to the backend

---@class Callbacks
---@field on_confirm_single function when only one entry has been selected
---@field on_confirm_muliple function when more than one entries has been selected

---@class BackendOptions
---@field catimg SharedBackendOptions options for the catimg backend
---@field chafa SharedBackendOptions options for the chafa backend
---@field viu SharedBackendOptions options for the viu backend
---@field ueberzug UeberzugOptions options for the ueberzug backend

---@class MediaConfig
---@field backend "catimg"|"chafa"|"viu"|"ueberzug"|"file"|"jp2a"|string backend choice
---@field cache_path string directory path where all cached images, videos, fonts, etc will be saved
---@field preview_title string title of the preview buffer
---@field results_title string title of the results buffer
---@field prompt_title string title of the prompt buffer
---@field cwd string current working directory
---@field callbacks Callbacks callbacks for various conditions
---@field backend_options BackendOptions general/backend-specific options
---@field preview PreviewOptions options related to the preview buffer
---@field log LogOptions logger configuration (developer option)
---@field find_command string[] command that will fetch file lists
---@field hidden boolean show hidden files and directories when true
---@field search_dirs string[] search directories
---@field no_ignore boolean ignore files/directories
---@field no_ignore_parent boolean ignore parent files/directories
---@field follow boolean boolean follow for changes
---@field search_file boolean search in a specifc file

---The default telescope-media.nvim configuration table.
---@type MediaConfig
M._defaults = {
  backend = "file",
  backend_options = {
    catimg = { move = false },
    chafa = { move = false },
    viu = { move = false },
    ueberzug = { xmove = -1, ymove = -2, warnings = true, supress_backend_warning = false },
  },
  callbacks = {
    on_confirm_single = function(...) require("telescope._extensions.media.canned").single.copy_path(...) end,
    on_confirm_muliple = function(...) require("telescope._extensions.media.canned").multiple.bulk_copy(...) end,
  },
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
      file = "~",
      error = ":",
      binary = "X",
      timeout = "+",
      permission = "╱",
    },
  },
  log = {
    plugin = "telescope-media",
    level = "warn",
    highlights = true,
    use_file = true,
    use_quickfix = false,
  },
}

---@type MediaConfig
M._current = vim.deepcopy(M._defaults)

---@param options MediaConfig
---@return string[]
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

---Merge passed options with current options state table
---@param options MediaConfig
function M.merge(options)
  options = vim.F.if_nil(options, {})
  options.find_command = validate_find_command(options)
  M._current = vim.tbl_deep_extend("keep", options, M._current)
end

---Extend passed options with current options state (this will not modify current options state table)
---@param options MediaConfig
function M.extend(options)
  options.find_command = validate_find_command(options)
  return vim.tbl_deep_extend("keep", options, M._current)
end

---Get current options table (M._current)
---@return MediaConfig
function M.get() return M._current end

return M
