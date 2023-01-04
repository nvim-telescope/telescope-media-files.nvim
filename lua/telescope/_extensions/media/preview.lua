-- Imports and local declarations. {{{
local Path = require("plenary.path")
local Job = require("plenary.job")
local Ueberzug = require("telescope._extensions.media.ueberzug")

local utils = require("telescope.utils")
local previewers = require("telescope.previewers")
local scope = require("telescope._extensions.media.scope")
local filetype = require("plenary.filetype")

local preview_utils = require("telescope.previewers.utils")

local api = vim.api
local fn = vim.fn
local uv = vim.loop
local F = vim.F
-- }}}

-- Helper functions. {{{
local function ueberzug_hide(options, ueberzug)
  if options.backend == "ueberzug" and ueberzug then
    ueberzug:send({
      path = vim.NIL,
      x = 100,
      y = 100,
      width = 1,
      height = 1,
    })
  end
end

local function split(string, separator, plain, options)
  options = options or {}
  local items = {}
  for item in vim.gsplit(string, separator, plain) do
    table.insert(items, item)
    if options.preview.timeout then
      local diff_time = (vim.loop.hrtime() - options.start_time) / 1E6
      if diff_time > options.preview.timeout then return end
    end
  end
  return items
end
-- }}}

-- MediaPreview previewer {{{
local MediaPreview = utils.make_default_callable(function(options)
  -- Initial preparation. {{{
  options = F.if_nil(options, {})
  options.preview = F.if_nil(options.preview, {})
  options.preview.timeout = F.if_nil(options.preview.timeout, 250)
  options.preview.filesize = F.if_nil(options.preview.filesize, 15)
  options.preview.fill = F.if_nil(options.preview.fill, "X")
  options.preview.treesitter = F.if_nil(options.preview.treesitter, true)

  local cache_path = Path:new(options.cache_path)
  scope.load_caches(cache_path)
  local UEBERZUG

  if options.backend == "ueberzug" then
    UEBERZUG = Ueberzug:new(os.tmpname())
    UEBERZUG:listen()
  end
  -- }}}

  -- Preview function. {{{
  local function preview_fn(_, entry, status)
    local buffer = status.preview_bufnr
    local window = status.preview_win
    local filepath = fn.fnamemodify(entry.value, ":p")
    local extension = fn.fnamemodify(filepath, ":e"):lower()

    local preview_filetype = filetype.detect(extension, { fs_access = true })
    if preview_filetype == "" then preview_filetype = extension end

    local preview_window = options.get_preview_window()
    local handler = scope.supports[extension]

    uv.fs_stat(entry.value, function(_, stat)
      -- File size limit check. {{{
      -- stylua: ignore start
      if options.preview.filesize then
        local megabyte_filesize = math.floor(stat.size / math.pow(1024, 2))
        if megabyte_filesize > options.preview.filesize then
          -- TODO: Find a better way of doing this.
          ueberzug_hide(options, UEBERZUG)
          vim.schedule(function()
            preview_utils.set_preview_message(buffer, window, "FILE EXCEEDS PREVIEW SIZE LIMIT", options.preview.fill)
          end)
          return
        end
      end
      -- stylua: ignore end
      -- }}}

      options.start_time = vim.loop.hrtime()
      Path:new(filepath):_read_async(vim.schedule_wrap(function(data)
        if not api.nvim_buf_is_valid(buffer) then return end
        local processed_data = split(data, "[\r]?\n", _, options)

        if processed_data then
          if handler then
            vim.schedule(function() api.nvim_buf_set_lines(buffer, 0, -1, false, { "" }) end)
            local path = handler(filepath, cache_path, {})

            -- Caching current entry check. {{{
            -- stylua: ignore start
            if path == vim.NIL then
              ueberzug_hide(options, UEBERZUG)
              vim.schedule(function()
                preview_utils.set_preview_message(buffer, window, "CACHING PREVIEW IMAGE", options.preview.fill)
              end)
              return
            end
            -- stylua: ignore end
            -- }}}

            -- Define backends and their functionality. {{{
            if options.backend == "ueberzug" and UEBERZUG then
              UEBERZUG:send({
                path = path,
                x = preview_window.col + options.geometry.x,
                y = preview_window.line + options.geometry.y,
                width = preview_window.width + options.geometry.width,
                height = preview_window.height + options.geometry.height,
              })
            elseif options.backend == "viu" then
            ---@todo
            elseif options.backend == "chafa" then
            ---@todo
            elseif options.backend == "jp2a" then
              ---@todo
            end
            -- }}}
          else
            -- Text file preview. {{{
            -- TODO: Find a better way of doing this.
            ueberzug_hide(options, UEBERZUG)
            local task = Job:new({ "cat", filepath })
            local mime = (utils.get_os_command_output({ "file", "--mime-type", "--brief", filepath }))[1]
            local mimetype = vim.split(mime, "/", { plain = true })[1]

            -- stylua: ignore start
            task:add_on_exit_callback(function(...)
              local args = { ... }
              local result = args[1]:result()
              if args[2] == 0 then
                if mimetype ~= "text" and mimetype ~= "inode" then
                  vim.schedule(function()
                    preview_utils.set_preview_message(buffer, window, "PREVIEW UNAVAILABLE", options.preview.fill)
                  end)
                else
                  vim.schedule(function()
                    api.nvim_buf_set_lines(buffer, 0, -1, false, result)
                    preview_utils.highlighter(buffer, preview_filetype, options)
                  end)
                end
              else
                vim.schedule(function()
                  preview_utils.set_preview_message(buffer, window, "PERMISSION DENIED", options.preview.fill)
                end)
              end
            end)
            task:start()
            -- stylua: ignore end
            -- }}}
          end
        else
          -- Time limit check. {{{
          -- stylua: ignore start
          ueberzug_hide(options, UEBERZUG)
          vim.schedule(function()
            preview_utils.set_preview_message(buffer, window, "PREVIEWER TIMED OUT", options.preview.fill)
          end)
          return
          -- stylua: ignore end
          -- }}}
        end
      end))
    end)
  end
  -- }}}

  -- Setup, teardown and scroll functions. {{{
  local function setup() scope.cleanup(cache_path) end

  local function scroll_fn(self, direction)
    if not self.state then return end
    local input = direction > 0 and [[]] or [[]]
    local count = math.abs(direction)
    api.nvim_win_call(self.state.winid, function() api.nvim_command([[normal! ]] .. count .. input) end)
  end

  local function teardown()
    if UEBERZUG then UEBERZUG:kill() end
  end
  -- }}}

  return previewers.new({
    setup = setup,
    preview_fn = preview_fn,
    teardown = teardown,
    scroll_fn = scroll_fn,
  })
end, {})

return MediaPreview
-- }}}

-- vim:filetype=lua:fileencoding=utf-8
