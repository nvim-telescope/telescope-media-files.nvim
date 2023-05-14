local M = {}

local Log = require("plenary.log")
local Config = require("telescope._extensions.media.config").get()

M._log = Log.new(Config.log)

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
