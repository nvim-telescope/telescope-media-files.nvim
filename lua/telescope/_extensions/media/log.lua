local M = {}

local Log = require("plenary.log")
local Config = require("telescope._extensions.media.config").get()

---@class Log
---@field debug function
---@field error function
---@field trace function
---@field warn function
---@field info function
---@field fatal function
M._log = Log.new(Config.log)

---An organised way to log errors. This logs the error message into the
---log file and also displays that message as a notification.
---@param bool boolean the condition that needs to be checked. An assertsion.
---@param message string the message to display if the assertion fails.
---@param title string the title of the error popup/notification.
function M.errors(bool, message, title)
  assert(message and title, "All params are required.")
  if not bool then
    error(message, vim.log.levels.ERROR)
    M._log.error(title .. "(): " .. message)
  end
end

return setmetatable(M, {
  __index = function(_, key) return M._log[key] end,
})
