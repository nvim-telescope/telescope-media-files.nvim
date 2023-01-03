local M = {}

local previewers = require("telescope.previewers")
local Ueberzug = require("telescope._extensions.media.ueberzug")
local scope = require("telescope._extensions.media.scope")

local fn = vim.fn

function M.ueberzug(options, cache_path)
  local UEBERZUG = Ueberzug:new(os.tmpname())
  UEBERZUG:listen()
  return previewers.new({
    setup = function() scope.cleanup(cache_path) end,
    preview_fn = function(_, entry, _)
      local preview = options.get_preview_window()
      local handler = scope.supports[fn.fnamemodify(entry.value, ":e")]
      if handler then
        UEBERZUG:send({
          path = handler(fn.fnamemodify(entry.value, ":p"), cache_path, {
            quality = "30%",
            blurred = "0.02",
          }),
          x = preview.col + options.geometry.x,
          y = preview.line + options.geometry.y,
          width = preview.width + options.geometry.width,
          height = preview.height + options.geometry.height,
        })
      end
    end,
    teardown = function() UEBERZUG:kill() end,
  })
end

function M.viu(options, cache_path)
  return previewers.new_termopen_previewer({
    get_command = function(entry)
      local preview = options.get_preview_window()
      local handler = scope.supports[fn.fnamemodify(entry.value, ":e")]
      return {
        "viu",
        "-b",
        "-s",
        handler(fn.fnamemodify(entry.value, ":p"), cache_path, { quality = "30%", blurred = "0.02" }),
      }
    end,
  })
end

function M.chafa(options, cache_path)
  return previewers.new_termopen_previewer({
    get_command = function(entry)
      local preview = options.get_preview_window()
      local handler = scope.supports[fn.fnamemodify(entry.value, ":e")]
      return {
        "chafa",
        "--animate",
        "off",
        handler(fn.fnamemodify(entry.value, ":p"), cache_path, { quality = "30%", blurred = "0.02" }),
      }
    end,
  })
end

function M.jp2a(options, cache_path)
  return previewers.new_termopen_previewer({
    get_command = function(entry)
      local preview = options.get_preview_window()
      local handler = scope.supports[fn.fnamemodify(entry.value, ":e")]
      return {
        "jp2a",
        handler(fn.fnamemodify(entry.value, ":p"), cache_path, { quality = "30%", blurred = "0.02" }),
      }
    end,
  })
end

return M
