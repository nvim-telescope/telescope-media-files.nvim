---@module "telescope._extensions.media.ueberzug"
---@diagnostic disable: undefined-field

local Job = require("plenary.job")
local Path = require("plenary.path")

local SIGKILL = 9
local EXIT_SUCCESS = 0

---@alias Path Path
---@alias Job Job

---@class Ueberzug
---@field fifo Path
---@field task Job
local Ueberzug = {}

local function tail(fifo, options)
  options = vim.F.if_nil(options, {})
  return Job:new({
    command = "tail",
    args = {
      "--silent",
      "--follow",
      fifo,
    },
    on_start = options.on_start,
    on_exit = options.on_exit,
    on_stderr = options.on_stderr,
  })
end

function Ueberzug:new(fifo)
  fifo = Path:new(fifo)
  fifo:touch({ parents = true })

  local ueberzug_task = Job:new({
    command = "ueberzug",
    args = {
      "--silent",
      "layer",
      "--parser",
      "json",
    },
    writer = tail(fifo.filename),
  })

  self.__index = self
  return setmetatable({ fifo = fifo, task = ueberzug_task }, self)
end

function Ueberzug:listen()
  self.task:start()
end

function Ueberzug:clean()
  self.fifo:rm()
end

function Ueberzug:shutdown()
  assert(self.task, "Ueberzug task is not running!")
  vim.loop.kill(self.task.writer.pid, SIGKILL)
  self:clean()
end

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
  self.fifo:write((vim.json.encode(message):gsub("\\", "")) .. "\n", "a")
end

return Ueberzug

---vim:filetype=lua
