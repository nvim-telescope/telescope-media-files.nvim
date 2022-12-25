<div align="center">

# telescope-media-files.nvim

Preview IMAGES, PDF, EPUB, VIDEO, and FONTS from Neovim using Telescope.

</div>

> NOTE: This plugin is only supported in Linux.

## PACKER

```lua
use({
  "nvim-telescope/telescope-media-files.nvim",
  config = function()
    require("telescope").load_extension("media_files")
  end,
  requires = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  }
})
```

## SETUP

``` lua
require("telescope").load_extension("media_files")
```

## CONFIG

This extension should be configured using `extensions` field inside Telescope.

```lua
require("telescope").setup({
  extensions = {
    media_files = {
      geometry = {
        x = -2,
        y = -2,
        width = 1,
        height = 1,
      },
      find_command = {
        "rg",
        "--files",
        "--glob",
        [[*.{]] .. "png,jpg,gif,mp4,webm,pdf" .. [[}]],
        ".",
      },
      on_confirm = function(filepath)
        vim.fn.setreg(vim.v.register, filepath)
        vim.notify("The image path has been copied!")
      end,
    },
})
```

## COMMANDS

```viml
:Telescope media_files

"Using lua function
lua require('telescope').extensions.media_files.media_files()
```

## Prerequisites

- [Überzug](https://github.com/seebye/ueberzug) (required for image support)
- [fd](https://github.com/sharkdp/fd) / [rg](https://github.com/BurntSushi/ripgrep) / [find](https://man7.org/linux/man-pages/man1/find.1.html) or fdfind in Ubuntu/Debian.
- [ffmpegthumbnailer](https://github.com/dirkvdb/ffmpegthumbnailer) (optional, for video preview support)
- [pdftoppm](https://linux.die.net/man/1/pdftoppm) (optional, for pdf preview support. Available in the AUR as **poppler** package.)
- [epub-thumbnailer](https://github.com/marianosimone/epub-thumbnailer) (optional, for epub preview support.)
- [fontpreview](https://github.com/sdushantha/fontpreview) (optional, for font preview support)

Credit to [vifmimg](https://github.com/cirala/vifmimg).
