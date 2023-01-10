---Minimal init file to run Feline with the most basic functionality
---Run from Feline top-level directory using:
---nvim --noplugin -u minimal.lua

---export env before you run the command
local TMPDIR = os.getenv("MEDIA_DEBUG_TEMPDIR")

local function load_plugins()
  local packer = require("packer")
  local use = packer.use

  packer.reset()
  packer.init({
    package_root = TMPDIR .. "/nvim/site/pack",
    git = {
      clone_timeout = -1,
    },
  })

  use({ "wbthomason/packer.nvim" })

  use({
    "dharmx/telescope-media.nvim",
    requires = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "kyazdani42/nvim-web-devicons",
    },
  })

  packer.install()
  packer.compile()
end

local function load_config()
  vim.o.termguicolors = true
  vim.o.colorcolumn = "120"
  vim.o.number = true

  require("telescope").setup({
    extensions = {
      media = {
        backend = "jp2a",
      },
    },
  })

  ---:lua MEDIA()
  function _G.MEDIA() require("telescope").extensions.media.media() end
end

local install_path = TMPDIR .. "/nvim/site/pack/packer/start/packer.nvim"

vim.o.packpath = TMPDIR .. "/nvim/site"
vim.g.loaded_remote_plugins = 1

if vim.fn.isdirectory(install_path) == 0 then
  vim.fn.system({ "git", "clone", "https://github.com/wbthomason/packer.nvim", install_path })
end

load_plugins()
vim.api.nvim_create_autocmd("User", {
  callback = load_config,
  pattern = "PackerComplete",
  desc = "Load colo config after packer is loaded.",
  once = true,
})

vim.notify("Remember to remove " .. TMPDIR .. " after testing.")
vim.notify("Remember to remove the generated packer_compiled.lua after testing.")

---vim:filetype=lua
