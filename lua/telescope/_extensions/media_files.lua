local has_telescope, telescope = pcall(require, "telescope")

-- TODO: make dependency errors occur in a better way
if not has_telescope then
  error("This plugin requires telescope.nvim (https://github.com/nvim-telescope/telescope.nvim)")
end


local utils = require('telescope.utils')
local defaulter = utils.make_default_callable
local actions = require('telescope.actions')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local previewers = require('telescope.previewers')
local conf = require('telescope.config').values

local M = {}

M.base_directory=""
M.media_preview = defaulter(function(opts)
    return previewers.new_termopen_previewer {
        get_command = opts.get_command or function(entry)
        local tmp_table = vim.split(entry.value,"\t");
        local preview = opts.get_preview_window()
        if vim.tbl_isempty(tmp_table) then
          return {"echo", ""}
        end
        return {
          M.base_directory .. '/scripts/vimg' ,
          tmp_table[1],
          preview.col ,
          preview.line ,
          preview.width ,
          preview.height
        }
      end
  }
end, {})

function M.media_files(opts)
print(vim.inspect(require('telescope').extensions.media_files))
  local sourced_file = require('plenary.debug_utils').sourced_filepath()
  M.base_directory = vim.fn.fnamemodify(sourced_file, ":h:h:h:h")
  opts = opts or {}
  opts.attach_mappings= function(prompt_bufnr,map)
    actions.goto_file_selection_edit:replace(function()
        local entry = actions.get_selected_entry()
        actions.close(prompt_bufnr)
        if entry[1] then
            local filename = entry[1]
            local cmd="call setreg(v:register,'"..filename.."')";
            print(vim.inspect(cmd))
            vim.cmd(cmd)
        end
    end)

     map('i','<c-t>',function ()
       vim.cmd[[stopinsert]]
     end)

    return true
  end
  opts.shorten_path = true
  local filetype ={"png", "jpg", "mp4", "webm", "pdf" }
  local find_command={
    'find',
    '.',
    '-iregex',
    [[.*\.\(]]..table.concat(filetype,"\\|") .. [[\)$]]
  }
  if 1 == vim.fn.executable("fd") then
    find_command = {
      'fdfind' ,
      '--type', 'f',
      '--regex',
      [[.*.(]]..table.concat(filetype,"|") .. [[)$]],
      '.'
    }
  elseif 1 == vim.fn.executable("fdfind") then
    find_command = {
      'fdfind' ,
      '--type', 'f',
      '--regex',
      [[.*.(]]..table.concat(filetype,"|") .. [[)$]],
      '.'
    }
  end

  local popup_opts={}
  opts.get_preview_window=function ()
    return popup_opts.preview
  end
  local picker=pickers.new(opts, {
    prompt_title = 'Media Files',
    finder = finders.new_oneshot_job(
      find_command,
      opts
    ),
    previewer = M.media_preview.new(opts),
    sorter = conf.file_sorter(opts),
  })


  local line_count = vim.o.lines - vim.o.cmdheight
  if vim.o.laststatus ~= 0 then
    line_count = line_count - 1
  end
  popup_opts = picker:get_window_options(vim.o.columns, line_count)
  picker:find()
end


return require('telescope').register_extension {
    exports = {
      media_files = M.media_files
    },
}
