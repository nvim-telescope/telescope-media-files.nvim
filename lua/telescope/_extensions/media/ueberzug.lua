---@tag media.ueberzug

---@config { ["name"] = "UEBERZUG", ["field_heading"] = "Options", ["module"] = "telescope._extensions.media.ueberzug" }

---@brief [[
--- This is a simple wrapper over python-ueberzug. All it does is start a ueberzug daemon which
--- listens in on a FIFO file for actions and displays images with respect to it.
--- Note that it also depends on `tail` for noticing the changes.
---
--- A standard example of using this is below:
--- <code>
--- local Ueberzug = require("telescope._extensions.media.ueberzug")
--- local ueberzug = Ueberzug:new(os.tmpname())
---
--- ueberzug:listen()
--- ueberzug:send("montage.png")
--- ueberzug:kill()
--- </code>
---@brief ]]

local Job = require("plenary.job")
local Path = require("plenary.path")

local SIGKILL = 9

---@class Ueberzug
---@field fifo Path the path to the FIFO file
---@field task Job the actual job that tails the file and supplies `stdin` to ueberzug.
local Ueberzug = {}

---@alias JobHandler fun(error: string, data: string, self: Job) handler functions like on_stderr that can be passed into Job.
---@alias TailOptions { on_start: JobHandler, on_stdout: JobHandler, on_exit: fun(self: Job, code: integer, signal: integer), on_start: function } options for the tail function.

--- A helper function for generating a tail job that will be used as a stdin supplier.
---@param fifo Path|string location to the fifo file.
---@param options table<TailOptions>? optional table that accepts Job handler functions.
---@return Job
---@private should I expose this?
local function _tail(fifo, options)
  options = vim.F.if_nil(options, {})
  return Job:new({
    command = "tail",
    args = {
      "--silent",
      "--follow",
      fifo,
    },
    on_stdout = options.on_stdout,
    on_start = options.on_start,
    on_exit = options.on_exit,
    on_stderr = options.on_stderr,
  })
end

--- Initialize a new ueberzug daemon but do not start the daemon job.
---@param fifo Path|string path to the fifo file.
---@return Ueberzug
function Ueberzug:new(fifo)
  fifo = Path:new(fifo)
  fifo:touch({ parents = true })

  local ueberzug_task = Job:new({
    command = "ueberzug",
    args = {
      "--silent",
      "layer",
      "--parser",
      "json", -- we have vim.json.(en|de)code which makes parsing dead simple
    },
    writer = _tail(fifo.filename), -- stdin supplier
  })

  self.__index = self
  return setmetatable({ fifo = fifo, task = ueberzug_task }, self)
end

--- Starts the ueberzug daemon.
function Ueberzug:listen() self.task:start() end

--- Remove the FIFO file.
function Ueberzug:clean() self.fifo:rm() end

--- Stop the ueberzug daemon. Stop viewing images and remove the FIFO file.
function Ueberzug:kill()
  assert(self.task, "Ueberzug task is not running!")
  vim.loop.kill(self.task.writer.pid, SIGKILL)
  self:clean()
end

---@alias UeberzugMessage { action: string, identifier: string, x: integer, y: integer, width: integer, height: integer, path: string } message specification.

--- Send a message to the ueberzug daemon. This is used to send what images will be previewed next.
---@param message UeberzugMessage|string message that needs to be sent to the daemon. A table means a whole message specification and string means just a path to the image. Having an empty string or, |vim.NIL| as the path will view nothing.
---@field identifier string a freely choosen identifier of the image
---@field x integer x position
---@field y integer y position
---@field width integer desired width; original width will be used if not set
---@field height integer desired height; original height will be used if not set
function Ueberzug:send(message)
  local defaults = {
    action = "add",
    identifier = "tele.media.fifo",
    x = 0,
    y = 0,
    width = 100,
    height = 50,
  }

  message = vim.tbl_extend("keep", type(message) == "table" and message or {
    path = message,
  }, defaults)
  assert(message.action == "add", "Changing action key is not allowed.", vim.log.levels.ERROR)

  -- /tmp/tele.media.cache becomes \/tmp\/tele.media.cache
  -- for some reason path string is escaped - so we attempt to remove the \
  self.fifo:write((vim.json.encode(message):gsub("\\", "")) .. "\n", "a")
end

function Ueberzug:hide() self:send({ path = vim.NIL, x = 1, y = 1, width = 1, height = 1 }) end

return Ueberzug

-- vim:filetype=lua:fileencoding=utf-8
