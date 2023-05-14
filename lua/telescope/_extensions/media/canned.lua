local M = {}

local Job = require("plenary.job")

local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")

local V = vim.fn
local if_nil = vim.F.if_nil

M.single = {}
M.multiple = {}
M.actions = {}

local function _enpath(entry) return (string.format("%s/%s", entry.cwd, entry.value):gsub("//", "/")) end

function M.single.copy_path(entry, options)
  entry = _enpath(entry)
  options = vim.tbl_extend("keep", if_nil(options, {}), {
    name_mod = ":p",
  })
  V.setreg(vim.v.register, V.fnamemodify(entry, options.name_mod))
end

function M.single.copy_image(entry, options)
  entry = _enpath(entry)
  if not vim.tbl_contains({ "png", "jpg", "jpeg", "jiff", "webp" }, V.fnamemodify(entry, ":e")) then return end
  options = vim.tbl_extend("keep", if_nil(options, {}), {
    command = "xclip",
    args = { "-selection", "clipboard", "-target", "image/png", entry },
  })
  Job:new(options):start()
end

function M.single.set_wallpaper(entry, options)
  entry = _enpath(entry)
  if not vim.tbl_contains({ "png", "jpg", "jpeg", "jiff", "webp" }, V.fnamemodify(entry, ":e")) then return end
  vim.ui.select(
    {
      "TILE",
      "SCALE",
      "FILL",
      "CENTER",
    },
    {
      prompt = "Background type:",
      format_item = function(item) return "Set background behavior to " .. item end,
    },
    function(choice)
      Job:new(vim.tbl_extend("keep", if_nil(options, {}), {
        command = "feh",
        args = { "--bg-" .. choice:lower(), entry },
      })):start()
    end
  )
end

function M.single.open_path(entry, options)
  entry = _enpath(entry)
  options = vim.tbl_extend("force", if_nil(options, {}), {
    command = "xdg-open",
    args = { entry },
  })
  Job:new(options):start()
end

function M.multiple.bulk_copy(entries, options)
  entries = vim.tbl_map(function(entry) return _enpath(entry) end, entries)
  options = vim.tbl_extend("keep", if_nil(options, {}), { name_mod = ":p" })
  V.setreg(
    vim.v.register,
    table.concat(vim.tbl_map(function(item) return V.fnamemodify(item, options.name_mod) end, entries), "\n")
  )
end

local function _split(prompt_buffer, command)
  local picker = actions_state.get_current_picker(prompt_buffer)
  local selections = picker:get_multi_selection()
  local entry = _enpath(actions_state.get_selected_entry())

  actions.close(prompt_buffer)
  if #selections < 2 then
    vim.cmd[command](entry.value)
  else
    for _, selection in ipairs(selections) do
      vim.cmd[command](selection.value)
    end
  end
end

function M.actions.multiple_split(prompt_buffer) _split(prompt_buffer, "split") end

function M.actions.multiple_vsplit(prompt_buffer) _split(prompt_buffer, "vsplit") end

return M
